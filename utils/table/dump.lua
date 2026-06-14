local type, tostring, next = type, tostring, next;
local concat, sort = table.concat, table.sort;
local find, gsub, match = string.find, string.gsub, string.match;
local math_type = math.type;

local escape_map = {
	["\\"] = "\\\\",
	['"']  = '\\"',
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
	["\0"] = "\\0",
};
local escape_match = '[\\"\n\r\t%z]';

local INDENTS = {};
for i = 0, 64 do
	INDENTS[i] = "\n" .. string.rep("  ", i);
end;

local function get_indent(depth)
	local s = INDENTS[depth];
	if (not s) then
		s = "\n" .. string.rep("  ", depth);
		INDENTS[depth] = s;
	end;
	return s;
end;

local function sort_handler(a, b)
	if (type(a) == "string" and type(b) == "string") then return a < b; end;
	return tostring(a) < tostring(b);
end;

local function encode_scalar(output, output_n, v, vt, wrap_quote)
	if (vt == "string") then
		output_n         = output_n + 1;
		output[output_n] = find(v, escape_match)
			and '"' .. gsub(v, escape_match, escape_map) .. '"'
			or '"' .. v .. '"';
	elseif (vt == "number" or vt == "boolean") then
		output_n         = output_n + 1;
		output[output_n] = tostring(v);
	else
		output_n         = output_n + 1;
		output[output_n] = wrap_quote
			and '"<' .. tostring(v) .. '>"'
			or '<' .. tostring(v) .. '>';
	end;
	return output_n;
end;

local function plain_seq_len(t)
	local n = #t;
	if (n == 0) then return 0; end;
	for k in next, t do
		local kt = math_type(k);
		if (not (kt == "integer" and k >= 1 and k <= n)) then
			return false;
		end;
		if (type(t[k]) == "table") then
			return false;
		end;
	end;
	return n;
end;

local function render_inline(output, output_n, node, n, wrap_quote)
	if (n == 0) then
		output_n         = output_n + 1;
		output[output_n] = "{}";
		return output_n;
	end;

	output_n         = output_n + 1;
	output[output_n] = "{ ";
	for i = 1, n do
		local v  = node[i];
		local vt = type(v);
		output_n = encode_scalar(output, output_n, v, vt, wrap_quote);
		if (i < n) then
			output_n         = output_n + 1;
			output[output_n] = ", ";
		end;
	end;
	output_n         = output_n + 1;
	output[output_n] = " }";
	return output_n;
end;

--- Dump table into readable string using stack-based iteration
--- @param root table<any, any>
--- @param opt? { sort?: boolean, wrap_quote?: boolean }
--- @return string
local function dump_table(root, opt)
	if (type(root) ~= "table") then return tostring(root); end;

	local sort_keys  = opt and opt.sort;
	local wrap_quote = opt and opt.wrap_quote;
	local cycle_str  = wrap_quote and '"<cycle>"' or "<cycle>";

	do
		local n = plain_seq_len(root);
		if (n) then
			local buf = {};
			render_inline(buf, 0, root, n, wrap_quote);
			return concat(buf);
		end;
	end;

	local output   = {};
	local output_n = 1;
	local seen     = {};
	local stack    = {};
	local stack_n  = 1;

	stack[1]   = { root, 0, 1, nil, nil, 1, false, nil, };
	seen[root] = true;
	output[1]  = "{";

	while stack_n > 0 do
		local frame   = stack[stack_n];
		local node    = frame[1];
		local depth   = frame[2];
		local seq_len = #node;
		local indent  = get_indent(depth + 1);

		local seq_i = frame[3];
		if (seq_i <= seq_len) then
			frame[3] = seq_i + 1;

			output_n         = output_n + 1;
			output[output_n] = indent;

			local v  = node[seq_i];
			local vt = type(v);
			if (vt == "table") then
				local pn = plain_seq_len(v);
				if (pn) then
					output_n         = render_inline(output, output_n, v, pn, wrap_quote);
					output_n         = output_n + 1;
					output[output_n] = ",";
				elseif (seen[v]) then
					output_n         = output_n + 1;
					output[output_n] = cycle_str .. ",";
				else
					seen[v]          = true;
					output_n         = output_n + 1;
					output[output_n] = "{";
					stack_n          = stack_n + 1;
					stack[stack_n]   = { v, depth + 1, 1, nil, nil, 1, false, nil, };
				end;
			else
				output_n         = encode_scalar(output, output_n, v, vt, wrap_quote);
				output_n         = output_n + 1;
				output[output_n] = ",";
			end;
		elseif (frame[7]) then
			seen[node]       = nil;
			output_n         = output_n + 1;
			output[output_n] = get_indent(depth) .. "}] = ";
			stack_n          = stack_n - 1;

			local v  = frame[8];
			local vt = type(v);
			if (vt == "table") then
				local pn = plain_seq_len(v);
				if (pn) then
					output_n         = render_inline(output, output_n, v, pn, wrap_quote);
					output_n         = output_n + 1;
					output[output_n] = ",";
				elseif (seen[v]) then
					output_n         = output_n + 1;
					output[output_n] = cycle_str .. ",";
				else
					seen[v]          = true;
					output_n         = output_n + 1;
					output[output_n] = "{";
					stack_n          = stack_n + 1;
					stack[stack_n]   = { v, depth, 1, nil, nil, 1, false, nil, };
				end;
			else
				output_n         = encode_scalar(output, output_n, v, vt, wrap_quote);
				output_n         = output_n + 1;
				output[output_n] = ",";
			end;
		else
			local k, v;

			if (sort_keys) then
				local keys = frame[5];
				if (not keys) then
					keys = {};
					local kn = 0;
					for kk in next, node do
						if (not (math_type(kk) == "integer" and kk >= 1 and kk <= seq_len)) then
							kn       = kn + 1;
							keys[kn] = kk;
						end;
					end;
					if (kn > 1) then sort(keys, sort_handler); end;
					frame[5] = keys;
					frame[6] = 1;
				end;
				local mi = frame[6];
				k = keys[mi];
				if (k ~= nil) then
					v        = node[k];
					frame[6] = mi + 1;
				end;
			else
				k, v = next(node, frame[4]);
				while k ~= nil and math_type(k) == "integer" and k >= 1 and k <= seq_len do
					k, v = next(node, k);
				end;
				frame[4] = k;
			end;

			if (k == nil) then
				seen[node]       = nil;
				output_n         = output_n + 1;
				output[output_n] = get_indent(depth) .. "}";
				stack_n          = stack_n - 1;
			else
				local kt = type(k);
				output_n = output_n + 1;

				if (kt == "string") then
					output[output_n] = match(k, "^[_%a][_%a%d]*$")
						and indent .. k .. " = "
						or indent ..
						'["' .. (find(k, escape_match) and gsub(k, escape_match, escape_map) or k) .. '"] = ';
				elseif (kt == "number") then
					output[output_n] = indent .. "[" .. k .. "] = ";
				elseif (kt == "table") then
					if (seen[k]) then
						output[output_n] = indent .. (wrap_quote and '["<cycle>"] = ' or '[<cycle>] = ');
					else
						seen[k]          = true;
						output[output_n] = indent .. "[{";
						stack_n          = stack_n + 1;
						stack[stack_n]   = { k, depth + 1, 1, nil, nil, 1, true, v, };
						goto continue;
					end;
				else
					output[output_n] = indent .. (wrap_quote
						and '["<' .. tostring(k) .. '>"] = '
						or '[<' .. tostring(k) .. '>] = ');
				end;

				local vt = type(v);
				if (vt == "table") then
					local pn = plain_seq_len(v);
					if (pn) then
						output_n         = render_inline(output, output_n, v, pn, wrap_quote);
						output_n         = output_n + 1;
						output[output_n] = ",";
					elseif (seen[v]) then
						output_n         = output_n + 1;
						output[output_n] = cycle_str .. ",";
					else
						seen[v]          = true;
						output_n         = output_n + 1;
						output[output_n] = "{";
						stack_n          = stack_n + 1;
						stack[stack_n]   = { v, depth + 1, 1, nil, nil, 1, false, nil, };
					end;
				else
					output_n         = encode_scalar(output, output_n, v, vt, wrap_quote);
					output_n         = output_n + 1;
					output[output_n] = ",";
				end;
			end;
		end;

		::continue::
	end;

	return concat(output);
end;

return dump_table;

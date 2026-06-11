local type, tostring, next = type, tostring, next;
local concat, sort = table.concat, table.sort;
local find, gsub, match = string.find, string.gsub, string.match;

local escape_map = {
	["\\"] = "\\\\",
	['"'] = '\\"',
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
	local indent = INDENTS[depth];
	if (not indent) then
		indent = "\n" .. string.rep("  ", depth);
		INDENTS[depth] = indent;
	end;
	return indent;
end;

local function sort_handler(a, b)
	local a_type, b_type = type(a), type(b);
	if (a_type == "string" and b_type == "string") then return a < b; end;
	return tostring(a) < tostring(b);
end;

local function escape_str(s)
	return find(s, escape_match) and gsub(s, escape_match, escape_map) or s;
end;

local output = {};
local output_n = 0;
local seen = {};
local sort_keys, wrap_quote, cycle_str;

local function format_node(node, depth)
	seen[node] = true;
	output_n = output_n + 1;
	output[output_n] = "{";

	local len = #node;
	local indent = get_indent(depth + 1);

	if (len > 0) then
		for i = 1, len do
			local v = node[i];
			local v_type = type(v);

			output_n = output_n + 2;
			output[output_n - 1] = indent;
			output[output_n] = "[" .. i .. "] = ";

			if (v_type == "string") then
				output_n = output_n + 1;
				output[output_n] = '"' .. escape_str(v) .. '",';
			elseif (v_type == "number" or v_type == "boolean") then
				output_n = output_n + 1;
				output[output_n] = tostring(v) .. ",";
			elseif (v_type == "table") then
				if (seen[v]) then
					output_n = output_n + 1;
					output[output_n] = cycle_str;
				else
					format_node(v, depth + 1);
					output_n = output_n + 1;
					output[output_n] = ",";
				end;
			else
				output_n = output_n + 1;
				output[output_n] =
					wrap_quote
					and '"<' .. tostring(v) .. '>",'
					or '<' .. tostring(v) .. '>,';
			end;
		end;
	end;

	local keys;
	local kn = 0;

	if (sort_keys) then
		keys = {};
		for k in next, node do
			if (type(k) ~= "number" or k < 1 or k > len or k % 1 ~= 0) then
				kn = kn + 1;
				keys[kn] = k;
			end;
		end;
		if (kn > 1) then
			sort(keys, sort_handler);
		end;
	end;

	local iter_limit = sort_keys and kn or 0;
	local k, v;
	local i = 1;

	while (true) do
		if (sort_keys) then
			if (i > iter_limit) then break; end;
			k = keys[i];
			v = node[k];
			i = i + 1;
		else
			k, v = next(node, k);
			if (k == nil) then break; end;
			if (type(k) == "number" and k >= 1 and k <= len and k % 1 == 0) then
				goto continue;
			end;
		end;

		local k_type = type(k);
		output_n = output_n + 1;

		if (k_type == "string") then
			if (match(k, "^[_%a][_%a%d]*$")) then
				output[output_n] = indent .. k .. " = ";
			else
				output[output_n] = indent .. '["' .. escape_str(k) .. '"] = ';
			end;
		elseif (k_type == "number") then
			output[output_n] = indent .. "[" .. k .. "] = ";
		elseif (k_type == "table") then
			if (seen[k]) then
				output[output_n] =
					indent ..
					(wrap_quote
						and '["<cycle>"] = '
						or '[<cycle>] = ');
			else
				output[output_n] = indent .. "[";
				format_node(k, depth + 1);
				output_n = output_n + 1;
				output[output_n] = "] = ";
			end;
		else
			output[output_n] =
				indent ..
				(wrap_quote
					and '["<' .. tostring(k) .. '>"] = '
					or '[<' .. tostring(k) .. '>] = ');
		end;

		local v_type = type(v);
		if (v_type == "string") then
			output_n = output_n + 1;
			output[output_n] = '"' .. escape_str(v) .. '",';
		elseif (v_type == "number" or v_type == "boolean") then
			output_n = output_n + 1;
			output[output_n] = tostring(v) .. ",";
		elseif (v_type == "table") then
			if (seen[v]) then
				output_n = output_n + 1;
				output[output_n] = cycle_str;
			else
				format_node(v, depth + 1);
				output_n = output_n + 1;
				output[output_n] = ",";
			end;
		else
			output_n = output_n + 1;
			output[output_n] =
				wrap_quote
				and '"<' .. tostring(v) .. '>",'
				or '<' .. tostring(v) .. '>,';
		end;

		::continue::
	end;

	seen[node] = nil;
	output_n = output_n + 1;
	output[output_n] = get_indent(depth) .. "}";
end;

--- Dump table into readable string using recursive call
--- @param root table<any, any>
--- @param opt? { sort?: boolean, wrap_quote?: boolean }
--- @return string
local function dump_table(root, opt)
	if (type(root) ~= "table") then return tostring(root); end;

	sort_keys  = opt and opt.sort;
	wrap_quote = opt and opt.wrap_quote;
	cycle_str  = wrap_quote and '"<cycle>",' or "<cycle>,";

	output_n = 0;

	format_node(root, 0);

	local final_str = concat(output, "", 1, output_n);
	seen = {};

	return final_str;
end;

return dump_table;

local type, tostring, next = type, tostring, next;
local concat, sort = table.concat, table.sort;
local find, gsub, match, rep = string.find, string.gsub, string.match, string.rep;

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
	INDENTS[i] = "\n" .. rep("  ", i);
end;

local out   = {};
local out_n = 0;
local seen  = {};

local OPT_SORT       = false;
local OPT_WRAP_QUOTE = false;
local CYCLE_STR      = "<cycle>,";

local function get_indent(depth)
	local s = INDENTS[depth];
	if (not s) then
		s = "\n" .. rep("  ", depth);
		INDENTS[depth] = s;
	end;
	return s;
end;

local function escape_str(s)
	return find(s, escape_match) and gsub(s, escape_match, escape_map) or s;
end;

local function sort_handler(a, b)
	if (type(a) == "string" and type(b) == "string") then return a < b; end;
	return tostring(a) < tostring(b);
end;

local format_node;

local function write_value(v, v_type, depth)
	if (v_type == "string") then
		out_n = out_n + 1;
		out[out_n] = '"' .. escape_str(v) .. '",';
	elseif (v_type == "number" or v_type == "boolean") then
		out_n = out_n + 1;
		out[out_n] = tostring(v) .. ",";
	elseif (v_type == "table") then
		if (seen[v]) then
			out_n = out_n + 1;
			out[out_n] = CYCLE_STR;
		else
			format_node(v, depth);
			out_n = out_n + 1;
			out[out_n] = ",";
		end;
	else
		out_n = out_n + 1;
		if (OPT_WRAP_QUOTE) then
			out[out_n] = '"<' .. tostring(v) .. '>",';
		else
			out[out_n] = '<' .. tostring(v) .. '>,';
		end;
	end;
end;

format_node = function(node, depth)
	seen[node] = true;

	out_n = out_n + 1;
	out[out_n] = "{";

	local child_indent = get_indent(depth + 1);
	local self_indent  = get_indent(depth);

	local len = #node;
	if (len > 0) then
		for i = 1, len do
			local v      = node[i];
			local v_type = type(v);

			out_n          = out_n + 2;
			out[out_n - 1] = child_indent;
			out[out_n]     = "[" .. i .. "] = ";

			write_value(v, v_type, depth + 1);
		end;
	end;

	if (OPT_SORT) then
		local keys = {};
		local kn   = 0;
		for k in next, node do
			local kt = type(k);
			if (not (kt == "number" and k >= 1 and k <= len and k % 1 == 0)) then
				kn = kn + 1;
				keys[kn] = k;
			end;
		end;
		if (kn > 1) then sort(keys, sort_handler); end;

		for i = 1, kn do
			local k      = keys[i];
			local k_type = type(k);
			local v      = node[k];
			local v_type = type(v);

			out_n = out_n + 1;
			if (k_type == "string") then
				if (match(k, "^[_%a][_%a%d]*$")) then
					out[out_n] = child_indent .. k .. " = ";
				else
					out[out_n] = child_indent .. '["' .. escape_str(k) .. '"] = ';
				end;
			elseif (k_type == "number") then
				out[out_n] = child_indent .. "[" .. k .. "] = ";
			elseif (k_type == "table") then
				if (seen[k]) then
					out[out_n] = child_indent .. (OPT_WRAP_QUOTE and '["<cycle>"] = ' or '[<cycle>] = ');
				else
					out[out_n] = child_indent .. "[";
					format_node(k, depth + 1);
					out_n = out_n + 1;
					out[out_n] = "] = ";
				end;
			else
				out[out_n] = child_indent .. (OPT_WRAP_QUOTE
					and '["<' .. tostring(k) .. '>"] = '
					or '[<' .. tostring(k) .. '>] = ');
			end;

			write_value(v, v_type, depth + 1);
		end;
	else
		local k, v = next(node, nil);
		while (k ~= nil) do
			local k_type = type(k);
			if (not (k_type == "number" and k >= 1 and k <= len and k % 1 == 0)) then
				local v_type = type(v);

				out_n = out_n + 1;
				if (k_type == "string") then
					if (match(k, "^[_%a][_%a%d]*$")) then
						out[out_n] = child_indent .. k .. " = ";
					else
						out[out_n] = child_indent .. '["' .. escape_str(k) .. '"] = ';
					end;
				elseif (k_type == "number") then
					out[out_n] = child_indent .. "[" .. k .. "] = ";
				elseif (k_type == "table") then
					if (seen[k]) then
						out[out_n] = child_indent .. (OPT_WRAP_QUOTE and '["<cycle>"] = ' or '[<cycle>] = ');
					else
						out[out_n] = child_indent .. "[";
						format_node(k, depth + 1);
						out_n = out_n + 1;
						out[out_n] = "] = ";
					end;
				else
					out[out_n] = child_indent .. (OPT_WRAP_QUOTE
						and '["<' .. tostring(k) .. '>"] = '
						or '[<' .. tostring(k) .. '>] = ');
				end;

				write_value(v, v_type, depth + 1);
			end;
			k, v = next(node, k);
		end;
	end;

	seen[node] = nil;

	out_n = out_n + 1;
	out[out_n] = self_indent .. "}";
end;

--- Dump table into readable string using recursive call
--- @param root table<any, any>
--- @param opt? { sort?: boolean, wrap_quote?: boolean }
--- @return string
local function dump_table(root, opt)
	if (type(root) ~= "table") then return tostring(root); end;

	OPT_SORT       = opt and opt.sort or false;
	OPT_WRAP_QUOTE = opt and opt.wrap_quote or false;
	CYCLE_STR      = OPT_WRAP_QUOTE and '"<cycle>",' or "<cycle>,";

	out_n = 0;

	format_node(root, 0);

	local result = concat(out, "", 1, out_n);

	for k in next, seen do seen[k] = nil; end;

	return result;
end;

return dump_table;

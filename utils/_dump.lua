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

local OPT_SORT       = false;
local OPT_WRAP_QUOTE = false;

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

local function write_value(v, v_type, depth, out, n)
	if (v_type == "string") then
		out[n + 1] = '"';
		out[n + 2] = escape_str(v);
		out[n + 3] = '",';
		return n + 3;
	elseif (v_type == "number") then
		out[n + 1] = v;
		out[n + 2] = ",";
		return n + 2;
	elseif (v_type == "boolean") then
		out[n + 1] = v and "true," or "false,";
		return n + 1;
	elseif (v_type == "table") then
		n = format_node(v, depth, out, n);
		out[n + 1] = ",";
		return n + 1;
	else
		out[n + 1] = OPT_WRAP_QUOTE
			and ('"<' .. tostring(v) .. '>",')
			or ('<' .. tostring(v) .. '>,');
		return n + 1;
	end;
end;

format_node = function(node, depth, out, n)
	n = n + 1;
	out[n] = "{";

	local child_indent = get_indent(depth + 1);
	local self_indent  = get_indent(depth);

	local len = #node;
	if (len > 0) then
		for i = 1, len do
			local v      = node[i];
			local v_type = type(v);

			out[n + 1] = child_indent;
			out[n + 2] = "[";
			out[n + 3] = i;
			out[n + 4] = "] = ";
			n = n + 4;

			n = write_value(v, v_type, depth + 1, out, n);
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

			if (k_type == "string") then
				if (match(k, "^[_%a][_%a%d]*$")) then
					out[n + 1] = child_indent;
					out[n + 2] = k;
					out[n + 3] = " = ";
					n = n + 3;
				else
					out[n + 1] = child_indent;
					out[n + 2] = '["';
					out[n + 3] = escape_str(k);
					out[n + 4] = '"] = ';
					n = n + 4;
				end;
			elseif (k_type == "number") then
				out[n + 1] = child_indent;
				out[n + 2] = "[";
				out[n + 3] = k;
				out[n + 4] = "] = ";
				n = n + 4;
			elseif (k_type == "table") then
				out[n + 1] = child_indent;
				out[n + 2] = "[";
				n = n + 2;
				n = format_node(k, depth + 1, out, n);
				out[n + 1] = "] = ";
				n = n + 1;
			else
				out[n + 1] = child_indent;
				out[n + 2] = OPT_WRAP_QUOTE
					and ('["<' .. tostring(k) .. '>"] = ')
					or ('[<' .. tostring(k) .. '>] = ');
				n = n + 2;
			end;

			n = write_value(v, v_type, depth + 1, out, n);
		end;
	else
		local k, v = next(node, nil);
		while (k ~= nil) do
			local k_type = type(k);
			if (not (k_type == "number" and k >= 1 and k <= len and k % 1 == 0)) then
				local v_type = type(v);

				if (k_type == "string") then
					if (match(k, "^[_%a][_%a%d]*$")) then
						out[n + 1] = child_indent;
						out[n + 2] = k;
						out[n + 3] = " = ";
						n = n + 3;
					else
						out[n + 1] = child_indent;
						out[n + 2] = '["';
						out[n + 3] = escape_str(k);
						out[n + 4] = '"] = ';
						n = n + 4;
					end;
				elseif (k_type == "number") then
					out[n + 1] = child_indent;
					out[n + 2] = "[";
					out[n + 3] = k;
					out[n + 4] = "] = ";
					n = n + 4;
				elseif (k_type == "table") then
					out[n + 1] = child_indent;
					out[n + 2] = "[";
					n = n + 2;
					n = format_node(k, depth + 1, out, n);
					out[n + 1] = "] = ";
					n = n + 1;
				else
					out[n + 1] = child_indent;
					out[n + 2] = OPT_WRAP_QUOTE
						and ('["<' .. tostring(k) .. '>"] = ')
						or ('[<' .. tostring(k) .. '>] = ');
					n = n + 2;
				end;

				n = write_value(v, v_type, depth + 1, out, n);
			end;
			k, v = next(node, k);
		end;
	end;

	out[n + 1] = self_indent;
	out[n + 2] = "}";
	return n + 2;
end;

--- Dump table into readable string using recursive call.
--- @param root table<any, any>
--- @param opt? { sort?: boolean, wrap_quote?: boolean }
--- @return string
local function dump_table(root, opt)
	if (type(root) ~= "table") then return tostring(root); end;

	OPT_SORT       = opt and opt.sort or false;
	OPT_WRAP_QUOTE = opt and opt.wrap_quote or false;

	local out = {};
	local n = format_node(root, 0, out, 0);

	return concat(out, "", 1, n);
end;

return dump_table;

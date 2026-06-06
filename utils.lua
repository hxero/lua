local escape_map = {
	["\\"] = "\\\\",
	['"'] = '\\"',
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
	["\0"] = "\\0",
};
local function escape(s)
	return tostring(s):gsub('[\\"\n\r\t%z]', escape_map);
end;

local function dump_table(node)
	local indent_char = "  ";
	local indent_cache = { [0] = "", };
	local cache, stack, output = {}, {}, { "{\n", };
	local depth = 1;

	local function _indent(d)
		if (not indent_cache[d]) then
			indent_cache[d] = _indent(d - 1) .. indent_char;
		end;
		return indent_cache[d];
	end;

	while (true) do
		local keys = {};
		for k in next, node do
			keys[#keys + 1] = k;
		end;
		local nested = false;
		for i = (cache[node] or 1), #keys, 1 do
			local k = keys[i];
			local v = node[k];

			local k_type, v_type = type(k), type(v);
			local key = (k_type == "number" or k_type == "boolean")
				and ("[" .. tostring(k) .. "]")
				or ('["' .. escape(k) .. '"]');

			local indent = _indent(depth);

			if (v_type == "table") then
				nested = true;

				output[#output + 1] = indent .. key .. " = {\n";
				stack[#stack + 1]   = node;
				stack[#stack + 1]   = v;

				cache[node] = i + 1;
				depth       = depth + 1;
				break;
			else
				local value = (v_type == "number" or v_type == "boolean")
					and tostring(v)
					or ('"' .. escape(v) .. '"');

				output[#output + 1] = indent .. key .. " = " .. value .. ",\n";
			end;
		end;

		if (not nested) then
			depth = depth - 1;
			output[#output + 1] = _indent(depth) .. "},\n";
		end;

		if (#stack > 0) then
			node = stack[#stack];
			stack[#stack] = nil;
		else
			break;
		end;
	end;

	return table.concat(output);
end;

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
	local indent_char  = "  ";
	local indent_cache = { [0] = "", };

	local cache, stack, output = {}, {}, { "{\n", };

	local depth = 1;
	local function _indent(d)
		if (not indent_cache[d]) then
			indent_cache[d] = _indent(d - 1) .. indent_char;
		end;
		return indent_cache[d];
	end;

	local function get_keys(obj, seen)
		seen = seen or {};
		if (seen[obj]) then return {}; end;
		seen[obj] = true;

		local keys = {};
		local o_type = type(obj);

		if (o_type == "table") then
			for k in next, obj do keys[#keys + 1] = k; end;
			local mt = getmetatable(obj);
			if mt and mt.__index then
				local sub = get_keys(mt.__index, seen);
				for _, k in ipairs(sub) do keys[#keys + 1] = k; end;
			end;
		elseif (o_type == "userdata") then
			keys[#keys + 1] = "COMPUTED PROPERTY";
			local mt = getmetatable(obj);
			if (mt and mt.__index) then
				local __index = mt.__index;
				if (type(__index) == "table") then
					local sub_keys = get_keys(__index, seen);
					for _, k in ipairs(sub_keys) do keys[#keys + 1] = k; end;
				end;
			end;
		end;

		return keys;
	end;

	while (true) do
		local keys = get_keys(node);
		local nested = false;
		for i = (cache[node] or 1), #keys, 1 do
			local k = keys[i];
			local s, v = pcall(function() return node[k]; end);
			if (not s) then v = "[ERROR INDEXING]"; end;

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

return {
	dump_table = dump_table,
};

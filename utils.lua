local function escape(s)
	return tostring(s)
		:gsub("\\", "\\\\")
		:gsub('"', '\\"')
		:gsub("\n", "\\n")
		:gsub("\r", "\\r")
		:gsub("\t", "\\t")
		:gsub("%z", "\\0");
end;

local function dump_table(node)
	local indent_char = "  ";

	local cache, stack, output = {}, {}, { "{\n", };
	local depth = 1;

	while (true) do
		local keys = {};
		for k in next, node do
			keys[#keys + 1] = k;
		end;
		local size   = #keys;
		local start  = cache[node] or 1;
		local nested = false;
		for i = start, size, 1 do
			local k = keys[i];
			local v = node[k];

			local k_type, v_type = type(k), type(v);
			local key = (k_type == "number" or k_type == "boolean")
				and ("[" .. tostring(k) .. "]")
				or ('["' .. escape(k) .. '"]');

			local indent = string.rep(indent_char, depth);

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
			output[#output + 1] = string.rep(indent_char, depth) .. "},\n";
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

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
	local indent_cache = setmetatable({}, {
		__index = function(t, k)
			local res = string.rep(indent_char, k);
			t[k] = res;
			return res;
		end,
	});

	local cache, stack, output = {}, {}, { "{\n", };
	local output_len = 1;
	local depth = 1;

	local function get_keys(obj)
		local keys = {};
		if (type(obj) == "table") then
			for k in next, obj do keys[#keys + 1] = k; end;
			local mt = getmetatable(obj);
			if (mt and type(mt.__index) == "table") then
				for k in next, mt.__index do keys[#keys + 1] = k; end;
			end;
		elseif (type(obj) == "userdata") then
			keys[1] = "COMPUTED PROPERTY";
		end;
		return keys;
	end;

	while (node) do
		if (not cache[node]) then
			cache[node] = { k = get_keys(node), i = 1, };
		end;

		local state = cache[node];
		local keys = state.k;
		local nested = false;

		for i = state.i, #keys do
			local k = keys[i];
			local success, v = pcall(function() return node[k]; end);
			if (not success) then v = "[ERROR]"; end;

			local k_type, v_type = type(k), type(v);
			local key = (k_type == "number" or k_type == "boolean")
				and ("[" .. tostring(k) .. "]")
				or ('["' .. escape(k) .. '"]');

			local indent = indent_cache[depth];

			if (v_type == "table" and not cache[v]) then
				output_len = output_len + 1;
				output[output_len] = indent .. key .. " = {\n";

				state.i = i + 1;
				stack[#stack + 1] = node;
				node = v;
				depth = depth + 1;
				nested = true;
				break;
			else
				local value = (v_type == "number" or v_type == "boolean")
					and tostring(v)
					or ('"' .. escape(tostring(v)) .. '"');
				output_len = output_len + 1;
				output[output_len] = indent .. key .. " = " .. value .. ",\n";
			end;
		end;

		if (not nested) then
			output_len = output_len + 1;
			output[output_len] = indent_cache[depth - 1] .. "},\n";
			depth = depth - 1;
			node = table.remove(stack);
		end;
	end;

	return table.concat(output);
end;

return {
	dump_table = dump_table,
};

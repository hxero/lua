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

local function dump_table(node, opt)
	local indent_char = opt.indent or "  ";
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

	local keys_buf = {};

	local function get_keys(obj)
		local type_obj = type(obj);
		if (type_obj ~= "table") then
			if (type_obj == "userdata") then
				return { "COMPUTED PROPERTY", };
			end;
			return {};
		end;

		local len = 0;
		for k in next, obj do
			len = len + 1;
			keys_buf[len] = k;
		end;

		local mt = getmetatable(obj);
		if (mt and type(mt.__index) == "table") then
			for k in next, mt.__index do
				len = len + 1;
				keys_buf[len] = k;
			end;
		end;

		if (not opt.sorted) then
			local keys = keys_buf;
			keys_buf = {};
			return keys;
		end

		if (len <= 1) then
			if (len == 1) then
				local single = { keys_buf[1], };
				keys_buf[1] = nil;
				return single;
			end;
			return {};
		end;

		table.sort(keys_buf);

		local sorted_keys = {};
		for i = 1, len, 1 do
			sorted_keys[i] = keys_buf[i];
			keys_buf[i] = nil;
		end;

		return sorted_keys;
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
			local v = node[k];

			local k_type, v_type = type(k), type(v);
			local key_str;
			if k_type == "number" or k_type == "boolean" then
				key_str = "[" .. tostring(k) .. "]";
			else
				key_str = '["' .. escape(k) .. '"]';
			end;

			local indent = indent_cache[depth];

			if (v_type == "table" and not cache[v]) then
				output_len = output_len + 1;
				output[output_len] = indent .. key_str .. " = {\n";

				state.i = i + 1;
				stack[#stack + 1] = node;
				node = v;
				depth = depth + 1;
				nested = true;
				break;
			else
				local val_str = (v_type == "number" or v_type == "boolean")
					and tostring(v)
					or ('"' .. escape(tostring(v)) .. '"');
				output_len = output_len + 1;
				output[output_len] = indent .. key_str .. " = " .. val_str .. ",\n";
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

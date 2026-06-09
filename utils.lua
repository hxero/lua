local type, tostring, next, getmetatable =
	type, tostring, next, getmetatable;
local rep, sort, concat, gsub =
	string.rep, table.sort, table.concat, string.gsub;

local escape_map = {
	["\\"] = "\\\\",
	['"'] = '\\"',
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
	["\0"] = "\\0",
};
local function escape(s)
	return gsub(tostring(s), '[\\"\n\r\t%z]', escape_map);
end;

local type_order = {
	number       = 1,
	string       = 2,
	boolean      = 3,
	table        = 4,
	userdata     = 5,
	["function"] = 6,
	thread       = 7,
};

local function sorter(a, b)
	local a_type, b_type = type(a), type(b);
	if (a_type ~= b_type) then
		return (type_order[a_type] or 8) < (type_order[b_type] or 8);
	end;
	return a < b;
end;

local function dump_table(node, opt)
	if (type(node) ~= "table") then return tostring(node); end;
	opt = opt or {};

	local indent_char  = opt.indent or "  ";
	local indent_cache = setmetatable({ [0] = "", }, {
		__index = function(t, k)
			local res = rep(indent_char, k);
			t[k] = res;
			return res;
		end,
	});

	local close_cache = setmetatable({ [0] = "},\n", }, {
		__index = function(t, k)
			local res = indent_cache[k] .. "},\n";
			t[k] = res;
			return res;
		end,
	});

	local node_keys = {};
	local node_i    = {};

	local cache, stack, output = {}, {}, { "{\n", };

	local output_len = 1;
	local stack_len  = 0;
	local depth      = 1;

	local sorted = opt.sorted;

	local function get_keys(obj)
		local type_obj = type(obj);
		if (type_obj ~= "table") then
			if (type_obj == "userdata") then
				return { "COMPUTED PROPERTY", };
			end;
			return {};
		end;

		local keys = {};
		local len = 0;
		for k in next, obj do
			len = len + 1;
			keys[len] = k;
		end;

		local mt = getmetatable(obj);
		if (mt) then
			local __index = mt.__index;
			if (type(__index) == "table") then
				for k in next, __index do
					len = len + 1;
					keys[len] = k;
				end;
			end;
		end;

		if (sorted and len > 1) then
			sort(keys, sorter);
		end;

		return keys;
	end;

	while (node) do
		local keys = node_keys[node];
		if (not keys) then
			keys = get_keys(node);
			node_keys[node] = keys;
			node_i[node] = 1;
		end;

		local nested = false;

		local keys_len = #keys;
		local indent = indent_cache[depth];

		local start = node_i[node];

		for i = start, keys_len, 1 do
			local k = keys[i];
			local v = node[k];

			local k_type, v_type = type(k), type(v);
			local key_str;
			if (k_type == "number" or k_type == "boolean") then
				key_str = "[" .. tostring(k) .. "]";
			else
				key_str = '["' .. escape(k) .. '"]';
			end;

			if (v_type == "table" and not cache[v]) then
				output_len = output_len + 1;
				output[output_len] = indent .. key_str .. " = {\n";

				node_i[node] = i + 1;

				stack_len = stack_len + 1;
				stack[stack_len] = node;

				node = v;
				depth = depth + 1;
				nested = true;
				break;
			else
				local val_str;
				if (v_type ~= "string") then
					val_str = tostring(v);
				else
					val_str = '"' .. escape(v) .. '"';
				end;

				output_len = output_len + 1;
				output[output_len] = indent .. key_str .. " = " .. val_str .. ",\n";
			end;
		end;

		if (not nested) then
			output_len = output_len + 1;
			output[output_len] = close_cache[depth - 1];
			depth = depth - 1;

			if (stack_len > 0) then
				node = stack[stack_len];
				stack[stack_len] = nil;
				stack_len = stack_len - 1;
			else
				node = nil;
			end;
		end;
	end;

	return concat(output);
end;

return {
	dump_table = dump_table,
};

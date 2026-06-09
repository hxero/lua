local type, tostring, next = type, tostring, next;
local concat, sort = table.concat, table.sort;
local match, gsub, find = string.match, string.gsub, string.find;

local escape_map = {
	["\\"] = "\\\\",
	['"'] = '\\"',
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
	["\0"] = "\\0",
};
local escape_match = '[\\"\n\r\t%z]';

local INT_KEY_CACHE = {};
for i = 1, 2048 do INT_KEY_CACHE[i] = "[" .. i .. "]"; end;

local INDENT_CACHE = { [0] = "", };
for i = 1, 64 do INDENT_CACHE[i] = INDENT_CACHE[i - 1] .. "  "; end;

local function sort_raw(a, b)
	return a < b;
end;

local function sort_fallback(a, b)
	local ta, tb = type(a), type(b);
	if (ta == "string" and tb == "string") then return a < b; end;
	return tostring(a) < tostring(b);
end;

local function dump_table(root, opt)
	if (type(root) ~= "table") then return tostring(root); end;
	local sort_keys = opt.sort;

	local out = { "{\n", };
	local out_n = 1;
	local visited = { [root] = true, };

	local keys_cache = {};

	local stack = {};
	local stack_n = 1;
	stack[1] = { root, 1, #root, nil, 0, false, nil, };

	while (stack_n > 0) do
		local current = stack[stack_n];

		local t       = current[1];
		local i       = current[2];
		local len     = current[3];
		local k       = current[4];
		local depth   = current[5];
		local is_hash = current[6];

		local child_depth = depth + 1;
		local child_indent = INDENT_CACHE[child_depth] or string.rep("  ", child_depth);

		if (not is_hash) then
			if (i <= len) then
				current[2] = i + 1;
				local v = t[i];
				local k_str = INT_KEY_CACHE[i] or ("[" .. i .. "]");
				local v_type = type(v);

				out_n = out_n + 1;
				if (v_type == "string") then
					out[out_n] = child_indent ..
						k_str .. ' = "' .. (find(v, escape_match) and gsub(v, escape_match, escape_map) or v) .. '",\n';
				elseif (v_type == "number") then
					out[out_n] = child_indent .. k_str .. " = " .. v .. ",\n";
				elseif (v_type == "boolean") then
					out[out_n] = child_indent .. k_str .. (v and " = true,\n" or " = false,\n");
				elseif (v_type == "table") then
					if (visited[v]) then
						out[out_n] = child_indent .. k_str .. ' = "<cycle>",\n';
					else
						visited[v] = true;
						out[out_n] = child_indent .. k_str .. " = {\n";
						stack_n = stack_n + 1;
						stack[stack_n] = { v, 1, #v, nil, child_depth, false, nil, };
					end;
				else
					out[out_n] = child_indent .. k_str .. ' = "<' .. tostring(v) .. '>",\n';
				end;
			else
				current[6] = true;

				if (sort_keys) then
					local keys = keys_cache[depth];
					if (not keys) then
						keys = {};
						keys_cache[depth] = keys;
					end;

					local keys_n = 0;
					local first_type;
					local uniform = true;

					for hk in next, t do
						if (type(hk) ~= "number" or hk < 1 or hk > len or hk % 1 ~= 0) then
							keys_n = keys_n + 1;
							keys[keys_n] = hk;

							if (uniform) then
								local tk = type(hk);
								if (not first_type) then
									first_type = tk;
								elseif (tk ~= first_type) then
									uniform = false;
								end;
							end;
						end;
					end;

					for m = keys_n + 1, #keys do keys[m] = nil; end;

					if (keys_n > 1) then
						if (uniform and (first_type == "string" or first_type == "number")) then
							sort(keys, sort_raw);
						else
							sort(keys, sort_fallback);
						end;
					end;

					current[7] = keys;
					current[4] = 1;
				end;
			end;
		else
			local next_k, v;
			if (sort_keys) then
				local keys = current[7];
				local idx = current[4];
				next_k = keys[idx];
				if (next_k ~= nil) then
					v = t[next_k];
					current[4] = idx + 1;
				end;
			else
				next_k, v = next(t, k);
				current[4] = next_k;
			end;

			if (next_k ~= nil) then
				if (not sort_keys and (type(next_k) == "number" and next_k >= 1 and next_k <= len and next_k % 1 == 0)) then
					-- continue
				else
					local k_type = type(next_k);
					local prefix;

					if (k_type == "string") then
						if (match(next_k, "^[_%a][_%a%d]*$")) then
							prefix = child_indent .. next_k .. " = ";
						else
							prefix = child_indent ..
								'["' ..
								(find(next_k, escape_match) and gsub(next_k, escape_match, escape_map) or next_k) ..
								'"] = ';
						end;
					elseif (k_type == "number") then
						prefix = child_indent .. (INT_KEY_CACHE[next_k] or ("[" .. next_k .. "]")) .. " = ";
					else
						prefix = child_indent .. '["<' .. tostring(next_k) .. '>"] = ';
					end;

					local v_type = type(v);
					out_n = out_n + 1;
					if (v_type == "string") then
						out[out_n] = prefix ..
							'"' .. (find(v, escape_match) and gsub(v, escape_match, escape_map) or v) .. '"' .. ",\n";
					elseif (v_type == "number") then
						out[out_n] = prefix .. v .. ",\n";
					elseif (v_type == "boolean") then
						out[out_n] = prefix .. (v and "true,\n" or "false,\n");
					elseif (v_type == "table") then
						if (visited[v]) then
							out[out_n] = prefix .. '"<cycle>",\n';
						else
							visited[v] = true;
							out[out_n] = prefix .. "{\n";
							stack_n = stack_n + 1;
							stack[stack_n] = { v, 1, #v, nil, child_depth, false, nil, };
						end;
					else
						out[out_n] = prefix .. '"<' .. tostring(v) .. '>",\n';
					end;
				end;
			else
				visited[t] = nil;
				if (stack_n > 1) then
					out_n = out_n + 1;
					local parent_indent = INDENT_CACHE[depth] or string.rep("  ", depth);
					out[out_n] = parent_indent .. "},\n";
				end;
				stack_n = stack_n - 1;
			end;
		end;
	end;

	out_n = out_n + 1;
	out[out_n] = "}\n";

	return concat(out);
end;

return { dump_table = dump_table, };

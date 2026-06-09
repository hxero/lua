local type, tostring, next = type, tostring, next;
local concat = table.concat;
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

local function dump_table(root)
	if type(root) ~= "table" then return tostring(root); end;

	local out = { "{\n", };
	local out_n = 1;
	local visited = { [root] = true, };

	-- may 'stackoverflow' on tables too deep but,
	-- you rarely see a too deep table,
	-- otherwise you have other problem to worry about
	local function dump(t, depth)
		local child_depth = depth + 1;
		local child_indent = INDENT_CACHE[child_depth] or string.rep("  ", child_depth);

		local len = #t;

		if len > 0 then
			for i = 1, len do
				local v = t[i];
				local k_str = INT_KEY_CACHE[i] or ("[" .. i .. "]");
				local v_type = type(v);

				out_n = out_n + 1;
				if v_type == "string" then
					out[out_n] = child_indent ..
							k_str .. ' = "' .. (find(v, escape_match) and gsub(v, escape_match, escape_map) or v) .. '",\n';
				elseif v_type == "number" then
					out[out_n] = child_indent .. k_str .. " = " .. v .. ",\n";
				elseif v_type == "boolean" then
					out[out_n] = child_indent .. k_str .. (v and " = true,\n" or " = false,\n");
				elseif v_type == "table" then
					if visited[v] then
						out[out_n] = child_indent .. k_str .. ' = "<cycle>",\n';
					else
						visited[v] = true;
						out[out_n] = child_indent .. k_str .. " = {\n";
						dump(v, child_depth);
						out_n = out_n + 1;
						out[out_n] = child_indent .. "},\n";
					end;
				else
					out[out_n] = child_indent .. k_str .. ' = "<' .. tostring(v) .. '>",\n';
				end;
			end;
		end;

		for k, v in next, t do
			if type(k) ~= "number" or k < 1 or k > len or k % 1 ~= 0 then
				local k_type = type(k);
				local prefix;

				if k_type == "string" then
					if match(k, "^[_%a][_%a%d]*$") then
						prefix = child_indent .. k .. " = ";
					else
						prefix = child_indent ..
								'["' .. (find(k, escape_match) and gsub(k, escape_match, escape_map) or k) .. '"] = ';
					end;
				elseif k_type == "number" then
					prefix = child_indent .. (INT_KEY_CACHE[k] or ("[" .. k .. "]")) .. " = ";
				else
					prefix = child_indent .. '["<' .. tostring(k) .. '>"] = ';
				end;

				local v_type = type(v);
				out_n = out_n + 1;
				if v_type == "string" then
					out[out_n] = prefix ..
							'"' .. (find(v, escape_match) and gsub(v, escape_match, escape_map) or v) .. '"' .. ",\n";
				elseif v_type == "number" then
					out[out_n] = prefix .. v .. ",\n";
				elseif v_type == "boolean" then
					out[out_n] = prefix .. (v and "true,\n" or "false,\n");
				elseif v_type == "table" then
					if visited[v] then
						out[out_n] = prefix .. '"<cycle>",\n';
					else
						visited[v] = true;
						out[out_n] = prefix .. "{\n";
						dump(v, child_depth);
						out_n = out_n + 1;
						out[out_n] = child_indent .. "},\n";
					end;
				else
					out[out_n] = prefix .. '"<' .. tostring(v) .. '>",\n';
				end;
			end;
		end;
	end;

	dump(root, 0);

	out_n = out_n + 1;
	out[out_n] = "}\n";

	return concat(out);
end;

return { dump_table = dump_table, };

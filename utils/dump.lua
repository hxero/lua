local type, tostring, next = type, tostring, next;
local concat, sort = table.concat, table.sort;
local find, gsub, match = string.find, string.gsub, string.match;

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
	INDENTS[i] = "\n" .. string.rep("  ", i);
end;

local function get_indent(depth)
	local indent = INDENTS[depth];
	if (not indent) then
		indent = "\n" .. string.rep("  ", depth);
		INDENTS[depth] = indent;
	end;
	return indent;
end;

local function sort_handler(a, b)
	local a_type, b_type = type(a), type(b);
	if (a_type == "string" and b_type == "string") then return a < b; end;
	return tostring(a) < tostring(b);
end;

--- Dump table into readable string
--- @param root table<any, any>
--- @param opt? { sort?: boolean, wrap_quote?: boolean }
--- @return string
local function dump_table(root, opt)
	if (type(root) ~= "table") then return tostring(root); end;

	local sort_keys  = opt and opt.sort;
	local wrap_quote = opt and opt.wrap_quote;
	local cycle_str  = wrap_quote and '"<cycle>"' or "<cycle>";

	local output = {};
	local output_n = 0;
	local seen = {};

	local function format_node(node, depth)
		seen[node] = true;
		output_n = output_n + 1;
		output[output_n] = "{";

		local len = #node;
		local indent = get_indent(depth + 1);

		for i = 1, len do
			local v = node[i];
			local v_type = type(v);
			output_n = output_n + 1;
			output[output_n] = indent .. "[" .. i .. "] = ";

			if (v_type == "string") then
				output_n = output_n + 1;
				output[output_n] = find(v, escape_match) and '"' .. gsub(v, escape_match, escape_map) .. '",' or
					'"' .. v .. '",';
			elseif (v_type == "number" or v_type == "boolean") then
				output_n = output_n + 1;
				output[output_n] = tostring(v) .. ",";
			elseif (v_type == "table") then
				if (seen[v]) then
					output_n = output_n + 1;
					output[output_n] = cycle_str .. ",";
				else
					format_node(v, depth + 1);
					output_n = output_n + 1;
					output[output_n] = ",";
				end;
			else
				output_n = output_n + 1;
				output[output_n] = wrap_quote and '"<' .. tostring(v) .. '>",' or '<' .. tostring(v) .. '>,';
			end;
		end;

		local keys;
		if (sort_keys) then
			keys = {};
			local kn = 0;
			for k in next, node do
				if (type(k) ~= "number" or k < 1 or k > len or k % 1 ~= 0) then
					kn = kn + 1;
					keys[kn] = k;
				end;
			end;
			if (kn > 1) then
				sort(keys, sort_handler);
			end;
		end;

		local k, v;
		local idx = 1;
		while (true) do
			if (sort_keys) then
				k = keys[idx];
				if (k == nil) then break; end;
				v = node[k];
				idx = idx + 1;
			else
				k, v = next(node, k);
				if (k == nil) then break; end;
				if (type(k) == "number" and k >= 1 and k <= len and k % 1 == 0) then
					goto continue;
				end;
			end;

			local k_type = type(k);
			output_n = output_n + 1;

			if (k_type == "string") then
				if (match(k, "^[_%a][_%a%d]*$")) then
					output[output_n] = indent .. k .. " = ";
				else
					output[output_n] =
						indent ..
						'["' .. (find(k, escape_match)
							and gsub(k, escape_match, escape_map)
							or k) .. '"] = ';
				end;
			elseif (k_type == "number") then
				output[output_n] = indent .. "[" .. k .. "] = ";
			elseif (k_type == "table") then
				if (seen[k]) then
					output[output_n] =
						indent ..
						(wrap_quote
							and '["<cycle>"] = '
							or '[<cycle>] = ');
				else
					output[output_n] = indent .. "[";
					format_node(k, depth + 1);
					output_n = output_n + 1;
					output[output_n] = "] = ";
				end;
			else
				output[output_n] =
					indent ..
					(wrap_quote
						and '["<' .. tostring(k) .. '>"] = '
						or '[<' .. tostring(k) .. '>] = ');
			end;

			local v_type = type(v);
			if (v_type == "string") then
				output_n = output_n + 1;
				output[output_n] =
					find(v, escape_match)
					and '"' .. gsub(v, escape_match, escape_map) .. '",'
					or '"' .. v .. '",';
			elseif (v_type == "number" or v_type == "boolean") then
				output_n = output_n + 1;
				output[output_n] = tostring(v) .. ",";
			elseif (v_type == "table") then
				if (seen[v]) then
					output_n = output_n + 1;
					output[output_n] = cycle_str .. ",";
				else
					format_node(v, depth + 1);
					output_n = output_n + 1;
					output[output_n] = ",";
				end;
			else
				output_n = output_n + 1;
				output[output_n] = wrap_quote and '"<' .. tostring(v) .. '>",' or '<' .. tostring(v) .. '>,';
			end;

			::continue::
		end;

		seen[node] = nil;
		output_n = output_n + 1;
		output[output_n] = get_indent(depth) .. "}";
	end;

	format_node(root, 0);
	return concat(output);
end;

return dump_table;

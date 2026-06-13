--- Clones the table
--- @generic K, V
--- @param tbl  table<K, V>
--- @param opt? { is_array?: boolean, deep?: boolean, iterative?: boolean }
--- @return table<K, V>
local function clone(tbl, opt)
	if (not tbl or not next(tbl)) then return tbl; end;
	local is_array  = opt and opt.is_array or false;
	local deep      = opt and opt.deep or false;
	local iterative = opt == nil or opt.iterative == nil or opt.iterative ~= false;

	if (not deep) then
		local result = {};
		if (is_array) then
			for i = 1, #tbl do
				result[i] = tbl[i];
			end;
		else
			for k, v in next, tbl do
				result[k] = v;
			end;
		end;
		return result;
	end;

	local memo = {};
	memo[tbl]  = {};
	local root = memo[tbl];

	if (iterative) then
		local stack     = { { tbl, root, }, };
		local stack_top = 1;

		if (is_array) then
			while stack_top > 0 do
				local entry = stack[stack_top];
				stack[stack_top] = nil;
				stack_top = stack_top - 1;

				local node, dest = entry[1], entry[2];
				for i = 1, #node do
					local v = node[i];
					if (type(v) == "table") then
						if (memo[v]) then
							dest[i] = memo[v];
						else
							local child      = {};
							memo[v]          = child;
							dest[i]          = child;
							stack_top        = stack_top + 1;
							stack[stack_top] = { v, child, };
						end;
					else
						dest[i] = v;
					end;
				end;
			end;
		else
			while stack_top > 0 do
				local entry = stack[stack_top];
				stack[stack_top] = nil;
				stack_top = stack_top - 1;

				local node, dest = entry[1], entry[2];
				for k, v in next, node do
					if (type(v) == "table") then
						if (memo[v]) then
							dest[k] = memo[v];
						else
							local child      = {};
							memo[v]          = child;
							dest[k]          = child;
							stack_top        = stack_top + 1;
							stack[stack_top] = { v, child, };
						end;
					else
						dest[k] = v;
					end;
				end;
			end;
		end;
	else
		local recurse;
		if (is_array) then
			recurse = function(node, dest)
				for i = 1, #node do
					local v = node[i];
					if (type(v) == "table") then
						if (memo[v]) then
							dest[i] = memo[v];
						else
							local child = {};
							memo[v]     = child;
							dest[i]     = child;
							recurse(v, child);
						end;
					else
						dest[i] = v;
					end;
				end;
			end;
		else
			recurse = function(node, dest)
				for k, v in next, node do
					if (type(v) == "table") then
						if (memo[v]) then
							dest[k] = memo[v];
						else
							local child = {};
							memo[v]     = child;
							dest[k]     = child;
							recurse(v, child);
						end;
					else
						dest[k] = v;
					end;
				end;
			end;
		end;
		recurse(tbl, root);
	end;

	return root;
end;

return clone;

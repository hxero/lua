--- Flatten the table
--- @generic K, T, K2, V2
--- @param tbl  table<K, T<K2, V2>>
--- @param opt? { is_array?: boolean, override?: boolean, iterative?: boolean }
--- @return table<K, V2>
local function flat(tbl, opt)
	if (not tbl or not next(tbl)) then return tbl; end;
	local is_array  = opt and opt.is_array or false;
	local override  = opt and opt.override or false;
	local iterative = opt == nil or opt.iterative == nil or opt.iterative ~= false;
	local result    = {};
	local result_n  = 0;

	if (iterative) then
		local stack     = { tbl, };
		local stack_top = 1;
		if (is_array) then
			while (stack_top > 0) do
				local node = stack[stack_top];
				stack[stack_top] = nil;
				stack_top = stack_top - 1;
				for i = 1, #node do
					local v = node[i];
					if (type(v) == "table") then
						stack_top = stack_top + 1;
						stack[stack_top] = v;
					else
						result_n = result_n + 1;
						result[result_n] = v;
					end;
				end;
			end;
		else
			while (stack_top > 0) do
				local node = stack[stack_top];
				stack[stack_top] = nil;
				stack_top = stack_top - 1;
				for _, v in next, node do
					if (type(v) == "table") then
						stack_top = stack_top + 1;
						stack[stack_top] = v;
					else
						result_n = result_n + 1;
						result[result_n] = v;
					end;
				end;
			end;
		end;
	else
		local recurse;
		if (is_array) then
			recurse = function(node)
				for i = 1, #node do
					local v = node[i];
					if (type(v) == "table") then
						recurse(v);
					else
						result_n = result_n + 1;
						result[result_n] = v;
					end;
				end;
			end;
		else
			recurse = function(node)
				for _, v in next, node do
					if (type(v) == "table") then
						recurse(v);
					else
						result_n = result_n + 1;
						result[result_n] = v;
					end;
				end;
			end;
		end;
		recurse(tbl);
	end;

	if (override) then
		for i = 1, result_n do
			tbl[i] = result[i];
		end;
		for i = result_n + 1, #tbl do
			tbl[i] = nil;
		end;
		if (not is_array) then
			for k in next, tbl do
				if (type(k) ~= "number") then
					tbl[k] = nil;
				end;
			end;
		end;
		return tbl;
	end;

	return result;
end;

return flat;

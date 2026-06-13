--- Merge two tables
--- with from overriding into if identical keys
--- @param into table<any, any>
--- @param from table<any, any>
--- @param opt? { override?: boolean }
--- @return table<any, any>
local function deep_merge(into, from, opt)
	local type, next = type, next;
	local override = not (opt and opt.override == false);
	local k, v = next(from);
	if (k == nil) then return into; end;
	local stack = {};
	local stack_top = 0;
	local node_1 = into;
	local node_2 = from;
	while (true) do
		while (k ~= nil) do
			local v_1 = node_1[k];
			if (type(v) == "table" and type(v_1) == "table") then
				stack_top            = stack_top + 3;
				stack[stack_top - 2] = node_1;
				stack[stack_top - 1] = node_2;
				stack[stack_top]     = next(node_2, k);
				node_1               = v_1;
				node_2               = v;
				k, v                 = next(node_2);
			elseif (type(v) == "table" and v_1 == nil) then
				local copy           = {};
				node_1[k]            = copy;
				stack_top            = stack_top + 3;
				stack[stack_top - 2] = node_1;
				stack[stack_top - 1] = node_2;
				stack[stack_top]     = next(node_2, k);
				node_1               = copy;
				node_2               = v;
				k, v                 = next(node_2);
			else
				if (override or v_1 == nil) then
					node_1[k] = v;
				end;
				k, v = next(node_2, k);
			end;
		end;
		if (stack_top > 0) then
			k         = stack[stack_top];
			node_2    = stack[stack_top - 1];
			node_1    = stack[stack_top - 2];
			stack_top = stack_top - 3;
			if (k ~= nil) then
				v = node_2[k];
			end;
		else
			break;
		end;
	end;
	return into;
end;
return deep_merge;

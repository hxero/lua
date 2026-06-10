local type, next = type, next

--- Merge two tables with `from` overriding `into` if identical keys
--- @param into table<any, any>
--- @param from table<any, any>
--- @return table<any, any>
local function deep_merge(into, from)
	local stack = {};
	local stack_top = 0;

	local node_1 = into;
	local node_2 = from;

	while (true) do
		local k, v = next(node_2);
		while (k ~= nil) do
			local v_1 = node_1[k];

			if (type(v) == "table" and type(v_1) == "table") then
				stack_top = stack_top + 2;
				stack[stack_top - 1] = v_1;
				stack[stack_top] = v;
			else
				node_1[k] = v;
			end;
			k, v = next(node_2, k);
		end;

		if (stack_top > 0) then
			node_2 = stack[stack_top];
			node_1 = stack[stack_top - 1];
			stack_top = stack_top - 2;
		else
			break;
		end;
	end;

	return into;
end;

return deep_merge;

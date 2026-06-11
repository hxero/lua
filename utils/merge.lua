local type, next = type, next;

--- Merge two table
--- with `from` overriding `into` if identical keys
--- @param into table<any, any>
--- @param from table<any, any>
--- @return table<any, any>
local function deep_merge(into, from)
	local stack = {};
	local stack_top = 0;

	local node_1 = into;
	local node_2 = from;
	local k, v = next(node_2);

	while (true) do
		while (k ~= nil) do
			local v_1 = node_1[k];

			if (type(v) == "table" and type(v_1) == "table") then
				local next_k = next(node_2, k);

				stack_top = stack_top + 3;

				stack[stack_top - 2] = node_1;
				stack[stack_top - 1] = node_2;
				stack[stack_top]     = next_k;

				node_1 = v_1;
				node_2 = v;
				k, v = next(node_2);
			else
				node_1[k] = v;
				k, v = next(node_2, k);
			end;
		end;

		if (stack_top > 0) then
			k      = stack[stack_top];
			node_2 = stack[stack_top - 1];
			node_1 = stack[stack_top - 2];

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

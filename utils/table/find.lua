--- Find a value in a table
--- @generic K, V
--- @param tbl  table<K, V>
--- @param val  V | fun(v: V, k?: K): unknown
--- @param opt? { is_array?: boolean, deep?: "iterative" | "recursive" | nil }
--- @return V, K | nil
local function find(tbl, val, opt)
	local type, next = type, next;
	if (not tbl or not next(tbl)) then return nil; end;

	local is_array = opt == nil or opt.is_array == nil or opt.is_array ~= false;
	local deep     = opt and opt.deep or 1;

	local is_fn = type(val) == "function";

	-- stack based iteration
	if (deep == "iterative") then
		local stack     = { tbl, };
		local stack_top = 1;
		if (is_fn) then
			if (is_array) then
				while (stack_top > 0) do
					local node = stack[stack_top];
					stack[stack_top] = nil;
					stack_top = stack_top - 1;
					for i = 1, #node do
						local v = node[i];
						if (val(v, i)) then
							return v, i;
						end;
						if (type(v) == "table") then
							stack_top = stack_top + 1;
							stack[stack_top] = v;
						end;
					end;
				end;
			else
				while (stack_top > 0) do
					local node = stack[stack_top];
					stack[stack_top] = nil;
					stack_top = stack_top - 1;
					for k, v in next, node do
						if (val(v, k)) then
							return v, k;
						end;
						if (type(v) == "table") then
							stack_top = stack_top + 1;
							stack[stack_top] = v;
						end;
					end;
				end;
			end;
		else
			if (is_array) then
				while (stack_top > 0) do
					local node = stack[stack_top];
					stack[stack_top] = nil;
					stack_top = stack_top - 1;
					for i = 1, #node do
						local v = node[i];
						if (v == val) then
							return v, i;
						end;
						if (type(v) == "table") then
							stack_top = stack_top + 1;
							stack[stack_top] = v;
						end;
					end;
				end;
			else
				while (stack_top > 0) do
					local node = stack[stack_top];
					stack[stack_top] = nil;
					stack_top = stack_top - 1;
					for k, v in next, node do
						if (v == val) then
							return v, k;
						end;
						if (type(v) == "table") then
							stack_top = stack_top + 1;
							stack[stack_top] = v;
						end;
					end;
				end;
			end;
		end;
		return nil;
	end;

	-- recursive call stacks
	if (deep == "recursive") then
		local function recurse(node)
			if (is_fn) then
				if (is_array) then
					for i = 1, #node do
						local v = node[i];
						if (val(v, i)) then return v, i; end;
						if (type(v) == "table") then
							local rv, rk = recurse(v);
							if (rv ~= nil) then return rv, rk; end;
						end;
					end;
				else
					for k, v in next, node do
						if (val(v, k)) then return v, k; end;
						if (type(v) == "table") then
							local rv, rk = recurse(v);
							if (rv ~= nil) then return rv, rk; end;
						end;
					end;
				end;
			else
				if (is_array) then
					for i = 1, #node do
						local v = node[i];
						if (v == val) then return v, i; end;
						if (type(v) == "table") then
							local rv, rk = recurse(v);
							if (rv ~= nil) then return rv, rk; end;
						end;
					end;
				else
					for k, v in next, node do
						if (v == val) then return v, k; end;
						if (type(v) == "table") then
							local rv, rk = recurse(v);
							if (rv ~= nil) then return rv, rk; end;
						end;
					end;
				end;
			end;
			return nil;
		end;
		return recurse(tbl);
	end;

	-- basic default
	if (is_fn) then
		if (is_array) then
			for i = 1, #tbl do
				local v = tbl[i];
				if (val(v, i)) then return v, i; end;
			end;
		else
			for k, v in next, tbl do
				if (val(v, k)) then return v, k; end;
			end;
		end;
	else
		if (is_array) then
			for i = 1, #tbl do
				local v = tbl[i];
				if (v == val) then return v, i; end;
			end;
		else
			for k, v in next, tbl do
				if (v == val) then return v, k; end;
			end;
		end;
	end;

	return nil;
end;

return find;

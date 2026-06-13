--- Filters table values
--- @generic V, K
--- @param tbl  table<K, V>
--- @param fn   fun(v: V, k: K): boolean
--- @param opt? { is_array?: boolean, override?: boolean }
local function filter(tbl, fn, opt)
	if (not tbl or not next(tbl)) then return tbl; end;

	local is_array = opt and opt.is_array or false;
	local override = opt and opt.override or false;

	if (is_array) then
		if (override) then
			local insert_n = 1;
			local len = #tbl;
			for i = 1, len do
				local v = tbl[i];
				if (fn(v, i)) then
					tbl[insert_n] = v;
					insert_n = insert_n + 1;
				end;
			end;

			for i = insert_n, len do
				tbl[i] = nil;
			end;
			return tbl;
		else
			local result = {};
			local insert_n = 1;
			local len = #tbl;
			for i = 1, len do
				local v = tbl[i];
				if (fn(v, i)) then
					result[insert_n] = v;
					insert_n = insert_n + 1;
				end;
			end;
			return result;
		end;
	else
		if (override) then
			for k, v in next, tbl do
				if (not fn(v, k)) then
					tbl[k] = nil;
				end;
			end;
			return tbl;
		else
			local result = {};
			for k, v in next, tbl do
				if (fn(v, k)) then
					result[k] = v;
				end;
			end;
			return result;
		end;
	end;
end;

return filter;

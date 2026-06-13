--- Maps the table's value
--- @generic K, V, R
--- @param tbl  table<K, V>
--- @param fn   fun(v: V, k?: K): R
--- @param opt? { is_array?: boolean, override?: boolean }
--- @return table<K, R>
local function map(tbl, fn, opt)
	if (not tbl or not next(tbl)) then
		return opt and opt.override and tbl or {};
	end;

	local is_array = opt and opt.is_array or false;
	local override = opt and opt.override or false;

	local result = override and tbl or {};
	if (is_array) then
		local len = #tbl;
		for i = 1, len do
			result[i] = fn(tbl[i], i);
		end;
	else
		for k, v in next, tbl do
			result[k] = fn(v, k);
		end;
	end;

	return result;
end;

return map;

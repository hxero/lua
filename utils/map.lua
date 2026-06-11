--- Maps table's value
--- @generic V, K
--- @param tbl  table<K, V>
--- @param fn   fun(v: V, k?: K): unknown
--- @param opt? { is_array?: boolean, override?: boolean }
local function map(tbl, fn, opt)
	if (not tbl or not next(tbl)) then return tbl; end;

	local override = false;
	local is_array = true;
	if (opt) then
		if (opt.override ~= nil) then override = opt.override; end;
		if (opt.is_array ~= nil) then is_array = opt.is_array; end;
	end;

	local result = override and tbl or {};
	if (is_array) then
		local len = #tbl;
		for i = 1, len, 1 do
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

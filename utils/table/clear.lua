--- Clears the table values
--- @generic K, V
--- @param tbl table<K, V>
--- @param opt? { start: integer };
--- @return table<K, nil>
local function clear(tbl, opt)
	local start = opt and opt.start or false;
	if (start) then
		for i = #tbl, start, -1 do
			tbl[i] = nil;
		end;
		return tbl;
	end;

	for k in next, tbl do
		tbl[k] = nil;
	end;
	return tbl;
end;

return clear;

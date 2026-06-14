--- Clears the table values
--- @generic K, V
--- @param tbl table<K, V>
--- @return table<K, nil>
local function clear(tbl)
	for k in next, tbl do
		tbl[k] = nil;
	end;

	return tbl;
end;

return clear;

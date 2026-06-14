local function clear(tbl)
	for k, v in next, tbl do
		tbl[k] = nil;
	end;

	return tbl;
end;

return clear;

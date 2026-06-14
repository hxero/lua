local function clear(tbl)
	for k, v in next, tbl do
		tbl[k] = nil;
	end;

	return tbl;
end;

print(require "_dump" (clear({ 1, 2, 3, key = "value", })));

return clear;

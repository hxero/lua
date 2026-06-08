local utils = require("inspect"); -- luarocks inspect.lua

local a = {};
for i = 1, 10000, 1 do
	a["mycool" .. tostring(i)] = { a = 1, b = 2, c = i };
end;

local start_dump = os.clock();
print(utils(a));
print("dumping took " .. os.clock() - start_dump)

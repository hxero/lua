local utils = require("utils"); -- my implementation (pure lua)

local a = {};
for i = 1, 10000, 1 do
	a["mycool" .. tostring(i)] = { a = 1, b = 2, c = i };
end;

local start_dump = os.clock();
print(utils.dump_table(a, { sorted = true }));
print("dumping took " .. os.clock() - start_dump)

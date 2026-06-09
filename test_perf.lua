local utils = require("inspect");

local a = {
	1, 2,
	a = 2
};

local start_dump = os.clock();
print(utils(a));
print("dumping took " .. os.clock() - start_dump)

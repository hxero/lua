local utils = require("utils");

local a = {
	1, 2,
	a = 2
};

local start_dump = os.clock();
print(utils.dump_table(a));
print("dumping took " .. os.clock() - start_dump)

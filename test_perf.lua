local utils = require("utils"); -- my implementation (pure lua)

local a = {1, 2, a = 2};

local start_dump = os.clock();
print(utils.dump_table(a, { sorted = true }));
print("dumping took " .. os.clock() - start_dump)

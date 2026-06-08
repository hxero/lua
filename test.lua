local utils = require("utils");

local start_init = os.clock();
local a = {};
for i = 1, 100000, 1 do
	a["mycool" .. tostring(i)] = true;
end;
local end_init = os.clock() - start_init;

local start_dump = os.clock();
print(utils.dump_table(
	a
));
print("dumping took " .. os.clock() - start_dump, "\ninitializing table took " .. end_init)

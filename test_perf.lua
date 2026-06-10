local utils      = require("utils");
local stack_dump = require("_dump");
local inspect    = require("inspect");

local timer = { {}, };
timer.__index = timer;

function timer.new(name, fn)
	local self = setmetatable({}, timer);
	self.name  = name;
	self.fn    = fn;

	timer[1][#timer[1] + 1] = self;
	return self;
end;

function timer.get_timers()
	return timer[1];
end;

function timer:run()
	local clock = os.clock;

	collectgarbage();
	collectgarbage();
	collectgarbage();

	local start = clock();
	self.output = self.fn();
	self.time   = clock() - start;
	return self.output;
end;

function timer:print()
	print(self.name, "took", self.time);
end;

local tbl = { [200] = { true, }, };
for i = 1, 1e5, 1 do
	tbl["mycool" .. tostring(i)] = { tbl, [20] = i, {}, };
end;

timer.new("iteration based", function()
	return utils.dump_table(tbl, { sort = false });
end);

timer.new("recursive based", function()
	return stack_dump.dump_table(tbl, { sort = false });
end);

timer.new("inspect", function()
	return inspect(tbl);
end);

local timers = timer.get_timers();
for i = 1, #timers, 1 do
	local output = timers[i]:run();
	print(string.sub(output, 1, 100));
end;
for i = 1, #timers, 1 do
	timers[i]:print();
end;

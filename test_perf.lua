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

function timer:run(iterations)
	iterations = iterations or 100;

	collectgarbage("collect");

	local clock = os.clock;
	local start = clock();

	for _ = 1, iterations do
		self.output = self.fn();
	end;

	local total_time = clock() - start;

	self.time = total_time / iterations;
	return self.output;
end;

function timer:print()
	print(self.name, "took", self.time);
end;

local tbl = { [200] = { true, }, };
for i = 1, 1e4, 1 do
	tbl["mycool" .. tostring(i)] = { tbl, [20] = i, { { { [2] = { { { { { { { { { { { {}, }, }, }, }, }, }, }, }, }, }, }, }, }, }, };
end;

timer.new("iteration based", function()
	-- usually 10% slower than recursive
	-- no stackoverflow
	return utils.dump_table(tbl, { sort = true, });
end);

timer.new("recursive based", function()
	-- usually the fastest
	-- but prone to stackoverflow on 10,000+ deep nested
	return stack_dump.dump_table(tbl, { sort = true, });
end);

timer.new("inspect", function()
	-- most human readable?
	-- slower because so many checking
	return inspect(tbl);
end);

local timers = timer.get_timers();
for i = 1, #timers, 1 do
	local output = timers[i]:run(10);
	-- print(string.sub(output, 1, 1000) .. "\n...");
end;
for i = 1, #timers, 1 do
	timers[i]:print();
end;

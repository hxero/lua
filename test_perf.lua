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

timer.new("reoksf", function()
	return "";
end);

timer.new("reoksf", function()
	return "1";
end);

local timers = timer.get_timers();
for i = 1, #timers, 1 do
	local output = timers[i]:run();
	print(string.sub(output, 1, 100));
end;
for i = 1, #timers, 1 do
	timers[i]:print();
end;

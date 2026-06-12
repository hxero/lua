local type, tostring, sub = type, tostring, string.sub;
local clock, write = os.clock, io.write;
local setmetatable, collectgarbage = setmetatable, collectgarbage;

local timer = {};
timer.__index = timer;

local instances = {};
setmetatable(instances, { __mode = "k", });

function timer.new(name, fn)
	assert(name, "Missing required argument `name`");
	assert(fn,   "Missing required argument `fn`");

	local self = setmetatable({}, timer);
	self.name  = name;
	self.fn    = fn;

	instances[self] = true;
	return self;
end;

function timer:remove()
	instances[self] = nil;
end;

function timer.clear()
	for inst in next, instances do
		instances[inst] = nil;
	end;
end;

function timer.get_timers()
	local list = {};
	local n = 0;
	for inst in next, instances do
		n = n + 1;
		list[n] = inst;
	end;
	return list;
end;

function timer:run(iterations)
	assert(type(iterations) == "nil" or type(iterations) == "number" or tonumber(iterations),
		"`iterations` must be an integer");

	iterations = math.floor(iterations or 1);

	collectgarbage("collect");

	local start = clock();
	for _ = 1, iterations, 1 do
		self.output = self.fn();
	end;
	local total_time = clock() - start;

	self.time = total_time / iterations;

	local out = self.output;

	return out;
end;

function timer:print()
	write(self.name, " took ", self.time or 0, "\n");
end;

function timer.compares(timers, opt)
	opt = opt or {};
	local len = #timers;
	for i = 1, len, 1 do
		local output = timers[i]:run(opt.iterations or 10);
		if (opt.output and type(opt.output) == "function") then
			write(sub(tostring(opt.output(output)), 1, 100), "\n...\n");
		else
			write(sub(tostring(output), 1, 100), "\n...\n");
		end;
	end;
	for i = 1, len, 1 do
		timers[i]:print();
	end;
end;

return timer;

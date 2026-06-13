local type, tostring, sub = type, tostring, string.sub;
local clock, write = os.clock, io.write;
local setmetatable, collectgarbage = setmetatable, collectgarbage;

--- @class Timer
--- @field name   string The name of this timer
--- @field fn     fun(): any The function being timed
--- @field time   number? The result time from the last run in seconds
--- @field output any The return value from the last run
local timer = {};
timer.__index = timer;

--- @type table<Timer, true>
local instances = {};
setmetatable(instances, { __mode = "k", });

--- Creates a new Timer instance
--- @param name string Name shown when printing results
--- @param fn   fun(): any The function to benchmark
--- @return Timer
function timer.new(name, fn)
	assert(name, "Missing required argument `name`");
	assert(fn,   "Missing required argument `fn`");
	local self = setmetatable({}, timer);
	self.name  = name;
	self.fn    = fn;

	instances[self] = true;
	return self;
end;

--- Removes this timer instance
--- @return nil
function timer:remove()
	instances[self] = nil;
end;

--- Removes all timer instances
--- @return nil
function timer.clear()
	for inst in next, instances do
		instances[inst] = nil;
	end;
end;

--- Returns a list of all instances
--- @return Timer[]
function timer.get_timers()
	local list = {};
	local n    = 0;
	for k in next, instances do
		n = n + 1;
		list[n] = k;
	end;
	return list;
end;

--- Runs the timer's function for given iterations
--- and record the average elapsed time
--- @param iterations? integer Number of times to call `fn` (default: 1)
--- @return any output The return value of the last call
function timer:run(iterations)
	assert(type(iterations) == "nil" or type(iterations) == "number" or tonumber(iterations),
		"`iterations` must be an integer");
	iterations = math.floor(iterations or 1);
	collectgarbage("collect");
	local start = clock();
	for _ = 1, iterations do
		self.output = self.fn();
	end;
	local total_time = clock() - start;
	self.time = total_time / iterations;
	local out = self.output;
	return out;
end;

--- Prints the last time recorded in the stdout
--- @return nil
function timer:print()
	write(self.name, " took ", self.time or 0, "\n");
end;

--- @class timer.ComparesOpt
--- @field iterations? integer Number of times to run the timers' function (default: 10)
--- @field output?    fun(value: any): any  Transform output before printing

--- Runs and compares a list of timers
--- and prints timing summary for all timers
--- @param timers Timer[] The list of timers to compare
--- @param opt?   timer.ComparesOpt
--- @return nil
function timer.compares(timers, opt)
	opt = opt or {};
	local len = #timers;
	for i = 1, len do
		local output = timers[i]:run(opt.iterations or 10);
		if (opt.output and type(opt.output) == "function") then
			write(sub(tostring(opt.output(output)), 1, 100), "\n...\n");
		else
			write(sub(tostring(output), 1, 100), "\n...\n");
		end;
	end;
	for i = 1, len do
		timers[i]:print();
	end;
end;

return timer;

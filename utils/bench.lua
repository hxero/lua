local type, tostring, sub = type, tostring, string.sub;
local clock, write = os.clock, io.write;
local setmetatable, collectgarbage = setmetatable, collectgarbage;

--- @class __HUTILS_BENCH
--- @field name   string
--- @field fn     function
--- @field output unknown | nil
--- @field time   number  | nil
local timer = {};
timer.__index = timer;

--- @type __HUTILS_BENCH[]
local instances = {};
setmetatable(instances, { __mode = "v", });

--- Create a new timer benchmark instance
--- @param name string
--- @param fn   function
--- @return __HUTILS_BENCH
function timer.new(name, fn)
	assert(name, "Missing required argument `name`");
	assert(fn,   "Missing required argument `fn`");

	local self = setmetatable({}, timer);
	self.name  = name;
	self.fn    = fn;

	instances[#instances + 1] = self;
	return self;
end;

--- Get a list of timers
--- @return __HUTILS_BENCH[]
function timer.get_timers()
	return instances;
end;

--- Run the timer
--- @param iterations integer # default: 100
--- @return unknown
function timer:run(iterations)
	assert(
		type(iterations) == "nil" or type(iterations) == "number" or tonumber(iterations),
		"`iterations` must be an integer");

	iterations = math.floor(iterations) or 100;

	collectgarbage("collect");

	local start = clock();

	for _ = 1, iterations, 1 do
		self.output = self.fn();
	end;

	local total_time = clock() - start;

	self.time = total_time / iterations;
	return self.output;
end;

--- Prints the last benchmarked time
function timer:print()
	write(self.name, " took ", self.time);
end;

--- Compares multiple timers instance
--- @param timers __HUTILS_BENCH[]
--- @param opt?   { 
	--- iterations?: integer,
	--- output?: fun(unknown): string } # default: { iterations = 100, output = nil }
function timer.compares(timers, opt)
	opt = opt or {};

	local len = #timers;
	for i = 1, len, 1 do
		local output = tostring(timers[i]:run(opt.iterations or 100));
		if (opt.output) then
			write(sub(opt.output(output), 1, 100) .. "\n..");
		else
			write(sub(output, 1, 100) .. "\n...");
		end;
	end;
	for i = 1, len, 1 do
		timers[i]:print();
	end;
end;

return timer;

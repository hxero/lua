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

function timer.compares(timers, opt)
	opt = opt or {};
	local len = #timers;
	for i = 1, len, 1 do
		local output = timers[i]:run(opt.iterations or 100);
		if (opt.output) then
			print(string.sub(opt.output(output), 1, 100) .. "\n..");
		else
			print(string.sub(output, 1, 100) .. "\n...");
		end;
	end;
	for i = 1, len, 1 do
		timers[i]:print();
	end;
end;

return timer;

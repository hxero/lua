local inspect = require 'utils.table._dump';

local skip_headers = ...;

local N = 100000;

local results = {};

local time = function(name, n, f)
	local clock = os.clock;

	collectgarbage();
	collectgarbage();
	collectgarbage();

	local startTime = clock();

	local o;
	for i = 0, n do o = f(); end;

	local duration = clock() - startTime;

	results[#results + 1] = { tostring(o) .. "\n", duration, };
end;

-------------------

time('nil', N, function()
	return inspect(nil, { sort = true });
end);

time('string', N, function()
	return inspect("hello", { sort = true });
end);

local e = {};
time('empty', N, function()
	return inspect(e, { sort = true });
end);

local seq = { 1, 2, 3, 4, };
time('sequence', N, function()
	return inspect(seq, { sort = true });
end);

local record = { a = 1, b = 2, c = 3, };
time('record', N, function()
	return inspect(record, { sort = true });
end);

local hybrid = { 1, 2, 3, a = 1, b = 2, c = 3, };
time('hybrid', N, function()
	return inspect(hybrid, { sort = true });
end);

local recursive = {};
recursive.x = recursive;
time('recursive', N, function()
	return inspect(recursive, { sort = true });
end);

local with_meta = setmetatable({},
	{ __tostring = function() return "s"; end, });
time('meta', N, function()
	return inspect(with_meta, { sort = true });
end);

local process_options = {
	process = function(i, p) return "p"; end,
};
time('process', N, function()
	return inspect(seq, process_options, { sort = true });
end);

local complex = {
	a = 1,
	true,
	print,
	[print] = print,
	[{}] = { {}, 3, b = { x = 42, }, },
};
complex.x = complex;
setmetatable(complex, complex);
time('complex', N, function()
	return inspect(complex, { sort = true });
end);

local big = {};
for i = 1, 1000 do
	big[i] = i;
end;
for i = 1, 1000 do
	big["a" .. i] = 1;
end;
time('big', N / 100, function()
	return inspect(big, { sort = true });
end);

------

if not skip_headers then
	for i, r in ipairs(results) do
		if i > 1 then io.write(","); end;
		io.write(r[1]);
	end;
	io.write("\n");
end;

for i, r in ipairs(results) do
	if i > 1 then io.write(","); end;
	io.write(r[2]);
end;
io.write("\n");

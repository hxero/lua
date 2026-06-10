local dump  = require("utils.dump");
local _dump = require("utils._dump");
-- local inspect    = require("inspect");

local timer = require("utils.bench");

-- local tbl = { [200] = { true, }, };
-- for i = 1, 1e5, 1 do
-- 	tbl["mycool" .. tostring(i)] = { tbl, [20] = i, { { { [2] = { { { { { { { { { { { {}, }, }, }, }, }, }, }, }, }, }, }, }, }, }, };
-- end;
--
-- timer.new("iteration based", function()
-- 	-- usually 1e5% slower than recursive
-- 	-- no stackoverflow
-- 	return utils.dump_table(tbl, { sort = true, });
-- end);
--
-- timer.new("recursive based", function()
-- 	-- usually the fastest
-- 	-- but prone to stackoverflow on 1e5,000+ deep nested
-- 	return stack_dump.dump_table(tbl, { sort = true, });
-- end);
--
-- timer.new("inspect", function()
-- 	-- most human readable?
-- 	-- slower because so many checking
-- 	return inspect(tbl);
-- end);
--
-- timer.compares(timer.get_timers(), { iterations = 1e5, });

local function basic_merge(a, b)
	for k, v in next, b do
		local _av = a[k];
		if (type(v) == "table" and type(_av) == "table") then
			basic_merge(_av, v);
		else
			a[k] = v;
		end;
	end;

	return a;
end;

local function table_merge(into, from)
	local stack = {};
	local node1 = into;
	local node2 = from;
	while (true) do
		for k, v in pairs(node2) do
			if (type(v) == "table" and type(node1[k]) == "table") then
				table.insert(stack, { node1[k], node2[k], });
			else
				node1[k] = v;
			end;
		end;
		if (#stack > 0) then
			local t = stack[#stack];
			node1, node2 = t[1], t[2];
			stack[#stack] = nil;
		else
			break;
		end;
	end;
	return into;
end;

local deep_merge = require("utils.merge");

local function build_t()
	local a = { [200] = { true, }, };
	for i = 1, 3e4, 1 do
		a["mycool" .. tostring(i)] = { "2", [20] = i, { { { [2] = { { { { { { { { { { { {}, }, }, }, }, }, }, }, }, }, }, }, }, }, }, };
	end;

	local b = { [200] = { { { false, }, }, }, };
	for i = 1, 3e4, 1 do
		b["mycool" .. tostring(i)] = { 213901239, [20] = i - i, { { { [2] = {}, }, }, }, };
	end;

	return a, b;
end;

do
	local a, b = build_t();
	timer.new("your basic merge", function()
		return basic_merge(a, b);
	end);
end;

do
	local a, b = build_t();
	timer.new("revolucas", function()
		return table_merge(a, b);
	end);
end;

do
	local a, b = build_t();
	timer.new("mine", function()
		return deep_merge(a, b);
	end);
end;

timer.compares(timer.get_timers(), {
	iterations = 5,
	output = function(o)
		return dump(o);
	end,
});

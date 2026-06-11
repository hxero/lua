local bench = require("utils.bench");

local dump    = require("utils.dump");
local _dump   = require("utils._dump");
local inspect = require("inspect");

local function get_deepest(tbl)
	local deepest   = tbl;
	local max_depth = 0;

	local function recurse(node, depth)
		local has_nested = false;

		for _, value in next, node do
			if (type(value) == "table") then
				has_nested = true;
				recurse(value, depth + 1);
			end;
		end;

		if (not has_nested and depth > max_depth) then
			max_depth = depth;
			deepest   = node;
		end;
	end;

	recurse(tbl, 1);
	return deepest, max_depth;
end;

local tbl = { {}, };
local tbl2 = { {}, };
local init = bench.new("initializing", function()
	local deepest = get_deepest;
	for i = 1, 1e6, 1 do
		-- local ref = deepest(tbl);
		tbl[i] = {
			[1] = i,
			[2] = true,
			[{ c = "hello", }] = {
				a = i + 10,
				b = i ^ 2,
			},
			["ee"] = {},
		};
		tbl[i]["ee"]["socool" .. i] = {
			[1] = true,
			[true] = { false, },
			a = "\n",
		};
		-- tbl[i] = { ref[2], };
	end;
	-- for i = 1, 1e4, 1 do
	-- 	local ref = deepest(tbl2);
	-- 	ref[1] = {
	-- 		[2] = { true, },
	-- 		[{ c = "hello", }] = {
	-- 			a = i ^ 2,
	-- 			b = i ^ 4,
	-- 		},
	-- 		["ee"] = { [400] = 100, },
	-- 	};
	-- 	ref[1]["ee"]["socool" .. i] = {
	-- 		[1] = false,
	-- 		[true] = { 1, },
	-- 		a = "\n\n\n\n",
	-- 	};
	-- 	tbl2[i] = { ref[2], };
	-- end;
end);

init:run();
init:print();
init:remove();

io.write("\27[2K\r");

local filter = require("utils.filter");
local subjects = {
	bench.new("filter", function()
		return filter(tbl, function(v)
			return not not v;
		end);
	end),
};
bench.compares(subjects, { iterations = 2, });
subjects = nil;
collectgarbage("collect");

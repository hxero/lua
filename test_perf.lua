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

-- local tbl = { {}, };
-- local init = bench.new("initializing", function()
-- 	for i = 1, 1e5 do
-- 		tbl[1] = {
-- 			[i] = i,
-- 			[2] = true,
-- 			[{ c = "hello", }] = {
-- 				a = i + 10,
-- 				b = i ^ 2,
-- 			},
-- 			["ee"] = {},
-- 		};
-- 		tbl[i] = { ee = {}, };
-- 		tbl[i]["ee"]["socool" .. i] = {
-- 			[1] = true,
-- 			[true] = { false, },
-- 			a = "\n",
-- 		};
-- 	end;
-- end);
--
-- init:run();
-- init:print();
-- init:remove();
--
-- io.write("\27[2K\r");

local table = setmetatable({}, {
	__index = function(_, v)
		if (table[v]) then
			return table[v];
		else
			local ok, module = pcall(require, "utils." .. v);
			if (not ok) then return nil; end;
			return module;
		end;
	end,
});

local print = function(...)
	io.write(table.concat(table.map({ ..., }, function(v)
		return table._dump(v);
	end)), "\n");
end;

local ref = {
	"abc",
	{
		["def"] = 5,
		{
			[{
				key = {
					"value",
				},
			}] = {
				"\0",
			},
		},
	},
};
print("ORIGIN: ", ref);
local cloned = table.clone(ref, { deep = true, iterative = false, });
ref[1] = "abcdefgh";
ref[2][1] = { 1000, };
ref[{ false, true, }] = "lol";

print("MODIFIED ORIGIN: ", ref, "\n", "CLONED: Remain untouched\n", cloned);

local merged = table.merge(ref, cloned);
print("MERGED: ", merged);

local _value, _key = table.find(merged, "lol", { is_array = false, deep = "recursive", });
print("FIND: Found `", _value, "` with the key [", _key, "]");

local flatten = table.flat(merged, { iterative = false, });
print("FLAT:\n", flatten, "\n");

print("FILTER: Only `string` value\n", table.filter(flatten, function(v)
	return type(v) == "string";
end, { is_array = true, }));

-- local dumpy = require("utils._dump");
-- local _ = bench.new("dump", function()
-- 	return dumpy(tbl);
-- end);
-- print(_:run(10));
-- _:print();
-- _:remove();

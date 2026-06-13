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
			local ok, module = pcall(require, "utils.table." .. v);
			if (not ok) then return nil; end;
			return module;
		end;
	end,
});

local string = setmetatable({}, {
	__index = function(_, v)
		if (string[v]) then
			return string[v];
		else
			local ok, module = pcall(require, "utils.string." .. v);
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
print("ORIGIN: ", ref, "\n");
local cloned = table.clone(ref, { deep = true, iterative = false, });
ref[1] = "abcdefgh";
ref[2][1] = { 1000, };
ref[{ false, true, }] = "lol";

print("MODIFIED ORIGIN: ", ref, "\n", "CLONED: Remain untouched\n", cloned);

local merged = table.merge(ref, cloned);
print("MERGED: ", merged, "\n");

local _value, _key = table.find(merged, "lol", { is_array = false, deep = "recursive", });
print("FIND: Found `", _value, "` with the key [", _key, "]\n");

local flatten = table.flat(merged, { iterative = false, });
print("FLAT:\n", flatten, "\n");

print("FILTER: Only `string` value\n", table.filter(flatten, function(v)
	return type(v) == "string";
end, { is_array = true, }));

--- @class UtilsTable: table
local M = setmetatable({}, {
	__index = function(t, v)
		if (table[v]) then return table[v]; end;
		if (rawget(t, v)) then return rawget(t, v); end;

		local ok, mod = pcall(require, "utils.table." .. v);
		if (not ok) then return nil; end;

		t[v] = mod;
		return mod;
	end,
});

if (false) then --- @diagnostic disable
	-- keep table.* completion
	M.concat = table.concat;
	M.insert = table.insert;
	M.remove = table.remove;
	M.sort   = table.sort;
	M.unpack = table.unpack;
	M.pack   = table.pack;
	M.move   = table.move;

	-- spoof type annotation without loading
	M._dump  = require("utils.table._dump");
	M.clone  = require("utils.table.clone");
	M.dump   = require("utils.table.dump");
	M.filter = require("utils.table.filter");
	M.find   = require("utils.table.find");
	M.flat   = require("utils.table.flat");
	M.map    = require("utils.table.map");
	M.merge  = require("utils.table.merge");
end; --- @diagnostic enable

--- @type UtilsTable
return M;

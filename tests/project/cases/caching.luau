-- A module runs once, and every path to it gets the same value
local t = require("./harness")

t.check("relative and @self paths share a module", function()
	t.equal(require("./harness"), require("@self/harness"), "./harness and @self/harness")
end)

t.check("relative and alias paths share a module", function()
	t.equal(require("@Lib/helper"), require("../src/lib/helper"), "@Lib/helper and ../src/lib/helper")
	t.equal(require("@Lib/util"), require("@Lib/helper").util, "@Lib/util and ./util from src/lib/helper")
end)

t.check("folder paths share a module", function()
	local folder = require("../src/folder")
	t.equal(require("@Folder"), folder, "@Folder and ../src/folder")
	t.equal(require("../src/folder/init"), folder, "../src/folder/init and ../src/folder")
end)

t.check("a module runs once however it's required", function()
	require("../src/once")
	require("../src/sub/../once")
	require("@self/../src/once")
	require("@Lib/../once")
	t.equal(require("../src/counter").runs, 1, "times src/once ran")
end)

t.done()

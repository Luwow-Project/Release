-- Aliases from the config, resolved from the config's folder
local t = require("./harness")

t.check("an alias finds a module in its folder", function()
	t.equal(t.name(require("@Lib/util")), "src/lib/util")
	t.equal(t.name(require("@Shared/x")), "shared/x")
end)

t.check("an alias finds a module in a subfolder", function()
	t.equal(t.name(require("@Lib/deep/thing")), "src/lib/deep/thing")
end)

t.check("a module found through an alias resolves its relative requires from its own folder", function()
	local helper = require("@Lib/helper")
	t.equal(t.name(helper), "src/lib/helper")
	t.equal(t.name(helper.util), "src/lib/util", "./util from src/lib/helper")
	t.equal(t.name(helper.value), "src/value", "../value from src/lib/helper")
end)

t.check("an alias to a folder module runs its init.luau", function()
	local folder = require("@Folder")
	t.equal(t.name(folder), "src/folder")
	t.equal(t.name(folder.value), "src/value", "./value from src/folder/init through @Folder")
	t.equal(t.name(require("@Folder/inner")), "src/folder/inner")
end)

t.check("an alias in a nested module resolves from the config, not from that module", function()
	t.equal(t.name(require("../src/sub/aliasuser").util), "src/lib/util", "@Lib/util from src/sub/aliasuser")
end)

t.check("an alias can climb with ../", function()
	t.equal(t.name(require("@Lib/../value")), "src/value")
end)

t.done()

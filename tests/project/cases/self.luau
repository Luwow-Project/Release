-- @self in a regular file is the folder the file is in
local t = require("@self/harness")

t.check("@self from the main script is its folder", function()
	t.equal(require("@self/harness"), require("./harness"), "@self/harness")
end)

t.check("@self from a regular module is its folder", function()
	local user = require("../src/sub/selfuser")
	t.equal(t.name(user.viaSelf), "src/sub/sibling", "@self/sibling from src/sub/selfuser")
	t.equal(user.viaSelf, user.viaDot, "@self/sibling and ./sibling")
end)

t.check("@self can climb with ../", function()
	t.equal(t.name(require("@self/../src/value")), "src/value")
end)

t.check("@self from a module found through an alias is that module's folder", function()
	t.equal(t.name(require("@Lib/helper").selfUtil), "src/lib/util", "@self/util from src/lib/helper")
end)

t.done()

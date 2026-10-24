-- ./ and ../ resolve from the calling file's folder
local t = require("./harness")

t.check("./ finds a file in the caller's folder", function()
	t.equal(type(require("./harness").check), "function", "./harness")
end)

t.check("../ goes up from the caller's folder", function()
	t.equal(t.name(require("../src/value")), "src/value")
	t.equal(t.name(require("../top")), "top")
end)

t.check("relative requires in a required module start at that module's folder", function()
	local leaf = require("../src/sub/leaf")
	t.equal(t.name(leaf), "src/sub/leaf")
	t.equal(t.name(leaf.sibling), "src/sub/sibling", "./sibling from src/sub/leaf")
	t.equal(t.name(leaf.parent), "src/value", "../value from src/sub/leaf")
	t.equal(t.name(leaf.top), "top", "../../top from src/sub/leaf")
end)

t.check("./ and ../ segments inside a path are normalized", function()
	t.equal(t.name(require("../src/sub/../value")), "src/value")
	t.equal(t.name(require("./../src/./sub/sibling")), "src/sub/sibling")
end)

t.check("a module deeper down resolves ../ from its own folder", function()
	t.equal(t.name(require("../src/lib/deep/thing").helper), "src/lib/helper", "../helper from src/lib/deep/thing")
end)

t.done()

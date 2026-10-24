-- Without a config there are no config aliases, but everything else resolves
local t = require("./harness")

t.check("relative requires work without a config", function()
	t.equal(t.name(require("../src/sub/leaf").parent), "src/value")
end)

t.check("@self works without a config", function()
	t.equal(t.name(require("../src/sub/selfuser").viaSelf), "src/sub/sibling")
end)

t.check("folder modules work without a config", function()
	t.equal(t.name(require("../src/folder").value), "src/value")
end)

t.check("config aliases are undefined without a config", function()
	t.fails(function()
		return require("@Lib/util")
	end, "undefined alias")
end)

t.done()

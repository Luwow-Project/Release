-- Paths that don't resolve raise an error rather than crash
local t = require("./harness")

t.check("a bare name is an error", function()
	t.fails(function()
		return require("value")
	end, "must always start with")
end)

t.check("an undefined alias is an error", function()
	t.fails(function()
		return require("@Undefined/value")
	end, "undefined alias")
end)

t.check("a missing relative module is an error", function()
	t.fails(function()
		return require("./missing")
	end)
	t.fails(function()
		return require("../src/missing/deeper")
	end)
end)

t.check("a missing module in an alias's folder is an error", function()
	t.fails(function()
		return require("@Lib/missing")
	end)
end)

t.check("a module that raises an error is an error to its requirer", function()
	t.fails(function()
		return require("../src/broken")
	end)
end)

t.check("require works after failed requires", function()
	t.equal(t.name(require("../src/value")), "src/value")
	t.equal(t.name(require("@Lib/util")), "src/lib/util")
end)

t.done()

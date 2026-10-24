-- Packages only: a package's modules are named from the project's folder, however compile was given their
-- paths and wherever it ran from, and are found by those names, never through the working directory
local t = require("./harness")

local function named(path: string): string
	return `[string "{path}"]`
end

t.check("the main script is named from the project's folder", function()
	t.equal(debug.info(1, "s"), named("cases/package_names.luau"), "main script")
end)

t.check("a module found through an alias is found by its name", function()
	t.equal(require("@Lib/whereami").source, named("src/lib/whereami.luau"), "@Lib/whereami")
end)

t.check("a module found through a relative path is found by its name", function()
	t.equal(require("../src/lib/whereami").source, named("src/lib/whereami.luau"), "../src/lib/whereami")
end)

t.check("a module found through @self is found by its name", function()
	t.equal(require("@self/../src/lib/whereami").source, named("src/lib/whereami.luau"), "@self/../src/lib/whereami")
end)

t.check("a folder module and its modules are found by their names", function()
	t.equal(require("@Folder/whereami").source, named("src/folder/whereami.luau"), "@Folder/whereami")
	t.equal(require("../src/folder/whereami").source, named("src/folder/whereami.luau"), "../src/folder/whereami")
end)

t.check("every name of a module is the same module", function()
	local viaAlias = require("@Lib/whereami")
	t.equal(require("../src/lib/whereami"), viaAlias, "../src/lib/whereami and @Lib/whereami")
	t.equal(require("@Folder/../lib/whereami"), viaAlias, "@Folder/../lib/whereami and @Lib/whereami")
end)

t.done()

-- Bundled executables
local t = require("./harness")

t.check("a bundled executable gets its own arguments", function()
	t.equal(#GlobalArgs, 2, "#GlobalArgs")
	t.equal(GlobalArgs[1], "first", "GlobalArgs[1]")
	t.equal(GlobalArgs[2], "second arg", "GlobalArgs[2]")
end)

local sdktest = require("@Luwow/sdktest")
if not sdktest.stub then
	t.check("files of any kind are packed as assets", function()
		t.equal(sdktest.packageHas("assets/data.bin"), true, "packageHas(assets/data.bin)")
		t.equal(sdktest.packageHas("assets/notes"), true, "packageHas(assets/notes)")
		t.equal(sdktest.packageHas("assets/table.csv"), true, "packageHas(assets/table.csv)")
	end)

	t.check("a script in an asset folder isn't packed", function()
		t.equal(sdktest.packageHas("assets/ignored.luau"), false, "packageHas(assets/ignored.luau)")
	end)
end

t.done()

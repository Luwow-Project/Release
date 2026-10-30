-- Native module aliases, next to a config alias of the same name. These also check a library built from the SDK works.
local t = require("./harness")

t.check("@Luwow finds a native module", function()
	local sdktest = require("@Luwow/sdktest")
	t.equal(type(sdktest), "table", "@Luwow/sdktest")
	t.equal(sdktest.stub, nil, "@Luwow/sdktest is the native module, not types/sdktest.luau")
end)

t.check("a native module is the same from any file", function()
	t.equal(require("@Luwow/sdktest"), require("@Luwow/sdktest"), "@Luwow/sdktest")
end)

t.check("a config alias sharing a native alias's name still finds its own modules", function()
	t.equal(t.name(require("@Luwow/stubonly")), "types/stubonly")
end)

t.check("a library built from the SDK calls into the executable's Luau", function()
	local sdktest = require("@Luwow/sdktest")
	t.equal(sdktest.answer(), 42, "answer()")
end)

t.check("a library's userdata from Userdata.h works", function()
	local point = require("@Luwow/sdktest").point(3, 4)
	t.equal(typeof(point), "SdkTestPoint", "typeof")
	t.equal(point.X, 3, "X")
	t.equal(point:Length(), 5, "Length()")
	point.X = 0
	t.equal(point.Length(point), 4, "Length() after setting X")
	t.fails(function()
		(point :: any).Y = 1
	end, "read-only")
end)

t.check("a library reaches the host through ILuauHost", function()
	local inPackage = string.sub(GlobalArgs[1], -4) == ".pkg"
	t.equal(require("@Luwow/sdktest").packageHas("cases/native.luau"), inPackage, "packageHas(cases/native.luau)")
end)

t.done()

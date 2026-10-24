-- Native module aliases, next to a config alias of the same name
local t = require("./harness")

t.check("@Luwow finds a native module", function()
	local fs = require("@Luwow/fs")
	t.equal(type(fs), "table", "@Luwow/fs")
	t.equal(fs.stub, nil, "@Luwow/fs is the native module, not types/fs.luau")
end)

t.check("a native module is the same from any file", function()
	t.equal(require("@Luwow/fs"), require("@Luwow/fs"), "@Luwow/fs")
end)

t.check("a config alias sharing a native alias's name still finds its own modules", function()
	t.equal(t.name(require("@Luwow/stubonly")), "types/stubonly")
end)

t.done()

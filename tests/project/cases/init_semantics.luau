-- A folder with an init.luau (or init.lua) is a module. In it @self is the folder, ./ is the folder's
-- parent and ../ goes up from the parent.
local t = require("./harness")

t.check("requiring a folder runs its init.luau", function()
	t.equal(t.name(require("../src/folder")), "src/folder")
end)

t.check("@self in init.luau is the folder itself", function()
	t.equal(t.name(require("../src/folder").inner), "src/folder/inner", "@self/inner from src/folder/init")
end)

t.check("./ in init.luau is the folder's parent", function()
	-- src/folder/value.luau exists too, and mustn't be picked
	t.equal(t.name(require("../src/folder").value), "src/value", "./value from src/folder/init")
end)

t.check("../ in init.luau goes up from the folder's parent", function()
	t.equal(t.name(require("../src/folder").top), "top", "../top from src/folder/init")
end)

t.check("requires in init.luau's functions resolve from init.luau", function()
	local folder = require("../src/folder")
	t.equal(t.name(folder.lazyValue()), "src/value", "./value inside a function of src/folder/init")
	t.equal(t.name(folder.lazyInner()), "src/folder/inner", "@self/inner inside a function of src/folder/init")
end)

t.check("requiring a folder runs its init.lua", function()
	local luafolder = require("../src/luafolder")
	t.equal(t.name(luafolder), "src/luafolder")
	t.equal(t.name(luafolder.inner), "src/luafolder/inner", "@self/inner from src/luafolder/init.lua")
	t.equal(t.name(luafolder.value), "src/value", "./value from src/luafolder/init.lua")
end)

t.check("folder modules nest", function()
	local nested = require("../src/nested")
	t.equal(t.name(nested), "src/nested")
	t.equal(t.name(nested.sibling), "src/nested/sibling", "@self/sibling from src/nested/init")
	t.equal(t.name(nested.child), "src/nested/child", "@self/child from src/nested/init")
	t.equal(t.name(nested.child.x), "src/nested/child/x", "@self/x from src/nested/child/init")
	t.equal(t.name(nested.child.sibling), "src/nested/sibling", "./sibling from src/nested/child/init")
	t.equal(t.name(nested.child.value), "src/value", "../value from src/nested/child/init")
end)

t.check("an init.luau can be required by its own name", function()
	t.equal(require("../src/folder/init"), require("../src/folder"), "../src/folder/init")
end)

t.check("a folder without an init file isn't a module", function()
	t.fails(function()
		return require("../src/noinit")
	end)
end)

t.done()

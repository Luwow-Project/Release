-- In an init.luau, @self is this folder, ./ is the folder's parent and ../ goes up from there
local folder = {
	name = "src/folder",
	inner = require("@self/inner"),
	value = require("./value"),
	top = require("../top"),
}

-- A require inside a function resolves from the file the function is written in, not its caller's
function folder.lazyValue()
	return require("./value")
end

function folder.lazyInner()
	return require("@self/inner")
end

return folder

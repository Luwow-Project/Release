-- @self in a regular file is the file's own folder, the same as ./
return {
	name = "src/sub/selfuser",
	viaSelf = require("@self/sibling"),
	viaDot = require("./sibling"),
}

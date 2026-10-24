-- ./ and ../ from a regular file start at its own folder
return {
	name = "src/sub/leaf",
	sibling = require("./sibling"),
	parent = require("../value"),
	top = require("../../top"),
}

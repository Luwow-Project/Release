-- A folder module inside a folder module: ./ is src/nested, ../ is src
return {
	name = "src/nested/child",
	x = require("@self/x"),
	sibling = require("./sibling"),
	value = require("../value"),
}

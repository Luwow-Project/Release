-- A folder module can be an init.lua as well
return {
	name = "src/luafolder",
	inner = require("@self/inner"),
	value = require("./value"),
}

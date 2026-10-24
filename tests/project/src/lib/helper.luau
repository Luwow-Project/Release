-- Found through @Lib, its own relative requires still start at its folder
return {
	name = "src/lib/helper",
	util = require("./util"),
	selfUtil = require("@self/util"),
	value = require("../value"),
}

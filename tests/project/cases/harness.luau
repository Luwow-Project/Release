--[[
	The checks' reporter. Each check prints PASS or FAIL with its name, and done() prints DONE with the
	number that failed, which run_tests.py reads. Requires stay in the case files: require resolves from the
	file that calls it, so a check's function is written there.
]]
local Harness = {}

local failed = 0

local function describe(value: any): string
	if type(value) == "table" and value.name ~= nil then
		return `module {value.name}`
	end
	return tostring(value)
end

function Harness.check(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		print(`PASS {name}`)
	else
		failed += 1
		print(`FAIL {name}: {err}`)
	end
end

function Harness.equal(actual: any, expected: any, what: string?)
	if actual ~= expected then
		error(`{what or "value"}: expected {describe(expected)}, got {describe(actual)}`, 2)
	end
end

-- The module's name, from a module table, erroring with what it got otherwise
function Harness.name(module: any): string
	if type(module) ~= "table" then
		error(`expected a module table, got {typeof(module)}`, 2)
	end
	return module.name
end

-- fn must raise an error, whose message contains pattern (a plain string) when given
function Harness.fails(fn: () -> any, pattern: string?)
	local ok, err = pcall(fn)
	if ok then
		error("expected an error, got none", 2)
	end
	if pattern and not string.find(tostring(err), pattern, 1, true) then
		error(`expected an error containing "{pattern}", got: {err}`, 2)
	end
end

function Harness.done()
	print(`DONE {failed}`)
end

return Harness

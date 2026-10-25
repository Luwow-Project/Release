-- net.request against the local HTTP server run_tests.py starts, through every platform's client. 
-- The runner gives the server's URL, the folder to save into and the
-- digest of /big's body as the script's arguments, after the config.

local t = require("./harness")
local fs = require("@Luwow/fs")
local net = require("@Luwow/net")

local server: string, folder: string, bigDigest: string = GlobalArgs[2], GlobalArgs[3], GlobalArgs[4]

t.check("GET answers with the status, headers and body", function()
	local response = net.request({ url = `{server}/hello` })
	t.equal(response.status, 200, "status")
	t.equal(response.ok, true, "ok")
	t.equal(response.body, "hello", "body")
	t.equal(response.bodyLength, 5, "bodyLength")
	t.equal(response.headers["x-test"], "yes", "header x-test")
end)

t.check("HEAD answers without a body", function()
	local response = net.request({ url = `{server}/hello`, method = "HEAD" })
	t.equal(response.status, 200, "status")
	t.equal(response.body, "", "body")
	t.equal(response.headers["x-test"], "yes", "header x-test")
end)

t.check("POST sends its body and headers, a body without a Content-Type as a form", function()
	local response = net.request({
		url = `{server}/echo`,
		method = "POST",
		headers = { ["X-Custom"] = "custom value" },
		body = "posted body",
	})
	t.equal(response.status, 200, "status")
	t.equal(response.body, "POST|posted body|custom value|application/x-www-form-urlencoded", "echo (method|body|X-Custom|Content-Type)")
end)

t.check("a body's Content-Type is the one given", function()
	local response = net.request({
		url = `{server}/echo`,
		method = "PUT",
		headers = { ["Content-Type"] = "application/json" },
		body = "{}",
	})
	t.equal(response.body, "PUT|{}||application/json", "echo (method|body|X-Custom|Content-Type)")
end)

t.check("redirects are followed, and the last response's headers kept", function()
	local response = net.request({ url = `{server}/redirect` })
	t.equal(response.status, 200, "status")
	t.equal(response.body, "hello", "body")
	t.equal(response.headers["location"], nil, "the redirect's Location")
end)

t.check("a gzip body is decompressed", function()
	local response = net.request({ url = `{server}/gzip` })
	t.equal(response.status, 200, "status")
	t.equal(response.body, "compressed hello", "body")
end)

t.check("an error status is a response", function()
	local response = net.request({ url = `{server}/missing` })
	t.equal(response.status, 404, "status")
	t.equal(response.ok, false, "ok")
	t.equal(response.body, "nope", "body")
end)

t.check("saveTo writes a successful body to the file", function()
	local path = `{folder}/big.bin`
	local response = net.request({ url = `{server}/big`, saveTo = path })
	t.equal(response.status, 200, "status")
	t.equal(response.body, "", "body in memory")
	t.equal(response.bodyLength, 1048576, "bodyLength")
	t.equal(fs.stat(path).size, 1048576, "file size")
	t.equal(fs.hashFile(path), bigDigest, "file contents")
end)

t.check("saveTo makes the file for an empty body", function()
	local path = `{folder}/empty.bin`
	net.request({ url = `{server}/empty`, saveTo = path })
	t.equal(fs.exists(path) and fs.stat(path).size, 0, "file size")
end)

t.check("saveTo leaves an error's body in memory", function()
	local path = `{folder}/missing.bin`
	local response = net.request({ url = `{server}/missing`, saveTo = path })
	t.equal(response.body, "nope", "body")
	t.equal(fs.exists(path), false, "file")
end)

t.check("a server that doesn't answer in time is an error", function()
	t.fails(function()
		return net.request({ url = `{server}/slow`, timeout = 0.5 })
	end)
end)

t.check("only http and https URLs are taken", function()
	t.fails(function()
		return net.request({ url = "ftp://example.com/file" })
	end)
	t.fails(function()
		return net.request({ url = "not a url" })
	end)
end)

t.done()

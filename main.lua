local M = {}
local REQUEST = "open-paths-request"
local RESPONSE = "open-paths-response"

function M:setup(opts)
	if self.ready then return end
	self.ready = true
	self.wait = (opts or {}).wait or 0.4
	assert(type(self.wait) == "number" and self.wait > 0, "open-paths: wait must be positive")
	ps.sub_remote(REQUEST, function(body)
		-- DDS can also deliver a broadcast back to its sender.
		if type(body) ~= "string" or body == self.token then return end
		local paths = {}
		for _, tab in ipairs(cx.tabs) do
			paths[#paths + 1] = tostring(tab.current.cwd)
		end
		-- Replies are ephemeral; only the requesting instance accepts the token.
		ps.pub_to(0, RESPONSE, { token = body, paths = paths })
	end)
	ps.sub_remote(RESPONSE, function(body)
		if type(body) ~= "table" or not self.token or body.token ~= self.token then return end
		if type(body.paths) ~= "table" then return end
		for _, path in ipairs(body.paths) do
			if type(path) == "string" and path ~= "" then self.paths[path] = true end
		end
	end)
end

local begin = ya.sync(function(self, token)
	if not self.ready then return nil end
	self.token, self.paths = token, {}
	ps.pub_to(0, REQUEST, token)
	return self.wait
end)

local finish = ya.sync(function(self, token)
	if self.token ~= token then return nil end
	local paths = {}
	for path in pairs(self.paths) do paths[#paths + 1] = path end
	self.token, self.paths = nil, nil
	table.sort(paths)
	return paths
end)

local function notify(message)
	ya.notify { title = "Open Yazi paths", content = message, timeout = 5 }
end

function M:entry(job)
	local token = ya.hash(tostring(ya.time()) .. ":" .. tostring({}))
	local wait = begin(token)
	if not wait then
		return notify('Add require("open-paths"):setup() to init.lua and restart Yazi.')
	end
	ya.sleep(wait)
	local paths = finish(token)
	if not paths then return end -- A newer invocation replaced this request.
	if #paths == 0 then
		return notify("No other Yazi instance replied. Restart other instances with open-paths enabled, or increase setup wait.")
	end

	local page, size = 1, 9
	while true do
		local first = (page - 1) * size + 1
		local last = math.min(first + size - 1, #paths)
		local cands = {}
		for i = first, last do
			-- Escape control characters in labels only; retain the original path.
			local label = paths[i]:gsub("%c", function(c) return string.format("\\x%02x", c:byte()) end)
			cands[#cands + 1] = { on = tostring(i - first + 1), desc = label }
		end
		local count = #cands
		if page > 1 then cands[#cands + 1] = { on = "p", desc = "Previous page" } end
		if last < #paths then cands[#cands + 1] = { on = "n", desc = "Next page" } end
		local choice = ya.which { cands = cands }
		if not choice then return end
		if choice <= count then
			local path = paths[first + choice - 1]
			if job.args[1] == "copy" then
				ya.clipboard(path)
			else
				ya.emit("cd", { path })
			end
			return
		end
		page = page + (cands[choice].on == "n" and 1 or -1)
	end
end

return M

local socket = require "socket"
dofile("irc/base64.lua")
local to_base64 = to_base64

local error = error
local setmetatable = setmetatable
local rawget = rawget
local unpack = unpack
local pairs = pairs
local assert = assert
local require = require
local tonumber = tonumber
local type = type
local pcall = pcall
local table_insert = table.insert
local table_concat = table.concat
local print = print

module "irc"

local meta = {}
meta.__index = meta
_META = meta

require "irc.util"
require "irc.asyncoperations"
require "irc.handlers"

local meta_preconnect = {}
function meta_preconnect.__index(o, k)
	local v = rawget(meta_preconnect, k)

	if not v and meta[k] then
		error(("field '%s' is not accessible before connecting"):format(k), 2)
	end
	return v
end

function new(data)
	local o = {
		nick = assert(data.nick, "Field 'nick' is required");
		username = data.username or "lua";
		realname = data.realname or "Lua owns";
		nickGenerator = data.nickGenerator or defaultNickGenerator;
		hooks = {};
		track_users = true;
	}
	assert(checkNick(o.nick), "Erroneous nickname passed to irc.new")
	return setmetatable(o, meta_preconnect)
end

function meta:hook(name, id, f)
	f = f or id
	self.hooks[name] = self.hooks[name] or {}
	self.hooks[name][id] = f
	return id or f
end
meta_preconnect.hook = meta.hook


function meta:unhook(name, id)
	local hooks = self.hooks[name]

	assert(hooks, "no hooks exist for this event")
	assert(hooks[id], "hook ID not found")

	hooks[id] = nil
end
meta_preconnect.unhook = meta.unhook

function meta:invoke(name, ...)
	local hooks = self.hooks[name]
	if hooks then
		for id,f in pairs(hooks) do
			if f(...) then
				return true
			end
		end
	end
end

function meta_preconnect:connect(connectionInfo)

	local host = connectionInfo.host
	local port = connectionInfo.port
	local timeout = connectionInfo.timeout
	local serverPassword = connectionInfo.serverPassword
	local secure = connectionInfo.secure
	local sasl = connectionInfo.sasl
	local account = connectionInfo.account
	local password = connectionInfo.password
	if password and not account then error("Got nickserv password, but not account") end
	if sasl and not password then error("Sasl requsted, but no password given") end

	host = host or error("host name required to connect", 2)
	port = port or 6667

	local s = socket.tcp()

	s:settimeout(timeout or 30)
	assert(s:connect(host, port))

	if secure then
		local work, ssl = pcall(require, "ssl")
		if not work then
			error("LuaSec required for secure connections", 2)
		end

		local params
		if type(secure) == "table" then
			params = secure
		else
			params = {mode = "client", protocol = "any"}
		end

		s = ssl.wrap(s, params)
		success, errmsg = s:dohandshake()
		if not success then
			error(("could not make secure connection: %s"):format(errmsg), 2)
		end
	end

	self.socket = s
	setmetatable(self, meta)

	self:send("CAP REQ :multi-prefix" .. (sasl and " sasl" or ""))

	if sasl then
		local saslParts = {}
		table_insert(saslParts, account)
		table_insert(saslParts, account)
		table_insert(saslParts, password)
		self.saslToken = to_base64(table_concat(saslParts, "\0"))
	else
		self:send("CAP END")
	end

	if serverPassword then
		self:send("PASS %s", serverPassword)
	end

	self:send("NICK %s", self.nick)
	self:send("USER %s 0 * :%s", self.nick, self.realname)

	self.channels = {}
	self.caps = {}

	s:settimeout(0)

	repeat
		self:think()
		socket.select(nil, nil, 0.1) -- Sleep so that we don't eat CPU
	until self.authed
	
	if not sasl and password then
		self:sendChat("NickServ", "identify " .. account .. " " .. password)
		print("Waiting 7 seconds for NickServ identification")
		socket.sleep(7)
	end
	if self.needsRegain then
		self:sendChat("NickServ", "ghost " .. self.needsRegain)
		self:send("NICK %s", self.needsRegain)
	end
	self:invoke("OnRegistered")
end

function meta:disconnect(message)
	message = message or "Bye!"

	self:invoke("OnDisconnect", message, false)
	self:send("QUIT :%s", message)

	self:shutdown()
end

function meta:shutdown()
	self.socket:close()
	setmetatable(self, nil)
end

local function getline(self, errlevel)
	local line, err = self.socket:receive("*l")

	if not line and err ~= "timeout" and err ~= "wantread" then
		self:invoke("OnDisconnect", err, true)
		self:shutdown()
		error(err, errlevel)
	end

	return line
end

function meta:think()
	while true do
		local line = getline(self, 3)
		if line and #line > 0 then
			if not self:invoke("OnRaw", line) then
				self:handle(parse(line))
			end
		else
			break
		end
	end
end

local handlers = handlers

function meta:handle(prefix, cmd, params)
	local handler = handlers[cmd]
	if handler then
		return handler(self, prefix, unpack(params))
	end
end

local whoisHandlers = {
	["311"] = "userinfo";
	["312"] = "node";
	["319"] = "channels";
	["330"] = "account"; -- Freenode
	["307"] = "registered"; -- Unreal
}

function meta:whois(nick)
	self:send("WHOIS %s", nick)

	local result = {}

	while true do
		local line = getline(self, 3)
		if line then
			local prefix, cmd, args = parse(line)

			local handler = whoisHandlers[cmd]
			if handler then
				result[handler] = args
			elseif cmd == "318" then
				break
			else
				self:handle(prefix, cmd, args)
			end
		end
	end

	if result.account then
		result.account = result.account[3]
	elseif result.registered then
		result.account = result.registered[2]
	end

	return result
end

function meta:topic(channel)
	self:send("TOPIC %s", channel)
end


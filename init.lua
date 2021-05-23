if IRC_RUNNING then error("Already running") end
IRC_RUNNING=true
WINDOWS = package.config:sub(1,1) == "\\"
dofile("derp.lua")
dofile("irc/init.lua")

local s,r = pcall(dofile,"config.lua")
if not s then
	if r:find("No such file or directory") then
		print("Config not found, copying template")
		os.execute("cp configtemplate.lua config.lua")
		r=dofile("config.lua")
	else
		error(r)
	end
end
config = r

local sleep=require "socket".sleep
socket = require"socket"
local console=socket.tcp()
console:settimeout(5)

if not WINDOWS and config.terminalinput then
	--start my console line-in
	os.execute(config.terminal.." lua consolein.lua")
end
shutdown = false
user = config.user
irc=irc.new(user)

for k,v in pairs(arg) do
	if v == "--verbose" then
		local function onSend(msg)
			print("--> " .. msg)
		end
		local function onRecv(msg)
			print("<-- " .. msg)
		end

		pcall(irc.unhook, irc, "OnSend", "onSend")
		irc:hook("OnSend","onSend", onSend)
		pcall(irc.unhook, irc, "OnRaw", "onRecv")
		irc:hook("OnRaw","onRecv", onRecv)
	end
end

--autojoin after registration
local function autojoin()
	if #config.autojoin <= 0 then print("No autojoin channels set in config.lua!") end
	local hasPrimary = false
	local hasLog = false
	for k,v in pairs(config.autojoin) do
		irc:join(v)
		if v == config.primarychannel then
			hasPrimary = true
		end
		if v == config.logchannel then
			hasLog = true
		end
	end
	--join extra config channels if they for some reason aren't in the autojoin
	if config.primarychannel and not hasPrimary then
		irc:join(config.primarychannel)
	end
	if config.logchannel and not hasLog then
		irc:join(config.logchannel)
	end
	irc:sendChat(config.primarychannel, "moo" * #config.autojoin)
	pcall(irc.unhook, irc, "OnRegistered", "autojoin")
end
irc:hook("OnRegistered", "autojoin", autojoin)


--support multiple networks sometime
local connectioninfo = {
    host = config.network.server,
    port = config.network.port,
    serverPassword = config.network.password,
    secure = config.network.ssl,
    timeout = config.network.timeout,
	sasl = config.network.sasl,
	
	account = config.user.account,
	password = config.user.password
}
irc:connect(connectioninfo)
config.user.password = nil
config.network.password = nil
print("Connected!")

local connected=false
if not WINDOWS then
	--connect to console thread
	function conConnect()
		console:connect("localhost",1337)
		console:settimeout(0)
		console:setoption("keepalive",true)
		connected=true
	end
	conConnect()
end

dofile("hooks.lua")
dofile("commands.lua")

local function consoleThink()
	if not connected then return end
	local line, err = console:receive()
	if line then
		if line:find("[^%s%c]") then
			consoleChat(line)
		end
	end
end
didSomething=false
while true do
	if shutdown then irc:shutdown() break end
	irc:think()
	consoleThink()
	ircSendOne()
	timerCheck()
	if not didSomething then
		sleep(0.05)
	else
		sleep(0.01)
	end
	didSomething=false
end

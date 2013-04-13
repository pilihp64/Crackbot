if IRC_RUNNING then error("Already running") end
IRC_RUNNING=true
dofile("derp.lua")
dofile("irc/init.lua")
dofile("config.lua")

local sleep=require "socket".sleep
local socket = require"socket"
local console=socket.tcp()
console:settimeout(5)

--start my console line-in
os.execute("xfce4-terminal -x lua consolein.lua")
shutdown = false
user = {
	nick = "Crackbot",
	username = "Meow",
	realname = "moo",
}
irc=irc.new(user)

irc:connect("irc.freenode.net",6667)

local connected=false
function conConnect()
	console:connect("localhost",1337) --connect to console thread
	console:settimeout(0)
	console:setoption("keepalive",true)
	connected=true
end
conConnect()
print("connected")

dofile("hooks.lua")
dofile("commands.lua")

irc:join("##powder-bots")
irc:join("#neotenic")
print("Joined")

local function consoleThink()
	if not connected then return end
	local line, err = console:receive()
	if line then
		if line:find("[^%s%c]") then
			consoleChat(line)
		end
	end
end
while true do
	if shutdown then irc:shutdown() break end
	irc:think()
	consoleThink()
	ircSendOne()
	timerCheck()
	sleep(0.5)
end

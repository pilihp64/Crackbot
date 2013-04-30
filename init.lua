if IRC_RUNNING then error("Already running") end
IRC_RUNNING=true
dofile("derp.lua")
dofile("irc/init.lua")
local s,r = pcall(dofile,"config.lua")
if not s then print("Config not found, copying template") os.execute("cp configtemplate.lua config.lua") r=dofile("config.lua") end
config = r

local sleep=require "socket".sleep
local socket = require"socket"
local console=socket.tcp()
console:settimeout(5)

--start my console line-in
os.execute("xfce4-terminal -x lua consolein.lua")
shutdown = false
user = config.user
irc=irc.new(user)

--support multiple networks sometime
irc:connect(config.network.server,config.network.port)
print("Connected")

local connected=false
--connect to console thread
function conConnect()
	console:connect("localhost",1337)
	console:settimeout(0)
	console:setoption("keepalive",true)
	connected=true
end
conConnect()


dofile("hooks.lua")
dofile("commands.lua")

if #config.autojoin <= 0 then print("No autojoin channels set in config.lua!") end
for k,v in pairs(config.autojoin) do
	irc:join(v)
end

local function consoleThink()
	if not connected then return end
	local line, err = console:receive()
	if line then
		if line:find("[^%s%c]") then
			consoleChat(line)
		end
	end
end
tick=0
while true do
	if shutdown then irc:shutdown() break end
	irc:think()
	consoleThink()
	ircSendOne()
	timerCheck()
	sleep(0.05)
	tick=tick+1
end

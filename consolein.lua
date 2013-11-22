if IRC_RUNNING then error("Can't load that from here") end
print("Line input to IRC bot! "..config.prefix:gsub("%%","").."chan to change who gets message")
local socket = require"socket"
local s = socket.bind("localhost",1337)
s:settimeout(30)
local client = s:accept()
if not client then print("Timeout") return end
print("Connected!")
s:settimeout(0)
client:settimeout(0)
while true do
	local line = io.read("*l")
	if line then
		local r,e = client:send(line.."\n")
		if not r then break end
	end
end

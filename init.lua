--Crackbot2.0
local irc = require('irc')
local socket = require'socket'
local sleep = require'socket'.sleep
ircMsg = irc.msgs

config = dofile'config.lua'
conns = {}
for k,v in pairs(config) do
	if v.serv and v.user then
		local con = irc.new(v.user)
		con:connect(v.serv)
		con.config = v
		table.insert(conns,con)
	end
end


socket.sleep(3)
dofile('main.lua')
print('yay, connected?')
--send(ircMsg.privmsg('NICKSERV','IDENTIFY something'))
for k,v in pairs(conns) do
	for _,chan in pairs(v.config.default.autojoin or config.default.autojoin) do
		v:queue(ircMsg.join(chan))
	end
end


while true do
	for k,v in pairs(conns) do
		v:think()
	end
	sleep(0.1)

end

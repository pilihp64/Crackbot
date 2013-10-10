permissions = {}
--insert !user@host into permissions here
--example: permissions["!~meow@Powder/Developer/cracker64"] = 101
--Owner should be 101

--Get perm value for part of a hostmask (usually just host)
function permFullHost(host)
	local highest=-99
	for k,v in pairs(permissions) do
		if host:find(k) then
			if v>highest then
				highest=v
			end
		end
	end
	if highest<-1 then highest=0 end
	return highest
end

--This has server specific data
local config={
	--Network to connect to, change to whatever network you use
	network = {
		server = "irc.freenode.net",
		port = 6667,
	},
	--User info, set these to whatever you need
	user = {
		nick = "Crackbot",
		username = "Meow",
		realname = "moo",
	},
	--Channels to join on start
	autojoin = {
		--"##foo",
	},
}

return config

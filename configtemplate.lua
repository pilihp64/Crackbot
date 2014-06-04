permissions = {}
--insert host into permissions here
--example: permissions["Powder/Developer/cracker64"] = 101
--Owner should be 101
permissions["/bot/"] = -1
permissions[" "..config.owner.host] = 101

--Get perm value for part of a hostmask (usually just host)
function getPerms(host)
	if permissions[host] then return permissions[host] end
	local highest=-99
	for k,v in pairs(permissions) do
		if host:find(k) then
			if v>highest then
				highest=v
			end
		end
	end
	if highest < -1 then highest=0 end
	return highest
end

--This has server specific data
local config = {
	--Network to connect to, change to whatever network you use
	network = {
		server = "irc.freenode.net",
		port = 6667,
		--password = ""
	},
	--User info, set these to whatever you need
	user = {
		nick = "wolfybot",
		username = "wolfy1339",
		realname = "Wolfy1339's Lua Bot",
		account = "BigWolfy1339",
		--password = "password"
	},
	--Owner info, only used now for terminal input
	owner = {
		nick = "wolfy1339",
		host = "botters/wolfy1339",
		fullhost = "wolfy1339!~wolfy1339@botters/wolfy1339"
	},
	--Channels to join on start
	channels = {
		autojoin = {
			--"##foo",
		},
		--used occasionally to kick people in games.lua
		primary = "##powder-bots",
		--logs all commands done in pm, and added aliases
		logs = "##foo",
	},
	prefix = "%*$",
	suffix = "woof+",
	
	--turns on terminal input, can be used on linux to input commands directly from a second terminal
	console = {
		terminal = "gnome-terminal",
		input = true
	}
}

return config

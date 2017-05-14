permissions = {}
--insert host into permissions here
--example: permissions["Powder/Developer/cracker64"] = 101
--Owner should be 101

--insert per channel permissions here
channelPermissions = {
	["##mychannel"] = {
		["Powder/Developer/jacob1"] = 50,
	},
}

--to override the default permission level of a command, insert it here
commandPermissions = {
	["mycommand"] = 10,
}
channelCommandPermissions = {
	["##mychannel"] = {
		["mycommand"] = 0,
	},
}

--Get perm value for part of a hostmask (usually just host)
function getPerms(host,chan)
	local perms, chanPerms = -1/0, nil
	for k,v in pairs(permissions) do
		if host:match("^"..k.."$") then
			if v < 0 then
				perms = -1
				break
			elseif v > perms then
				perms = v
			end
		end
	end
	if chan and channelPermissions[chan] then
		for k,v in pairs(channelPermissions[chan]) do
			if host:match("^"..k.."$") then
				if v < 0 then
					return -1
				elseif v > (chanPerms or -1/0) then
					chanPerms = math.min(v, 99)
				end
			end
		end
	end
	if perms < -1 then perms=0 end
	if chanPerms and chanPerms < -1 then chanPerms=0 end
	return chanPerms or perms
end

function getCommandPerms(cmd,chan)
	local defaultlvl = commands[cmd].level
	if defaultlvl >= 100 then return defaultlvl end
	if chan and channelCommandPermissions[chan] then
		return channelCommandPermissions[chan][cmd] or defaultlvl
	end
	return defaultlvl
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
		nick = "Crackbot",
		username = "Meow",
		realname = "moo",
		
		--account = "Crackbot",
		--password = "password"
	},
	--Owner info, only used now for terminal input
	owner = {
		nick = "jacob1",
		host = "Powder/Developer/jacob1",
		fullhost = "jacob1!~jacob1@Powder/Developer/jacob1"
	},
	--Channels to join on start
	autojoin = {
		--"##foo",
	},
	--used occasionally to kick people in games.lua
	primarychannel = "#powder-bots",
	--logs all commands done in pm, and added aliases
	logchannel = "##foo",
	
	prefix = "%./",
	suffix = "moo+",
	
	--turns on terminal input, can be used on linux to input commands directly from a second terminal
	terminal = "gnome-terminal -x",
	terminalinput = true
}

return config

module("ircModes", package.seeall)

--IRC MODE STUFF
function setMode(chan,mode,tar)
	if not tar then return end
	if chan:sub(1,1)=='#' then
		ircSendRawQ("MODE "..chan.." "..mode.." "..tar)
	else
		local _,_,channel,target = tar:find("^(.-)%s(.+)[^%s-]?")
		if channel and target then
			ircSendRawQ("MODE "..channel.." "..mode.." "..target)
		end
	end
end

--MODE
local function mode(usr,chan,msg,args)
	if not msg then return "Usage: '/mode [<chan>] <mode> [...]', if no chan given, will use current" end
	local tochan = ""
	local tomode = ""
	local rest = ""
	if args[1]:sub(1,1)=="#" then
		if not args[2] then return "Need a mode" end
		tochan=args[1]
		tomode=args[2]
		rest = table.concat(args, " ", 3)
	else
		tomode=args[1]
		if chan:sub(1,1)~='#' then return "Need to specify channel in query" end
		tochan=chan
		rest = table.concat(args, " ", 2)
	end
	
	ircSendRawQ("MODE "..tochan.." "..tomode.." "..rest)
end
add_cmd(mode,"mode",40,"Set a mode, '/mode [<chan>] <mode> [...]', if no chan given, will use current",true)

--OP
local function op(usr,chan,msg,args)
	if not args[1] then args[2]=usr.nick end
	if args[1] then
		if args[1]:sub(1,1)~='#' then
			args[2]=args[1]
		else
			if not args[2] then args[2]=usr.nick end
			chan=args[1]
		end
	end
	setMode(chan,"+o", args[2] or msg)
end
add_cmd(op,"op",30,"Op a user, '/op [<chan>] <username>'",true)
--DEOP
local function deop(usr,chan,msg,args)
	if not args[1] then msg=usr.nick end
	if args[1] then
		if args[1]:sub(1,1)~='#' then
			msg=args[1]
		else
			if not args[2] then msg=usr.nick end
			chan=args[1]
		end
	end
	setMode(chan,"-o",args[2] or msg)
end
add_cmd(deop,"deop",30,"DeOp a user, '/deop [<chan>] <username>'",true)

--VOICE
local function voice(usr,chan,msg,args)
	if not args[1] then args[2]=usr.nick end
	if args[1] then
		if args[1]:sub(1,1)~='#' then
			args[2]=args[1]
		else
			if not args[2] then args[2]=usr.nick end
			chan=args[1]
		end
	end
	setMode(chan,"+v", nick)
end
add_cmd(voice,"voice",15,"Voice a user, '/voice [<chan>] <username>'",true)

--DEVOICE
local function devoice(usr,chan,msg,args)
	if not args[1] then args[2]=usr.nick end
	if args[1] then
		if args[1]:sub(1,1)~='#' then
			args[2]=args[1]
		else
			if not args[2] then args[2]=usr.nick end
			chan=args[1]
		end
	end
	setMode(chan,"-v",args[2] or msg)
end
add_cmd(devoice,"devoice",10,"DeVoice a user, '/devoice [<chan>] <username>'",true)

--UNQUIET
local function unquiet(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local nick
	local host
	if args[1]:sub(1,1)=='#' then
		chan=args[1]
		if not args[2] then error("Missing target") end
		nick = args[2]
	else
		nick = args[1]
		host = getUserFromNick(args[1])
	end
	host = getUserFromNick(nick)
	host = host and host.host or nick
	setMode(chan,"-q",host)
end
add_cmd(unquiet,"unquiet",15,"UnQuiet a user, '/unquiet [<chan>] <host/username>'",true,{"unstab"})

--QUIET
local function quiet(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local unbanTimer
	local nick
	if args[1]:sub(1,1)=='#' then
		chan=args[1]
		if not args[2] then error("Missing target") end
		nick = args[2]
		unbanTimer = tonumber(args[3])
	else
		nick = args[1]
		unbanTimer = tonumber(args[2])
	end
	local host = getUserFromNick(nick)
	host = host and host.host or nick
	setMode(chan,"+q",host)
	if not unbanTimer then
		unbanTimer = math.random(60,600)
	end
	if unbanTimer then
		addTimer(setMode[chan]["-q"][host],unbanTimer,chan)
		ircSendNoticeQ(usr.nick, nick.." has been quieted for "..unbanTimer.." seconds")
	end
end
add_cmd(quiet,"quiet",20,"Quiet a user, '/quiet [<chan>] <host/username> [<time>]. If no time is specified, picks a random time between 60 and 600 seconds.'",true,{"stab"})

--UNBAN
local function unban(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local nick
	local host
	if args[1]:sub(1,1)=='#' then
		chan = args[1]
		if not args[2] then error("Missing target") end
		nick = args[2]
	else
		nick = args[1]
	end
	host = getUserFromNick(nick)
	host = host and host.host or nick
	setMode(chan,"-b",host)
end
add_cmd(unban,"unban",20,"Unban a user, '/unban [<chan>] <host/username>'",true)

--BAN
local function ban(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local nick
	local host
	local unbanTimer
	if args[1]:sub(1,1)=='#' then
		chan=args[1]
		if not args[2] then error("Missing target") end
		nick = args[2]
		unbanTimer = tonumber(args[3])
	else
		nick = args[1]
		unbanTimer = tonumber(args[2])
	end
	host = getUserFromNick(nick)
	host = host and host.host or nick
	setMode(chan,"+b",host)
	if unbanTimer then
		addTimer(setMode[chan]["-b"][host],unbanTimer,chan)
	end
end
add_cmd(ban,"ban",25,"Ban a user, '/ban [<chan>] <username> [<time>]'",true)

--KICK
local function kick(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local reason = ""
	if args[1]:sub(1,1)~='#' then
		local t={} for i=2,#args do table.insert(t,args[i]) end
		reason=table.concat(t," ")
		args[2]=args[1]
	else
		if not args[2] then error("Missing target") end
		local t={} for i=3,#args do table.insert(t,args[i]) end
		reason=table.concat(t," ")
		chan=args[1]
	end
	local nick = args[2] or msg
	local user = getUserFromNick(nick)
	if nick ~= usr.nick and user and user.host and getPerms(user.host) > 30 then
		return "Error: You can't kick other ops"
	elseif nick == irc.nick then
		nick = usr.nick
	end
	ircSendRawQ("KICK "..chan.." "..nick.." :"..reason)
end
add_cmd(kick,"kick",10,"Kick a user, '/kick [<chan>] <username> [<reason>]'",true)

--KBAN
local function kickban(usr,chan,msg,args)
	ban(usr,chan,msg,args)
	local timercheck = 2
	if args[1]:sub(1,1)=='#' then timercheck = 3 end
	if tonumber(timercheck) then table.remove(args, timercheck) end
	kick(usr,chan,msg,args)
end
add_cmd(kickban,"kban",30,"Kick and ban user, '/kban [<chan>] <username> [<time>] [<reason>]'",true)

--INVITE
local function invite(usr,chan,msg,args)
	if not args[1] then error("No args") end
	if args[2] then
		if args[2]:sub(1,1)~='#' then
			error("Not a channel")
		else
			chan=args[2]
		end
	end
	ircSendRawQ("INVITE "..args[1].." "..chan)
end
add_cmd(invite,"invite",50,"Invite someone to the channel, '/invite <user>'",true)

--JOIN a channel
local function join(usr,chan,msg,args)
	if not args[1] then error("No args") end
	if args[1]:sub(1,1)~='#' then
		error("Not a channel")
	else
		chan=args[1]
	end
	ircSendRawQ("JOIN "..chan)
end
add_cmd(join,"join",101,"Make bot join a channel, '/join <chan>'",true)

--PART a channel
local function part(usr,chan,msg,args)
	if args[1] then
		if args[1]:sub(1,1)~='#' then
			error("Not a channel")
		else
			chan=args[1]
		end
	end
	_G.expectedPart=chan
	ircSendRawQ("PART "..chan)
end
add_cmd(part,"part",101,"Make bot part a channel, '/part <chan>'",true)

--CYCLE a channel
local function cycle(usr,chan,msg,args)
	if args[1] then
		if args[1]:sub(1,1)~='#' then
			error("Not a channel")
		else
			chan=args[1]
		end
	end
	ircSendRawQ("PART "..chan)
	ircSendRawQ("JOIN "..chan)
end
add_cmd(cycle,"cycle",101,"Make bot part and rejoin channel, '/cycle <chan>'",true)

--REMOVE a user (ninja)
local function remove(usr,chan,msg,args)
	if not args[1] then error("No args") end
	if args[1] and args[1]:sub(1,1)=='#' then
		chan = args[1]
		table.remove(args, 1)
	end
	local nick = args[1]
	table.remove(args, 1)
	ircSendRawQ("REMOVE "..chan.." "..nick.." :"..table.concat(args, " "))
	--ircSendRawQ("JOIN "..chan) --cycle doesn't work, so lets just let the autorejoin fix it
end
add_cmd(remove,"remove",50,"Forefully remove a user from a channel, '/remove [<chan>] <user> [<reason>]'",true, {"ninja"})

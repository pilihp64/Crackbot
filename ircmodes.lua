--IRC MODE STUFF
local function setMode(chan,mode,tar)
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
	if not msg then return usr.nick..": '/mode [<chan>] <mode> [...]', if no chan given, will use current" end
	local tochan = ""
	local tomode = ""
	local rest = ""
	if args[1]:sub(1,1)=="#" then
		if not args[2] then return usr.nick..": Need a mode" end
		tochan=args[1]
		tomode=args[2]
		rest=args[3] or ""
	else
		tomode=args[1]
		if chan:sub(1,1)~='#' then return usr.nick..": Need to specify channel in query" end
		tochan=chan
		rest=args[2] or ""
	end

	ircSendRawQ("MODE "..tochan.." "..tomode.." "..rest)
end
add_cmd(mode,"mode",15,"Set a mode, '/mode [<chan>] <mode> [...]', if no chan given, will use current",true)
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
	setMode(chan,"+o",args[2] or msg)
end
add_cmd(op,"op",10,"Op a user, '/op [<chan>] <username>'",true)
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
add_cmd(deop,"deop",10,"DeOp a user, '/deop [<chan>] <username>'",true)
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
	setMode(chan,"+v",args[2] or msg)
end
add_cmd(voice,"voice",10,"Voice a user, '/voice [<chan>] <username>'",true)
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
--QUIET
local function quiet(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local host
	if args[1]:sub(1,1)=='#' then
		if not args[2] then error("Missing target") end
		host = getBestHost(chan,args[2] or msg)
		chan=args[1]
	else
		host = getBestHost(chan,args[1] or msg)
	end
	setMode(chan,"+q",host)
end
add_cmd(quiet,"quiet",10,"Quiet a user, '/quiet [<chan>] <host/username>'",true,{"stab"})
--UNQUIET
local function unquiet(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local host
	if args[1]:sub(1,1)=='#' then
		if not args[2] then error("Missing target") end
		host = getBestHost(chan,args[2] or msg)
		chan=args[1]
	else
		host = getBestHost(chan,args[1] or msg)
	end
	setMode(chan,"-q",host)
end
add_cmd(unquiet,"unquiet",10,"UnQuiet a user, '/unqueit [<chan>] <host/username>'",true,{"unstab"})

--UNBAN
local function unban(usr,chan,msg,args)
	if not args[1] then error("No args") end
	local host
	if args[1]:sub(1,1)=='#' then
		if not args[2] then error("Missing target") end
		host = getBestHost(chan,args[2] or msg)
		chan=args[1]
	else
		host = getBestHost(chan,args[1] or msg)
	end
	setMode(chan,"-b",host)
end
add_cmd(unban,"unban",15,"Unban a user, '/unban [<chan>] <host/username>'",true)
--BAN
local function ban(usr,chan,msg,args,unbanTimer)
	if not args[1] then error("No args") end
	--if not user.access:match("@") then error("Not Op") end
	local host
	if args[1]:sub(1,1)=='#' then
		if not args[2] then error("Missing target") end
		host = getBestHost(chan,args[2] or msg)
		unbanTimer = tonumber(args[3])
		chan=args[1]
	else
		host = getBestHost(chan,args[1] or msg)
		unbanTimer = tonumber(args[2])
	end
	setMode(chan,"+b",host)
	if unbanTimer then
		addTimer(setMode[chan]["-b"][host],unbanTimer,chan)
	end
end
add_cmd(ban,"ban",15,"Ban a user, '/ban [<chan>] <username> [<time>]'",true)
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
	ircSendRawQ("KICK "..chan.." "..(args[2] or msg).." :"..reason)
end
add_cmd(kick,"kick",10,"Kick a user, '/kick [<chan>] <username> [<reason>]'",true)
--KBAN
local function kickban(usr,chan,msg,args)
	--timed bans sometime?
	ban(usr,chan,msg,args,unbanTimer)
	kick(usr,chan,msg,args)
end
add_cmd(kickban,"kban",15,"Kick and ban user, '/kban [<chan>] <username> [<time>] [<reason>]'",true)
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
	if not args[1] then return usr.nick..": Need a message" end
	if args[1]:sub(1,1)~='#' then
		error("Not a channel")
	else
		chan=args[1]
	end
	ircSendRawQ("PART "..chan)
end
add_cmd(part,"part",101,"Make bot part a channel, '/part <chan>'",true)

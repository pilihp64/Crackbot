local buffer = {}
local waitingCommands = {}
--make print log everything to file as well
_print = _print or print
print = function(...)
	_print(...)
	local arg={...}
	local str = table.concat(arg,"\t")
	local frqq=io.open("log.txt","a")
	frqq:write(os.date("[%x] [%X] ")..str.."\n")
	frqq:flush()
	frqq:close()
end

local onSendHooks = {}
function addSendHook(hook,key)
	if type(hook)=="function" then
		onSendHooks[key] = onSendHooks[key] or hook
	end
end
function remSendHook(key)
	onSendHooks[key] = nil
end

--chat queue, needs to prevent excess flood eventually
function ircSendChatQ(chan,text,nohook)
	--possibly keep rest of text to send later
	if not text then return end
	if not nohook then
		for k,v in pairs(onSendHooks) do
			chan,text = v(chan,text)
		end
	end
	text = text:gsub("[\r\n]"," ")
	local host = ""
	if not chan then chan=config.logchannel end
	if irc.channels[config.primarychannel] and irc.channels[config.primarychannel].users[irc.nick] then
		host = irc.channels[config.primarychannel].users[irc.nick].fullhost or ""
	end
	local byteLimit = 498 - #chan - #host
	if byteLimit - #text < 0 and byteLimit - #text > -1600 then
		table.insert(buffer,{["channel"]=chan,["msg"]=text:sub(1,byteLimit),["raw"]=false,["notice"]=false})
		ircSendChatQ(chan,string.sub(text,byteLimit+1),true)
	else
		table.insert(buffer,{["channel"]=chan,["msg"]=text:sub(1,512),["raw"]=false,["notice"]=false})
	end
end
function ircSendRawQ(text)
	table.insert(buffer,{["msg"]=text:sub(1,417):gsub("[\r\n]",""),["raw"]=true,["notice"]=false})
end
function ircSendNoticeQ(channel, text)
	table.insert(buffer,{["channel"]=channel,["msg"]=text:sub(1,417):gsub("[\r\n]",""),["raw"]=false,["notice"]=true})
end

--send a line of queue
local messageBurst,messageBurstTimeout,timer = 4,0,socket.gettime()
function ircSendOne()
	if #buffer == 0 then return end
	if messageBurst == 0 and messageBurstTimeout < socket.gettime() then
		messageBurst = 4
	end
	if timer < socket.gettime() then
		local line = table.remove(buffer,1)
		if not line or not line.msg then return end
		if line.raw then
			local s,r = pcall(irc.send,irc,line.msg)
			if not s then
				print(r)
			else
				print(user.nick .. ": ".. line.msg)
			end
		elseif line.notice then
			local s,r = pcall(irc.sendNotice,irc,line.channel,line.msg)
			if not s then
				print(r)
			else
				print(">"..line.channel.."< "..line.msg)
			end
		else
			local s,r = pcall(irc.sendChat,irc,line.channel,line.msg)
			if not s then
				print(r)
			else
				print("["..line.channel.."] <"..user.nick.."> "..line.msg)
			end
		end
		if messageBurst == 0 then
			timer = socket.gettime() + .8
		else
			messageBurst = messageBurst - 1
			timer = socket.gettime() + .05
		end
		messageBurstTimeout = socket.gettime() + 5
	end
end

local prefix = config.prefix
function setPrefix(fix)
	if fix and type(fix)=="string" and fix~="" then
		prefix=fix
	else
		error("Not a string")
	end
end
local suffix = config.suffix
function setSuffix(fix)
	if fix and type(fix)=="string" and fix~="" then
		suffix=fix
	else
		error("Not a string")
	end
end

--timers, might be useful to save these for long bans
timers = timers or {}
updates = updates or {}
function addTimer(f,time,chan,name)
	name = name or ""--name for removing a timer
	table.insert(timers,{f=f,time=os.time()+time-1,chan=chan,name=name})
end
function remTimer(name)
	for k,v in pairs(timers) do
		if v.name==name then
			timers[k]=nil
		end
	end
end
function addUpdate(f,time,chan,name)
	name = name or ""--name for removing
	table.insert(updates,{f=f,time=time,lastcheck=0,chan=chan,name=name})
end
function remUpdate(name)
	for k,v in pairs(updates) do
		if v.name==name then
			v.f=nil
			updates[k]=nil
		end
	end
end
function timerCheck()
	for k,v in pairs(timers) do
		if os.time()>v.time then
			didSomething=true
			local s,r = pcall(v.f)
			if not s then ircSendChatQ(v.chan,r) end
			table.remove(timers,k)
		end
	end
	--updates should never be removed, have an interval timer
	for k,v in pairs(updates) do
		if os.time()-v.lastcheck>=v.time then
			v.lastcheck = os.time()
			local s,r = pcall(v.f)
			if not s then ircSendChatQ(v.chan,r) end
		end
	end
	for k,v in pairs(waitingCommands) do
		if os.time()>v.time then
			didSomething=true
			local s,s2,resp,noNickPrefix = pcall(coroutine.resume,v.co)
			if not s and s2 then
				ircSendChatQ(v.channel,s2)
			elseif s2 then
				--coroutine was success
				if resp then
					if type(resp)=="table" then
						for kk,vv in pairs(resp) do
							ircSendChatQ(v.channel,vv)
						end
					else
						if not noNickPrefix then resp=v.usr.nick..": "..resp end
						ircSendChatQ(v.channel,resp)	
					end
					table.remove(waitingCommands,k)
				elseif resp==false then
					--wait this amount of time to resume
					v.time=os.time()+noNickPrefix-1
				else
					table.remove(waitingCommands,k)
				end
			else
				--coroutine succeeded but caught an error
				table.remove(waitingCommands,k)
				ircSendChatQ(v.channel,resp)
			end
		end
	end
end

--chat listeners, can read for specific messages, returning true means delete listener
chatListeners = {}
function addListener(name,f)
	if type(f)=="function" then
		chatListeners[name]=f
	end
end
local function listen(usr,chan,msg)
	for k,v in pairs(chatListeners) do
		local s,r = pcall(v,usr,chan,msg)
		if s then
			if r==true then chatListeners[k]=nil end
		end
	end
end

--Something to run before/after specific commands
preCommands = {}
postCommands = {}
local function onPreCommand(cmd,usr)
	if preCommands[cmd] then preCommands[cmd](usr) end
end
local function onPostCommand(cmd,usr)
	if postCommands[cmd] then postCommands[cmd](usr) end
end

--capture args into table that supports "test test" args
function getArgs(msg)
	if not msg then return {} end
	local args = {}
	local index=1
	while index<=#msg do
		local s2,e2,word2 = msg:find("\"([^\"]-)\"",index)
		local s,e,word = msg:find("([^%s]+)",index)
		if s2 and s2<=s then
			word=word2
			e=e2
		end
		table.insert(args,word)
		index = (e or #msg)+1 or #msg+1
	end
	return args
end
function getArgsOld(msg)
    if not msg then return {} end
    local args = {}
    for word in msg:gmatch("([^%s]+)") do
		table.insert(args,word)
    end
    return args
end

local nestify=nil
local nestBegin = "<<"
local nestEnd = ">>"
function setNest(nb,ne)
	if #nb and #ne and nb~=ne then
		nestBegin = nb
		nestEnd = ne
	else
		return "Bad nest"
	end
end

function makeCMD(cmd,usr,channel,msg,permcheck)
	cmd = cmd:lower()
	if commands[cmd] then
		--command exists
		--print("INHOOK "..getPerms(usr.host).." "..tostring(cmd))
		if permcheck or getPerms(usr.host) >= commands[cmd].level then
			--we have permission
			
			return function()
				if msg and cmd ~= "alias" and cmd ~= "aa" then
					--check for nested commands, ./echo {`echo test`}
					msg,_ = nestify(msg,1,0,usr,channel)
				end
				if msg=="" then msg=nil end
				coroutine.yield(false,0)
				local s,r,e = commands[cmd].f(usr,channel,msg,getArgs(msg))
				if type(s)=="string" then s = s:sub(1,5000) end
				return s,r,e
			end
		else
			return false,usr.nick..": No permission for "..cmd
		end
	else
		--ircSendChatQ(channel,usr.nick..": "..cmd.." doesn't exist!")
	end
end
function tryCommand(usr,channel,msg)
	local temps = ""
	local _,_,ncmd,nrest = msg:find("([^%s]*)%s?(.*)$")
	if ncmd then
		local vf = makeCMD(ncmd,usr,channel,nrest)
		if ncmd == "timer" or ncmd == "use" or ncmd == "bug" then
			return "Error: this command cannot be nested"
		end
		if vf then
			temps = (vf() or "")
		end
	end
	return temps
end
nestify=function(str,start,level,usr,channel)
	if level>10 then error("Max nest level reached!") end
	local tstring=""
	local st,en = str:find(nestBegin,start)
	local st2,en2 = str:find(nestEnd,start)
	while st or st2 do
		if st2 then
			if not st or (st and st>st2) then
				if level~=0 then
					--closing bracket, end of level, execute the level
					--Entire level gets replaced with cmd return
					tstring = tryCommand(usr,channel,tstring..str:sub(start,st2-1))
					start = en2+1
					break
				else
					tstring = tstring..str:sub(start,en2)
					start = en2+1
				end
			elseif st then
				--opening bracket is before close, new level! Keep first part of string
				tstring=tstring..str:sub(start,st-1)
				--Add the result of the next level
				local rstring,cstart = nestify(str,en+1,level+1,usr,channel)
				tstring,start = tstring..rstring,cstart
			else
				return str,start
			end
		else
			return str,start
		end
		st,en = str:find(nestBegin,start)
		st2,en2 = str:find(nestEnd,start)
	end
	--add anything remaining
	if level==0 then tstring=tstring..str:sub(start) end
	return tstring,start
end

local function realchat(usr,channel,msg)
	--if usr.host:find("c%-75%-70%-221%-236%.hsd1%.co%.comcast%.net") then return end
	didSomething=true
	if prefix ~= config.prefix then
		panic,_ = msg:find("^"..config.prefix.."fix")
		if panic then prefix = config.prefix end
	end
	local _,_,pre,cmd,rest = msg:find("^("..prefix..")([^%s]*)%s?(.*)$")
	if not cmd then
		--no cmd found for prefix, try suffix
		_,_,cmd,rest,pre = msg:find("^([^%s]+) (.-)%s?("..suffix..")$")
	end

	local func,err
	if cmd then
		func,err=makeCMD(cmd,usr,channel,rest)
	end
	listen(usr,channel,msg)
	if func then
		--we can execute the command
		local co = coroutine.create(func)
		onPreCommand(cmd,usr)
		local s,s2,resp,noNickPrefix = pcall(coroutine.resume,co)
		onPostCommand(cmd,usr)
		if not s and s2 then
			ircSendChatQ(channel,s2)
		elseif s2 then
			--coroutine was success
			if resp then
				if not noNickPrefix then resp=usr.nick..": "..resp end
				ircSendChatQ(channel,resp)
			elseif resp==false then
				--wait this amount of time to resume
				table.insert(waitingCommands,{co=co,time=os.time()+noNickPrefix-1,usr=usr,channel=channel,msg=msg})
			end
		else
			ircSendChatQ(channel,resp)
		end
		--log to channel, to notice things faster
		if config.logchannel and channel:sub(1,1):match("%a") then
			ircSendChatQ(config.logchannel, usr.nick.."!"..usr.username.."@"..usr.host.." used "..config.prefix:gsub("%%","")..cmd)
		end
	else
		if err then ircSendNoticeQ(usr.nick,err) end
		--Last said
		if channel and channel:sub(1,1)=='#' then (irc.channels[channel].users[usr.nick] or {}).lastSaid = {["msg"]=msg, ["time"]=os.time()} end
	end

	if user.nick=="Crackbot" and channel=='##jacob1' and usr.nick == "CrackbotRepo" and usr.host:find("192%.30%.252") then
		ircSendChatQ("##powder-bots",msg)
	end
	if channel=='##pwc' and usr.nick:match("^TrialReporter") and (usr.host == "prime.pwc-networks.com"or usr.host == "108.59.12.136") then
		local mtime,nusr,nmsg = msg:match("^%((%d?%d?:?%d%d:%d%d)%) \003%d%d\002(.-)\002\003: (.+)$")
		--print(nusr.." AND "..nmsg)
		if nmsg and nmsg~="" then 
			realchat({nick=nusr,host="ut2k4/ingame",fullhost=nusr.."!usr@ut2k4/ingame",ingame=true,gametime=mtime},channel,nmsg:gsub("^!","./"))
			return
		end
	end
	if channel:sub(1,13) ~= "##starcatcher" then
		print("["..tostring(channel).."] <".. tostring(usr.nick) .. ">: "..tostring(msg))
	end
end
local function chat(usr,channel,msg)
	if channel==user.nick then channel=usr.nick end --if query, respond back to usr
	if not usr.nick then return end
	local s,r = pcall(realchat,usr,channel,msg)
	if not s and r then
		onSendHooks = {}
		ircSendChatQ(channel,r)
	end
end

--console is read as messages from me
local conChannel = config.primarychannel
function consoleChat(msg)
	local _,_,chan = msg:find("^"..config.prefix.."chan (.+)")
	local isPrefix = msg:find("^"..config.prefix)
	if not isPrefix then
		msg = config.prefix:gsub("%%","").."echo "..msg
	end
	if chan then
		print("Channel set to "..chan)
		conChannel = chan
		return
	end
	chat({nick=config.owner.nick,host=config.owner.host,fullhost=config.owner.fullhost},conChannel,msg)
end
--remove old hook for reloading
pcall(irc.unhook,irc,"OnChat","chat1")
irc:hook("OnChat","chat1",chat)

--get hostmask from channel
local function doWho(chan,msg)
	ircSendRawQ("WHO "..chan)
end
pcall(irc.unhook,irc,"NameList","doWho")
irc:hook("NameList","doWho",doWho)

--auto rejoin
local function kickCheck(chan,kicked,usr,reason)
	if kicked==user.nick then
		print("Kicked from "..chan)
		ircSendRawQ("JOIN "..chan)
	else
		print(kicked.." was Kicked from "..chan)
	end
end
pcall(irc.unhook,irc,"OnKick","kickCheck")
irc:hook("OnKick","kickCheck",kickCheck)

--auto rejoin
expectedPart = ""
local function partCheck(usr,chan,reason)
	if usr.nick==user.nick then
		print("Parted from "..chan)
		if expectedPart~=chan then
			ircSendRawQ("JOIN "..chan)
		else 
			expectedPart=""
		end
	else
		print(usr.nick.." Parted from "..chan)
	end
end
pcall(irc.unhook,irc,"OnPart","partCheck")
irc:hook("OnPart","partCheck",partCheck)


local function onNotice(usr,channel,msg)
	print("[NOTICE "..tostring(channel).."] <".. tostring(usr.nick) .. ">: "..tostring(msg))
end
pcall(irc.unhook,irc,"OnNotice","notice1")
irc:hook("OnNotice","notice1",onNotice)

local function onCTCP(usr,channel,type,msg)
	if channel==user.nick then channel=usr.nick end --if query, respond back to usr
	local response = nil
	if type == "VERSION" then
		local cmd = io.popen(WINDOWS and "ver" or "uname -a")
		local version = cmd:read("*a")
		cmd:close()
		response = "Crackbot, the best IRC bot. Running on "..version
	elseif type == "TIME" then
		response = os.date()
	elseif type == "PING" then
		response = msg
	elseif type == "SOURCE" then
		response = "https://github.com/cracker64/Crackbot"
	end
	if response then
		ircSendNoticeQ(usr.nick,"\001"..type.." "..response.."\001")
	end
	if type == "ACTION" then
		print("["..tostring(channel).."] * "..tostring(usr.nick).." "..tostring(msg))
	else
		print("Recieved a CTCP "..tostring(type)..(msg~="" and " " or "")..tostring(msg).. " from "..tostring(usr.nick))
	end
end
pcall(irc.unhook,irc,"OnCTCP","ctcp1")
irc:hook("OnCTCP","ctcp1",onCTCP)

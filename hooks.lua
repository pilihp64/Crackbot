local buffer = {}
local bannedChans = {['nickserv']=true,['chanserv']=true,['memoserv']=true}
local activeFilters = {}
local badWordFilts = nil
waitingCommands = {}
setmetatable(activeFilters,{__index = function(t,k) t[k]={t = {},lock = false} return t[k] end})
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

local function chatFilter(chan,text)
	if bannedChans[chan:lower()] then error("Bad chan") end
	for k,v in pairs(activeFilters[chan].t) do
		text = v.f(text,v.args,true):sub(1,500)
	end
	--don't censor query
	if badWordFilts and chan:sub(1,1)=='#' then text = badWordFilts(text) end
	return chan,text
end
--show active filters
function getFilts(chan)
	local t={}
	for k,v in pairs(activeFilters[chan].t) do
		table.insert(t, v.name .. " " .. table.concat(v.args," ") )
	end
	local text = table.concat(t,"> ") or ""
	print(text)
	return "in > "..text .. "> out"
end
--add new filter
function addFilter(chan,filt,name,args)
	if type(filt)=='function' then
		if not activeFilters[chan].lock then
			table.insert(activeFilters[chan].t,{['f']=filt,['name']=name,['args']=args})
			return true
		else
			return false
		end
	end
end
function setBadWordFilter(f)
	badWordFilts  = f
end
--clear filter
function clearFilter(chan)
   	if not activeFilters[chan].lock then
		activeFilters[chan].t={}
		return true
	else
		return false
	end
end
--kill all filters, for errors
function clearAllFilts()
	for k,v in pairs(activeFilters) do
		v.t = {}
	end
end
function filtLock(chan)
	activeFilters[chan].lock = true
end
function filtUnLock(chan)
	activeFilters[chan].lock = false
end
--chat queue, needs to prevent excess flood eventually
function ircSendChatQ(chan,text,nofilter)
	--possibly keep rest of text to send later
	if not text then return end
	text = text:sub(1,417):gsub("[\r\n]","")
	if not nofilter then
		chan,text = chatFilter(chan,text)
	end
	table.insert(buffer,{["channel"]=chan,["msg"]=text,["raw"]=false})
end
function ircSendRawQ(text)
	table.insert(buffer,{["msg"]=text:sub(1,417):gsub("[\r\n]",""),["raw"]=true})
end

--send a line of queue
function ircSendOne()
	if tick%12==0 and #buffer then
		local line = table.remove(buffer,1)
		if not line or not line.msg then return end
		if line.raw then
			local s,r = pcall(irc.send,irc,line.msg)
			if not s then
				print(r)
			else
				print(user.nick .. ": ".. line.msg)
			end
		else
			local s,r = pcall(irc.sendChat,irc,line.channel,line.msg)
			if not s then
				print(r)
			else
				print("["..line.channel.."] "..user.nick..": "..line.msg)
			end
		end
	end
end

local prefix = "%./"
function setPrefix(fix)
	if fix and type(fix)=="string" and fix~="" then
		prefix=fix
	else
		error("Not a string")
	end
end
local suffix = "moo+"
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
					if not noNickPrefix then resp=v.usr.nick..": "..resp end
					ircSendChatQ(v.channel,resp)
					table.remove(waitingCommands,k)
				elseif resp==false then
					--wait this amount of time to resume
					v.time=os.time()+noNickPrefix-1
				else
					table.remove(waitingCommands,k)
				end
			else
				table.remove(waitingCommands,k)
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

nestify=nil
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

function makeCMD(cmd,usr,channel,msg)
	if commands[cmd] then
		--command exists
		if permFullHost(usr.fullhost) >= commands[cmd].level then
			--we have permission
			return function()
					if msg then
						--check for {` `} nested commands, ./echo {`echo test`}
						msg,_ = nestify(msg,1,0,usr,channel)
					end
					if msg=="" then msg=nil end
					return commands[cmd].f(usr,channel,msg,getArgs(msg))
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
	if prefix~= '%./' then
		panic,_ = msg:find("^%./fix")
		if panic then prefix='%./' end
	end
	local _,_,pre,cmd,rest = msg:find("^("..prefix..")([^%s]*)%s?(.*)$")
	if not cmd then
		--no cmd found for prefix, try suffix
		_,_,cmd,rest,pre = msg:find("^([^%s]+) (.-)%s?("..suffix..")$")
	end

	local func,err
	if cmd then func,err=makeCMD(cmd,usr,channel,rest) end

	if func then
		--we can execute the command
		local co = coroutine.create(func)
		local s,s2,resp,noNickPrefix = pcall(coroutine.resume,co)
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
	else
		if err then ircSendChatQ(channel,err) end
		--Last said
		if channel:sub(1,1)=='#' then (irc.channels[channel].users[usr.nick] or {}).lastSaid = msg end
	end
	listen(usr,channel,msg)
	if user.nick=="Crackbot" and channel=='#neotenic' and usr.host:find("192%.30%.252%.49$") then
		--relay to ##powder-bots because i'm lazy
		ircSendChatQ("##powder-bots",msg)
	end
	print("["..tostring(channel).."] <".. tostring(usr.nick) .. ">: "..tostring(msg))
end
local function chat(usr,channel,msg)
	if channel==user.nick then channel=usr.nick end --if query, respond back to usr
	local s,r = pcall(realchat,usr,channel,msg)
	if not s and r then
		clearAllFilts()
		ircSendChatQ(channel,r)
	end
end

--console is read as messages from me
local conChannel = "##powder-bots"
function consoleChat(msg)
	local _,_,chan = msg:find("^%./chan (.+)")
	local isPrefix = msg:find("^%./")
	if not isPrefix then
		msg = "./echo "..msg
	end
	if chan then
		print("Channel set to "..chan)
		conChannel = chan
		return
	end
	chat({nick="cracker64",host="Powder/Developer/cracker64",fullhost="!~meow@Powder/Developer/cracker64"},conChannel,msg)
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

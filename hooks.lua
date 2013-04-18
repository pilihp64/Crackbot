local buffer = {}
local bannedChans = {['nickserv']=true,['chanserv']=true,['memoserv']=true}
local activeFilters = {}
local badWordFilts = nil
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
--Activates all filters and then badwords
local function chatFilter(chan,text)
	if bannedChans[chan:lower()] then error("Bad chan") end
	for k,v in pairs(activeFilters[chan].t) do
		text = v.f(text,v.args,true)
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
	local text = table.concat(t," > ") or ""
	return "in > "..text .. " > out"
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
	text = text:sub(1,417)
	if not nofilter then
		chan,text = chatFilter(chan,text)
	end
	table.insert(buffer,{["channel"]=chan,["msg"]=text,["raw"]=false})
end
function ircSendRawQ(text)
	table.insert(buffer,{["msg"]=text:sub(1,417),["raw"]=true})
end
--send a line of queue
function ircSendOne()
	if #buffer then
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
function timerCheck()
	for k,v in pairs(timers) do
		if os.time()>v.time then
			local s,r = pcall(v.f)
			if not s then ircSendChatQ(v.chan,r) end
			table.remove(timers,k)
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

local function realchat(usr,channel,msg)
	if prefix~= '%./' then
		panic,_ = msg:find("^%./fix")
		if panic then prefix='%./' end
	end
	local _,_,pre,cmd,rest = msg:find("^("..prefix..")([^%s]+)%s?(.*)$")
	if not cmd then --no cmd found for prefix, try suffix
		_,_,cmd,rest,pre = msg:find("^([^%s]+) (.-)%s?("..suffix..")$")
	end
	if rest=="" then rest=nil end
	if channel==user.nick then channel=usr.nick end --if query, respond back to usr
	if commands[cmd] then
		--command exists
		if permFullHost(usr.fullhost) >= commands[cmd].level then
			--we have permission
			local s,r = pcall(commands[cmd].f,usr,channel,rest,getArgs(rest))
			if not s and r then
				ircSendChatQ(channel,r)
			else
				if r then ircSendChatQ(channel,r) end
			end
		else
			ircSendChatQ(channel,usr.nick..": No permission for "..cmd)
		end
	else
		--Last said
		if channel:sub(1,1)=='#' then (irc.channels[channel].users[usr.nick] or {}).lastSaid = msg end
	end
	listen(usr,channel,msg)
	if channel=='#neotenic' and usr.host:find("github.com$") then
		--relay to ##powder-bots because i'm lazy
		ircSendChatQ("##powder-bots",msg)
	end
	print("["..tostring(channel).."] <".. tostring(usr.nick) .. ">: "..tostring(msg))
end
local function chat(usr,channel,msg)
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
local function partCheck(usr,chan,reason)
	if usr.nick==user.nick then
		print("Parted from "..chan)
		ircSendRawQ("JOIN "..chan)
	else
		print(usr.nick.." Parted from "..chan)
	end
end
pcall(irc.unhook,irc,"OnPart","partCheck")
irc:hook("OnPart","partCheck",partCheck)

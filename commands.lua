--List of files to load
local modList = {"sandybox.lua","filters.lua","games.lua"}
math.randomseed(os.time())
commands = {}
local stepcount=0
local cmdcount = 0
local function infhook()
	stepcount = stepcount+1
	if stepcount>100000 then
		stepcount=0
		debug.sethook()
		error("Break INF LOOP")
	else
		return
	end
end
function add_cmd(f, name, lvl, help, shown, aliases)
	commands[name]={["name"]=name,["f"]=f,["level"]=lvl,["helptext"]=help,["show"]=shown}
	if aliases then
		for k,v in pairs(aliases) do
			commands[v] = {["name"]=name,["f"]=f,["level"]=lvl,["helptext"]=help,false}
		end
	end
end
--Load mods here so it can use add_cmd
for k,v in pairs(modList) do
	local s,r = pcall(dofile,v)
	if not s then print(r) end
end

--Helper to return hostmask for a name
local function getBestHost(chan,msg,long)
	local host = false
	local besthost = nil
	if msg:match("@") then host=true end
	if not host then
		for nick,v in pairs(irc.channels[chan].users) do
			if (string.lower(nick))==(string.lower(msg)) then if not long then besthost= "*!*@"..v.host else besthost= "!"..v.username.."@"..v.host end end
		end
	end
	return besthost or msg
end

--QUIT
local function suicide(usr,chan,msg)
	ircSendRawQ("QUIT :moo")
	shutdown = true;
end
add_cmd(suicide,"suicide",101,"Quits the bot",true,{"quit"})

--PING
local function ping(usr,chan,msg)
	return "pong"
end
add_cmd(ping,"ping",0,"pong",true)

--DO
local function dothis(usr,chan,msg)
	if msg then return "\001ACTION does "..msg.."\001" end
end
add_cmd(dothis,"do",0,"Performs an action, '/do <text>'",true)
--ME
local function methis(usr,chan,msg)
	if msg then return "\001ACTION "..msg.."\001" end
end
add_cmd(methis,"me",0,"Performs an action, '/me <text>'",true)

--SNEAAK
local function sneaky(usr,chan,msg)
	return "You found me!"
end
add_cmd(sneaky,"./",0,"No help for ./ found!",false)
local function sneaky2(usr,chan,msg)
	ircSendChatQ(usr.nick,"1 point gained")
	return nil
end
add_cmd(sneaky2,"./moo",0,"No help for ./moo found!",false)
local function sneaky3(usr,chan,msg)
	return "MooOoOoooOooo"
end
add_cmd(sneaky3,"moo",0,"No help for moo found!",false)

--RELOAD files
local function reload(usr,chan,msg,args)
	if not args[1] then args[1]="hooks" end
	local rmsg=""
	for k,v in pairs(args) do
		local s,r = pcall(dofile,v..".lua")
		if s then rmsg = rmsg .. "Loaded: "..v.." "
		else rmsg = rmsg .. r .. " "
		end
	end
	return rmsg
end
add_cmd(reload,"load",100,"Loads file(s), '/load <file1> [<file2>] [<files...>]",true,{"reload"})

--ECHO
local function echo(usr,chan,msg)
	return msg
end
add_cmd(echo,"echo",0,"Replies same text, '/echo <text>'",true)

--LIST
local function list(usr,chan,msg,args)
	local perm = tonumber(args[1]) or permFullHost(usr.fullhost)
	local t = {}
	local cmdcount=0
	for k,v in pairs(commands) do
		if perm>=commands[k].level and commands[k].show then
			cmdcount=cmdcount+1
			t[cmdcount]=k
		end
	end
	table.sort(t,function(x,y)return x<y end)
	return "Commands("..perm.."): " .. table.concat(t,", ")
end
add_cmd(list,"list",0,"Lists commands for the specified level, or your own, '/list [<level>]'",true,{"ls"})

--CHMOD
local function chmod(usr,chan,msg,args)
	if not msg then return end
	local perm = permFullHost(usr.fullhost)
	local setmax = perm-1
	local host,level = getBestHost(chan,args[1],true),args[2]
	if tonumber(level) > setmax then
		return "You can't set that high"
	end
	if permissions[host] and permissions[host] >= perm then
		return "You can't change this user"
	end
	permissions[host] = tonumber(level)
	return usr.nick .. ": perm['"..host.."'] = "..level
end
add_cmd(chmod,"chmod",2,"Changes a hostmask level, '/chmod <name/host> <level>'",true)

--LUA sandbox
local function lua(usr,chan,msg,args,luan)
	if not msg then return false,"No message" end
	local sdump=""
	luan = luan or "lua"
	--byte the string so you can't escape
	for char in msg:gmatch(".") do sdump = sdump .. "\\"..char:byte() end
	local rf = io.popen(luan..[[ -e 'dofile("derp.lua") dofile("sandybox.lua") local e,err=load_code("]]..sdump..[[",nil,"t",env)
    							if e then local r = {pcall(e)}
    								local s = table.remove(r,1)
    								print(unpack(r))
    							else print(err) end' 2>&1]])
	socket.sleep(1)
	local kill = io.popen("pgrep -f '"..luan.." -e'"):read("*a")
	if kill~="" then os.execute("pkill -f '"..luan.." -e'") end
	local r = rf:read("*a")
	if r=="" and kill and kill~="" then r="Killed" end
	if r then return usr.nick .. ": "..r:gsub("[\r\n\t]"," ") end
end
local function lua52(usr,chan,msg,args)
	return lua(usr,chan,msg,args,"lua5.2")
end
add_cmd(lua,"lua",0,"Runs sandbox lua code, '/lua <code>'",true)
add_cmd(lua52,"5.2",0,"Runs sandbox lua5.2 code, '/lua <code>'",false)

--LUA
local function lua2(usr,chan,msg,args)
	local e,err = loadstring(msg)
	if e then
		debug.sethook(infhook,"l")
		local s,r = pcall(e)
		debug.sethook()
		stepcount=0
		if s then
			local str = tostring(r) 
			return usr.nick.. ": " .. str:gsub("[\r\n]"," ")
		else
			return usr.nick.. ": ERROR: " .. r
		end
		return
	end
	return usr.nick.. ": ERROR: " .. err
end
add_cmd(lua2,"..",101,"Runs full lua code, '/lua <code>'",false)

--PYTHON code
local function python(usr,chan,msg,args)
	if not msg then return false,"No message" end
	local sdump= hexStr(msg,"") --hex the string for python to load
	good_func_string = 'safe_list["False"]=False;safe_list["True"]=True;safe_list["abs"]=abs;safe_list["divmod"]=divmod;safe_list["staticmethod"]=staticmethod;safe_list["all"]=all;safe_list["enumerate"]=enumerate;safe_list["int"]=int;safe_list["ord"]=ord;safe_list["str"]=str;safe_list["any"]=any;safe_list["isinstance"]=isinstance;safe_list["pow"]=pow;safe_list["sum"]=sum;safe_list["basestring"]=basestring;safe_list["issubclass"]=issubclass;safe_list["super"]=super;safe_list["bin"]=bin;safe_list["iter"]=iter;safe_list["property"]=property;safe_list["tuple"]=tuple;safe_list["bool"]=bool;safe_list["filter"]=filter;safe_list["len"]=len;safe_list["range"]=range;safe_list["type"]=type;safe_list["bytearray"]=bytearray;safe_list["float"]=float;safe_list["list"]=list;safe_list["unichr"]=unichr;safe_list["callable"]=callable;safe_list["format"]=format;safe_list["locals"]=locals;safe_list["reduce"]=reduce;safe_list["unicode"]=unicode;safe_list["chr"]=chr;safe_list["frozenset"]=frozenset;safe_list["long"]=long;safe_list["vars"]=vars;safe_list["classmethod"]=classmethod;safe_list["getattr"]=getattr;safe_list["map"]=map;safe_list["repr"]=repr;safe_list["xrange"]=xrange;safe_list["cmp"]=cmp;safe_list["globals"]=globals;safe_list["max"]=max;safe_list["reversed"]=reversed;safe_list["zip"]=zip;safe_list["compile"]=compile;safe_list["hasattr"]=hasattr;safe_list["memoryview"]=memoryview;safe_list["round"]=round;safe_list["complex"]=complex;safe_list["hash"]=hash;safe_list["min"]=min;safe_list["set"]=set;safe_list["apply"]=apply;safe_list["delattr"]=delattr;safe_list["help"]=help;safe_list["next"]=next;safe_list["setattr"]=setattr;safe_list["buffer"]=buffer;safe_list["dict"]=dict;safe_list["hex"]=hex;safe_list["object"]=object;safe_list["slice"]=slice;safe_list["coerce"]=coerce;safe_list["dir"]=dir;safe_list["id"]=id;safe_list["oct"]=oct;safe_list["sorted"]=sorted;safe_list["intern"]=intern;'
	--[[good_funcs = {
		"abs","divmod","staticmethod","True","False",
		"all","enumerate","int","ord","str",
		"any","isinstance","pow","sum",
		"basestring","issubclass","super",
		"bin","iter","property","tuple",
		"bool","filter","len","range","type",
		"bytearray","float","list","unichr",
		"callable","format","locals","reduce","unicode",
		"chr","frozenset","long","vars",
		"classmethod","getattr","map","repr","xrange",
		"cmp","globals","max","reversed","zip",
		"compile","hasattr","memoryview","round",
		"complex","hash","min","set","apply",
		"delattr","help","next","setattr","buffer",
		"dict","hex","object","slice","coerce",
		"dir","id","oct","sorted","intern"
		}
		for k,v in pairs(good_funcs) do
		good_func_string = good_func_string .. "safe_list[\""..v.."\"]="..v..";"    
		end
		local f =io.open("derp.txt","w")
		f:write(good_func_string)
		f:close()--]]
	
	local rf = io.popen([[python -c '
import math;
import cmath;
import random;
execdict = {"__builtins__": None,"math": math,"cmath": cmath,"random": random};
print("]]..usr.nick..[[:");
safe_list = {};
]]..good_func_string..[[
exec(("]]..sdump..[[").decode("hex"),execdict,safe_list);exit()' 2>&1]])

	socket.sleep(1)

	local kill = io.popen("pgrep -f 'python -c'"):read("*a")
	if kill~="" then os.execute("pkill -f 'python -c'") end
	local r = rf:read("*a")
	if r=="" and kill and kill~="" then print(kill) r=usr.nick..": Killed" end
	if r then return r:gsub("[\r\n\t]"," ") end
end
add_cmd(python,"py",0,"Runs sandy python code, '/py <code>'",true)

--BRAINFUCK
local function BF(usr,chan,msg)
	if not msg then return false,"No message" end
	local sdump=""
	luan = luan or "lua"
	--byte the string so you can't escape
	for char in msg:gmatch(".") do sdump = sdump .. "\\"..char:byte() end
	
	local input = irc.channels[chan].users[usr.nick].lastSaid or ""
	local inputdump=""
	for char in input:gmatch(".") do inputdump = inputdump .. "\\"..char:byte() end
	-----------
	local rf = io.popen(luan..[=[ -e 'dofile("sandybox.lua")
	io.write("]=]..usr.nick..[=[: ")
	local readS = 0
	local function readInput()
		readS = readS+1
		return ("]=]..inputdump..[=["):sub(readS,readS) or "\0"
	end
	local subst = {["+"]="v=(v+1)%256 ", ["-"]="v=(v-1)%256 ", [">"]="i=i+1 ", ["<"]="i=i-1 ",
		["."] = "w(v)", [","]="v=r()", ["["]="while v~=0 do ", ["]"]="end "}
	local env = setmetatable({ i=0, t=setmetatable({},{__index=function() return 0 end}),
	r=function() return readInput():byte() end, w=function(c) io.write(string.char(c)) end }, 
	{__index=function(t,k) return t.t[t.i] end, __newindex=function(t,k,v) t.t[t.i]=v end })
	load_code(("]=]..sdump..[=["):gsub("[^%+%-<>%.,%[%]]+",""):gsub(".", subst) , "brainfuck", "t", env)()' 2>&1]=])
			    
			    socket.sleep(1)
			    local kill = io.popen("pgrep -f '"..luan.." -e'"):read("*a")
			    if kill~="" then os.execute("pkill -f '"..luan.." -e'") end
			    local r = rf:read("*a")
			    if r=="" and kill and kill~="" then r="Killed" end
			    if r then return r:gsub("[\r\n\t]"," ") end
			    return r
end
add_cmd(BF,"BF",0,"Runs BF code, '/bf <code>'",false,{"bf"})

--HELP
local function help(usr,chan,msg)
	msg = msg or "help"
	if commands[msg] then
		if commands[msg].helptext then
			return msg ..": ".. commands[msg].helptext
		end
	end
	return "No help for "..msg.." found!"
end
add_cmd(help,"help",0,"Returns hopefully helpful information, '/help <cmd>'",true)

--UNHELP, no idea
local function unhelp(usr,chan,msg)
	msg = msg or "help"
	if commands[msg] then
		if commands[msg].helptext then
			return msg ..": ".. commands[msg].helptext
		end
	end
	return "No help for "..msg.." found!"
end
--add_cmd(unhelp,"unhelp",0,"Returns hopefully unhelpful information, '/help <cmd>'",true)

--TIMER
local function timer(usr,chan,msg,args)
	if tonumber(args[1]) and args[2] then
		local t={}
		for i=2,#args do
			table.insert(t,args[i])
		end
		local pstring = table.concat(t," ")
		addTimer(ircSendChatQ[chan][pstring],tonumber(args[1]),chan)
	else
		return usr.nick..": Bad timer"
	end
end
add_cmd(timer,"timer",0,"Time until a print is done, '/timer <time(seconds)> <text>'",true)


--BADWORDS
local function badWord(usr,chan,msg,args)
	if not args[2] then return "Usage: badword add/rem <word>" end
	if args[1] == "add" then
		return usr.nick .. ": " .. addBadWord(args[2])
	elseif args[1] == "rem" then
		return usr.nick .. ": " .. remBadWord(args[2])
	end
	return "Usage: badword add/rem <word>"
end
add_cmd(badWord,"badword",20,"Set or remove bad words, '/badword add/rem <word>'",true)

--MODE STUFF, probably own file

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

--BUG, report something to me in a file
local function rbug(usr,chan,msg,args)
	if not msg then error("No msg") end
	local f = io.open("bug.txt","a")
	f:write("["..os.date().."] ".. usr.host..": "..msg.."\n")
	f:close()
	return usr.nick..": Reported bug"
end
add_cmd(rbug,"bug",0,"Report something to cracker, '/bug <msg>'",true)

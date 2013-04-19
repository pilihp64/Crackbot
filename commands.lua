--List of files to load
dofile("tableSave.lua")
local modList = {"sandybox.lua","filters.lua","games.lua","ircmodes.lua"}
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

--Helper to return hostmask for a name
function getBestHost(chan,msg,long)
	local host = false
	local besthost = nil
	if msg:match("@") then host=true end
	if not host then
		for nick,v in pairs(irc.channels[chan].users) do
			if (string.lower(nick))==(string.lower(msg)) then
				if not long then besthost= "*!*@"..v.host
				else besthost= "!"..v.username.."@"..v.host
				end
			end
		end
	end
	return besthost or msg
end

--Load mods here so it can use some functions
for k,v in pairs(modList) do
	local s,r = pcall(dofile,v)
	if not s then print(r) end
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
local function dothis(usr,chan,msg) --fix DO and ME with filters
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

--CHMOD, set a user's permission level, is temporary, add to config for permanent.
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

--hostmask
local function getHost(usr,chan,msg,args)
	if not msg then return usr.nick..": "..usr.host end
	local host = getBestHost(chan,args[1])
	if host==args[1] then return usr.nick..": Invalid user or not online." end
	return usr.nick .. ": "..host:sub(5)
end
add_cmd(getHost,"hostmask",0,"The hostmask for a user, '/hostmask <name>'",false)

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
print("]]..usr.nick..[[:");
safe_list = {};
]]..good_func_string..[[
execdict = {"__builtins__": safe_list,"math": math,"cmath": cmath,"random": random};
exec("def foo(): "+("]]..sdump..[[").decode("hex")+";\nresp=foo();\nif resp!=None: print(resp);",execdict);exit()' 2>&1]])

	socket.sleep(1)

	local kill = io.popen("pgrep -f 'python -c'"):read("*a")
	if kill~="" then os.execute("pkill -f 'python -c'") end
	local r = rf:read("*a")
	if r=="" and kill and kill~="" then r=usr.nick..": Killed" end
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
	local num = tonumber(args[1])
	if num and num==num and num<36000 and args[2] then
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

--BUG, report something to me in a file
local function rbug(usr,chan,msg,args)
	if not msg then error("No msg") end
	local f = io.open("bug.txt","a")
	f:write("["..os.date().."] ".. usr.host..": "..msg.."\n")
	f:close()
	return usr.nick..": Reported bug"
end
add_cmd(rbug,"bug",0,"Report something to cracker, '/bug <msg>'",true)

--Contains data needed to create command
aliasList = aliasList or table.load("AliasList.txt") or {}
--Return a helper function to insert new args correctly
local aliasDepth = 0
local function mkAliasFunc(t,aArgs)
	return function(nusr,nchan,nmsg,nargs)
			--Put new args after alias args
			if aliasDepth>10 then aliasDepth=0 error("Alias depth limit reached!") end
			local sendArgs = {}
			for i=1,#aArgs do table.insert(sendArgs,aArgs[i]) end
			for i=1,#nargs do table.insert(sendArgs,nargs[i]) end
			local sendMsg = t.aMsg
			if nmsg and nmsg~="" then
				if t.aMsg~="" then sendMsg=sendMsg.." "..nmsg
				else sendMsg=nmsg
				end
			end
			if not commands[t.cmd] then aliasDepth=0 error("Alias destination for "..t.name.." doesn't exist!") end
			aliasDepth = aliasDepth+1
			local ret = {commands[t.cmd].f(nusr,nchan,sendMsg,sendArgs)}
			aliasDepth = 0
			return unpack(ret)
		end
end
--Insert alias commands on reload
for k,v in pairs(aliasList) do
	local aArgs = getArgs(v.aMsg)
	if not commands[v.name] then
		add_cmd( mkAliasFunc(v,aArgs) ,v.name,v.level,"Alias for "..v.cmd.." "..v.aMsg,false)
	else
		--name already exists, hide alias
		aliasList[k]=nil
	end
end
--ALIAS, add an alias for a command
local function alias(usr,chan,msg,args)
	if not msg or not args[1] then return usr.nick..": '/alias add/rem/list <name> <cmd> [<args>]'" end
	if args[1]=="add" then
		if not args[2] then return usr.nick..": '/alias add <name> <cmd> [<args>]'" end
		if not args[3] then return usr.nick..": No cmd specified! '/alias add <name> <cmd> [<args>]'" end
		local name,cmd,aArgs = args[2],args[3],{}
		if not commands[cmd] then return usr.nick..": "..cmd.." doesn't exist!" end
		if commands[name] then return usr.nick..": "..name.." already exists!" end
		if permFullHost(usr.fullhost) < commands[cmd].level then return usr.nick..": You can't alias that!" end
		for i=4,#args do table.insert(aArgs,args[i]) end
		local aMsg = table.concat(aArgs," ")
		local alis = {name=name,cmd=cmd,aMsg=aMsg,level=commands[cmd].level}
		add_cmd( mkAliasFunc(alis,aArgs) ,name,alis.level,"Alias for "..cmd.." "..aMsg,false)

		table.insert(aliasList,alis)
		table.save(aliasList,"AliasList.txt")
		return usr.nick..": Added alias"
	elseif args[1]=="rem" or args[1]=="remove" then
		if not args[2] then return usr.nick..": '/alias rem <name>'" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				if v.lock then return usr.nick..": Alias is locked!" end
				aliasList[k]=nil
				commands[name]=nil
				table.save(aliasList,"AliasList.txt")
				return usr.nick..": Removed alias"
			end
		end
		return usr.nick..": Alias not found"
	elseif args[1]=="list" then
		local t={}
		for k,v in pairs(aliasList) do
			table.insert(t,v.name)
		end
		return usr.nick..": Aliases: "..table.concat(t,", ")
	elseif args[1]=="lock" then
		--Lock an alias so other users can't remove it
		if not args[2] then return usr.nick..": '/alias lock <name>'" end
		if permFullHost(usr.fullhost) < 50 then return usr.nick..": No permission to lock!" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = "" --bool doesn't save right now
				table.save(aliasList,"AliasList.txt")
				return usr.nick..": Locked alias"
			end
		end
		return usr.nick..": Alias not found"
	elseif args[1]=="unlock" then
		if not args[2] then return usr.nick..": '/alias unlock <name>'" end
		if permFullHost(usr.fullhost) < 50 then return usr.nick..": No permission to unlock!" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = nil
				table.save(aliasList,"AliasList.txt")
				return usr.nick..": Unlocked alias"
			end
		end
		return usr.nick..": Alias not found"
	end
end
add_cmd(alias,"alias",0,"Add another name to execute a command, '/alias add/rem/list <newName> <cmd> [<args>]'.",true)

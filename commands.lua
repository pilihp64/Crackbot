--List of files to load
dofile("tableSave.lua")
local modList = {"sandboxes.lua","filters.lua","games.lua","ircmodes.lua","alias.lua"}
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

--LUA full acess
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

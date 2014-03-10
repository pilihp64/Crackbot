local http = require("socket.http")

local function loadNotes()
	local t = table.load("PWCNotes.txt") or {}
	setmetatable(t,{__index=function(t,k) t[k]={notes={}} return t[k] end})
	return t
end
notes = notes or loadNotes()

local PWClist = {}
local function PWChook(f, name, lvl, help, shown, aliases)
	PWClist[name] = {name=name,level=lvl,show=shown}
	add_cmd(f, name, lvl, help, false, aliases)
end
--[[ServerIP: 74.208.15.252
ServerPort: 15000
MapName: RTR-Rocks-v05ed
GameMode: UT04Trial_GameInfo
LastUpdate: 2014-01-01 22:31:47
ServerName: PWC Trials]]
local infoName = {[0]="ip",[1]="port",[2]="map",[3]="game",[4]="update",[5]="server"}
function currentMap()
	local t = {}
	local r,c,h = http.request("http://pwc-gaming.com/webbtimes/bot/lpninfo.php")
	if not r or c~=200 then print("LPN INFO FAILED") return end
	local count = 0
	for line in r:gmatch(".-: (.-)\n") do
		t[infoName[count]] = line
		count = count+1
	end
	return t
end
function currentMapTemp()
	local t = {}
	local r,c,h = http.request("http://pwc-gaming.com/webbtimes/bot/lpninfo.php")
	if not r or c~=200 then print("LPN INFO FAILED") return end
	local count = 0
	for line in r:gmatch(".-: ([^\n]+)") do
		t[infoName[count]] = line
		count = count+1
	end
	return t
end

local lastBotJoin,didNotify = os.time(),false
local function pwcUpdate()
	if not didNotify and (os.time()-lastBotJoin) > 90 then
		didNotify=true
		ircSendChatQ("##pwc","I am listening for commands, type '!utlist' for a list of trial related commands!")
		local t = currentMap()
		if t then
			if #notes[t.map].notes >0 then
				ircSendChatQ("##pwc","This map has stored notes, type '!notes' to read them.")
			end
			for k,v in pairs(notes) do
				if #v.notes==0 then notes[k]=nil end
			end
		end
		
	end
end
remUpdate("PWC")
addUpdate(pwcUpdate,5,"cracker64","PWC")

local function getRec()
	local r,c,h = http.request("http://pwc-gaming.com/webbtimes/bot/2013time.php")
	if not r or c~=200 then return {c} end
	local t = {}
	r = r:gsub("(.-)%+%+%+",function(str)
		str = str:gsub("\027....","")
		table.insert(t,str)
		return ""
	end)
	if r~="" then --Leftover from +++ split
		if r=="Error Finding the Map ID" then r="This map has no 2013 record!" end
		r = r:gsub("\027....","")
		table.insert(t,r)
	end
	return t
end

local recName = {[0]="name",[1]="current",[2]="last",[3]="twelve",[4]="elite",[5]="player"}
records = {}
setmetatable(records,{__index=function(t,k) t[k]={name="???",current="???",last="???",twelve="???",elite="???",player="???"} return t[k] end})
local function buildRecs()
	local r,c,h = http.request("http://pwc-gaming.com/webbtimes/")
	if not r or c~=200 then return c end
	--<span title="Actual Time: 00:33:34.02 by PIF | [TT]{»KIWI«}"><font color="green">00:33:34.02</font></span>
	r = r:gsub([[<span title="Actual Time: (.-) by .-">.-</span>]],"%1")
	r = r:gsub("<head>.-<%/head>",""):gsub("<.->",""):gsub("\n*%s*(\n)","%1")
	local count,maps = 0,0
	for line in r:gmatch("\n?%s*(.-)\n") do
		if (not line:find("%s") or count%6==5) and (count%6~=0 or line:find("%-")) then
			records[maps][recName[count%6]] = line
			if count%6 == 5 then
				maps = maps+1
			end
			count = count+1
		end
	end
	return "Updated recs!"
end
buildRecs() --make recs!



local function utList(usr,chan,msg,args)
	local t,cmdcount={},0
	for k,v in pairs(PWClist) do
		if v.show then
			cmdcount=cmdcount+1
			t[cmdcount]=k
		end
	end
	t[cmdcount+1]="help"
	table.sort(t,function(x,y)return x<y end)
	return "UTCommands: " .. table.concat(t,", ")
end
add_cmd(utList,"utlist",0,"List UT2k4 trial related commands, '/utlist' For help on specific commands, use '/help <cmd>'",false)

local function setNote(usr,chan,msg,args)
	if msg == "" then return "No text!" end
	local t = currentMap()
	if t then
		table.insert(notes[t.map].notes,{msg=msg,user=usr.nick})
		table.save(notes,"PWCNotes.txt")
		return "Added note to "..t.map.." !"
	end
	return "Could not add note"
end
PWChook(setNote,"addnote",0,"Add a note for current map, '/addnote <text>'",true)

local function remNote(usr,chan,msg,args)
	local id = tonumber(args[1])
	if not id then return "Invalid ID" end
	local t = currentMap()
	if t and notes[t.map].notes[id] then
		table.remove(notes[t.map].notes,id)
		table.save(notes,"PWCNotes.txt")
		return "Removed note"
	end
	return "Could not remove that note!"
end
PWChook(remNote,"remnote",10,"Remove a note for current map, '/remnote <id>'",true)

local function readNote(usr,chan,msg,args)
	local t = currentMap()
	if t then
		--ircSendChatQ(chan,"Notes for "..t.map)
		if #notes[t.map].notes==0 then return "No notes for this map!" end
		for k,v in pairs(notes[t.map].notes) do
			ircSendChatQ(chan,k..": "..v.msg.." ("..v.user..")")
		end
		return nil
	end
	return "Could not read notes!"
end
PWChook(readNote,"notes",0,"Reads notes for current map, '/notes'",true)

local function updateRec(usr,chan,msg,args)
	return buildRecs()
end
PWChook(updateRec,"recupdate",0,"Update bots record database, '/recupdate'",true)

local function record(usr,chan,msg,args)
	local rt = getRec()
	for k,v in pairs(rt) do ircSendChatQ(chan,v) end
	return nil
end
PWChook(record,"rec",0,"Get info of the specified map, '/rec <mapName>'",true,{"2013"})

local function findRec(usr,chan,msg,args)
	if not args[1] then return "Need a map! '/map <mapname>'"end
	local t={}
	for k,v in pairs(records) do
		if (v.name:lower()):find(args[1]:lower():gsub("([%[%]%%%$%^%-%+%*%(%)%.])","%%%1")) then
			table.insert(t,v)
		end
	end
	if #t==1 then
		ircSendChatQ(chan,t[1].name.." || Best Time in 2014 is "..t[1].current.." ||")
		ircSendChatQ(chan,"|| 2013 time is "..t[1].last.." ||")
		ircSendChatQ(chan,"|| 2012 time is "..t[1].twelve.." ||")
		ircSendChatQ(chan,"|| Elite time is "..t[1].elite.." ||")
		return "|| Overall best(adj.) is by "..t[1].player.." ||",true
	elseif #t>25 then
		return #t.." results! Be more specific!"
	elseif #t>1 then
		local rstring, count = #t.." results:", 0
		for k,v in pairs(t) do
			count = count+1
			rstring = rstring .. " | ".. v.name
			if count==3 then
				ircSendChatQ(chan,rstring)
				rstring,count = "",0
			end
		end
		if rstring~="" then ircSendChatQ(chan,rstring) end
	else
		return "No results found!"
	end
end
PWChook(findRec,"map",0,"Search for map records, '/map <mapname>'",true)

local function maptime(usr,chan,msg,args)
	if not usr.ingame then return "Must be in game!" end
	
	return "Round timer is "..usr.gametime
end
PWChook(maptime,"maptime",0,"Shows how long the round has been, '/maptime'",true)

--JOIN HOOK
local function pwcJoin(usr,chan)
	if chan=="##pwc" then
		if usr.nick:find("TrialReporter") then
			print("BOT JOINED")
			lastBotJoin=os.time()
			didNotify=false
		end
	end
end
pcall(irc.unhook,irc,"OnJoin","pwcjoin")
irc:hook("OnJoin","pwcjoin",pwcJoin)
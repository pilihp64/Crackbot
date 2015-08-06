module("alias", package.seeall)

--Contains data needed to create command
aliasList = alias.aliasList or (table.load("plugins/AliasList.txt") or {})
local macroCMDs = {
	["me"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return nusr.nick
	end,
	["chan"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return nchan
	end,
	["host(m?a?s?k?)"] = function(nusr,nchan,nmsg,nargs,usedArgs,right)
		if right then
			if right=="mask" then
				return nusr.fullhost
			end
		end
		return nusr.host..right
	end,
	["cash"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return games.gameUsers[nusr.host].cash
	end,
	["price%[(%w-)%]"] = function(nusr,nchan,nmsg,nargs,usedArgs,item)
		return (games.storeInventory[item] or {cost=0}).cost
	end,
	["ping"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return "pong"
	end,
	["inv%[(%w-)%]"] = function(nusr,nchan,nmsg,nargs,usedArgs,item)
		return tostring((games.gameUsers[nusr.host].inventory[item] or {amount=0}).amount)
	end,
	["USER"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return "crackbot"
	end,
	["PWD"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return "/home/crackbot/bot"
	end,
}
--Return a helper function to insert new args correctly
local aliasDepth = 0
local function mkAliasFunc(t,aArgs)
	local tempPerm={}
	return function(nusr,nchan,nmsg,nargs)
			--TODO: FIX DEPTH CHECK
			if aliasDepth>10 then aliasDepth=0 error("Alias depth limit reached!") end
			if not commands[t.cmd] then aliasDepth=0 error("Alias destination for "..t.name.." doesn't exist!") end
			--A few blacklists
			if t.cmd == "use" or t.cmd == "timer" or t.cmd == "bug" then
				aliasDepth=0 error("You can't alias to that")
			end
			--Replace for numbered macros first
			local usedArgs = {}
			nmsg = t.aMsg:gsub("%$(%d)",function(repl)
				local repN = tonumber(repl)
				if repN and repN~=0 then
					usedArgs[repN] = true
					return nargs[repN] or ""
				end
			end)
			--Replace $* here because
			nmsg = nmsg:gsub("%$%*",function()
				local t = {}
				for k,v in pairs(nargs) do
					if not usedArgs[k] then
						table.insert(t,v)
					end
				end
				return table.concat(t," ")
			end)
			--An alias of 'alias add $*' should skip macro evaluate to properly insert macros
			if not (t.cmd=="alias" and aArgs[1]=="add")then
				--Replace custom macros now
				for k,v in pairs(macroCMDs) do
					nmsg = nmsg:gsub("%$"..k,v[nusr][nchan][nmsg][nargs][usedArgs])
				end
			end
			aliasDepth = aliasDepth+1
			--TODO: Fix coroutine to actually make nested alias loops not block
			--coroutine.yield(false,0)
			if getPerms(nusr.host) < t.level then
				return "No permission for "..t.name --this is never displayed anyway
			end
			--print("INALIAS",t.usrlvl or "0",getPerms(nusr.host),t.suid or "0",tostring(changed),t.cmd)
			local f = makeCMD(t.cmd,nusr,nchan,nmsg,true)
			if not f then return "" end
			local ret = {f()}
			aliasDepth = 0
			return unpack(ret)
		end
end
--Insert alias commands on reload
for k,v in pairs(aliasList) do
	local aArgs = getArgs(v.aMsg)
	if not commands[v.name] then
		add_cmd( mkAliasFunc(v,aArgs) ,v.name,v.level,"("..(v.suid and "set" or "").."lvl="..(v.usrlvl or 0)..",req="..v.level..") Alias for "..v.cmd.." "..v.aMsg,false)
	else
		--name already exists, hide alias
		--aliasList[k]=nil
	end
end
--ALIAS, add an alias for a command
local function alias(usr,chan,msg,args)
	args = getArgsOld(msg)
	if not msg or not args[1] then return "Usage: '/alias add/rem/list/lock/unlock/hide/unhide/suid/restrict <name> <cmd> [<args>]'" end
	if args[1]=="add" then
		if not args[2] then return "Usage: '/alias add <name> <cmd> [<args>]'" end
		if not args[3] then return "No cmd specified! '/alias add <name> <cmd> [<args>]'" end
		local name,cmd,aArgs = args[2]:lower(),args[3]:lower(),{}
		if not commands[cmd] then return cmd.." doesn't exist!" end
		if cmd == "timer" or cmd == "use" or cmd == "bug" then
			return "You can't alias that!"
		end
		if allCommands[name] then return name.." already exists!" end
		local userlevel = getPerms(usr.host)
		if userlevel < commands[cmd].level then return "You can't alias that!" else userlevel = commands[cmd].level end
		if name:find("[%*:][%c]?%d?%d?,?%d?%d?$") then return "Bad alias name!" end
		if name:find("[\128-\255]") or name:find("[\1-\20]") then return "Ascii aliases only!" end
		if #name > 30 then return "Alias name too long!" end
		if #args > 60 then return "Alias too complex!" end
		for i=4,#args do table.insert(aArgs,args[i]) end
		local aMsg = table.concat(aArgs," ")
		if #aMsg > 550 then return "Alias too complex!" end
		local alis = {name=name,cmd=cmd,aMsg=aMsg,level=commands[cmd].level,usrlvl = userlevel,suid=false,shown=true}
		add_cmd( mkAliasFunc(alis,aArgs) ,name,alis.level,"(lvl="..userlevel..",req="..commands[cmd].level..") Alias for "..cmd.." "..aMsg,false)
		table.insert(aliasList,alis)
		table.save(aliasList,"plugins/AliasList.txt")
		if config.logchannel then
			ircSendChatQ(config.logchannel, usr.nick.."!"..usr.username.."@"..usr.host.." added alias "..name.." to "..cmd.." "..aMsg)
		end
		return "Added alias"
	elseif args[1]=="rem" or args[1]=="remove" then
		if not args[2] then return "Usage: '/alias rem <name>'" end
		local name = args[2]:lower()
		for k,v in pairs(aliasList) do
			if name==v.name then
				if v.lock then return "Alias is locked!" end
				aliasList[k]=nil
				commands[name]=nil
				allCommands[name]=nil
				table.save(aliasList,"plugins/AliasList.txt")
				return "Removed alias"
			end
		end
		return "Alias not found"
	elseif args[1]=="list" then
		local t={}
		local locked,unlocked,hidden = true,true,false
		if args[2] then
			if args[2] == "locked" then unlocked = false
			elseif args[2] == "unlocked" then locked = false
			elseif args[2] == "hidden" and getPerms(usr.host) >= 100 then hidden = true
			end
		end
		for k,v in pairs(aliasList) do
			if v.shown == nil then v.shown = true end
			if v.shown ~= hidden then
				if v.lock and locked then
					table.insert(t,v.name.."\15"..(unlocked and v.lock or ""))
				elseif not v.lock and unlocked then
					table.insert(t,v.name.."\15")
				end
			end
		end
		table.sort(t)
		return "Aliases: "..table.concat(t,", ")
	elseif args[1]=="lock" then
		--Lock an alias so other users can't remove it
		if not args[2] then return "'/alias lock <name>'" end
		if getPerms(usr.host) < 100 then return "No permission to lock!" end
		local name = args[2]:lower()
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = "*" --bool doesn't save right now
				table.save(aliasList,"plugins/AliasList.txt")
				return "Locked alias"
			end
		end
		return "Alias not found"
	elseif args[1]=="unlock" then
		if not args[2] then return "'/alias unlock <name>'" end
		if getPerms(usr.host) < 100 then return "No permission to unlock!" end
		local name = args[2]:lower()
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = nil
				table.save(aliasList,"plugins/AliasList.txt")
				return "Unlocked alias"
			end
		end
		return "Alias not found"
	elseif args[1]=="suid" then
		if not args[2] then return "'/alias suid <name> [level]' No level will disable" end
		if getPerms(usr.host) < 101 then return "No permission to suid!" end
		local name, level = args[2]:lower(),tonumber(args[3])
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.usrlvl,v.suid = (level or v.usrlvl),(level and 1 or nil)
				table.save(aliasList,"plugins/AliasList.txt")
				commands[name]=nil
				allCommands[name]=nil
				add_cmd( mkAliasFunc(v,getArgs(v.aMsg)) ,v.name,v.level,"("..(v.suid and "set" or "").."lvl="..v.usrlvl..",req="..v.level..") Alias for "..v.cmd.." "..v.aMsg,false)
				return "Set suid to "..level
			end
		end
		return "Alias not found"
	elseif args[1]=="restrict" then
		if not args[3] then return "'/alias restrict <name> <level>'" end
		if getPerms(usr.host) < 101 then return "No permission to restrict!" end
		local name, level = args[2]:lower(),(tonumber(args[3]) or 101)
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.level = level
				commands[name].level = level
				table.save(aliasList,"plugins/AliasList.txt")
				commands[name]=nil
				allCommands[name]=nil
				add_cmd( mkAliasFunc(v,getArgs(v.aMsg)) ,v.name,v.level,"("..(v.suid and "set" or "").."lvl="..v.usrlvl..",req="..v.level..") Alias for "..v.cmd.." "..v.aMsg,false)
				return "Set restrict to "..level
			end
		end
		return "Alias not found"
	elseif args[1]=="hide" or args[1]=="unhide" then
		if not args[2] then return "'/alias "..args[1].." <name>'" end
		if getPerms(usr.host) < 100 then return "No permission to "..args[1].."!" end
		local shown = args[1] == "unhide"
		local name = args[2]:lower()
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.shown = shown
				table.save(aliasList,"plugins/AliasList.txt")
				commands[name]=nil
				allCommands[name]=nil
				add_cmd(mkAliasFunc(v,getArgs(v.aMsg)) ,v.name,v.level,"("..(v.suid and "set" or "").."lvl="..v.usrlvl..",req="..v.level..") Alias for "..v.cmd.." "..v.aMsg,false)
				return name.." is now "..(shown and "unhidden" or "hidden")
			end
		end
		return "Alias not found"
	end
end
add_cmd(alias,"alias",0,"Add another name to execute a command, '/alias add/rem/list/lock/unlock/suid/restrict <newName> <cmd> [<args>]'.",true)

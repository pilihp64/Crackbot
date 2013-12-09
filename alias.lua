--Contains data needed to create command
aliasList = table.load("AliasList.txt") or {}
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
		return gameUsers[nusr.host].cash
	end,
	["ping"] = function(nusr,nchan,nmsg,nargs,usedArgs)
		return "pong"
	end,
	["inv%[(%w-)%]"] = function(nusr,nchan,nmsg,nargs,usedArgs,item)
		return tostring((gameUsers[nusr.host].inventory[item] or {amount=0}).amount)
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
	return function(nusr,nchan,nmsg,nargs)
			--TODO: FIX DEPTH CHECK
			if aliasDepth>10 then aliasDepth=0 error("Alias depth limit reached!") end
			if not commands[t.cmd] then aliasDepth=0 error("Alias destination for "..t.name.." doesn't exist!") end
			--A few blacklists
			if t.cmd == "use" or t.cmd == "timer" or t.cmd == "bug" then
				error("You can't alias to that")
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
			end,1)
			--An alias of 'alias add $*' should skip macro evaluate to properly insert macros
			if not (t.cmd=="alias" and aArgs[1]=="add")then
				--Replace custom macros now
				for k,v in pairs(macroCMDs) do
					nmsg = nmsg:gsub("%$"..k,v[nusr][nchan][nmsg][nargs][usedArgs])
				end
			end
			aliasDepth = aliasDepth+1
			--TODO: Fix coroutine to actually make nested alias loops not block
			coroutine.yield(false,0)
			
			local f = makeCMD(t.cmd,nusr,nchan,nmsg,getArgs(nmsg))
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
		add_cmd( mkAliasFunc(v,aArgs) ,v.name,v.level,"Alias for "..v.cmd.." "..v.aMsg,false)
	else
		--name already exists, hide alias
		aliasList[k]=nil
	end
end
--ALIAS, add an alias for a command
local function alias(usr,chan,msg,args)
	if not msg or not args[1] then return "Usage: '/alias add/rem/list <name> <cmd> [<args>]'" end
	if args[1]=="add" then
		if not args[2] then return "Usage: '/alias add <name> <cmd> [<args>]'" end
		if not args[3] then return "No cmd specified! '/alias add <name> <cmd> [<args>]'" end
		local name,cmd,aArgs = args[2],args[3],{}
		if not commands[cmd] then return cmd.." doesn't exist!" end
		if cmd == "timer" or cmd == "use" or cmd == "bug" then
			return "Error: You can't alias to that"
		end
		if allCommands[name] then return name.." already exists!" end
		if getPerms(usr.host) < commands[cmd].level then return "You can't alias that!" end
		if name:find("[%*:][%c]?%d?%d?,?%d?%d?$") then return "Bad alias name!" end
		if name:find("[\128-\255]") then return "Ascii aliases only" end
		if #args > 60 then return "Alias too complex!" end
		for i=4,#args do table.insert(aArgs,args[i]) end
		local aMsg = table.concat(aArgs," ")
		if #aMsg > 550 then return "Alias too complex!" end
		local alis = {name=name,cmd=cmd,aMsg=aMsg,level=commands[cmd].level}
		add_cmd( mkAliasFunc(alis,aArgs) ,name,alis.level,"Alias for "..cmd.." "..aMsg,false)

		table.insert(aliasList,alis)
		table.save(aliasList,"AliasList.txt")
		if config.logchannel then
			ircSendChatQ(config.logchannel, usr.nick.."!"..usr.username.."@"..usr.host.." added alias "..name.." to "..cmd.." "..aMsg)
		end
		return "Added alias"
	elseif args[1]=="rem" or args[1]=="remove" then
		if not args[2] then return "Usage: '/alias rem <name>'" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				if v.lock then return "Alias is locked!" end
				aliasList[k]=nil
				commands[name]=nil
				allCommands[name]=nil
				table.save(aliasList,"AliasList.txt")
				return "Removed alias"
			end
		end
		return "Alias not found"
	elseif args[1]=="list" then
		local t={}
		for k,v in pairs(aliasList) do
			table.insert(t,v.name.."\15"..(v.lock or ""))
		end
		return "Aliases: "..table.concat(t,", ")
	elseif args[1]=="lock" then
		--Lock an alias so other users can't remove it
		if not args[2] then return "'/alias lock <name>'" end
		if getPerms(usr.host) < 101 then return "No permission to lock!" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = "*" --bool doesn't save right now
				table.save(aliasList,"AliasList.txt")
				return "Locked alias"
			end
		end
		return "Alias not found"
	elseif args[1]=="unlock" then
		if not args[2] then return "'/alias unlock <name>'" end
		if getPerms(usr.host) < 101 then return "No permission to unlock!" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = nil
				table.save(aliasList,"AliasList.txt")
				return "Unlocked alias"
			end
		end
		return "Alias not found"
	end
end
add_cmd(alias,"alias",0,"Add another name to execute a command, '/alias add/rem/list <newName> <cmd> [<args>]'.",true)

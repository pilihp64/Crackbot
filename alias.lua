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
		if name:find("%*[%c]?%d?%d?,?%d?%d?$") then return usr.nick..": Bad alias name!" end
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
			table.insert(t,v.name.."\15"..(v.lock or ""))
		end
		return usr.nick..": Aliases: "..table.concat(t,", ")
	elseif args[1]=="lock" then
		--Lock an alias so other users can't remove it
		if not args[2] then return usr.nick..": '/alias lock <name>'" end
		if permFullHost(usr.fullhost) < 50 then return usr.nick..": No permission to lock!" end
		local name = args[2]
		for k,v in pairs(aliasList) do
			if name==v.name then
				v.lock = "*" --bool doesn't save right now
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

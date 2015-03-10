users = dofile('users.lua')
local prefix = '.'

--Simple commands for now
local cheesy = {
	['moo'] =  function(s,usr,chan,msg,args)
		return 'Moo0o'
	end,
	['moo2'] =  function(s,usr,chan,msg,args)
		return 'Moo0o'
	end,
	['reload'] = function(s,usr,chan,msg,args)
		if usr.lvl < 101 then return "You are not worthy to use this." end
		local rmsg = ''
		msg = msg or 'main'
		local st,r = pcall(dofile,msg ..".lua")
		if st then
			rmsg = rmsg .. "Loaded: "..msg.." "
		else
			rmsg = rmsg .. r .. " "
		end
		return rmsg
	end,
	['lua'] = function(s,usr,chan,msg,args)
	if usr.lvl < 101 then return "You are too weak to use this." end
	local e,err = loadstring(msg)
	if e then
		debug.sethook(infhook,"l")
		local st,r = pcall(e)
		debug.sethook()
		stepcount=0
		if st then
			local str = tostring(r) 
			return str:gsub("[\r\n]"," ")
		else
			return "ERROR: " .. r
		end
		return
	end
	return "ERROR: " .. err
	end,
	['test'] = function(s,usr,chan,msg,args)
		return "You are level " .. usr.lvl
	end,
}
addConfig("default",nil,"moo",false)

local function chatHook(conn)
	local server = conn.config.serv.host
	return function(usr,chan,msg)
		if chan==conn.nick then chan=usr.nick end
		local pre,cmd,rest = msg:match("^(".. getConfig(server,chan,"cmdPrefix") ..")([^%s]*)%s?(.*)$")
		if cheesy[cmd] then
			if rest=="" then rest=nil end
			usr.lvl = users.findUser(server,chan,usr).lvl
			local s,r,e = pcall(cheesy[cmd],server,usr,chan,rest,getArgs(rest))
			if not s then
				conn:queue(ircMsg.privmsg(chan,e))
			end
			if r then
				conn:queue(ircMsg.privmsg(chan,r))
			end
		end
		--print(conn,usr.host,chan,msg)
	end
end
local function joinHook(conn)
	local server = conn.config.serv.host
	return function(usr,chan)
		if usr.nick == conn.nick then
			joinChannel(server,chan)
		end
		print('JOIN ',usr.nick,chan)
	end
end


local function initHooks(c)
	pcall(c.unhook,c,'OnChat','hook1')
	c:hook('OnChat','hook1',chatHook(c))
	pcall(c.unhook,c,'OnJoin','configJoin')
	c:hook('OnJoin','configJoin',joinHook(c))
end
for k,v in pairs(conns) do
	initHooks(v)
end
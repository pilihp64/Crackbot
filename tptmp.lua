--LUA sandbox
local TPTMPsock
local TPTconnected = false
local function connectTPT()
	if TPTconnected then return end
	TPTMPsock = socket.tcp()
	local s,r = TPTMPsock:connect("localhost",34404)
	if s then
		TPTMPsock:settimeout(0.3)
		TPTconnected = true
		print("Connected TPTMP!")
	end
end

local function sendTPT(msg)
	if not TPTconnected then connectTPT() end
	
	local s,r = TPTMPsock:send(msg.."\n")
	if not s and r~="timeout" then
		TPTconnected=false
		return false
	end
	return true
end
local function recTPT()
	if not TPTconnected then return end
	local s,r = TPTMPsock:receive("*l")
	local more = TPTMPsock:receive("*l")
	if more then s=s..more end
	if not s and r~="timeout" then
		TPTconnected=false
		return false
	end
	return s or ""
end

local function tptmp(usr,chan,msg,args,luan)
	local resp = ""
	if args[1]=="raw" then
	
	elseif args[1]=="online" then
		if (sendTPT("local t={} for i=0,255 do v=clients[i] if v then table.insert(t,'('..i..')'..v.nick) end end return table.concat(t,' ')")) then
			coroutine.yield(false,1)
			resp = recTPT()
		end
	elseif args[1]=="info" and args[2] then
		if (sendTPT("local t={} for i=0,255 do v=clients[i] if v and v.nick:find('"..args[2].."') then table.insert(t,v.nick..': id:'..i..' ip:'..v.host..' room:'..v.room) end end return table.concat(t,' | ')")) then
			coroutine.yield(false,1)
			resp = recTPT()
		end
	else
		if sendTPT(msg) then
			coroutine.yield(false,1)
			resp = recTPT()
		end
	end
	return resp
end
add_cmd(tptmp,"tptmp",101,"Various TPTMP functions, '/tpt [something] [code]'",false)
local pairs = pairs
local error = error
local tonumber = tonumber
local table = table

module "irc"

handlers = {}

handlers["PING"] = function(o, prefix, query)
	o:send("PONG :%s", query)
end

handlers["001"] = function(o, prefix, me)
	o.authed = true
	o.nick = me
end

handlers["PRIVMSG"] = function(o, prefix, channel, message)
	if message:sub(1,1) == "\001" then
		local space = message:find(" ") or #message
		o:invoke("OnCTCP", parsePrefix(prefix), channel, message:sub(2, space-1):upper(), message:sub(space+1,#message-1))
	else
		o:invoke("OnChat", parsePrefix(prefix), channel, message)
	end
end

handlers["NOTICE"] = function(o, prefix, channel, message)
	o:invoke("OnNotice", parsePrefix(prefix), channel, message)
end

handlers["JOIN"] = function(o, prefix, channel)
	local user = parsePrefix(prefix)
	if o.track_users then
		if user.nick == o.nick and not o.channels[channel] then
			o.channels[channel] = {users = {}}
		end
		o.channels[channel].users[user.nick] = user
	end

	o:invoke("OnJoin", user, channel)
end

handlers["PART"] = function(o, prefix, channel, reason)
	local user = parsePrefix(prefix)
	if o.track_users then
		if user.nick == o.nick then
			o.channels[channel] = nil
		else
			o.channels[channel].users[user.nick] = nil
		end
	end
	o:invoke("OnPart", user, channel, reason)
end

handlers["KICK"] = function(o, prefix, channel, kicked, reason)
	if o.track_users then
		local user = o.channels[channel].users[kicked]
		if user then
			if user.nick == o.nick then
				o.channels[channel] = nil
			elseif o.channels[channel] then
				o.channels[channel].users[user.nick] = nil
			end
		end
	end
	o:invoke("OnKick", channel, kicked, parsePrefix(prefix), reason)
end

handlers["QUIT"] = function(o, prefix, msg)
	local user = parsePrefix(prefix)
	if o.track_users then
		for channel, v in pairs(o.channels) do
			v.users[user.nick] = nil
		end
	end
	o:invoke("OnQuit", user, msg)
end

handlers["NICK"] = function(o, prefix, newnick)
	local user = parsePrefix(prefix)
	if o.track_users then
		for channel, v in pairs(o.channels) do
			local users = v.users
			local oldinfo = users[user.nick]
			if oldinfo then
				users[newnick] = oldinfo
				users[newnick].nick = newnick
				if users[newnick].fullhost then
					users[newnick].fullhost = users[newnick].nick.."!"..users[newnick].username.."@"..users[newnick].host
				end
				users[user.nick] = nil
				o:invoke("NickChange", user, newnick, channel)
			end
		end
	else
		o:invoke("NickChange", user, newnick)
	end
	if user.nick == o.nick then
		o.nick = newnick
	end
end

local numTries = 0
local function needNewNick(o, prefix, target, badnick)
	numTries = numTries + 1
	if numTries > 3 then
		o:invoke("OnDisconnect", "Cannot claim nickname, exiting", true)
		o:shutdown()
		error("Cannot claim nickname, exiting", 3)
	end
	if not o.needsRegain then
		o:send("NICK %s", o.nickGenerator(badnick))
		o.needsRegain = badnick -- mark ns regain to be used later on, once we are registered and identified
	else
		-- Keep attempting nick, we've already ghosted it so it should become available
		o:send("NICK %s", badnick)
	end
end

-- ERR_ERRONEUSNICKNAME (Misspelt but remains for historical reasons)
handlers["432"] = needNewNick

-- ERR_NICKNAMEINUSE
handlers["433"] = needNewNick

--WHO list
handlers["352"] = function(o, prefix, me, channel, name1, host, serv, name, access1 ,something, something2)
	if o.track_users then
		local user = {nick=name, host=host, username=name1, serv=serv, access=parseAccess(access1), fullhost=name.."!"..name1.."@"..host}
		--print(user.nick,user.host,user.ID,user.serv,user.access)
		if not o.channels[channel] then
			o.channels[channel] = {users = {}}
		end
		o.channels[channel].users[user.nick] = user
	end
end
--NAMES list
--disabled, better to always track everything instead of having it have an empty user with just an "access" field
--also it is broken a bit anyway
--[[handlers["353"] = function(o, prefix, me, chanType, channel, names)
	if o.track_users then
		o.channels[channel] = o.channels[channel] or {users = {}, type = chanType}

		local users = o.channels[channel].users
		for nick in names:gmatch("(%S+)") do
			local access, name = parseNick(nick)
			users[name] = {access = access}
		end
	end
end]]

--end of NAMES
handlers["366"] = function(o, prefix, me, channel, msg)
	if o.track_users then
		o:invoke("NameList", channel, msg)
	end
end

--no topic
handlers["331"] = function(o, prefix, me, channel)
	o:invoke("OnTopic", channel, nil)
end

--new topic
handlers["TOPIC"] = function(o, prefix, channel, topic)
	o:invoke("OnTopic", channel, topic)
end

handlers["332"] = function(o, prefix, me, channel, topic)
	o:invoke("OnTopic", channel, topic)
end

--topic creation info
handlers["333"] = function(o, prefix, me, channel, nick, time)
	o:invoke("OnTopicInfo", channel, nick, tonumber(time))
end

--RPL_UMODEIS
--To answer a query about a client's own mode, RPL_UMODEIS is sent back
handlers["221"] = function(o, prefix, user, modes)
	o:invoke("OnUserMode", modes)
end

--RPL_CHANNELMODEIS
--The result from common irc servers differs from that defined by the rfc
handlers["324"] = function(o, prefix, user, channel, modes)
	o:invoke("OnChannelMode", channel, modes)
end

handlers["MODE"] = function(o, prefix, target, modes, ...)
	if o.track_users and target ~= o.nick then
		local add = true
		local optList = {...}
		for c in modes:gmatch(".") do
			if     c == "+" then add = true
			elseif c == "-" then add = false
			elseif c == "o" then
				local user = table.remove(optList, 1)
				if user and o.channels[target].users[user] then o.channels[target].users[user].access.op = add end
			elseif c == "h" then
				local user = table.remove(optList, 1)
				if user then o.channels[target].users[user].access.halfop = add end
			elseif c == "v" then
				local user = table.remove(optList, 1)
				if user then o.channels[target].users[user].access.voice = add end
			elseif c == "b" or c == "q" then
				table.remove(optList, 1)
			end
		end
	end
	o:invoke("OnModeChange", parsePrefix(prefix), target, modes, ...)
end

handlers["ERROR"] = function(o, prefix, message)
	o:invoke("OnDisconnect", message, true)
	o:shutdown()
	error(message, 3)
end

handlers["CAP"] = function(o, prefix, star, capType, ...)
	local args = {...}
	local numArgs = #args
	if capType == "ACK" then
		for cap in args[numArgs]:gmatch("(%S+)") do
			if cap:sub(1,1) == "-" then
				o.caps[cap:sub(2)] = nil
			else
				o.caps[cap] = true
			end
			if cap == "sasl" then
				o:send("AUTHENTICATE PLAIN")
			end
		end
	elseif capType == "NAK" then
		for cap in args[numArgs]:gmatch("(%S+)") do
			o.caps[cap] = nil
			if cap == "sasl" then
				o:invoke("OnDisconnect", "SASL not supported, but was requested. Aborting.", true)
				o:shutdown()
				error("SASL not supported, but was requested. Aborting.", 3)
			end
		end
	end
end

handlers["AUTHENTICATE"] = function(o, prefix, plus)
	if plus == "+" then
		o:send("AUTHENTICATE " + o.saslToken)
		o.saslToken = nil
	end
end

handlers["903"] = function(o, ...)
	o:send("CAP END")
end

local function saslFailed(o, ...)
	o:invoke("OnDisconnect", "SASL connection failed. Aborting.", true)
	o:shutdown()
	error("SASL connection failed. Aborting.", 3)
end
handlers["902"] = saslFailed
handlers["904"] = saslFailed
handlers["905"] = saslFailed
handlers["906"] = saslFailed
handlers["908"] = saslFailed

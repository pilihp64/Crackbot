local pairs = pairs
local error = error
local tonumber = tonumber
local print=print

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
	o:invoke("OnChat", parsePrefix(prefix), channel, message)
end

handlers["NOTICE"] = function(o, prefix, channel, message)
	o:invoke("OnNotice", parsePrefix(prefix), channel, message)
end

handlers["JOIN"] = function(o, prefix, channel)
	local user = parsePrefix(prefix)
	if o.track_users then
		if user.nick == o.nick then
			o.channels[channel] = {users = {}}
		else
			o.channels[channel].users[user.nick] = user
		end
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
				users[user.nick] = nil
				o:invoke("NickChange", user, newnick, channel)
			end
		end
	else
		o:invoke("NickChange", user, newnick)
	end
end
--:zelazny.freenode.net 352 Crackbot ##powder-bots ~meow Powder/Developer/cracker64 barjavel.freenode.net cracker64 H+ :0 14Wafflessssss
--[[
verne.freenode.net	Crackbot	##powder-bots	~Meow	r75-110-131-16.nbrncmtc02.nwbrnc.ab.dh.suddenlink.net	verne.freenode.net	Crackbot	H	0 moo	nil
verne.freenode.net	Crackbot	##powder-bots	~Mitch|hat	unaffiliated/incredible	cameron.freenode.net	Mitch|hater	H	0 Why do you read this?	nil
verne.freenode.net	Crackbot	##powder-bots	Bott	cpe-24-170-62-161.stx.res.rr.com	niven.freenode.net	Bott	H	0 bubdan	nil
verne.freenode.net	Crackbot	##powder-bots	~mniip	178.219.36.155	hubbard.freenode.net	mniip	H	0 mniip	nil
verne.freenode.net	Crackbot	##powder-bots	~jacob	Powder/Developer/jacob1	morgan.freenode.net	jacob1[A]	H+	0 realname	nil
verne.freenode.net	Crackbot	##powder-bots	~ErEnUa	WiseOS/Bot/WiseBot	card.freenode.netErEnUa	H	0 ErEnUa Bot	nil
verne.freenode.net	Crackbot	##powder-bots	~NiaTeppel	WiseOS/Founder/NiaTeppelin	card.freenode.net	SuinDraw	H	0 realname	nil
verne.freenode.net	Crackbot	##powder-bots	~Incredibl	modemcable139.215-23-96.mc.videotron.ca	card.freenode.net	TheBombMaker	H	0 realname	nil
verne.freenode.net	Crackbot	##powder-bots	~meow	Powder/Developer/cracker64	barjavel.freenode.net	cracker64	H+	0 14Wafflessssss	nil
verne.freenode.net	Crackbot	##powder-bots	~WFeliks	81-237-248-234-no113.tbcn.telia.com	barjavel.freenode.net	WFeliks	H	0 WFeliks	nil
verne.freenode.net	Crackbot	##powder-bots	~xsBot	178.219.36.155	wolfe.freenode.net	xsBot	H@	0 xsBot	nil
verne.freenode.net	Crackbot	##powder-bots	~evil_dan2	unaffiliated/evil-dan2wik/x-0106201	wright.freenode.net	evil_dan2wik	H	0 dan2wik	nil
verne.freenode.net	Crackbot	##powder-bots	~huehue	WiseOS/PkgBuilder/RafaelRistovski	wright.freenode.net	[Ristovski]	H	0 HUEHUE	nil
verne.freenode.net	Crackbot	##powder-bots	~Tribot200	unaffiliated/triclops200/bot/tribot200	hubbard.freenode.net	Tribot200	H@	0 Tribot200	nil
verne.freenode.net	Crackbot	##powder-bots	Stewie	2a01:7e00::f03c:91ff:fedf:890f	cameron.freenode.net	StewieGriffinSub	H@	0 SG substitute, contact jacksonmj about problems	nil
verne.freenode.net	Crackbot	##powder-bots	jacksonmj	2a01:7e00::f03c:91ff:fedf:890f	lindbohm.freenode.net	jacksonmj-away	G+	0 jacksonmj	nil
verne.freenode.net	Crackbot	##powder-bots	ChanServ	services.	services.	ChanServ	H@	0 Channel Services	nil
verne.freenode.net	Crackbot	##powder-bots	~Triclops2	Powder/Developer/Triclops200	asimov.freenode.net	Triclops256|away	H+	0 Nonya	nil
]]
handlers["352"] = function(o, prefix, me, channel, name1, host, serv, name, access ,something, something2)
	if o.track_users then
	    local user = {nick=name, host=host, username=name1, serv=serv, access=parseWhoAccess(access)}
	    --print(user.nick,user.host,user.ID,user.serv,user.access)
	    for channel, v in pairs(o.channels) do
		if v.users[user.nick] then
		   v.users[user.nick] = user
		end
	    end
	end
end
--NAMES list
handlers["353"] = function(o, prefix, me, chanType, channel, names)
	if o.track_users then
		o.channels[channel] = o.channels[channel] or {users = {}, type = chanType}

		local users = o.channels[channel].users
		for nick in names:gmatch("(%S+)") do
			local access, name = parseNick(nick)
			users[name] = {type = access}
		end
	end
end

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

handlers["KICK"] = function(o, prefix, channel, kicked, reason)
	o:invoke("OnKick", channel, kicked, parsePrefix(prefix), reason)
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

handlers["MODE"] = function(o, prefix, target, modes)
	o:invoke("OnModeChange", parsePrefix(prefix), target, modes)
end

handlers["ERROR"] = function(o, prefix, message)
	o:invoke("OnDisconnect", message, true)
	o:shutdown()
	error(message, 3)
end

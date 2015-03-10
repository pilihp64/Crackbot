dofile('util.lua')
local findValue
local config = readTable("settings.lua")
config.default = config.default or {}
function reloadConfig()
	config = readTable("settings.lua")
end
function saveConfig()
	writeTable('settings.lua',config)
end

--Add a config option (not overwrite)
function addConfig(server,channel,k,v)
	if server == "default" and config.default[k] == nil then
		config.default[k] = v
	elseif config[server] and config[server][channel] and config[server][channel][k] == nil then
		config[server][channel][k] = v
	end
	saveConfig()
end
--Read a value from config
function getConfig(server,channel,...)
	assert(server~="default","Can't get bot default config directly, use a valid server")
	assert(config[server],"This server does not exist")
	local chan = config[server][channel]
	local t = {...}
	--Check local channel config 1st
	local result = findValue(chan,t)
	if result==nil then
		--Then check Server defaults 2nd
		result = findValue(config[server]["default"],t)
		if result==nil then
			--Then check bot defaults 3rd
			result = findValue(config["default"],t)
		end
	end
	--assert(result~=nil,"Config value "..table.concat(t,".") .." is missing from all default")
	return result
end
function setConfig(server,channel,...)
	assert(server~="default","Can't set bot default config from command")
	local keys = {...}
	local val, chan = table.remove(keys,#keys), config[server][channel or "default"]
	assert(chan,"Invalid channel!")
	for i,v in ipairs(keys) do
		chan[v] = chan[v] or {}
		if i==#keys then
			chan[v] = val
		else
			chan = chan[v]
		end
	end
	saveConfig()
end
function delConfig(server,channel,...)
	assert(server~="default","Can't set bot default config from command")
	local keys = {...}
	local chan = config[server][channel or "default"]
	assert(chan,"Invalid channel!")
	for i,v in ipairs(keys) do
		chan[v] = chan[v] or {}
		if i==#keys then
			chan[v] = nil
		else
			chan = chan[v]
		end
	end
	saveConfig()
end

--Global Config Start, should be moved inside settings file later
addConfig("default",nil,"nest",{enabled=true,start="<<",ending=">>"})
addConfig("default",nil,"autojoin",{"##jacob1"})
addConfig("default",nil,"cmdPrefix","%.")
--Global Config End

--Register a channel into settings
function joinChannel(server,channel)
	assert(config[server],"Invalid server")
	config[server][channel] = config[server][channel] or {}
	saveConfig()
end

local function server(address,port,timeout,password,secure)
	return {host=address,port=port,timeout=timeout,password=password,secure=secure}
end
local function user(nick,username,realname)
	return {nick=nick,username=username,realname=realname}
end
local function addNetwork(server,usr)
	if config[server.host] then
		--Server has been loaded before
		config[server.host].serv = server
		config[server.host].user = usr
	else
		--New server
		config[server.host] = {conn=nil,serv=server,user=usr,default={}}
		--tableMerge(config[server.host].default,config.default)
	end
end

--Find a setting value with multiple keys
findValue = function(t,keys)
	for i,v in ipairs(keys) do
		if not t or t[v]==nil then
			break --not found in table
		end
		if type(t[v])~="table" or i==#keys then
			return t[v]
		end
		t = t[v]
	end
end

addNetwork(server("irc.freenode.net"),user('Crackbot2','jacobot','moo2'))
--addNetwork(server("chat.freenode.net"),user('Crackbot3','jacobot','moo2'))
--addNetwork(server("irc.freenode.net"),user('Crackbot4','jacobot','moo2'))

return config
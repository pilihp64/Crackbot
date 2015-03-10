local u = {}
--Add in default user account
addConfig("default",nil,"users",{["default"]={lvl=0},["Powder/Developer/cracker64"]={lvl=101}})
local defaultUser = {lvl=0}
u.findUser = function(serv,chan,usr)
	local host = usr.host
	local res = getConfig(serv,chan,"users",host)
	return res or defaultUser
end
return u
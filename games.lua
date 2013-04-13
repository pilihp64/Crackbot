local users = {}
setmetatable(users,{__index=function(t,k) t[k]={cash=1000} return t[k] end})
local function loadUsers()
	local f = io.open("cashList.txt","r")
	if not f then return end
	for line in f:lines() do
		local host,hcash = line:match("^(.-) (%d-)$")
		users[host]= {cash=tonumber(hcash)}
	end
	f:close()
end
loadUsers()
local function saveUsers()
	local f = io.open("cashList.txt","w")
	for k,v in pairs(users) do
		f:write(k.." "..v.cash.."\n")
	end
	f:close()
end
--make a timer loop save users every minute, errors go to me
local function timedSave()
	saveUsers()
	addTimer(timedSave,60,"cracker64")
end
addTimer(timedSave,60,"cracker64")

--change cash, that resets if 0 or below
local function changeCash(usr,amt)
	users[usr.host].cash = users[usr.host].cash + amt
	if users[usr.host].cash <= 0 then
		users[usr.host].cash = 1000
		return " You went bankrupt, money reset"
	end
	return ""
end

--User cash
function myCash(usr)
	return usr.nick .. ": You have $"..users[usr.host].cash
end
--50% chance to win double
function coinToss(usr,bet)
	local mycash = users[usr.host].cash
	if bet > mycash then
		return usr.nick .. ": Not enough money!"
	end
	local res = math.random(2)
	if res==1 then
		--win
		changeCash(usr,bet)
		return usr.nick .. ": You win " .. bet .. " dollars!"
	else
		--lose
		local str = changeCash(usr,-bet)
		return usr.nick .. ": You lost " .. bet .. " dollars!"..str
	end
end

--open a weird door
function odoor(usr,door)
	door = door or ""
	local isNumber=false
	local randMon = 50
	local divideFactor = 2
	if door:find("moo") then divideFactor=2.5 end
	local adjust =  os.time()-(users[usr.host].lastDoor or os.time())
	randMon = randMon+adjust*5--get higher for waiting longer
	users[usr.host].lastDoor = os.time()

	if tonumber(door) then
		if tonumber(door)>15 and (tonumber(door)<=adjust+1 and tonumber(door)>=adjust-1) then randMon=randMon+(adjust*50) divideFactor=5 end
		isNumber=true
	end
	--some other weird functions to change money
	
	local randomnes = math.random(randMon)-math.floor(randMon/divideFactor)
	local brupt = changeCash(usr,randomnes)
	if randomnes<0 then
		return usr.nick .. ": You lost " .. -randomnes .. " dollar(s)!"..brupt
	end
	return usr.nick .. ": You found " .. randomnes .. " dollar(s)!"
end

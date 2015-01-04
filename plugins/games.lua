module("games", package.seeall)

local function loadUsers()
	local t= table.load("plugins/gameUsers.txt") or {}
	setmetatable(t,{__index=function(t,k) t[k]={cash=1000, lastDoor=os.time(), winStreak=0, loseStreak=0, maxWinStreak=1, maxLoseStreak=1, lastGameWon=nil, inventory={}} return t[k] end})
	return t
end
gameUsers = gameUsers or loadUsers()

storeInventory={
["paradox"]={name="paradox",cost=-5000000000000,info="Game over for you, buddy",amount=1,instock=false},
["blackhole"]=	{name="blackhole",	cost=-50000000000,info="OH MY GOD, GET RID OF IT NOW",amount=1,instock=false},
["loan"]=	{name="loan",	cost=-500000000,info="Why would you take out such a large loan.. better get rid of it fast (it grows)",amount=1,instock=false},
["credit"]=	{name="credit",	cost=-5000000,info="You owe somebody a lot of money",amount=1,instock=false},
["void"]=	{name="void",	cost=-50000,info="Watch out, this will take money with it!",amount=1,instock=false},
["junk"]=	{name="junk",	cost=-500,info="Why do you have this, you will have to PAY someone to get rid of it",amount=1,instock=false},
["powder"]=	{name="powder",	cost=5,info="It's some kind of powder...",amount=1,instock=true},
["chips"]=	{name="chips",	cost=50,info="Baked Lays.",amount=1,instock=true},
["shoe"]=	{name="shoe",	cost=200,info="One shoe, why is there only one?",amount=1,instock=false},
["iPad"]=	{name="iPad",	cost=499,info="A new iPad.",amount=1,instock=true},
["lamp"]=	{name="lamp",	cost=1001,info="A very expensive lamp, great lighting.",amount=1,instock=true},
["penguin"]={name="penguin",cost=5000,info="Don't forget to feed it.",amount=1,instock=false},
["nothing"]={name="nothing",cost=10000,info="Nothing, how can you even have this.",amount=1,instock=false},
["doll"]=	{name="doll",	cost=15000,info="A voodoo doll of mitch, do whatever you want to it.",amount=1,instock=true},
["derp"]=	{name="derp",	cost=50000,info="One derp, to derp things.",amount=1,instock=true},
["table"]=	{name="table",	cost=70000,info="The fanciest table around!",amount=1,instock=true},
["water"]=	{name="water",	cost=100000,info="Holy Water, you should feel very blessed now.",amount=1,instock=false},
["vroom"]=	{name="vroom",	cost=500000,info="Vroom vroom.",amount=1,instock=true},
["moo"]=	{name="moo",	cost=1000000,info="A very rare moo, hard to find.",amount=1,instock=false},
["potato"]=	{name="potato",	cost=2000000,info="Just a potato.",amount=1,instock=true},
["gold"]=	{name="gold",	cost=5000000,info="Sparkly.",amount=1,instock=false},
["diamond"]={name="diamond",cost=10000000,info="You are rich.",amount=1,instock=false},
["cow"]=	{name="cow",	cost=24000000,info="Can generate moo's.",amount=1,instock=true},
["house"]=	{name="house",	cost=50000000,info="A decent size mansion.",amount=1,instock=false},
["cube"]=	{name="cube",	cost=76000000,info="A Rubik's cube made of ice.",amount=1,instock=true},
["cracker"]={name="cracker",cost=100000000,info="Just in-case anyone ever rolls this high.",amount=1,instock=false},
["estate"]=	{name="estate",	cost=300000000,info="You can live here forever.",amount=1,instock=true},
["moo2"]=	{name="moo2",	cost=500000000,info="This moo has evolved into something new.",amount=1,instock=false},
["billion"]={name="billion",cost=999999999,info="A bill not actually worth a billion.",amount=1,instock=true},
["company"]={name="company",cost=25000000000,info="A successful company that makes money.",amount=1,instock=true},
["antiPad"]={name="antiPad",cost=100000000000,info=".daPi wen A, For the rich, made from antimatter.",amount=1,instock=true},
["country"]={name="country",cost=1000000000000,info="You own a country and everything in it.",amount=1,instock=true},
["world"]=	{name="world",	cost=1000000000000000,info="You managed to buy the entire world",amount=1,instock=true},
["god"]=	{name="god",	cost=999999999999999999999,info="Even God sold himself to obey your will.",amount=1,instock=true},
}
local inStockSorted = {}
for k,v in pairs(storeInventory) do
	if v.instock then
		table.insert(inStockSorted,v)
	end
end
table.sort(inStockSorted,function(a,b) if a.cost<b.cost then return a end end)
--for k,v in pairs(inStockSorted) do print(v.name) end

--make function hook to reload user cash
local function loadUsersCMD()
	gameUsers = loadUsers()
end

--adjust win/lose streak
local function streak(usr,win)
	local gusr = gameUsers[usr.host]
	if win then
		if gusr.lastGameWon then
			gusr.winStreak = gusr.winStreak+1
			if gusr.winStreak>gusr.maxWinStreak then gusr.maxWinStreak=gusr.winStreak end
		else
			gusr.winStreak = 1
		end
		gusr.loseStreak = 0
		gusr.lastGameWon = true
	else
		if gusr.lastGameWon==false then
			gusr.loseStreak = gusr.loseStreak+1
			if gusr.loseStreak>gusr.maxLoseStreak then gusr.maxLoseStreak=gusr.loseStreak end
		else
			gusr.loseStreak = 1
		end
		gusr.winStreak = 0
		gusr.lastGameWon = false
	end
end

local function nicenum(number)
	if filters and filters.nicenum then return filters.nicenum(tostring(number)) else return number end
end

--change cash, that resets if 0 or below
local function changeCash(usr,amt)
	if amt ~= amt then
		return " Invalid amount, no money changed"
	end
	gameUsers[usr.host].cash = gameUsers[usr.host].cash + amt
	gameUsers[usr.host].inventory = gameUsers[usr.host].inventory or {}
	if gameUsers[usr.host].cash <= 0 then
		local total = 0
		for k,v in pairs(gameUsers[usr.host].inventory) do
			total = total + v.cost * v.amount
		end
		if total > 0 then
			if gameUsers[usr.host].cash < -total then
				gameUsers[usr.host].cash = -total+1
			end
			return " You went bankrupt, sell items for money"
		end
		if not skip then
			gameUsers[usr.host].cash = 1000
			return " You went bankrupt, money reset"
		end
	end
	return " ($\002"..nicenum(gameUsers[usr.host].cash).." \002now)"
end

--add item to inventory, creating if not exists
local function addInv(usr,item,amt)
	gameUsers[usr.host].inventory = gameUsers[usr.host].inventory or {}
	local inv = gameUsers[usr.host].inventory
	if inv[item.name] then
		inv[item.name].amount = inv[item.name].amount+amt
	else
		inv[item.name]= {name=item.name,cost=item.cost,info=item.info,amount=amt,instock=item.instock}
	end
end
local function remInv(usr,name,amt)
	gameUsers[usr.host].inventory = gameUsers[usr.host].inventory or {}
	local inv = gameUsers[usr.host].inventory
	if inv[name] then
		inv[name].amount = inv[name].amount-amt
		if inv[name].amount<=0 then inv[name]=nil end
	end
end

local antiPadList = {"iPad","blackhole","company","billion","iPad","country"}

--make a timer loop save users every minute, errors go to me
local function timedSave()
	--now we are parsing items in inventories for updates
	for host,usr in pairs(gameUsers) do
		for k,v in pairs(usr.inventory or {}) do
			if k=="loan" then
				v.cost = math.floor(v.cost*1.002)
			elseif k=="blackhole" then
				v.cost = math.floor(v.cost*1.02)
			elseif k=="paradox" then
				v.cost = math.floor(v.cost*.9)
			elseif k=="cow" and math.random()>.9 then
				addInv({host=host},storeInventory["moo"],1)
			elseif k=="company" and math.random()>.75 then
				changeCash({host=host},math.random(100,100000))
			elseif k=="antiPad" and math.random()>.99 then
				addInv({host=host},storeInventory[antiPadList[math.random(#antiPadList)]],1)
			end
			if v.cost < -1e300 then
				local total = usr.cash
				for k,v in pairs(usr.inventory) do
					if v.cost > 1e-300 then
						total = total + v.amount*v.cost
					end
				end
				usr.inventory = {}
				usr.cash = 1000
				addInv({host=host},{name="momento",cost=0,info="Lost memories of your past, you were apparently worth $"..nicenum(total),amt=1,instock=false},1)
			end
		end
	end
	table.save(gameUsers,"plugins/gameUsers.txt")
end
remUpdate("gameSave")
addUpdate(timedSave,60,config.owner.nick,"gameSave")

--Find closest item value
local function findClosestItem(amt)
	local closestitem=nil
	local closestdiff=1/0
	for k,v in pairs(storeInventory) do
		local temp = math.abs(v.cost-amt)
		if temp<closestdiff then
			closestdiff=temp
			closestitem=v
		end
	end
	return closestitem
end

--Uses for items, with /use
local itemUses = {
	["void"] = function(usr,args,chan)
		if not irc.channels[chan] then return "You fall into a bottomless void"..changeCash(usr, -500000) end
		for i=1,4 do
			amount = math.floor(gameUsers[usr.host].inventory["void"].amount*gameUsers[usr.host].inventory["void"].cost*math.random()*-1)
			usertotal = 0  for i,v in pairs(irc.channels[chan].users) do usertotal = usertotal + 1 end
			randomuser,usertotal = math.random(0, usertotal),0
			for k,v in pairs(irc.channels[config.primarychannel].users) do
				if randomuser == usertotal then
					if not gameUsers[v.host] or not gameUsers[v.host].inventory then
						randomuser = randomuser + 1
					else
						randomitem, randomitemcount = math.random(0, #gameUsers[v.host].inventory), 0
						for k2,v2 in pairs(gameUsers[v.host].inventory) do
							if randomitemcount == randomitem then
								if v2.cost > 0 and v2.cost < amount and storeInventory[v2.name] then
									destroyed = math.floor(amount/v2.cost)
									if destroyed > v2.amount then destroyed = v2.amount end
									lostvoids = math.floor(destroyed*v2.cost/(5000*math.random(5,10)))
									if destroyed == 0 or lostvoids == 0 then break end
									remInv(usr, "void", lostvoids)
									remInv(v, v2.name, destroyed)
									return "The void sucks up "..destroyed.." of "..v.nick.."'s "..v2.name.."s! (-"..lostvoids.." voids)"
								else
									randomitem = randomitem + 1
								end
							end
							randomitemcount = randomitemcount + 1
						end
					end
				end
				usertotal = usertotal + 1
			end
		end
		return "You fall into a bottomless void"..changeCash(usr, -500000)
	end,
	["junk"] = function(usr)
		local rnd = math.random(100)
		if rnd <= 10 then
			remInv(usr,"junk",1)
			addInv(usr,storeInventory["iPad"], 1)
			return "It wasn't junk after all! (-1 junk, +1 iPad)"
		elseif rnd <= 20 then
			addInv(usr,storeInventory["junk"], 2)
			return "You had more junk than you realized! (+2 junk)"
		elseif rnd <= 30 then
			remInv(usr,"junk",1)
			addInv(usr,storeInventory["nothing"], 1)
			return "You never had any junk. (-1 junk, +1 nothing)"
		elseif rnd <= 40 then
			return "You trip over the junk and hurt your leg. The hospital bill was $10000. (-$10000)"..changeCash(usr,-10000)
		elseif rnd <= 50 then
			return "You look for your junk, you find it in your pants"
		elseif rnd <= 60 then
			remInv(usr,"junk",1)
			addInv(usr,storeInventory["doll"], 1)
			return "You look at your junk and find it is actually mitch (-1 junk, +1 doll)"
		elseif rnd <= 70 then
			return "You attempt to dispose of your junk, but are caught and fined $50000 for illegal dumping"..changeCash(usr,-50000)
		elseif rnd <= 80 then
			local junk = (gameUsers[usr.host].inventory.junk or {amount=1}).amount
			junk = junk>1000000 and 1000000 or junk
			addInv(usr, storeInventory["junk"], junk)
			return "You donate the junk to charity, but they refuse your offer and give you just as much. (+".. junk .." junk)"
		elseif rnd <= 90 then
			local t = {}
			for k,v in pairs(gameUsers[usr.host].inventory) do if v.cost < 100000 and v.cost>0 then table.insert(t,v) end end
			local nom = t[math.random(#t)]
			remInv(usr, nom.name, 1)
			return "The junk expanded and ate your ".. nom.name .." (-1 ".. nom.name ..")"
		else
			addInv(usr, storeInventory["penguin"], 1)
			return "You find a penguin in your junk. (+1 penguin)"
		end
		return "Yup it is junk all right"
	end,
	["chips"] = function(usr)
		local rnd = math.random(1,150)
		if rnd <= 3 then
			remInv(usr,"chips",1)
			return "You got lead poisoning. You sued the chip company and made $"..(rnd*100000)..changeCash(usr,rnd*100000)
		elseif rnd < 30 then
			remInv(usr,"chips",1)
			return "You finished the bag of chips (-1 chips)"
		else
			return "You ate a chip"..((rnd%3 == 1) and ". It needs more salt" or "")
		end
	end,
	["shoe"]=function(usr)
		if gameUsers[usr.host].inventory["shoe"].amount > 1 then
			remInv(usr,"shoe",2)
			local rnd = math.random(1,200000)
			if rnd < 10000 then
				return "You put on another pair of shoes. Why do they always go missing ... (-2 shoes)"
			else
				return "You sold your designer pair of shoes for $"..rnd..changeCash(usr,rnd*100)
			end
		end
		if math.random(1,20) == 1 then
			remInv(usr,"shoe",1)
			return "Your shoe gets worn out (-1 shoe)"
		else
			return "You found a wad of cash in your shoe!"..changeCash(usr,math.random(1,50000))
		end
	end,
	["iPad"] = function(usr)
		local rnd = math.random(1,5)
		if rnd == 1 then
			remInv(usr,"iPad",1)
			addInv(usr,storeInventory["junk"],1)
			if math.random(1,5) == 5 then
				return "Your iPad was incinerated (-1 iPad, +1 junk)"
			else
				return "Your iPad broke (-1 iPad, +1 junk)"
			end
		end
		local info = gameUsers[usr.host].inventory["iPad"].status
		if info and os.time() < info then
			return "Please wait "..(info-os.time()).." seconds for the eBay app update to finish downloading"
		end
		local name
		for k,v in pairs(inStockSorted) do
			if math.random(1,7) < 2 and v.cost>0 then
				name = v.name
				break
			end
		end
		if name == nil then
			return "You play Angry birds."
		elseif storeInventory[name].instock then
			local cost = math.floor(storeInventory[name].cost*(math.random()+.3))
			if cost < gameUsers[usr.host].cash then
				if cost > 10000000000 and gameUsers[usr.host].cash > 300000000000 and math.random()>.85 then
					remInv(usr,"iPad",1)
					addInv(usr,storeInventory["blackhole"],1)
					return "The app imploded into a blackhole while browsing, THANKS OBAMA! (-1 iPad, +1 blackhole)"
				end
				addInv(usr, storeInventory[name], 1)
				--if usr.nick == "cracker64" then
				--	addInv(usr, storeInventory["iPad"], math.random(1,3))
				--end
				gameUsers[usr.host].inventory["iPad"].status = os.time()+math.floor((.6-cost/storeInventory[name].cost)*math.log(storeInventory[name].cost)^2)
				return "You bought a "..name.." on Ebay for "..cost..changeCash(usr,-cost)
			else
				return "You couldn't afford to buy "..name
			end
		else
			return "You couldn't find "..name.." on Ebay"
		end
	end,
	["lamp"]=function(usr)
		local rnd = math.random(1,100)
		if rnd<50 then
			remInv(usr,"lamp",1)
			return "The lamp broke (-1 lamp)."
		else
			local amt = math.floor((.016*rnd)*1001)
			remInv(usr,"lamp",1)
			return "You sold lamp on Ebay for "..amt.." (-1 lamp)"..changeCash(usr,amt)
		end
	end,
	["penguin"]=function(usr)
		local rnd = math.random(1,10)
		if usr.nick:find("iam") then
			return "Error: You can't use yourself"..changeCash(usr,1)
		end
		remInv(usr,"penguin",1)
		if rnd < 3 then
			return "Your pet penguin caught a plane back to Antarctica (-1 penguin)"
		elseif rnd < 4 then
			return "You were fined $10000 for having an illegal pet"..changeCash(usr,-10000)
		end
		return "You sold your pet penguin for $5000000. You feel bad for selling such a rare species"..changeCash(usr,5000000)
	end,
	["nothing"]=function(usr)
		local rnd = math.random(1,10)
		if rnd < 2 then
			remInv(usr,"nothing",1)
			return "Your nothing was confiscated by the universal oversight committee for breaking the laws of the universe. You are given a $50000 fine"..changeCash(usr,-50000)
		elseif rnd < 3 then
			remInv(usr,"nothing",1)
			return "You look inside your nothing and get sucked inside to an alternate universe where you didn't have it (-1 nothing)"
		elseif rnd < 8 then
			addInv(usr,storeInventory["nothing"],1)
			return "You look inside your nothing and find nothing inside (+1 nothing)"
		else
			return "You can't use nothin'"
		end
	end,
	["doll"]=function(usr)
		remInv(usr,"doll",1)
		if string.lower(usr.nick):find("mitch") then
			ircSendRawQ("KICK "..config.primarychannel.." "..usr.nick)
			return "You stick a needle in the doll. Your leg starts bleeding and you die (-1 doll)"
		end
		local rnd = math.random(1,100)
		if rnd <= 50 then
			return "You find out the doll was gay and throw it away (-1 doll)"
		elseif rnd == 51 then
			ircSendRawQ("KICK "..config.primarychannel.." wolfmitchell")
			return "You stick a needle in the doll. wolfmitchell dies (-1 doll)"
		else
			return "The doll looks so ugly that you burn it (-1 doll)"
		end
	end,
	["derp"]=function(usr)
		remInv(usr,"derp",1)
		local count = 0
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if v.cost >= -1000 then
				count = count + v.amount
			end
		end
		if count == 0 then
			return "You are a derp"
		end
		local item,rnd,count = nil,math.random(count),0
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if v.cost >= -1000 then
				count = count + v.amount
				if count >= rnd then
					item = v
					break
				end
			end
		end
		if not item then
			return "jacob1 is a derp"
		end
		rnd = math.random()
		if rnd < .5 then
			addInv(usr,item,1)
			return "You derp your "..item.name.." and it multiplies! (+1 "..item.name..")"
		else
			remInv(usr,item.name,1)
			return "You derp your "..item.name.." and it explodes! (-1 "..item.name..")"
		end
	end,
	["water"]=function(usr)
		local rnd = math.random(1,10)
		remInv(usr,"water",1)
		if rnd < 3 then
			return "You drink the holy water. Nothing happens (-1 water)"
		elseif rnd < 5 then
			return "You get paid $1000000 to burn the water by a mysterious man with horns"..changeCash(usr,1000000)
		else
			local amt = ((rnd-5)^3)*100000+1
			return "You discover that the holy water cures cancer. You sell it for $"..amt..changeCash(usr,amt)
		end
	end,
	["table"] = function(usr)
		local rnd = math.random(100)
		if rnd <= 20 then
			inv = {}
			for k,v in pairs(gameUsers[usr.host].inventory) do if v.cost > 0 and storeInventory[v.name] then table.insert(inv,v) end end
			randomitem = inv[math.random(1, #inv)]
			remInv(usr, randomitem.name, 1)
			return "You flip a table (╯°□°）╯︵ ┻━┻. It lands on your " ..randomitem.name.. " and breaks it. (-1 "..randomitem.name..")"
		elseif rnd <= 40 then
			return "You stare at your table. The table stares back o.o"
		elseif rnd <= 65 then
			return "You look underneath your table and find a huge wad of cash!"..changeCash(usr,math.random(1,50000))
		elseif rnd <= 90 then
			remInv(usr, "table", 1)
			return "You flip your table (╯°□°）╯︵ ┻━┻. It falls and breaks. (-1 table)"
		elseif rnd <= 97 then
			addInv(usr, storeInventory["shoe"], 2)
			return "You flip your table (╯°□°）╯︵ ┻━┻ and find a pair of shoes. (+2 shoes)"
		else
			addInv(usr, storeInventory["gold"], 1)
			return "Eureka! You find gold under your table! (+1 gold)"
		end
	end,
	["vroom"]=function(usr)
		--maybe have this do something later
		local rnd = math.random(1,100)
		if rnd<33 then
			remInv(usr,"vroom",1)
			return "You use vroom! A cloud of smoke appears (-1 vroom)"
		elseif rnd<46 then
			addInv(usr,storeInventory["credit"],1)
			return "You find out the vroom was stolen, you have to take out a credit card to pay it off ( +1 credit)"
		else
			return "Ye ye vroom vroom +$1500000"..changeCash(usr,1500000)
		end	
	end,
	["moo"]=function(usr, args)
		local other = getUserFromNick(args[2])
		if other and other.nick ~= usr.nick then
			if (other.nick == "jacob1" or other.nick == "cracker64") and math.random() < .5 then
				addInv(usr,storeInventory["moo"],1)
				return "You moo at "..other.nick..". "..other.nick.." moos back (+1 moo)"
			end
			remInv(usr, "moo", 1)
			addInv(other,storeInventory["moo"],1)
			return "You moo at "..args[2].." (-1 moo)"
		end
		local moo = math.random(1,24)
		if moo < 10 then
			return "moo"
		elseif moo < 11 then
			remInv(usr, "moo", 1)
			addInv(usr,storeInventory["cow"],1)
			return "The moo turns into a baby cow! (-1 moo, +1 cow)"
		elseif moo < 21 then
			remInv(usr, "moo", 1)
			return "You sell your moo for $1500000"..changeCash(usr,1500000)
		else
			if gameUsers[usr.host].inventory["cow"] and gameUsers[usr.host].inventory["cow"].amount > 0 then
				remInv(usr, "moo", 1)
				remInv(usr, "cow", 1)
				return "The moo accidentally hits a baby cow and it dies (-1 moo, -1 cow)"
			end
			local mooCount = gameUsers[usr.host].inventory["moo"].amount
			remInv(usr, "moo", mooCount)
			return "You realize you didn't actually have any moos (-"..mooCount.." moo"..(mooCount > 1 and "s" or "")..")"
		end
	end,
	["potato"]=function(usr,args,chan)
		if usr.nick == "jacob1" then
			return "You are a potato"..changeCash(usr,1000)
		end
		local rnd = math.random(0,99)
		if rnd < 20 then
			return "I'm a potato"
		elseif rnd < 30 then
			addInv(usr,storeInventory["potato"],1)
			return "You are turned into a potato (+1 potato)"
		elseif rnd < 50 then
			return "You stare at the potato. You determine it is a potato"
		elseif rnd < 60 then
			remInv(usr,"potato",1)
			return "You find out potatoes that can't talk are very expensive and sell yours for $75000000"..changeCash(usr, 60000000)
		else
			local str
			if rnd < 70 then
				str = "You plant the potato in the ground"
			elseif rnd < 80 then
				str = "You run over the potato with a steamroller to make mashed potatoes"
			elseif rnd < 90 then
				str = "You peel the potato"
			elseif rnd < 100 then
				str = "You fry the potato and make french fries"
			end
			if rnd%2 == 1 and irc.channels[chan] then
				str = str..". The potato attacks you"..changeCash(usr,-10000000)
				ircSendRawQ("KICK "..chan.." "..usr.nick.." :"..str)
				str = ""
			end
			remInv(usr,"potato",1)
			return str
		end
	end,
	["cow"]=function(moo)
		local cowCount = gameUsers[moo.host].inventory["cow"].amount
		local rnd = math.random(1,100)
		--[[local info = gameUsers[moo.host].inventory["cow"].status
		if info and os.time() < info then
			return "Please wait "..(info-os.time()).." seconds before spamming this again"
		end
		gameUsers[moo.host].inventory["cow"].status = os.time()+3]]
		if cowCount > 2 then
			if rnd%5 == 1 then
				local amountgained = math.ceil(cowCount/24)
				addInv(moo,storeInventory["cow"], amountgained )
				return "Your cows moo and "..amountgained.." baby cow"..(amountgained==1 and " is" or "s are").." born"
			end
			if cowCount > 10 then
				if rnd%5 == 2 then
					local amountLost = math.ceil(cowCount*math.random()/2)
					remInv(moo, "cow", amountLost)
					return "Your cows stampede and many escape (-"..amountLost.." cow"..(amountLost==1 and "" or "s")..")"
				end
				if cowCount > 20 and rnd%5 == 3 then
					if math.random()>.9 then
						addInv(moo,storeInventory["loan"],1)
						return "You start a cow farm, but it quickly becomes overrun with peasants who start summoning a demonic rift. A great demon appears and allows you to live at a cost (+1 loan)"
					end
					local amountLost = math.ceil(rnd/5)
					local amountgained = (math.floor(math.random(1,10))*4+1)*25000000
					remInv(moo, "cow", amountLost)
					return "You start a cow farm and make an expensive enchantment table factory (-"..amountLost.." cow"..(amountLost==1 and "" or "s")..") (+$"..amountgained..")"..changeCash(moo, amountgained)
				end
			end
		end
		if rnd <= 15 then
			remInv(moo, "cow", 1)
			return "You have a fancy steak dinner (-1 cow)"
		elseif rnd <= 25 then
			addInv(moo,storeInventory["cow"],1)
			return "Your cow breeds asexually (+1 cow)"
		elseif rnd <= 30 then
			addInv(moo,storeInventory["cow"], cowCount)
			return "Your cows all breed asexually (+"..cowCount.." cows)"
		elseif rnd <= 40 then
			return "The cow tries to moo but is unable to because you never feed it"
		elseif rnd <= 50 then
			local voids = math.random(45*cowCount)
			addInv(moo,storeInventory["void"],voids)
			return "The cow tries to moo but accidentally creates voids everywhere (+"..voids.." voids)"
		elseif rnd <= 55 then
			return "You feed your cow"
		elseif rnd <= 85 then
			addInv(moo,storeInventory["moo"],cowCount)
			return "Your cows all moo (+"..cowCount.." moos)"
		elseif rnd <= 88 then
			local amountLost = math.ceil(cowCount*math.random())
			remInv(moo, "cow", amountLost)
			addInv(moo,storeInventory["moo2"],1)
			return "Your cow moos. This cow was special though, it moos so hard that it makes a moo2 appear! Some of the other cows can't handle such a special moo and die (+1 moo2) (-"..amountLost.." cow"..(amountLost==1 and "" or "s")..")"
		else
			return filters and filters.rainbow("mo".."o"*math.random(1,75)) or "mo".."o"*math.random(1,75)
		end
	end,
	["billion"] = function(usr,args)
		local other = getUserFromNick(args[2])
		if other and other.nick ~= usr.nick then
			local rnd = math.random(100)
			if rnd < 33 then
				remInv(usr, "billion", 1)
				addInv(other,storeInventory["billion"],1)
				return "You threw your billion at "..other.nick.." and they gladly accept it"
			elseif rnd < 66 then
				return "You threw your billion at "..other.nick..", but they kindly return it."
			else
				remInv(usr, "billion", 1)
				addInv(other,storeInventory["billion"],1)
				local t = {}
				for k,v in pairs(gameUsers[other.host].inventory) do table.insert(t,v) end
				local otheritem = t[math.random(#t)]
				if otheritem.instock or otheritem.cost<0 then
					remInv(other, otheritem.name, 1)
					addInv(usr, otheritem,1)
					return "You threw your billion at "..other.nick..", they are thankful and give you a " .. otheritem.name .. " in return without thinking."
				else
					return "You dropped the billion down a drain. "..other.nick.." lives in the sewers and found it."
				end
			end
		end
		return "You are just happy you have the billion"
	end,
	["company"] = function(usr, args)
		local rnd = math.random(94)
		local other = getUserFromNick(args[2])
		if other and other.nick ~= usr.nick then
			if other.nick == config.user.nick then return "You cannot sue the bot!" end
			amt = math.random(1, 500000)
			if math.random() >= .5 then
				if amt > gameUsers[other.host].cash then amt = gameUsers[other.host].cash end
				changeCash(other, -amt)
				return "Your company sues "..other.nick.." for $" ..nicenum(amt).. " and wins!" .. changeCash(usr, amt)
			else
				changeCash(other, amt)
				return "Your company sues "..other.nick.." for $" ..nicenum(amt).. " and loses." .. changeCash(usr, -amt)
			end
		end
		if rnd <= 30 then
			items = {"derp", "vroom", "chips", "iPad", "powder", "cube", "lamp", "table"}
			randomitem = items[math.random(1, #items)]
			amt = math.random(1,200)
			addInv(usr, storeInventory[randomitem], amt)
			-- Pluralize item names properly --you only made this do that? >_>
			if randomitem ~= "chips" then
				name = randomitem + "s"
			else
				name = randomitem
			end
			return "Your company starts manufacturing " ..name.. " (+" .. amt .. " " .. name..")"
		elseif rnd <= 48 then
			amt = math.random(1, 200000000)
			return "Your company is making money. (+$" ..nicenum(amt).. ")" .. changeCash(usr, amt)
		elseif rnd <= 65 then
			fines = {"tax evasion", "violating competition laws", "money laundering", "selling defective products", "genocide"}
			fine = fines[math.random(1, #fines)]
			amt = math.random(1, 500000000)
			return "Your company is caught for " ..fine.. " and is given a hefty fine. (-$" ..nicenum(amt).. ")" ..changeCash(usr, -amt)
		elseif rnd <= 75 then
			amt = math.random(1,9) * 100000000
			amtjunk = math.random(1000,10000)
			addInv(usr, storeInventory["junk"], amtjunk)
			return "A mob of angry customers descends on your headquarters and loots the entire place, causing you many damages. (-$" ..nicenum(amt)..", +" ..amtjunk.." junk)"..changeCash(usr, -amt)
		elseif rnd <= 81 then
			items = {"gold", "diamond", "billion"}
			item = items[math.random(1, #items)]
			amt = math.ceil(storeInventory["company"].cost / storeInventory[item].cost)
			good = math.random(1, math.floor(amt/2))
			bad = amt - good
			addInv(usr, storeInventory[item], good)
			addInv(usr, storeInventory["junk"], bad)
			remInv(usr, "company", 1)
			return "A clever conman comes by and tricks you into selling your company for the equivalent value in " ..item.. "s. Unfortunately, it turns out all but " ..good.. " of them were fake! (-1 company, +" ..good.. " " ..item..", +" ..bad.. " junk)"
		elseif rnd <= 89 then
			remInv(usr, "company", 1)
			return "Your company goes bankrupt after a freak accident. (-1 company)"
		else
			local users = {}
			for k,v in pairs(irc.channels[config.primarychannel].users) do
				if k ~= usr.nick then
					table.insert(users, v)
				end
			end
			giveto = users[math.random(1,#users)]
			remInv(usr, "company", 1)
			addInv(giveto, storeInventory["company"], 1)
			actions = {"eating potatoes", "ice cream", "apple products", "apocalypse preparations", "hugs", "donating to charity", "fighting terrorists", "drugs", "taking over foreign countries"}
			randomaction = actions[math.random(1, #actions)]
			return "Shareholders, angry over "..usr.nick.."'s tendency to spend all company profits on "..randomaction..", revolt and select "..giveto.nick.." as the new CEO (-1 company)"
		end
	end,
	['antiPad'] = function(usr,args)
		return "You play Angry Birds."
	end
}
--powder, chips, shoe, iPad, lamp, penguin, nothing, doll, derp, water, vroom, moo, 
--potato
--gold, diamond, cow, house, cube, cracker, estate, moo2, billion, company, country, 
--world, god
--- computer ($99) Who would use this piece of junk from your grandmother
--- iMac ($2999) Glorious master race
--- MacPro ($999999) A bit expensive but does have an apple logo!
local function useItem(usr,chan,msg,args)
	if not args[1] then
		return "Need to specify an item! '/use <item>'"
	end
	if not gameUsers[usr.host].inventory[args[1]] or gameUsers[usr.host].inventory[args[1]].amount<=0 then
		return "You don't have that item!"
	elseif itemUses[args[1]] and gameUsers[usr.host].inventory[args[1]] then
		return itemUses[args[1]](usr,args,chan)
	else
		return "This item can't be used!"
	end
end
add_cmd(useItem,"use",0,"Use an item, '/use <item>', Find out what all the items can do!",true)

--User cash
local function myCash(usr,all)
	if all then
		local cash = gameUsers[usr.host].cash
		for k,v in pairs(gameUsers[usr.host].inventory or {}) do
			cash = cash+ (v.cost*v.amount)
		end
		return "You have $"..cash.." including items."
	end
	return "You have $"..nicenum(gameUsers[usr.host].cash)
end
--give money
local function give(fromHost,toHost,amt)
	if gameUsers[fromHost].cash-amt <= 10000 then
		return "You can only give if you have over 10k left"
	end
	gameUsers[fromHost].cash = gameUsers[fromHost].cash-amt
	gameUsers[toHost].cash = gameUsers[toHost].cash+amt
	return "Gave money"
end
--50% chance to win double
local function coinToss(usr,bet)
	local mycash = gameUsers[usr.host].cash
	if bet > mycash then
		return "Not enough money!"
	end
	local res = math.random(2)
	if res==1 then
		--win
		local str = changeCash(usr,bet)
		streak(usr,true)
		return "You win $" .. bet .. "!"..str
	else
		--lose
		local str = changeCash(usr,-bet)
		streak(usr,false)
		return "You lost $" .. bet .. "!"..str
	end
end

--open a weird door
local function odoor(usr,door)
	if gameUsers[usr.host].cash <= 0 then
		return "You are broke, you can't afford to open doors"
	end
	--[[if usr.nick == "JZTech101" then
		return "You forgot how to open doors"
	end]]
	
	door = door[1] or "" --do something with more args later?
	local isNumber=false
	local randMon = 50
	local divideFactor = 2
	if door:find("moo") then divideFactor=2.5 end
	local adjust =  os.time()-(gameUsers[usr.host].lastDoor or (os.time()-1))
	randMon = (randMon+adjust*5)^1.15--get higher for waiting longer

	if tonumber(door) then
		if tonumber(door)>15 and (tonumber(door)<=adjust+1 and tonumber(door)>=adjust-1) then randMon=randMon+(adjust*50)^1.15 divideFactor=6 end
		isNumber=true
	end
	--blacklist of people
	--if (string.lower(usr.nick)):find("mitchell_") then divideFactor=1 end
	--if (string.lower(usr.nick)):find("boxnode") then divideFactor=1 end
	--if (string.lower(usr.host)):find("unaffiliated/angryspam98") then divideFactor=1 end

	--some other weird functions to change money
	
	--randomly find items
	local fitem = math.random(9)
	if fitem==1 then fitem=true else fitem=false end
	randMon = math.floor(randMon)
	local minimum = math.floor(randMon/divideFactor)
	local randomness = math.ceil(randMon*math.random())-minimum
	local rstring=""
	--reset last door time
	gameUsers[usr.host].lastDoor = os.time()
	
	if fitem and randomness>0 then
		--find an item of approximate value
		local item = findClosestItem(randomness)
		rstring = "You found a "..item.name.."! Added to inventory, see the store to sell"
		addInv(usr,item,1)
	else
		fitem=false
		rstring = changeCash(usr,randomness)
	end
	if fitem then
		streak(usr,true)
		return rstring
	elseif randomness<0 then
		streak(usr,false)
		return "You lost $" .. nicenum(-randomness) .. " (-"..nicenum(minimum).." to "..nicenum(randMon-minimum)..")!"..rstring
	elseif randomness==0 then
		return "The door is broken, try again"
	end
	streak(usr,true)
	return "You found $" .. nicenum(randomness) .. " (-"..nicenum(minimum).." to "..nicenum(randMon-minimum)..")!"..rstring
end

--GAME command hooks
--CASH
local function myMoney(usr,chan,msg,args)
	if args then
		if args[1]=="stats" then
			return "WinStreak: "..gameUsers[usr.host].maxWinStreak.." LoseStreak: "..gameUsers[usr.host].maxLoseStreak
		end
		if args[1]=="all" then
			return myCash(usr,true)
		end
	end
	return myCash(usr)
end
add_cmd(myMoney,"cash",0,"Your current balance, '/cash [stats]', Sending stats will show some saved stats.",true,{"money"})
--GIVE
local function giveMon(usr,chan,msg,args)
	if not args[2] then return "Usage: '/give <username> <amount>'" end
	local toHost
	local amt,item
	if tonumber(args[2]) then
		amt = math.floor(tonumber(args[2]))
	else
		amt= math.floor(tonumber(args[3]) or 1)
		item=args[2]
	end
	if string.lower(args[1]) == string.lower(usr.nick) then
		return "You can't give to yourself..."
	end
	if string.lower(args[1]) == string.lower(config.user.nick) then
		return "Please do not give to the bot"
	end
	toHost = getUserFromNick(args[1])
	if not toHost or not toHost.host then
		return "Invalid user, or not online"
	end
	toHost = toHost.host
	
	if amt and not item then
		--if toHost == "Powder/Developer/jacob1" and amt < 50 then
		--	return "Donations to jacob1 must be at least 1 million"
		--end
		if amt>0 and amt==amt then
			return give(usr.host,toHost,amt)
		else
			return "Bad amount!"
		end
	end
	if item and amt>0 and gameUsers[usr.host].inventory[item] and gameUsers[usr.host].inventory[item].amount>=amt then
		if gameUsers[usr.host].inventory[item].cost<0 then return "You can't give crap to people" end
		local i = gameUsers[usr.host].inventory[item]
		if i.name == "antiPad" then return "You can't give that!" end
		if gameUsers[usr.host].inventory["blackhole"] then return "The force of your blackhole prevents you from giving!." end
		if toHost == "Powder/Developer/jacob1" and i.cost < 2000000 then
			return "Please do not give crap to jacob1"
		end
		remInv(usr,item,amt)
		addInv({host=toHost},{name=i.name,cost=i.cost,info=i.info,amount=1,instock=i.instock},amt)
		return "Gave "..amt.." "..item
	else
		return "You don't have that!"
	end
	
	
end
add_cmd(giveMon,"give",0,"Give money or item to a user, '/give <username> <amount/item>', need over 10k to give.",true)
--reload cashtext
local function loadCash(usr,chan,msg,args)
	return loadUsersCMD()
end
add_cmd(loadCash,"loadcash",101,"Reload saved money",true)
--FLIP
local function flipCoin(usr,chan,msg,args)
	if not args[1] or not tonumber(args[1]) then
		return "You need to place a bet! '/flip <bet>'"
	end
	local bet = math.floor(tonumber(args[1]))
	if bet < 1 then return "Bet too low" end
	return coinToss(usr,bet)
end
add_cmd(flipCoin,"flip",0,"Flip a coin with a bet, '/flip <bet>', 50% chance to win double",true,{"bet"})
--DOOR
local function odor(usr,chan,msg,args)
	return odoor(usr,args)
end
add_cmd(odor,"door",0,"Open a door, '/door <door>', No one knows what will happen",true)

--STORE, to buy somethings?
local function store(usr,chan,msg,args)
	if not msg  or args[1]=="help" then
		return "Welcome to the CrackStore, use '/store list' or '/store info <item>' or '/store buy <item> [<amt>]' or '/store sell <item> [<amt>]'."
	end
	if args[1]=="list" then
		local t={}
		for k,v in pairs(storeInventory) do
			if v.instock and gameUsers[usr.host].cash>=v.cost then table.insert(t,"\15"..v.name.."\00309("..nicenum(v.cost)..")") end
		end
		return table.concat(t," ")
	end
	if args[1]=="info" then
		if not args[2] then return "Need an item! 'info <item>'" end
		local item = args[2]
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if k==item then return "Item: "..k.." Cost: $"..nicenum(v.cost).." Info: "..v.info end
		end
		for k,v in pairs(storeInventory) do
			if k==item then return "Item: "..k.." Cost: $"..nicenum(v.cost).." Info: "..v.info end
		end
		return "Item not found"
	end
	if args[1]=="buy" then
		if not args[2] then return "Need an item! 'buy <item> [<amt>]'" end
		local item = args[2]
		local amt = math.floor(tonumber(args[3]) or 1)
		if amt==amt and amt>0 then
			for k,v in pairs(storeInventory) do
				if k==item and v.instock then
					if gameUsers[usr.host].cash-v.cost*amt>=0 then
						changeCash(usr,-(v.cost*amt))
						addInv(usr,v,amt)
						return "You bought "..nicenum(amt).." "..k
					else
						return "Not enough money!"
					end
				end
			end
		end
		return "Item not found"
	end
	if args[1]=="inventory" then
		local t={}
		for k,v in pairs(gameUsers[usr.host].inventory) do
			table.insert(t,v.name.."("..v.amount..")")
		end
		return "You have, "..table.concat(t,", ")
	end
	if args[1]=="sell" then
		if not args[2] then return "Need an item! 'sell <item> [<amt>] [<item2> [<amt2>]]...'" end
		local sold, rstring, totalSold = false, "Sold ", 0
		local i=2
		while args[i] do
			local item = args[i]
			local amt = math.floor(tonumber(args[i+1]) or 1)
			if tonumber(args[i+1]) then i=i+1 end
			if amt==amt and amt>0 then
				local v = gameUsers[usr.host].inventory[item]
				if v and v.amount>=amt then
					if v.cost<0 and gameUsers[usr.host].cash < -v.cost*amt then return "You can't afford that!" end
					changeCash(usr,v.cost*amt)
					remInv(usr,item,amt)
					rstring = rstring..nicenum(amt).." "..v.name..", "
					totalSold = totalSold + (v.cost*amt)
					sold=true
				end
			end
			i=i+1
		end
		if sold then
			return rstring.."for $"..totalSold
		else
			return "You don't have that!"
		end
	end
end
add_cmd(store,"store",0,"Browse the store, '/store list/info/buy/sell'",true,{"shop"})


local charLookAlike={["0"]="O",["1"]="I",["2"]="Z",["3"]="8",["4"]="H",["5"]="S",["6"]="G",["7"]="Z",["8"]="3",["9"]="6",
["b"]="d",["c"]="s",["d"]="b",["e"]="c",["f"]="t",["g"]="q",["h"]="n",["i"]="j",["j"]="i",
["k"]="h",["l"]="1",["m"]="n",["n"]="m",["o"]="c",["p"]="q",["q"]="p",
["r"]="n",["s"]="c",["t"]="f",["u"]="v",["v"]="w",["w"]="vv",["x"]="X",["z"]="Z",
["A"]="&",["B"]="8",["C"]="O",["D"]="0",["E"]="F",["F"]="E",["G"]="6",["H"]="4",["I"]="l",
["J"]="U",["K"]="H",["L"]="J",["M"]="N",["N"]="M",["O"]="0",["P"]="R",["R"]="P",
["S"]="5",["T"]="F",["U"]="V",["V"]="U",["W"]="VV",["X"]="x",["Y"]="V",["Z"]="2",
["!"]="1",["@"]="&",["#"]="H",["$"]="S",["^"]="/\\",["&"]="8",["("]="{",[")"]="}",["-"]="=",["="]="-",
["{"]="(",["}"]=")",["\""]="'",["'"]="\"",["/"]="\\",["\\"]="/",["`"]="'",["~"]="-",
}
local questions={}
table.insert(questions,{
q= function() --Count a letter in string, with some other simple math
	if not filters.mknumscramb then return "Error: filter plugin must be loaded" end
	local chars = {}
	local extraNumber = math.random(10)
	if extraNumber<=7 then extraNumber=math.random(20000) else extraNumber=nil end
	local rstring=""
	local countChar,answer
	local timeout=25
	local multiplier=0.75
	local i,maxi = 1,math.random(2,7)

	--pick countChar first
	countChar,answer = string.char(math.random(93)+33),(math.random(16)-1)
	rstring = rstring.. string.rep(countChar,answer)
	chars[countChar]=true
	local pickedR=false
	while i<maxi do
		--pick 2-7 chars (2-7 filler) make sure all different
		local rchar
		--possibly add look-alike
		if not pickedR and math.random(10)==1 then
			rchar= charLookAlike[countChar] or string.char(math.random(93)+33)
			pickedR=true
		else
			rchar = string.char(math.random(93)+33)
		end

		if not chars[rchar] then
			chars[rchar]=true
			local amount=(math.random(16)-1)
			rstring = rstring.. string.rep(rchar,amount)
			i = i+1
		end
	end

	local t={}
	for char in rstring:gmatch(".") do
		table.insert(t,char)
	end
	local n=#t
	while n >= 2 do
		local k = math.random(n)
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end
	local intro="Count the number of"
	if extraNumber then
		local randMod = math.random(43)
		if randMod<=15 then --subtract
			intro="What is "..filters.mknumscramb(extraNumber).." minus the number of"
			answer = extraNumber-answer
			multiplier=0.85
		elseif randMod<=22 then --Multiply
			extraNumber = extraNumber%200
			intro="What is "..filters.mknumscramb(extraNumber).." times the number of"
			answer = extraNumber*answer
			timeout,multiplier = 40,1.1
		elseif randMod==23 then --addition AND multiply
			extraNumber = extraNumber
			local extraNum2 = math.random(200)-1
			intro="What is "..filters.mknumscramb(extraNumber).." plus "..filters.mknumscramb(extraNum2).." times the number of"
			answer = extraNumber + (extraNum2*answer)
			timeout,multiplier = 50,1.3
		elseif randMod==24 then --subtraction AND multiply
			extraNumber = extraNumber
			local extraNum2 = math.random(200)-1
			intro="What is "..filters.mknumscramb(extraNumber).." minus "..filters.mknumscramb(extraNum2).." times the number of"
			answer = extraNumber - (extraNum2*answer)
			timeout,multiplier = 50,1.3
		elseif randMod<=26 and answer>0 then --Repeat string
			extraNumber = extraNumber%1000
			intro="Repeat the string \" "..extraNumber.." \" by the amount of"
			answer = (tostring(extraNumber)):rep(answer)
			timeout,multiplier = 40,1.2
		elseif randMod<=40 then --add
			intro="What is "..filters.mknumscramb(extraNumber).." plus the number of"
			answer = answer+extraNumber
			multiplier=0.85
		else
			local possibleAnswers = {"Ring-ding-ding-ding-dingeringeding", "Wa-pa-pa-pa-pa-pa-pow", "Hatee-hatee-hatee-ho", "Joff-tchoff-tchoffo-tchoffo-tchoff", "Jacha-chacha-chacha-chow", "Fraka-kaka-kaka-kaka-kow", "A-hee-ahee ha-hee", "A-oo-oo-oo-ooo"}
			answer = possibleAnswers[math.random(#possibleAnswers)]
			multiplier = 2
			return "What does the fox say?", answer, timeout, multiplier
		end
	end
	return intro.." ' "..countChar.." ' in: "..table.concat(t,""),tostring(answer),timeout,multiplier
end,
isPossible= function(s) --this question only accepts number answers
	if tonumber(s) then return true end
	local possibleAnswers = {"Ring-ding-ding-ding-dingeringeding", "Wa-pa-pa-pa-pa-pa-pow", "Hatee-hatee-hatee-ho", "Joff-tchoff-tchoffo-tchoffo-tchoff", "Jacha-chacha-chacha-chow", "Fraka-kaka-kaka-kaka-kow", "A-hee-ahee ha-hee", "A-oo-oo-oo-ooo"}
	for k,v in pairs(possibleAnswers) do
		if s == k then return true end
	end
	return false
end})
local allColors = {white='00', black='01', blue='02', green='03', red='04', brown='05', purple='06', orange='07', yellow='08', lightgreen='09', turquoise='10', cyan='11', skyblue='12', pink='13', gray='14', grey='14'}
local wordColorList = {'blue','green','red','brown','purple','orange','yellow','cyan','pink','gray',}
table.insert(questions,{
q= function() --Count the color of words, or what the word says.
	local guessC = wordColorList[math.random(#wordColorList)]
	local answer = math.random(0,5)
	local filler = math.random(3,10)
	local intro = "Count the number "
	local chance = math.random(1,100)
	local timeout,multiplier=25,.75
	local t,nt={},{}
	if chance<25 then --count words of a color
		for i=1,filler do
			local ch = wordColorList[math.random(#wordColorList)]
			if ch~= guessC then table.insert(t,"\003"..allColors[ch]) else i=i-1 end
		end
		for i=1,answer do
			table.insert(t,"\003"..allColors[guessC])
		end
		for k,v in pairs(t) do table.insert(nt,v..wordColorList[math.random(#wordColorList)]) end
		intro = intro.."of words that are colored "
	elseif chance<50 then --count words
		for i=1,filler do
			local ch = wordColorList[math.random(#wordColorList)]
			if ch~= guessC then table.insert(t,ch) else i=i-1 end
		end
		for i=1,answer do
			table.insert(t,guessC)
		end
		for k,v in pairs(t) do table.insert(nt,"\003"..allColors[wordColorList[math.random(#wordColorList)]]..v) end
		intro = intro.."of words that say "
	elseif chance<75 then --what does the colored word say
		for i=1,filler do
			local ch = wordColorList[math.random(#wordColorList)]
			if ch~= guessC then table.insert(t,"\003"..allColors[ch]) else i=i-1 end
		end
		answer = wordColorList[math.random(#wordColorList)]
		table.insert(nt,"\003"..allColors[guessC]..answer)
		
		for k,v in pairs(t) do table.insert(nt,v..wordColorList[math.random(#wordColorList)]) end
		intro = "What does the "..guessC.." word say" guessC=""
	else --what colour is the word
		for i=1,filler do
			local ch = wordColorList[math.random(#wordColorList)]
			if ch~= guessC then table.insert(t,ch) else i=i-1 end
		end
		answer = wordColorList[math.random(#wordColorList)]
		table.insert(nt,"\003"..allColors[answer]..guessC)
		
		for k,v in pairs(t) do table.insert(nt,"\003"..allColors[wordColorList[math.random(#wordColorList)]]..v) end
		intro = "What color is the word "
	end
	local n=#nt
	while n >= 2 do
		local k = math.random(n)
		nt[n], nt[k] = nt[k], nt[n]
		n = n - 1
	end
	
	return intro..guessC.." : "..table.concat(nt," "),tostring(answer),timeout,multiplier
end,
isPossible= function(s) --this question only accepts number and color answers
	if tonumber(s) or allColors[s] then return true end
	return false
end})

--[[
table.insert(questions,{
q= function() --A filler question, just testing
	return "Say moo, this is a test question","moo",15,1
end,
isPossible= function(s) --this question takes any string
	if not s:find("%./") then return true end
	return false
end})--]]
local activeQuiz= {}
local activeQuizTime={}
--QUIZ, generate a question, someone bets, anyone can answer
local function quiz(usr,chan,msg,args)
	--timeout based on winnings
	if os.time() < (gameUsers[usr.host].nextQuiz or 0) then
		return "You must wait "..(gameUsers[usr.host].nextQuiz-os.time()).." seconds before you can quiz!."
	end
	if not msg or not tonumber(args[1]) then
		return "Start a question for the channel, '/quiz <bet>'"
	end
	
	local qName = chan.."quiz"
	if activeQuiz[qName] then return
		"There is already an active quiz here!"
	end
	
	local bet= math.floor(tonumber(args[1]))
	if chan:sub(1,1)~='#' then
		if bet>10000 then
			return "Quiz in query has 10k max bid"
		end
	end
	if usr.host=="unaffiliated/mniip/bot/xsbot" or usr.host=="178.219.36.155" or usr.host=="april-fools/2014/third/mniip" then
		if bet > 13333337 then
			return "You cannot bet this high!"
		end
	elseif bet > 10000000000 then
		return "You cannot bet more than 10 billion"
	end
	
	local gusr = gameUsers[usr.host]
	if bet~=bet or bet<1000 then
		return "Must bet at least 1000!"
	elseif gusr.cash-bet<0 then
		return "You don't have that much!"
	end

	changeCash(usr,-bet)
	--pick out of questions
	local wq = math.random(#questions)
	local rstring,answer,timer,prizeMulti = questions[wq].q()
	print("QUIZ ANSWER: "..answer)
	activeQuiz[qName],activeQuizTime[qName] = true,os.time()
	local alreadyAnswered={}
	--insert answer function into a chat listen hook
	addListener(qName,function(nusr,nchan,nmsg)
		--blacklist of people
		--if nusr.host=="gprs-inet-65-277.elisa.ee" then return end
		--if nusr.host=="unaffiliated/mniip/bot/xsbot" then return end
		--if nusr.host=="178.219.36.155" then return end
		--if nusr.host=="unaffiliated/mniip" then return end
		if nchan==chan then
			if nmsg==answer and not alreadyAnswered[nusr.host] then
				local answeredIn= os.time()-activeQuizTime[qName]-1
				if answeredIn <= 0 then answeredIn=1 end
				local earned = math.floor(bet*(prizeMulti+(math.sqrt(1.1+1/answeredIn)-1)*3))
				local cstr = changeCash(nusr,earned)
				if nusr.nick==usr.nick then
					ircSendChatQ(chan,nusr.nick..": Answer is correct, earned "..(earned-bet)..cstr)
				else
					ircSendChatQ(chan,nusr.nick..": Answer is correct, earned "..earned..cstr)
				end
				gameUsers[nusr.host].nextQuiz = math.max((gameUsers[nusr.host].nextQuiz or os.time()),os.time()+math.floor(43*(math.log(earned-bet)^1.1)-360) )
				remTimer(qName)
				activeQuiz[qName]=false
				return true
			else
				--you only get one chance to answer correctly
				if questions[wq].isPossible(nmsg) then alreadyAnswered[nusr.host]=true end
			end
		end
		return false
	end)
	--insert a timer to remove quiz after a while
	addTimer(function() chatListeners[qName]=nil activeQuiz[qName]=false ircSendChatQ(chan,"Quiz timed out, no correct answers! Answer was "..answer) end,timer,chan,qName)
	ircSendChatQ(chan,rstring,true)
	--no return so you can't see nest result
	return nil
end
add_cmd(quiz,"quiz",0,"Start a question for the channel, '/quiz <bet>' First to answer correctly wins a bit more, only your first message is checked.",true)

--ASK a question, similar to quiz, but from a user in query
local function ask(usr,chan,msg,args)
	if chan:sub(1,1)=='#' then return "Can only start question in query." end
	if not msg or not args[3] then return commands["ask"].helptext end
	local toChan = args[1]
	if toChan and toChan:sub(1,1) ~= "#" then
		return "Error, you must ask questions to a channel"
	end
	local qName = toChan.."ask"
	if activeQuiz[qName] then return "There is already an active question there!" end
	local prize, argA = args[2]:match("(%d+)"), 0
	if prize then
		if not args[4] then return commands["ask"].helptext end
		if gameUsers[usr.host].cash-prize<0 then return "You don't have enough money for the prize!" end
		argA=1
	end
	local rstring,answer,timer = "Question from "..usr.nick..(prize and (" ($"..prize.."): ") or ": ")..args[2+argA],args[3+argA],30
	local answers= {}
	for i=3+argA,#args do
		answers[args[i]]=true
	end
	activeQuiz[qName] = true
	--insert answer function into a chat listen hook
	addListener(qName,function(nusr,nchan,nmsg)
		if nchan==toChan and answers[nmsg] then
			if prize then changeCash(usr,-prize) end
			ircSendChatQ(toChan,nusr.nick..": "..nmsg.." is correct, congratulations!"..(prize and " Got $"..prize..changeCash(nusr,prize) or ""))
			remTimer(qName)
			activeQuiz[qName]=false
			return true
		end
		return false
	end)
	--insert a timer to remove question after a while
	addTimer(function() chatListeners[qName]=nil activeQuiz[qName]=false ircSendChatQ(toChan,"Quiz timed out, no correct answers! Answer was "..answer) end,timer,toChan,qName)
	ircSendChatQ(toChan,rstring)
	return nil
end
add_cmd(ask,"ask",0,"Ask a question to a channel, '/ask <channel> [<prize($)>] <question> <mainAnswer> [<altAns...>]' Optional prize, It will help to put \" around the question and answer.",true)

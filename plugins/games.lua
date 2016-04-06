module("games", package.seeall)

local function loadUsers()
	local t= table.load("plugins/gameUsers.txt") or {}
	setmetatable(t,{__index=function(t,k) t[k]={cash=1000, lastDoor=os.time(), winStreak=0, loseStreak=0, maxWinStreak=1, maxLoseStreak=1, lastGameWon=nil, inventory={}, coupons={}} return t[k] end})
	return t
end
gameUsers = gameUsers or loadUsers()

local function itemName(item)
	local fixed = item:lower()
	if fixed == "ipad" then return "iPad"
	elseif fixed == "antipad" then return "antiPad"
	else return fixed
	end
end
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
["table"]=	{name="table",	cost=700,info="The fanciest table around!",amount=1,instock=true},
["lamp"]=	{name="lamp",	cost=1001,info="A very expensive lamp, great lighting.",amount=1,instock=true},
["penguin"]={name="penguin",cost=5000,info="Don't forget to feed it.",amount=1,instock=false},
["nothing"]={name="nothing",cost=10000,info="Nothing, how can you even have this.",amount=1,instock=false},
["doll"]=	{name="doll",	cost=15000,info="A voodoo doll of mitch, do whatever you want to it.",amount=1,instock=true},
["derp"]=	{name="derp",	cost=50000,info="One derp, to derp things.",amount=1,instock=true},
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
local storeInventorySorted = {}
for k,v in pairs(storeInventory) do
	table.insert(storeInventorySorted,v)
end
table.sort(storeInventorySorted,function(a,b) if a.cost<b.cost then return a end end)
local function copyTable(t)
	if not t then return end
	local d = {}
	for k,v in pairs(t) do
		d[k]=v
	end
	return d
end


couponList = {
	--Usable Coupons
		--1 2 3
	{name="Purchase Discount I",var=0.05,cost=5,useFunc=1,info="Your next purchase is discounted!"},
	{name="Purchase Discount II",var=0.15,cost=5,useFunc=1,info="Your next purchase is discounted!"},
	{name="Purchase Discount III",var=0.25,cost=5,useFunc=1,info="Your next purchase is discounted!"},
		--4 5 6
	{name="Sell Bonus I",var=0.05,cost=5,useFunc=2,info="Your next sell is increased!"},
	{name="Sell Bonus II",var=0.15,cost=5,useFunc=2,info="Your next sell is increased!"},
	{name="Sell Bonus III",var=0.25,cost=5,useFunc=2,info="Your next sell is increased!"},
		--7 8 9 10
	{name="Flip Bonus I",var=-0.2,cost=5,useFunc=3,info="Your next flip is changed."},
	{name="Flip Bonus II",var=-0.1,cost=5,useFunc=3,info="Your next flip is changed."},
	{name="Flip Bonus III",var=0.1,cost=5,useFunc=3,info="Your next flip is changed."},
	{name="Flip Bonus IV",var=0.2,cost=5,useFunc=3,info="Your next flip is changed."},
		--11 12 13
	{name="Quiz Bonus I",var=0.1,cost=5,useFunc=4,info="Your next quiz will give more reward."},
	{name="Quiz Bonus II",var=0.2,cost=5,useFunc=4,info="Your next quiz will give more reward."},
	{name="Quiz Bonus III",var=0.3,cost=5,useFunc=4,info="Your next quiz will give more reward."},
		--14 15 16 17
	{name="Give Bonus I",var=10000,cost=5,useFunc=5,info="Being nice to people may help you."},
	{name="Give Bonus II",var=1000000,cost=5,useFunc=5,info="Being nice to people may help you."},
	{name="Give Bonus III",var=100000000,cost=5,useFunc=5,info="Being nice to people may help you."},
	{name="Give Bonus IV",var=10000000000,cost=5,useFunc=5,info="Being nice to people may help you."},
		--18
	{name="Whitehole",var=1,cost=5,info="Removes one blackhole on use. - 'Who knew the existence of whiteholes were coupons all along!'"},

	--Useless Coupons
		--19..27
	{name="Paper",var=1,cost=5,info="Just a blank piece of paper"},
	{name="Old Paper",var=1,cost=5,info="Just an old piece of paper"},
	{name="Wet Paper",var=1,cost=5,info="Just a wet piece of paper"},
	{name="Burnt Paper",var=1,cost=5,info="Just a burnt piece of paper"},
	{name="Outdated",var=1,cost=5,info="This was a great coupon, but it expired"},
	{name="+1 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	{name="+100 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	{name="+1,000,000 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	{name="+1,000,000,000,000 Nothing",var=1,cost=5,info="Wow, it's nothing."},

	--Permanent Effect Coupons
		--28 29 30 31 32
	{name="+1 Powder Value",func=function(c,a)return c+a end,cost=5,bonusVal="powder",info="Holding this makes Powders worth more."},
	{name="+10,000,000 Moo Value",func=function(c,a)return c+(10000000*a) end,cost=5,bonusVal="moo",info="Holding this makes Moos worth more."},
	{name="Blackhole Attractor",var=0.4,cost=-5,info="You are more likely to get a blackhole."},
	{name="Void Expanse",func=function(c)return math.abs(c) end,allowstore=true,cost=5,bonusVal="void",info="Voids are now positive value to you."},
	{name="Bankrupt",func=function(c)return -math.abs(c) end,allowstore=true,bonusVal="billion",info="Billions are now negative value to you."},

	--Event coupons
		--33 34 35
	{name="Missing No.",var=1,cost=15,info="&*$@#*@^%@()#$)@(#*$*`!&^@#*&)#@)$()*)("},
	{name="Cryptic Message",var=0.1,cost=15,info="Moooooo moooo moo mOOOoo"},
	{name="Bomb",var=1,cost=15,info="Execute './store bombdefuse' or ALL your coupons will explode!!!"},

	--Place new coupons below here for now
}
itemValueBonus = {}
for i,v in ipairs(couponList) do
	if v.bonusVal then
		itemValueBonus[v.bonusVal] = itemValueBonus[v.bonusVal] or {}
		table.insert(itemValueBonus[v.bonusVal],i)
	end
end

couponList = {
	--Usable Coupons
		--1 2 3
	{name="Purchase Discount I",var=0.05,cost=5,useFunc=1,info="Your next purchase is discounted!"},
	{name="Purchase Discount II",var=0.15,cost=5,useFunc=1,info="Your next purchase is discounted!"},
	{name="Purchase Discount III",var=0.25,cost=5,useFunc=1,info="Your next purchase is discounted!"},
		--4 5 6
	{name="Sell Bonus I",var=0.05,cost=5,useFunc=2,info="Your next sell is increased!"},
	{name="Sell Bonus II",var=0.15,cost=5,useFunc=2,info="Your next sell is increased!"},
	{name="Sell Bonus III",var=0.25,cost=5,useFunc=2,info="Your next sell is increased!"},
		--7 8 9 10
	{name="Flip Bonus I",var=-0.2,cost=5,useFunc=3,info="Your next flip is changed."},
	{name="Flip Bonus II",var=-0.1,cost=5,useFunc=3,info="Your next flip is changed."},
	{name="Flip Bonus III",var=0.1,cost=5,useFunc=3,info="Your next flip is changed."},
	{name="Flip Bonus IV",var=0.2,cost=5,useFunc=3,info="Your next flip is changed."},
		--11 12 13
	{name="Quiz Bonus I",var=0.1,cost=5,useFunc=4,info="Your next quiz will give more reward."},
	{name="Quiz Bonus II",var=0.2,cost=5,useFunc=4,info="Your next quiz will give more reward."},
	{name="Quiz Bonus III",var=0.3,cost=5,useFunc=4,info="Your next quiz will give more reward."},
		--14 15 16 17
	{name="Give Bonus I",var=10000,cost=5,useFunc=5,info="Being nice to people may help you."},
	{name="Give Bonus II",var=1000000,cost=5,useFunc=5,info="Being nice to people may help you."},
	{name="Give Bonus III",var=100000000,cost=5,useFunc=5,info="Being nice to people may help you."},
	{name="Give Bonus IV",var=10000000000,cost=5,useFunc=5,info="Being nice to people may help you."},
		--18
	{name="Whitehole",var=1,cost=5,info="Removes one blackhole on use. - 'Who knew the existence of whiteholes were coupons all along!'"},
	
	--Useless Coupons
		--19..27
	{name="Paper",var=1,cost=5,info="Just a blank piece of paper"},
	{name="Old Paper",var=1,cost=5,info="Just an old piece of paper"},
	{name="Wet Paper",var=1,cost=5,info="Just a wet piece of paper"},
	{name="Burnt Paper",var=1,cost=5,info="Just a burnt piece of paper"},
	{name="Outdated",var=1,cost=5,info="This was a great coupon, but it expired"},
	{name="+1 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	{name="+100 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	{name="+1,000,000 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	{name="+1,000,000,000,000 Nothing",var=1,cost=5,info="Wow, it's nothing."},
	
	--Permanent Effect Coupons
		--28 29 30 31 32
	{name="+1 Powder Value",func=function(c,a)return c+a end,cost=5,bonusVal="powder",info="Holding this makes Powders worth more."},
	{name="+10,000,000 Moo Value",func=function(c,a)return c+(10000000*a) end,cost=5,bonusVal="moo",info="Holding this makes Moos worth more."},
	{name="Blackhole Attractor",var=0.4,cost=-5,info="You are more likely to get a blackhole."},
	{name="Void Expanse",func=function(c)return abs(c) end,allowstore=true,cost=5,bonusVal="void",info="Voids are now positive value to you."},
	{name="Bankrupt",func=function(c)return -abs(c) end,allowstore=true,bonusVal="billion",info="Billions are now negative value to you."},
	
	--Event coupons
		--33 34 35
	{name="Missing No.",var=1,cost=15,info="&*$@#*@^%@()#$)@(#*$*`!&^@#*&)#@)$()*)("},
	{name="Cryptic Message",var=0.1,cost=15,info="Moooooo moooo moo mOOOoo"},
	{name="Bomb",var=1,cost=15,info="Execute './store bombdefuse' or ALL your coupons will explode!!!"},
	
	--Place new coupons below here for now
}
local itemValueBonus = {}
for i,v in ipairs(couponList) do
	if v.bonusVal then
		itemValueBonus[v.name] = itemValueBonus[v.name] or {}
		table.insert(itemValueBonus[v.name],i)
	end
end

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

--Add coupon to user : coup is the table index of coupon?
function addCoup(usr,coup,amt)
	gameUsers[usr.host].coupons = gameUsers[usr.host].coupons or {}
	local userC = gameUsers[usr.host].coupons
	if userC[coup] then
		userC[coup] = userC[coup] + amt
	else
		userC[coup] = amt
	end
end
function remCoup(usr,coup,amt)
	gameUsers[usr.host].coupons = gameUsers[usr.host].coupons or {}
	local userC = gameUsers[usr.host].coupons
	if userC[coup] then
		userC[coup] = userC[coup] - amt
		if userC[coup] <= 0 then userC[coup]=nil end
	end
end
--Returns first valid coupon and how many
function hasCoup(usr,...)
	gameUsers[usr.host].coupons = gameUsers[usr.host].coupons or {}
	local userC = gameUsers[usr.host].coupons
	for i,v in ipairs({...}) do
		if userC[v] then
			return v, userC[v]
		end
	end
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
local function addInv(usr,item,amt,store)
	gameUsers[usr.host].inventory = gameUsers[usr.host].inventory or {}
	local inv = gameUsers[usr.host].inventory
	local InvItem = inv[item.name]
	local coups = itemValueBonus[item.name]
	if coups then
		local change, cnum = hasCoup(usr,table.unpack(coups))
		if change and (not store or couponList[change].allowstore) then item.cost = couponList[change].func(item.cost,cnum) end
	end
	if InvItem then
		InvItem.cost = math.floor(((InvItem.cost*InvItem.amount) + item.cost*amt)/(InvItem.amount+amt))
		InvItem.amount = InvItem.amount+amt
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
ratelimit = ratelimit or {}
local peruserlimit = 500
local perusermutelimit = 600
local perchannellimit = 1750

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
					if v.cost > -1e300 then
						total = total + v.amount*v.cost
					end
				end
				usr.inventory = {}
				usr.cash = 1000
				addInv({host=host},{name="memento",cost=0,info="Lost memories of your past, you were apparently worth $"..nicenum(total),amt=1,instock=false},1)
			end
		end
	end
	if os.date("%M") == "00" then
		ratelimit = {}
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
		if not irc.channels[chan] or not irc.channels[chan].users then return "You fall into a bottomless void (-$500000)"..changeCash(usr, -500000) end
		local rnd = math.random(100)
		if rnd < 10 then
			-- prevent void from doing anything
			gameUsers[usr.host].inventory["void"].status = 1
		elseif rnd > 80 then
			-- void works again
			gameUsers[usr.host].inventory["void"].status = nil
		elseif gameUsers[usr.host].inventory["void"].status then
			local lostvoids = math.random(gameUsers[usr.host].inventory["void"].amount)
			remInv(usr, "void", lostvoids)
			return "The void implodes in on itself (-"..lostvoids.." voids)"
		end

		local maxCost = gameUsers[usr.host].inventory["void"].amount*gameUsers[usr.host].inventory["void"].cost*-1

		local userlist = {}
		for k,v in pairs(irc.channels[chan].users) do
			if gameUsers[v.host] and gameUsers[v.host].inventory then
				table.insert(userlist, v)
			end
		end
		local randomuser = userlist[math.random(#userlist)]

		local userinventory = {}
		for k,v in pairs(gameUsers[randomuser.host].inventory) do
			if v.cost > 0 and v.cost < maxCost and storeInventory[v.name] then
				table.insert(userinventory, v)
			end
		end
		if #userinventory == 0 then return randomuser.nick.." pushes you into a bottomless void (-$500000)"..changeCash(usr, -500000) end
		local randomitem = userinventory[math.random(#userinventory)]

		local destroyed = math.floor(maxCost/randomitem.cost)
		if destroyed > randomitem.amount then destroyed = randomitem.amount end
		local lostvoids = math.floor(destroyed*randomitem.cost/(5000*math.random(5,10)))
		if destroyed == 0 or lostvoids == 0 then
			return "You fall into a bottomless void (-$555555)"..changeCash(usr, -555555)
		end

		remInv(usr, "void", lostvoids)
		remInv(randomuser, randomitem.name, destroyed)
		return "The void sucks up "..destroyed.." of "..randomuser.nick.."'s "..randomitem.name.."s! (-"..lostvoids.." voids)"
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
			if #t>0 then
				local nom = t[math.random(#t)]
				remInv(usr, nom.name, 1)
				return "The junk expanded and ate your ".. nom.name .." (-1 ".. nom.name ..")"
			end
			remInv(usr,"junk",1)
			return "The junk expanded and ate itself (-1 junk)."
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
			if rnd < 100000 then
				return "You put on another pair of shoes. Why do they always go missing ... (-2 shoes)"
			else
				return "You sold your designer pair of shoes for $"..(rnd*10)..changeCash(usr,rnd*10)
			end
		end
		if math.random(1,20) == 1 then
			remInv(usr,"shoe",1)
			return "Your shoe gets worn out (-1 shoe)"
		else
			return "You found a wad of cash in your shoe!"..changeCash(usr,math.random(1,30000))
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
		for k,v in pairs(storeInventorySorted) do
			if v.instock and math.random(1,7) < 2 and v.cost>0 then
				name = v.name
				break
			end
		end
		if name == nil then
			return "You play Angry birds."
		elseif storeInventory[name].instock then
			local cost = math.floor(storeInventory[name].cost*(math.random()+.25))
			if cost < gameUsers[usr.host].cash then
				if cost > 10000000000 and gameUsers[usr.host].cash > 300000000000 and math.random()>.82 then
					remInv(usr,"iPad",1)
					addInv(usr,storeInventory["blackhole"],1)
					return "The app imploded into a blackhole while browsing, THANKS OBAMA! (-1 iPad, +1 blackhole)"
				end
				addInv(usr, storeInventory[name], 1)
				gameUsers[usr.host].inventory["iPad"].status = os.time()+math.floor((.6-cost/storeInventory[name].cost)*math.log(storeInventory[name].cost)^2)
				return "You bought a "..name.." on eBay for $"..cost..changeCash(usr,-cost)
			else
				return "You couldn't afford to buy "..name
			end
		else
			return "You couldn't find "..name.." on eBay"
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
			return "You sold lamp on eBay for "..amt.." (-1 lamp)"..changeCash(usr,amt)
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
	["doll"]=function(usr,args,chan)
		remInv(usr,"doll",1)
		if chan == "##powder-bots" then
			if string.lower(usr.nick):find("mitch") then
				ircSendRawQ("KICK "..config.primarychannel.." "..usr.nick)
				return "You stick a needle in the doll. Your leg starts bleeding and you die (-1 doll)"
			end
			local rnd = math.random(1,100)
			if rnd <= 50 then
				return "You find out the doll was gay and throw it away (-1 doll)"
			elseif rnd == 51 then
				-- TODO: wolfmitchel parted the channel ):
				ircSendRawQ("KICK "..chan.." wolfmitchell")
				return "You stick a needle in the doll. wolfmitchell dies (-1 doll)"
			else
				return "The doll looks so ugly that you burn it (-1 doll)"
			end
		else
			local rnd = math.random(1,100)
			if rnd <= 33 then
				return "You play with the doll. It tries burning your house down and runs away (-1 doll)"
			elseif rnd <= 66 then
				return "You play with the doll. It disintegrates. (-1 doll)"
			else
				return "The doll looks so ugly that you burn it (-1 doll)"
			end
		end
	end,
	["derp"]=function(usr)
		remInv(usr,"derp",1)
		local itemList, itemWeight, total = {}, {}, 0
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if v.cost >= -1000 and v.instock then
				table.insert(itemList,v)
				total = total + v.amount
				table.insert(itemWeight,total)
			end
		end
		if #itemList == 0 then
			return "You are a derp"
		end
		local item,rnd = nil,math.random(total)
		for i,v in ipairs(itemWeight) do
			if v >= rnd then
				item = itemList[i]
				break
			end
		end
		if not item then
			return "jacob1 is a derp"
		end
		rnd = math.random()
		--return total.." "..rnd.." : "..table.concat(itemWeight," ")
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
			remInv(usr,"potato",1)
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
				str = str..". The potato attacks you (-1 potato)"..changeCash(usr,-5000000)
				if irc.channels[chan].users[config.user.nick].access.op then
					ircSendRawQ("KICK "..chan.." "..usr.nick.." :"..str)
					return nil
				end
			end
			return str
		end
	end,
	--gold
	--[[["diamond"]=function(usr, args)
		local other = getUserFromNick(args[2])
		if other and other.nick ~= usr.nick then
			local rnd = math.random(1,100)
			if rnd < 25 then
				remInv(usr, "diamond", 1)
				addInv(other, storeInventory["diamond"], 1)
				return "You give your diamond ring to "..other.nick..". They accept it! You live happily ever after."
			elseif rnd < 40 then
				remInv(usr, "diamond", 1)
				rejectmessage = ""
				if gameUsers[usr.host].inventory["iPad"] and gameUsers[usr.host].inventory["iPad"].amount > 20 and math.random(1,3) == 1 then
					if rnd%5 == 0 then
						return "they don't like Apple fanboys."
					elseif rnd%6 == 0 then
						return "they hate angry birds."
					end
				elseif gameUsers[usr.host].inventory["company"] and gameUsers[usr.host].inventory["company"].amount > 5 and math.random(1,12) == 1 then
					return "they hate businessmen."
				end
			end
		end
	end,]]
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
					local amountLost = math.ceil(rnd/6)
					local amountgained = (math.floor(math.random(1,10))*4+1)*40000000
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
	["cube"] = function(usr,args,other)
		local rnd = math.random(26)
		if rnd <= 5 then
			return "You play with your Rubik's cube..."
		elseif rnd <= 10 then
			remInv(usr, "cube", 1)
			local amt = math.random(40,90)
			addInv(usr, storeInventory["water"], amt)
			return "You play with your cube, but it unfortunately melts. (-1 cube, +"..amt.." water)"
		elseif rnd <= 15 then
			remInv(usr, "cube", 1)
			return "The cube shatters and cuts your eye in the process. The medical costs were $20000. (-1 cube)" .. changeCash(usr, -20000)
		elseif rnd <= 20 then
			local amt = math.random(5,50)*10
			return "You solve the 4D Rubik's cube after months of deliberation and are awarded with a $"..amt.." prize." .. changeCash(usr, amt)
		elseif rnd <= 24 then
			remInv(usr, "cube", 1)
			return "You find out that the cube is evil and was actually plotting to start another ice age. Disgusted, you throw it away. (-1 cube)"
		else
			remInv(usr, "cube", 1)
			addInv(usr, storeInventory["billion"], 1)
			return "Your cube shatters into a billion pieces. (-1 cube, +1 billion)"
		end
	end,
	["estate"] = function(usr,args)
		local rnd = math.random(38)
		if rnd <= 5 then
			return "The sun shines on your grand estate. A new day has begun..."
		elseif rnd <= 10 then
			return "You gaze upon the lawns of your estate that seem to go on forever..."
		elseif rnd <= 16 then
			local amt = math.random(1,5)
			addInv(usr, storeInventory["house"], amt)
			local text = (amt == 1 and "a house" or "some houses")
			return "You build "..text.." on your estate. (+"..amt.." house"..(amt == 1 and "" or "s")..")"
		elseif rnd <= 22 then
			local houseCount = gameUsers[usr.host].inventory["house"] and gameUsers[usr.host].inventory["house"].amount or 0
			local bad = {"catches on fire", "spontaneously combusts", "gets eaten by termites", "magically disappears"}
			local randombad = bad[math.random(1, #bad)]
			if houseCount > 1 then
				remInv(usr, "house", 1)
				return "One of the houses on your estate " ..randombad..". (-1 house)"
			else
				local cost = storeInventory["house"].cost
				return "One of the houses on your estate " ..randombad..", and you are forced to pay the damages. (-$"..cost..")"..changeCash(usr, -cost)
			end
		elseif rnd <= 28 then
			local amt = (math.random(1,15) * 1000000)
			return "You collect rent from your tenants. (+$"..amt..")"..changeCash(usr, amt)
		elseif rnd <= 32 then
			local bad = {"angry aliens", "government spies", "hungry black holes", "angry tenants", "evil monsters"}
			local randombad = bad[math.random(1, #bad)]
			remInv(usr, "estate", 1)
			return "A group of "..randombad.." shows up on your estate and seizes it with force! (-1 estate)"
		else
			local potatoes = math.random(10, 60)
			local cows = math.random(2, 18)
			local cost = ((storeInventory["cow"].cost * cows) + (storeInventory["potato"].cost * potatoes))
			local subtractedcost = (cost * math.random(75, 125) / 100)
			if subtractedcost < gameUsers[usr.host].cash then
				addInv(usr, storeInventory["potato"], potatoes)
				addInv(usr, storeInventory["cow"], cows)
				return "You start a farm on your estate. However, this costs you some money to set up. (+"..cows.." cows, +"..potatoes.." potatoes, -$"..subtractedcost..")"..changeCash(usr, -subtractedcost)
			else
				return "You want to start a farm on your estate, but you realize you don't have enough money."
			end
		end
	end,
	["billion"] = function(usr,args)
		local other = getUserFromNick(args[2])
		if other and other.nick ~= usr.nick then
			local rnd = math.random(100)
			if rnd < 20 then
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
				if (otheritem.instock or otheritem.cost<0) and otheritem.cost<1e14 then
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
	["whitehole"] = function(usr, args)
		if hasCoup(usr,18) then
			if not gameUsers[usr.host].inventory["blackhole"] then
				return "I wouldn't want to use that without a blackhole."
			end
			remInv(usr,"blackhole",1)
			remCoup(usr,18,1)
			return "Whoosh, they both vanished."
		else
			return "You don't have that!"
		end
	end,
	["company"] = function(usr, args)
		local rnd = math.random(96)
		local other = getUserFromNick(args[2])
		if other and other.nick ~= usr.nick then
			if rnd < 20 then
				remInv(usr, "company", 1)
				addInv(other, storeInventory["company"], 1)
				local actions = {"eating potatoes", "ice cream", "apple products", "apocalypse preparations", "hugs", "donating to charity", "fighting terrorists", "drugs", "taking over foreign countries"}
				local randomaction = actions[math.random(1, #actions)]
				return "Shareholders, angry over "..usr.nick.."'s tendency to spend all company profits on "..randomaction..", revolt and select "..other.nick.." as the new CEO (-1 company)"
			else
				if other.nick == config.user.nick then return "You cannot sue the bot!" end
				local amt = math.random(1, 500000)
				if math.random() >= .5 then
					if amt > gameUsers[other.host].cash then amt = gameUsers[other.host].cash end
					changeCash(other, -amt)
					return "Your company sues "..other.nick.." for $" ..nicenum(amt).. " and wins!" .. changeCash(usr, amt)
				else
					changeCash(other, amt)
					return "Your company sues "..other.nick.." for $" ..nicenum(amt).. " and loses." .. changeCash(usr, -amt)
				end
			end
		end
		if rnd <= 30 then
			local items = {"derp", "vroom", "chips", "iPad", "powder", "cube", "lamp", "table"}
			local randomitem = items[math.random(1, #items)]
			local amt = math.random(1,1500)
			addInv(usr, storeInventory[randomitem], amt)
			-- Pluralize item names properly
			local name = randomitem..(randomitem:sub(-1) == "s" and "" or "s")
			return "Your company starts manufacturing " ..name.. " (+" .. amt .. " " .. name..")"
		elseif rnd <= 64 then
			local amt = math.random(1, 2000000000)
			return "Your company is making money. (+$" ..nicenum(amt).. ")" .. changeCash(usr, amt)
		elseif rnd <= 75 then
			local fines = {"illegally manufacturing iPads", "tax evasion", "violating competition laws", "money laundering", "selling defective products", "genocide"}
			local fine = fines[math.random(1, #fines)]
			local amt = math.random(1, 500000000)
			return "Your company is caught for " ..fine.. " and is given a hefty fine. (-$" ..nicenum(amt).. ")" ..changeCash(usr, -amt)
		elseif rnd <= 82 then
			local amt = math.random(1,9) * 100000000
			local amtjunk = math.random(1000,10000)
			addInv(usr, storeInventory["junk"], amtjunk)
			return "A mob of angry customers descends on your headquarters and loots the entire place, causing you many damages. (-$" ..nicenum(amt)..", +" ..amtjunk.." junk)"..changeCash(usr, -amt)
		elseif rnd <= 87 then
			local items = {"gold", "diamond", "billion"}
			local item = items[math.random(1, #items)]
			local amt = math.ceil(storeInventory["company"].cost / storeInventory[item].cost)
			local good = math.random(1, math.floor(amt/2))
			local bad = amt - good
			addInv(usr, storeInventory[item], good)
			addInv(usr, storeInventory["junk"], bad)
			remInv(usr, "company", 1)
			return "A clever conman comes by and tricks you into selling your company for the equivalent value in " ..item.. "s. Unfortunately, it turns out all but " ..good.. " of them were fake! (-1 company, +" ..good.. " " ..item..", +" ..bad.. " junk)"
		elseif rnd <= 93 then
			remInv(usr, "company", 1)
			return "Your company goes bankrupt after a freak accident. (-1 company)"
		else
			remInv(usr, "company", 1)
			addInv(usr, storeInventory["country"], 1)
			local countries = {"The United States", "China", "Russia", "Somalia", "The Democratic People's Republic of Korea", "Texas", "Greece", "Thailand", "Japan", "New Zealand", "Indonesia", "Kenya", "Spain", "Macedonia"}
			local randomcountry = countries[math.random(1, #countries)]
			return "Your company becomes so powerful that it buys "..randomcountry.." (-1 company) (+1 country)"
		end
	end,
	['antiPad'] = function(usr,args)
		return "You play Angry Birds."
	end,
}

local function useItem(usr,chan,msg,args)
	if not args[1] then
		return "Need to specify an item! '/use <item>'"
	end
	if chan:sub(1,1) ~= "#" then
		return "This command must be run in a channel"
	end
	if usr.host then
		ratelimit[usr.host] = ratelimit[usr.host] and ratelimit[usr.host] + 1 or 1
		if ratelimit[usr.host] == perusermutelimit then
			ircSendRawQ("MODE "..chan.." +q :*!*@"..usr.host)
			return "Error: You have been muted due to excessive spam"
		elseif ratelimit[usr.host] > peruserlimit then
			return "Error: You have been spamming ./use too often, please wait an hour"
		end
	end
	ratelimit[chan] = ratelimit[chan] and ratelimit[chan] + 1 or 1
	if ratelimit[chan] > perchannellimit then
		return "Error: this command has been temporarily disabled due to spam, please wait an hour"
	end
	local item = itemName(args[1])
	--Cheap coupon use area for now.
	if item=="whitehole" then
		return itemUses[item](usr,args,chan)
	end
	if not gameUsers[usr.host].inventory[item] or gameUsers[usr.host].inventory[item].amount<=0 then
		return "You don't have that item!"
	elseif itemUses[item] and gameUsers[usr.host].inventory[item] then
		return itemUses[item](usr,args,chan)
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
		return "You have $"..nicenum(cash).." including items."
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
	local res = math.random()
	local bonus = hasCoup(usr,7,8,9,10)
	if bonus then res = res + couponList[bonus].var remCoup(usr,bonus,1) end
	if res>.5 then
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
	
	door = door[1] or "" --do something with more args later?
	if door == "secret" then return "http://starcatcher.us:54329/Door" end
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
		item=itemName(args[2])
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
		addInv({host=toHost},{name=i.name,cost=i.cost,info=i.info,amount=1,instock=i.instock},amt,true)
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
	local command = args[1]:lower()
	if command=="list" then
		local t={}
		for k,v in pairs(storeInventorySorted) do
			if v.instock and gameUsers[usr.host].cash>=v.cost then table.insert(t,"\15"..v.name.."\00309("..nicenum(v.cost)..")") end
		end
		return table.concat(t," ")
	end
	if command=="info" then
		if not args[2] then return "Need an item! 'info <item>'" end
		local item = itemName(args[2])
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if k==item then return "Item: "..k.." ("..v.amount..") Cost: $"..nicenum(v.cost).." Info: "..v.info end
		end
		for k,v in pairs(storeInventory) do
			if k==item then return "Item: "..k.." Cost: $"..nicenum(v.cost).." Info: "..v.info end
		end
		return "Item not found"
	end
	if command=="buy" then
		if not args[2] then return "Need an item! 'buy <item> [<amt>]'" end
		local item = itemName(args[2])
		local amt = math.floor(tonumber(args[3]) or 1)
		if amt==amt and amt>0 then
			local v = copyTable(storeInventory[item])
			if v and v.instock then
				--New Coupon discounts!
				local discount = hasCoup(usr,1,2,3)
				if discount then v.cost = v.cost * (1-couponList[discount].var) remCoup(usr,discount,1) end

				local cost = v.cost*amt

				if gameUsers[usr.host].cash - cost >= 0 then
					changeCash(usr, -cost)
					addInv(usr, v, amt, true)
					return "You bought "..nicenum(amt).." "..v.name.." for $"..cost
				else
					return "Not enough money!"
				end
			end
		end
		return "Item not found"
	end
	if command=="inventory" then
		local invnames = {}
		for k,v in pairs(gameUsers[usr.host].inventory) do
			invnames[v.name] = true
		end
		local t = {}
		for k,v in pairs(storeInventorySorted) do
			if invnames[v.name] then
				table.insert(t, v.name.."("..gameUsers[usr.host].inventory[v.name].amount..")")
			end
		end
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if not storeInventory[k] then
				table.insert(t, v.name.."("..v.amount..")")
			end
		end
		if #t > 0 then
			return "You have: "..table.concat(t,", ")
		else
			return "You have no items ):"
		end
	end
	if command=="sell" then
		if not args[2] then return "Need an item! 'sell <item> [<amt>] [<item2> [<amt2>]]...'" end
		local sold, rstring, totalSold = false, "Sold ", 0
		local i=2
		while args[i] do
			local item = itemName(args[i])
			local amt = math.floor(tonumber(args[i+1]) or 1)
			if tonumber(args[i+1]) then i=i+1 end
			if amt==amt and amt>0 then
				local v = gameUsers[usr.host].inventory[item]
				if v and v.amount>=amt then
					local value = v.cost*amt
					--New Coupon Bonus
					local discount = hasCoup(usr,4,5,6)
					if discount then value = value * (1+couponList[discount]) remCoup(usr,discount,1) end

					if v.cost<0 and gameUsers[usr.host].cash < -value then return "You can't afford that!" end
					changeCash(usr,value)
					remInv(usr,item,amt)
					rstring = rstring..nicenum(amt).." "..v.name..", "
					totalSold = totalSold + value
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
	if command=="sellall" then
		local sellList, rstring, totalSold = {}, "", 0
		--Only sellall INSTOCK positive items
		for k,v in pairs(gameUsers[usr.host].inventory) do
			if v.instock and v.cost >= 0 then table.insert(sellList,v) end
		end
		if #sellList == 0 then return "You don't have any items to 'sellall'" end
		for i,v in ipairs(sellList) do
			changeCash(usr,v.cost*v.amount)
			rstring = rstring..nicenum(v.amount).." "..v.name..", "
			totalSold = totalSold + (v.cost*v.amount)
			remInv(usr,v.name,v.amount)
		end
		return "Sold "..rstring.."for $"..totalSold
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
	if bet > 100000000000 then
		return "You cannot bet more than 100 billion"
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
		if nchan==chan then
			if nmsg==answer and not alreadyAnswered[nusr.host] then
				local answeredIn= os.time()-activeQuizTime[qName]-1
				if answeredIn <= 0 then answeredIn=1 end
				local earned = math.floor(bet*(prizeMulti+(math.sqrt(1.1+1/answeredIn)-1)*3))
				--Quiz Coupon Answer Bonus
				local discount = hasCoup(nusr,11,12,13)
				if discount then earned = earned * (1+couponList[discount]) remCoup(usr,discount,1) end

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

local function loadUsers()
	local t= table.load("userData.txt")
	setmetatable(t,{__index=function(t,k) t[k]={cash=1000, lastDoor=os.time(), winStreak=0, loseStreak=0, maxWinStreak=1, maxLoseStreak=1, lastGameWon=nil, inventory={}} return t[k] end})
	return t
end
gameUsers = gameUsers or loadUsers()

local storeInventory={
["powder"]=	{name="powder",	cost=5,info="It's some kind of powder...",amount=1,instock=true},
["chips"]=	{name="chips",	cost=50,info="Baked Lays.",amount=1,instock=true},
["shoe"]=	{name="shoe",	cost=200,info="One shoe, why is there only one?",amount=1,instock=false},
["iPad"]=	{name="iPad",	cost=499,info="A new iPad.",amount=1,instock=true},
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
["house"]=	{name="house",	cost=50000000,info="A decent size mansion.",amount=1,instock=false},
["cracker"]={name="cracker",cost=100000000,info="Just in-case anyone ever rolls this high.",amount=1,instock=false},
}

--make function hook to reload user cash
local function loadUsersCMD()
	gameUsers = loadUsers()
end
local function saveUsers()
	table.save(gameUsers,"userData.txt")
end
--make a timer loop save users every minute, errors go to me
local function timedSave()
	saveUsers()
	addTimer(timedSave,60,"cracker64","gameSave")
end
remTimer("gameSave")
addTimer(timedSave,60,"cracker64","gameSave")

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

--change cash, that resets if 0 or below
local function changeCash(usr,amt)
	if amt ~= amt then
		return " Invalid amount, no money changed"
	end
	gameUsers[usr.host].cash = gameUsers[usr.host].cash + amt
	if gameUsers[usr.host].cash <= 0 then
		gameUsers[usr.host].cash = 1000
		return " You went bankrupt, money reset"
	end
	return " ($"..gameUsers[usr.host].cash.." now)"
end

--add item to inventory, creating if not exists
local function addInv(usr,item)
	gameUsers[usr.host].inventory = gameUsers[usr.host].inventory or {}
	local inv = gameUsers[usr.host].inventory
	if inv[item.name] then
		inv[item.name].amount = inv[item.name].amount+1
	else
		inv[item.name]= {name=item.name,cost=item.cost,info=item.info,amount=item.amount,instock=item.instock}
	end
end
local function remInv(usr,name)
	gameUsers[usr.host].inventory = gameUsers[usr.host].inventory or {}
	local inv = gameUsers[usr.host].inventory
	if inv[name] then
		inv[name].amount = inv[name].amount-1
		if inv[name].amount<=0 then inv[name]=nil end
	end
end

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

--User cash
local function myCash(usr)
	return "You have $"..gameUsers[usr.host].cash
end
--give money
local function give(fromHost,toHost,amt)
	if gameUsers[fromHost].cash-amt <= 100000 then
		return "You can only give if you have over 100k left"
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
	door = door[1] or "" --do something with more args later?
	local isNumber=false
	local randMon = 50
	local divideFactor = 2
	if door:find("moo") then divideFactor=2.5 end
	local adjust =  os.time()-(gameUsers[usr.host].lastDoor or os.time())
	randMon = randMon+adjust*5--get higher for waiting longer
	gameUsers[usr.host].lastDoor = os.time()

	if tonumber(door) then
		if tonumber(door)>15 and (tonumber(door)<=adjust+1 and tonumber(door)>=adjust-1) then randMon=randMon+(adjust*50) divideFactor=5 end
		isNumber=true
	end
	--blacklist of people
	--if (string.lower(usr.nick)):find("mitchell_") then divideFactor=1 end
	--if (string.lower(usr.nick)):find("boxnode") then divideFactor=1 end
	--some other weird functions to change money

	--randomly find items
	local fitem = math.random(9)
	if fitem==1 then fitem=true else fitem=false end
	
	local minimum = math.floor(randMon/divideFactor)
	local randomnes = math.random(randMon)-minimum
	local rstring=""
	if fitem and randomnes>0 then
		--find an item of approximate value
		local item = findClosestItem(randomnes)
		rstring = "You found a "..item.name.."! Added to inventory, see the store to sell"
		addInv(usr,item)
	else
		fitem=false
		rstring = changeCash(usr,randomnes)
	end
	if fitem then
		streak(usr,true)
		return rstring
	elseif randomnes<0 then
		streak(usr,false)
		return "You lost $" .. -randomnes .. " (-"..minimum.." to "..(randMon-minimum)..")!"..rstring
	elseif randomnes==0 then
		return "The door is broken, try again"
	end
	streak(usr,true)
	return "You found $" .. randomnes .. " (-"..minimum.." to "..(randMon-minimum)..")!"..rstring
end

--GAME command hooks
--CASH
local function myMoney(usr,chan,msg,args)
	if args then
		if args[1]=="stats" then
			return "WinStreak: "..gameUsers[usr.host].maxWinStreak.." LoseStreak: "..gameUsers[usr.host].maxLoseStreak
		end
	end
	return myCash(usr)
end
add_cmd(myMoney,"cash",0,"Your current balance, '/cash [stats]', Sending stats will show some saved stats.",true)
--GIVE
local function giveMon(usr,chan,msg,args)
	if not args[2] then return "Usage: '/give <username> <amount>'" end
	local toHost
	local amt = math.floor(tonumber(args[2]) or 0)
	if chan:sub(1,1)~='#' then
		if args[1]:sub(1,1)=='#' then
			if string.lower(args[2])==string.lower(usr.nick) then return "You can't give to yourself..." end
			toHost = getBestHost(args[1],args[2])
			if toHost~=args[2] then toHost=toHost:sub(5)
			else return "Invalid user, or not online"
			end
			amt = math.floor(tonumber(args[3]) or 0)
		else
			return "Channel required in query, '/give <chan> <username> <amount>'"
		end
	else
		toHost = getBestHost(chan,args[1])
		if string.lower(args[1])==string.lower(usr.nick) then return "You can't give to yourself..." end
		if toHost~=args[1] then toHost=toHost:sub(5)
		else return "Invalid user, or not online"
		end
	end

	if amt and amt>0 and amt==amt then
		return give(usr.host,toHost,amt)
	else
		return "Bad amount!"
	end
end
add_cmd(giveMon,"give",0,"Give money to a user, '/give <username> <amount>', need over 100k to give.",true)
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
add_cmd(flipCoin,"flip",0,"Flip a coin with a bet, '/flip <bet>', 50% chance to win double",true)
--DOOR
local function odor(usr,chan,msg,args)
	return odoor(usr,args)
end
add_cmd(odor,"door",0,"Open a door, '/door <door>', No one knows what will happen",true)

--STORE, to buy somethings?
local function store(usr,chan,msg,args)
	if not msg  or args[1]=="help" then
		return "Welcome to the CrackStore, use '/store list' or '/store info <item>' or '/store buy <item>' or '/store sell [<item>]' will list your items."
	end
	if args[1]=="list" then
		local t={}
		for k,v in pairs(storeInventory) do
			if v.instock then table.insert(t,"\15"..v.name.."\00309("..v.cost..")") end
		end
		return table.concat(t," ")
	end
	if args[1]=="info" then
		if not args[2] then return "Need an item! 'info <item>'" end
		local item = args[2]
		for k,v in pairs(storeInventory) do
			if k==item then return "Item: "..k.." Cost: $"..v.cost.." Info: "..v.info end
		end
		return "Item not found"
	end
	if args[1]=="buy" then
		if not args[2] then return "Need an item! 'buy <item>'" end
		local item = args[2]
		for k,v in pairs(storeInventory) do
			if k==item and v.instock then
				if gameUsers[usr.host].cash-v.cost>=0 then
					changeCash(usr,-v.cost)
					addInv(usr,v)
					return "You bought "..k
				else
					return "Not enough money!"
				end
			end
		end
		return "Item not found"
	end
	if args[1]=="sell" then
		if not args[2] then
			local t={}
			for k,v in pairs(gameUsers[usr.host].inventory) do
				table.insert(t,v.name.."("..v.amount..")")
			end
			return "You have, "..table.concat(t,", ")
		end
		local item = args[2]
		for k,v in pairs(gameUsers[usr.host].inventory or {}) do
			if v.name==item then
				changeCash(usr,v.cost)
				remInv(usr,k)
				return "Sold "..v.name.." for $"..v.cost
			end
		end
		return "You don't have that!"
	end
end
add_cmd(store,"store",0,"Browse the store, '/store list/info/buy/sell'",true)

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
		local randMod = math.random(40)
		if randMod<=15 then --subtract
			intro="What is "..extraNumber.." minus the number of"
			answer = extraNumber-answer
			multiplier=0.85
		elseif randMod<=22 then --Multiply
			extraNumber = extraNumber%200
			intro="What is "..extraNumber.." times the number of"
			answer = extraNumber*answer
			timeout,multiplier = 40,1.1
		elseif randMod==23 then --addition AND multiply
			extraNumber = extraNumber
			local extraNum2 = math.random(200)-1
			intro="What is "..extraNumber.." plus "..extraNum2.." times the number of"
			answer = extraNumber + (extraNum2*answer)
			timeout,multiplier = 50,1.3
		elseif randMod==24 then --subtraction AND multiply
			extraNumber = extraNumber
			local extraNum2 = math.random(200)-1
			intro="What is "..extraNumber.." minus "..extraNum2.." times the number of"
			answer = extraNumber - (extraNum2*answer)
			timeout,multiplier = 50,1.3
		else --add
			intro="What is "..extraNumber.." plus the number of"
			answer = answer+extraNumber
			multiplier=0.85
		end
	end
	return intro.." ' "..countChar.." ' in: "..table.concat(t,""),tostring(answer),timeout,multiplier
end,
isPossible= function(s) --this question only accepts number answers
	if tonumber(s) then return true end
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
	if not msg or not tonumber(args[1]) then return "Start a question for the channel, '/quiz <bet>'" end
	local qName = chan.."quiz"
	if activeQuiz[qName] then return "There is already an active quiz here!" end
	local bet=tonumber(args[1])
	if chan:sub(1,1)~='#' then if bet>10000 then return "Quiz in query has 10k max bid" end end
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
	activeQuiz[qName],activeQuizTime[qName] = true,os.time()
	local alreadyAnswered={}
	--insert answer function into a chat listen hook
	addListener(qName,function(nusr,nchan,nmsg)
		--blacklist of people
		--if nusr.host=="Powder/Developer/jacob1" then return end
		if nusr.host=="gprs-inet-65-130.elisa.ee" then return end
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

	return rstring
end
add_cmd(quiz,"quiz",0,"Start a question for the channel, '/quiz <bet>' First to answer correctly wins a bit more, only your first message is checked.",true)

--ASK a question, similar to quiz, but from a user in query
local function ask(usr,chan,msg,args)
	if chan:sub(1,1)=='#' then return "Can only start question in query." end
	if not msg or not args[3] then return "Ask a question to a channel, '/ask <channel> <question> <mainAnswer> [<altAns...>]' No prize, It will help to put \" around the question and answer." end
	local toChan = args[1]
	local qName = toChan.."ask"
	if activeQuiz[qName] then return "There is already an active question there!" end
	local rstring,answer,timer = "Question from "..usr.nick..": "..args[2],args[3],30
	local answers= {}
	for i=3,#args do
		answers[args[i]]=true
	end
	activeQuiz[qName] = true
	--insert answer function into a chat listen hook
	addListener(qName,function(nusr,nchan,nmsg)
		if nchan==toChan and answers[nmsg] then
			ircSendChatQ(toChan,nusr.nick..": "..nmsg.." is correct, congratulations!")
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
add_cmd(ask,"ask",0,"Ask a question to a channel, '/ask <channel> <question> <mainAnswer> [<altAns...>]' No prize, It will help to put \" around the question and answer.",true)

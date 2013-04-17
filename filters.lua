filters = {}
local function add_filt(f,name,sane,help)
	filters[name] = { f=f, sanity=sane or function() return true end,helptext = help}
end
local allColors = {'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15',white='00', black='01', blue='02', green='03', red='04', brown='05', purple='06', orange='07', yellow='08', lightgreen='09', turquoise='10', lightblue='11', skyblue='12', lightpurple='13', gray='14', lightgray='15'}
allColors[0]='00'
local rainbowOrder = {'04','07','08','03','02','12','06'}
local cchar = '\003'
--returns a table with data about where color codes are, might not be correct at all, old
local function tableColor(text)
	local t = {}
	local i = 0 --amount of color chars deleted
	local d = 0 --amount deleted
	local startOf = true
	while true do
		local st3,en3,cap3 = text:find("(\003%d%d?,%d%d?)",1)
		local st2,en2,cap2 = text:find("(\003%d%d?)",1)
		local st,en,cap = text:find("(\003)",1)
		local short=false
		if not en then break end --smallest check

		if st3 and st3==st then
			en=en3 cap=cap3 --first x03 is longest
		elseif st2 and st2==st then
			en=en2 cap=cap2 --first x03 is medium
		else --else first x03 is x03
			short=true
		end
		text = text:sub(en+1)
		local skip=false
		if startOf then
			if st==1 and short then 
				skip=true 
			end
			startOf=false
		end
		if not skip then
			local ending,_ = text:find("(\003)",1)
			ending = ending or 99999
			table.insert(t,{["start"]=st+d-i,["en"]=st+ending+d-i-2,["col"]=cap})
		end
		i = i + #cap
		d = d+en
	end
	return t
end
--COLORSTRIP strips colors
local function colorstrip(text)
	local newstring = text:gsub("\003%d%d?,%d%d?","") --remove colors with backgrounds
	newstring = newstring:gsub("\003%d%d?","") --remove normal
	newstring = newstring:gsub("\003","") --remove extra \003
	return newstring
end
add_filt(colorstrip,"colorstrip",nil,"Strips color from text, '/colorstrip <text>'")
--RAINBOW every letter is new color
local function rainbow(text)
	local newtext= ""
	local rCount=1
	for char in colorstrip(text):gmatch(".") do
		newtext = newtext .. cchar .. rainbowOrder[rCount] .. char
		rCount = ((rCount)%(#rainbowOrder))+1
	end
	newtext = newtext .. cchar --end with color clear
	return newtext
end
add_filt(rainbow,"rainbow",nil,"Rainbows! '/rainbow <text>'")
--COLOR add color to a line or section of line
local function color(text,args)
	local newstring
	text = colorstrip(args.str or text)
	--print(text:sub(1,args.start-1) .. cchar .. args[1] .. text:sub(args.start,args.en-1) .. cchar .. text:sub(args.en))
	if args.start then --TODO preserve outside colors
		newstring =  text:sub(1,args.start-1) .. cchar .. args.col .. text:sub(args.start,args.en-1) .. cchar .. text:sub(args.en)
	else
		newstring = cchar .. args.col .. text
	end
	return newstring
end
local function colorsane(args)
	if args then
		local _,_,c1,c2 = args[1]:find("^(%w-),(%w-)$") --backgrounds
		if not c1 then _,_,c1 = args[1]:find("^(%w-)$")end --normal
		local nc1 = allColors[c1] or allColors[tonumber(c1)]
		local nc2 = allColors[c2] or allColors[tonumber(c2)]
		if (c1 and not nc1) or (c2 and not nc2) then
			return false,"Invalid color parameter (0-15)"
		end
		args.col = ""
		if c1 then args.col = args.col .. nc1
			if c2 then args.col = args.col .. ","..nc2 end
		end
		if args[2] and args[3] and tonumber(args[2]) and tonumber(args[3]) and tonumber(args[3]) >= tonumber(args[2]) then
			args.start = tonumber(args[2])
			args.en = tonumber(args[3])
			local t={}
			for i=4, #args do
				table.insert(t,args[i])
			end
			local str = table.concat(t," ")
			if str~="" then args.str=str end
			return true
		else
			local t={}
			for i=2, #args do
				table.insert(t,args[i])
			end
			local str = table.concat(t," ")
			if str~="" then args.str=str end
		end
		return true
	else
		return false,"Need a color arg (0-15)"
	end
end
add_filt(color,"color",colorsane,"Set to a specific color: '/color <col1>[,<col2>] [<startx> <endx>] <text>'")

--REVERSE reverses string while moving color codes
local function reverse(text)
	local t = tableColor(text)
	local bt = {}
	local rstring = string.reverse(colorstrip(text))
	local tempstring = ""
	local index=#rstring
	for char in rstring:gmatch(".") do
		local code=""
		for i,v in ipairs(t) do
			if (v.en)>=index then
				code=v.col
				v.en = -1
				break
			end
		end
		index = index-1
		tempstring = tempstring .. code .. char
	end
	return tempstring
end
--mniips *slightly* better reverse
function reverse2(text)
	local text=text:gsub("\3(%d?%d?)(,?)(%d?%d?)",function(a,b,c)
				     if #a==0 then return "\3\0\0,\0\0"..b..c end
				     if #c==0 or #b==0 then return "\3"..a..",\0\0"..b..c end
				     return "\3"..a..b..c end)
	local t={}
	for s,a,b,p in text:gmatch"()\3([%d%z][%d%z]?),([%d%z]?[%d%z]?)()" do
		a,b=tonumber(a) or -1,tonumber(b)or -1
		table.insert(t,{s,p,a,b})
	end
	for s,p in text:gmatch"()\15()" do
		table.insert(t,{s,p,-1,-1})
	end
	table.sort(t,function(a,b)return a[1]<b[1]end)
	table.insert(t,1,{0,1,-1,-1})
	table.insert(t,{#text+1,#text+2})
	local c={}
	local lastbg=-1
	for i=1,#t-1 do
		local a,b=t[i][3],t[i][4]
		if a==-1 then lastbg=-1 end
		if b~=-1 then lastbg=b end
		table.insert(c,{text:sub(t[i][2],t[i+1][1]-1),a,lastbg})
	end
	local s=""
	for i=#c,1,-1 do
		if c[i][2]==-1 then
			s=s.."\15"..c[i][1]:reverse()
		elseif c[i][3]==-1 then
			s=s.."\3"..("%02d"):format(c[i][2])..c[i][1]:reverse()
		else
			s=s.."\3"..("%02d,%02d"):format(c[i][2],c[i][3])..c[i][1]:reverse()
		end
	end
	return s
end
add_filt(reverse2,"reverse",nil,"Reverses text, '/reverse <text>'")
--add_filt(reverse,"oldreverse",nil,"Reverses text, '/reverse <text>'")

--SCRAMBLE, scrambles letters inside each word
local function scramble(text,args)
	local rstring
	local words={}
	if args.skip then args = getArgs(text) end
	for k,word in pairs(args) do
		if #word>2 then
			local b,s,e = word:match("^(.)(.-)(.)$")
			local t={}
			if b and s and e then
				for char in s:gmatch(".") do
					table.insert(t,char)
				end
				local n=#t
				while n >= 2 do
					local k = math.random(n)
					t[n], t[k] = t[k], t[n]
					n = n - 1
				end
				word = b.. table.concat(t,"")..e
			end
		end
		table.insert(words,word)
		rstring = table.concat(words," ")
	end
	return rstring
end
local function scrambSane(args,filt)
	if filt then args.skip=true end
	return true
end
add_filt(scramble,"scramble",scrambSane,"Scrambles words, '/scramble <text>'")

--Pattern filter
local function patF(text,args)
	if not args.skip then text = args.str end
	return (text:gsub(args.pat,args.repl)):sub(1,500) or "" --prevent huge messages
end
local function patFSane(args,filt)
	args.pat = args[1]
	args.repl = args[2]
	local t={}
	for i=3,#args do
		table.insert(t,args[i])
	end
	args.str = table.concat(t," ")

	if not args.pat or not args.repl then
		return false,"Bad parameters, '/pattern <pat> <repl>'"
	end
	if filt then args.skip=true end
	return true
end
add_filt(patF,"pattern",patFSane,"Performs a gsub on text, '/pattern <patt> <repl> <text>'")

--BRAINFUCK filter
function toBF(str)
	return str
end
local function brainF(text,args)
	return toBF(text)
end
--add_filt(brainF,"bf")

--HEX and UNHEX
function hexStr(str,spacer)
	return (string.gsub(str,"(.)",
			    function (c)
				    return string.format("%02X%s",string.byte(c), spacer or "")
			    end)
	       )
end
function unHexStr(str)
	return string.gsub(str, '(%x%x)', function(value) return string.char(tonumber(value, 16)) end)
end
local function hexlify(text,args)
	text = text or ""
	return hexStr(text,"")
end
add_filt(hexlify,"hex",nil,"Convert to hex, '/hex <text>'")
local function unhexlify(text,args)
	text = text or ""
	return unHexStr(text)
end
add_filt(unhexlify,"unhex",nil,"Convert hex to chars, '/unhex <text>'")
--CAPS
function toCaps(text,args)
	return string.upper(text)
end
add_filt(toCaps,"caps",nil,"CAPITALIZES TEXT, '/CAPS <TEXT>'")
function toLower(text,args)
	return string.lower(text)
end
add_filt(toLower,"nocaps",nil,"turns text to lowercase, '/nocaps <text>'")

--function to let filters sanity check some args for direct calls
function callFilt(f,sanf,filt)
	return function(usr,chan,msg,args)
		local args = args
		if not msg then return end
		local s,err = sanf(args,filt) --allow filter to sanity check args before running
		if s then
			ircSendChatQ(chan,usr.nick .. ": "..f(msg,args))
		else
			ircSendChatQ(chan,usr.nick .. ": ".. err)
		end
	end
end

--FILTER main command, set filter for output
local function filter(usr,chan,msg,args)
	if msg=="current" then
		ircSendChatQ(chan,getFilts(chan),true)
		return nil
	elseif msg=="list" then
		local t = {}
		for k,v in pairs(filters) do
			table.insert(t,k)
		end
		return "Filters: "..table.concat(t,", ")
	elseif msg=="lock" then
		local perm = permFullHost(usr.fullhost)
		if perm > 20 then
			filtLock(chan)
			return "Locked "..chan
		else
			return "No permissions to lock"
		end
	elseif msg=="unlock" then
		local perm = permFullHost(usr.fullhost)
		if perm > 20 then
			filtUnLock(chan)
			return "Unlocked "..chan
		else
			return "No permission to unlock"
		end
	elseif not msg then
		if clearFilter(chan) then
			return "Cleared Filts"
		end
		return chan.." is locked"
	end
	local name=table.remove(args,1)
	args.name=name
	if filters[name] then
		local s,err = filters[name].sanity(args,true) --allow filter to sanity check args before adding
		if s then
			if addFilter(chan,filters[name].f,name,args) then
				return "Filter added: "..name
			else
				return chan.." is locked"
			end
		else
			return usr.nick .. ": ".. err
		end
	else
		return "No filter named "..name
	end
end
add_cmd(filter,"filter",0,"Set a filter, '/filter <filtName>/list/current [<arguments to filter>]', no argument to clear",true)

--add sub commands to call filters directly
for k,v in pairs(filters) do
	add_cmd(callFilt(v.f,v.sanity),k,0,v.helptext,false)
end

--BADWORD filter, hopefully always active, uses my terrible color table to re-add
--possibly save this list to file
local badlist= {"nigger","yolo","^;","^%%"}
local function badWords(text)
	local t = tableColor(text)
	local nocol = colorstrip(text)
	local amt = 0
	for k,word in pairs(badlist) do
		local nonocol,newamt = (nocol):gsub(word,function(s) return ("*")*#s end)
		nocol,amt = nonocol, amt+newamt
	end
	local tempstring = ""
	if #t>0 then
		local index=0
		for char in nocol:gmatch(".") do
			local code=""
			for i,v in ipairs(t) do
				if (v.start)<=index+1 then
					code=v.col
					v.start = 99999
					break
				end
			end
			index = index+1
			tempstring = tempstring .. code .. char
		end
	elseif amt>0 then
		tempstring = nocol
	else
		tempstring = text
	end
	return tempstring
end
local function addBadWord(text)
	for k,v in pairs(badlist) do
		if v==text then
			return "Bad word already exists"
		end
	end
	table.insert(badlist,text)
	return "Added bad word"
end
local function remBadWord(text)
	for k,v in pairs(badlist) do
		if v==text then 
			table.remove(badlist,k)
			return "Bad word removed"
		end
	end
	return "Bad word not found"
end
setBadWordFilter(badWords)

--command hook for badword
local function badWord(usr,chan,msg,args)
	if not args[2] then return "Usage: badword add/rem <word>" end
	if args[1] == "add" then
		return usr.nick .. ": " .. addBadWord(args[2])
	elseif args[1] == "rem" then
		return usr.nick .. ": " .. remBadWord(args[2])
	end
	return "Usage: badword add/rem <word>"
end
add_cmd(badWord,"badword",20,"Set or remove bad words, '/badword add/rem <word>'",true)

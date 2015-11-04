module("filters", package.seeall)

local filters = {}
local activeFilters = {}
local badWordFilt = nil
local bannedChans = {['nickserv']=true,['chanserv']=true,['memoserv']=true}
setmetatable(activeFilters,{__index = function(t,k) t[k]={t = {},lock = false} return t[k] end})
local function add_filt(f,name,sane,help,level)
	filters[name] = { f=f, sanity=sane or function() return true end,helptext = help,level=level or 0}
end
local function chatFilter(chan,text)
	if bannedChans[chan:lower()] then error("Bad chan") end
	local oldtext, status = colorstrip(text), true
	for k,v in pairs(activeFilters[chan].t) do
		status, text = pcall(v.f,text,v.args,true)
		if text then
			if type(text)=="table" then
				for k,v in pairs(text) do
					ircSendChatQ(chan,v,true)
				end
				
				return chan,''
			end
			text = text:sub(1,4450)
		end
	end
	if not status then
		text = "Error in filter: "..text
		table.remove(activeFilters[chan].t)
	end
	if #colorstrip(text) > 100 and #colorstrip(text) > 2*#oldtext then
		text = "Error, filter too long"
		table.remove(activeFilters[chan].t)
	end
	--don't censor query
	if badWordFilt and chan:sub(1,1)=='#' then text = badWordFilt(text) end
	return chan,text
end
remSendHook("filter")
addSendHook(chatFilter,"filter")

--show active filters
local function getFilts(chan)
	local t={}
	for k,v in pairs(activeFilters[chan].t) do
		table.insert(t, v.name .. " " .. table.concat(v.args," ") )
	end
	local text = table.concat(t,"> ") or ""
	print(text)
	return "in > "..text .. "> out"
end
--add new filter
local function addFilter(chan,filt,name,args)
	if type(filt)=='function' then
		if not activeFilters[chan].lock then
			table.insert(activeFilters[chan].t,{['f']=filt,['name']=name,['args']=args})
			return true
		end
		return false
	end
end
--clear filter
local function clearFilter(chan)
   	if not activeFilters[chan].lock then
		activeFilters[chan].t={}
		return true
	end
	return false
end
--remove last filter
local function popFilter(chan)
	local chanF = activeFilters[chan]
	if not chanF.lock and #chanF.t>0 then
		table.remove(chanF.t,#chanF.t)
		return true
	end
	return false
end
--kill all filters, for errors
local function clearAllFilts()
	for k,v in pairs(activeFilters) do
		v.t = {}
	end
end
local function filtLock(chan)
	activeFilters[chan].lock = true
end
local function filtUnLock(chan)
	activeFilters[chan].lock = false
end

local allColors = {'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15',white='00', black='01', blue='02', green='03', red='04', brown='05', purple='06', orange='07', yellow='08', lightgreen='09', turquoise='10', lightblue='11', skyblue='12', lightpurple='13', gray='14', lightgray='15'}
allColors[0]='00'
local rainbowOrder = {'04','07','08','03','10','02','06'}
local cchar = '\003'
--returns a table with data about where color codes are, might not be correct at all, old
local function tableColor(text)
	local t = {}
	if not text then return {} end
	local i = 0 --amount of color chars deleted
	local d = 0 --amount deleted
	local startOf = true
	while true do
		local st3,en3,cap3 = text:find("(\022?\003%d%d?,%d%d?)",1)
		local st2,en2,cap2 = text:find("(\022?\003%d%d?)",1)
		local st,en,cap = text:find("([\003\015\022])",1)
		local short=false
		if not en then break end --smallest check

		if st3 and st3==st then
			en=en3 cap=cap3 --first x03 is longest
		elseif st2 and st2==st then
			en=en2 cap=cap2 --first x03 is medium
		else --else first x03 is x03
			short=true
		end
		local ending,_ = text:find("([\003\015])",en+1)
		text = text:sub(en+1)
		local skip=false
		if startOf then
			if st==1 and short then 
				skip=true 
			end
			startOf=false
		end
		if not skip then
			ending = ending or 99999
			if en+1<ending or cap=="\022" then
				table.insert(t,{["start"]=st+d-i,["en"]=st+ending-en+d-i-2,["col"]=cap})
			end
		end
		i = i + #cap
		d = d + en
	end
	return t
end
--COLORSTRIP strips colors
function colorstrip(text,qqq,www,ignore)
	local newstring = text:gsub("\003%d%d?,%d%d?","") --remove colors with backgrounds
	newstring = newstring:gsub("\003%d%d?","") --remove normal
	if not ignore then newstring = newstring:gsub("[\003\015\022]","") end --remove extra \003
	return newstring
end
add_filt(colorstrip,"colorstrip",nil,"Strips color from text, '/colorstrip <text>'")
--RAINBOW every letter is new color
function rainbow(text)
	local newtext= ""
	local rCount=1
	newtext = (colorstrip(text,1,1,true)):gsub("([^%s%c])",function(c)
		c = cchar .. rainbowOrder[rCount] .. c
		rCount = ((rCount)%(#rainbowOrder))+1
		return c
	end)
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
		if not c1 then _,_,c1 = args[1]:find("^([^%s]-)$")end --normal
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
local function cow_text(text,length)
	if (#text < length) then return {text} end
	local t,start,en = {},1,length
	local s = text:sub(start,en)
	while (#s>0) do
		if (#s<length) then s = s..string.rep(" ",length-#s) end
		table.insert(t,s)
		start = en+1
		en = en + length
		s = text:sub(start,en)
	end
	return t	
end
local function get_border(lines,i)
	if lines < 2 then
		return '<','>'
	elseif i==0 then
		return '/','\\'
	elseif i==(lines-1) then
		return '\\','/'
	else
		return '|','|'
	end
end
local function get_cow()
    return [[
          \   ^__^ 
           \  (oo)\_______
              (__)\       )\/\\
                  ||----w |
                  ||     ||
     ]]
end
local function get_bubble(text)
	local bubble = {}
	local lines = cow_text(text,40)
	local bordersize = #lines[1]
	table.insert(bubble,"   "..string.rep("_",bordersize))
	for i,v in ipairs(lines) do
		local b1,b2 = get_border(#lines,i-1)
		table.insert(bubble,string.format(" %s %s %s",b1,v,b2))
	end

	table.insert(bubble,"   "..string.rep("-",bordersize))
	return table.concat(bubble,'\n')..'\n'
end

local function docowsay(text)
	return get_bubble(text)..get_cow()
end

local function cowsay(text,args)
	if #text>1000 then return '' end
	local t = {}
	local s = docowsay(text)
	for line in s:gmatch('(.-)\n') do
		table.insert(t,line)
	end
	return t
end
local function cowsane(args,filt)
	if filt then args.skip=true end
	return true
end
add_filt(cowsay,"cowsay",cowsane,"Says things with a cow.",1)

--SCRAMBLE, scrambles letters inside each word
local function scramble(text,args)
	local rstring
	local words={}
	if args.skip then args = getArgs(text) end
	for k,word in pairs(args) do
		if #word>2 then
			local t = {}
			for char in word:gmatch("[\3%d%d?[,%d%d?]*]-.") do
				table.insert(t,char)
			end
			local n = #t-1
			while n >= 2 do
				local k = math.random(#t-2)
				t[n], t[k+1] = t[k+1], t[n]
				n = n - 1
			end
			word = table.concat(t,"")
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
	return (text:gsub(args.pat,args.repl)) or ""
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

local magn=setmetatable({"thousand","million","billion","trillion","quadrillion","quintillion","sextillion","septillion"},{__index=function(_,i)return i.."-bajillion"end})
local one={"one","two","three","four","five","six","seven","eight","nine"}
local ten={nil,"twenty","thirty","fourty","fifty","sixty","seventy","eighty","ninety"}
local eleven={"eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen"}
local function mksmall(n)
    local s=""
    if n>=100 then
        s=one[math.floor(n/100)].." hundred "
        n=n%100
        if n~=0 then
            s=s.."and "
        end
    end
    if n>=20 then
        s=s..ten[math.floor(n/10)].." "
        n=n%10
        if n~=0 then
            s=s..one[n].." "
        end
        return s
    elseif n>10 then
        return s..eleven[n-10].." "
    elseif n==10 then
        return s.."ten "
    elseif n>0 then
        return s..one[n].." "
    else
        return s
    end
end
function mknum(n)
    n=tonumber(n)
    if n~=n then return "Not A Number" end
    local p=""
    if n<0 then
        p="minus "
        n=-n
    end
    if n==0 then return p.."zero" end
    if n==1/0 then return p.."infinity" end
    if n>2^52 then io.stderr:write"Warning: mantissa overflow, result might be unprecise\n" end
    local t={}
    for i=0,math.floor(math.log(n)/math.log(1000)) do
        local g=math.floor(n/1000^i)%1000
        if g>999 or g<0 then break end
        if g~=0 then
            if i==0 then
                table.insert(t,1,mksmall(g):sub(1,-2))
            else
                table.insert(t,1,mksmall(g)..magn[i])
            end
        end
    end
    return p..table.concat(t," and ")
end
local function numify(text,args)
	return text:gsub("(%-?%d+)",function(s) return mknum(tonumber(s)) end)
end
add_filt(numify,"mknum",nil,"Turns digits into their text, '/mknum <text>'")
function mknumscramb(n)
	local rnd=math.random(1,100)
	if rnd<15 then return tostring(n) end
	return scramble(mknum(n),{skip=true})
end

function nicenum(text,args)
	return text:gsub("([-]?)(%d+)([.]?%d*)",function(minus, int, fraction) return minus..int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")..fraction end)
end
add_filt(nicenum,"nicenum",nil,"Inserts commas into numbers, '/nicenum <text>'")

local function luaFilt(text,args)
	local msg = args[1]
	if not msg then return "" end
	local realtext=""
	if not args.skip then
		for i=2,#args do realtext=realtext.." "..args[i] end
		realtext = realtext:sub(2)
	else
		realtext=text or ""
	end
	
	local luan = WINDOWS and "plugins/sandbox/luasandbox.exe" or "./plugins/sandbox/luasandbox"
	realtext = realtext:gsub(".",function(x)return("\\%03d"):format(x:byte())end)
	local command = "return (function(...) "..msg.." end)('"..realtext.."')"
	command = command:gsub(".",function(a)return string.char(65+math.floor(a:byte()/16),65+a:byte()%16)end)
	local rf = io.popen(luan.." "..command)
	local r = rf:read("*a")
	return r
end
local function luaFiltSane(args,filt)
	args.skip = filt
	return true
end
add_filt(luaFilt,"luafilt",luaFiltSane,"Lua code to parse text, input is ... , return/print the output '/luafilt \"<code>\" <text>'")

--function to let filters sanity check some args for direct calls
function callFilt(name,f,sanf,filt)
	return function(usr,chan,msg,args)
		if not commands[name] then return end		
		local args = args
		if not msg then return end
		local s,err = sanf(args,filt) --allow filter to sanity check args before running
		if s then
			return f(msg,args)
		else
			return err
		end
	end
end

--FILTER main command, set filter for output
local function filter(usr,chan,msg,args)
	local command = msg and msg:lower() or nil
	if command=="current" then
		ircSendChatQ(chan,getFilts(chan),true)
		return nil
	elseif command=="list" then
		local t = {}
		for k,v in pairs(filters) do
			table.insert(t,k)
		end
		return "Filters: "..table.concat(t,", ")
	elseif command=="lock" then
		local perm = getPerms(usr.host)
		if perm > 20 then
			filtLock(chan)
			return "Locked "..chan
		else
			return "No permissions to lock"
		end
	elseif command=="unlock" then
		local perm = getPerms(usr.host)
		if perm > 20 then
			filtUnLock(chan)
			return "Unlocked "..chan
		else
			return "No permission to unlock"
		end
	elseif command=="pop" then
		if popFilter(chan) then
			return "Removed last filter"
		else
			return "Can't pop! Locked or no filters"
		end	
	elseif not command then
		if clearFilter(chan) then
			return "Cleared Filts"
		end
		return chan.." is locked"
	end
	local name=table.remove(args,1):lower()
	args.name=name
	if filters[name] and commands[name] then
		local perm = getPerms(usr.host)
		if perm < commands[name].level then
			return "No permission to add this filter"
		end
		local s,err = filters[name].sanity(args,true) --allow filter to sanity check args before adding
		if s then
			if addFilter(chan,filters[name].f,name,args) then
				return "Filter added: "..name
			else
				return chan.." is locked"
			end
		else
			return err
		end
	else
		return "No filter named "..name
	end
end
add_cmd(filter,"filter",0,"Set a filter, '/filter <filtName>/list/current [<arguments to filter>]', no argument to clear",true,{"f"})

--add sub commands to call filters directly
for k,v in pairs(filters) do
	add_cmd(callFilt(k,v.f,v.sanity),k,v.level,v.helptext,false)
end

--BADWORD filter, hopefully always active, uses my terrible color table to re-add
--possibly save this list to file
local badlist= {"\007","^%$","^!","^;","^%%","^@","^#","^%?","^%.","^<","^/","^\\","^`","^%+","^%-", "^%&","^%)","^%(","^%~"}
badWordFilt = function(text)
	if type(text)~="string" then return nil end
	local t = tableColor(text)
	local nocol = colorstrip(text)
	--local orig = nocol
	local amt = 0
	for k,word in pairs(badlist) do
		local nonocol,newamt = (nocol):gsub(word,function(s) return ("*")*#s end)
		nocol,amt = nonocol, amt+newamt
	end
	--if orig==nocol then return text end
	local tempstring = ""
	if #t>0 then
		local index=1
		for char in nocol:gmatch(".") do
			local code=""
			for i,v in ipairs(t) do
				if (v.start)<=index then
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

--command hook for badword
local function badWord(usr,chan,msg,args)
	if not args[2] then return "Usage: badword add/rem <word>" end
	if args[1] == "add" then
		return addBadWord(args[2])
	elseif args[1] == "rem" then
		return remBadWord(args[2])
	end
	return "Usage: badword add/rem <word>"
end
add_cmd(badWord,"badword",20,"Set or remove bad words, '/badword add/rem <word>'",true)

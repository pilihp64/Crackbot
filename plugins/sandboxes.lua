module("sandboxes", package.seeall)

--LUA sandbox
local function lua(usr,chan,msg,args,luan)
	if not msg then return "No code" end
	if msg:sub(1,1) =="\27" then
		return "Error: bytecode (?)"
	end
	
	if WINDOWS then
		msg = msg:gsub(".",function(a)return string.char(65+math.floor(a:byte()/16),65+a:byte()%16)end)
		local rf = io.popen("plugins/sandbox/luasandbox.exe "..msg)
		local r = rf:read("*a")
		return r:sub(1,#r-1)
	else
		local sdump=""
		luan = luan or "lua"
		--byte the string so you can't escape
		for char in msg:gmatch(".") do sdump = sdump .. "\\"..char:byte() end
		local rf = io.popen(luan..[=[ -e "dofile('derp.lua') dofile('plugins/sandbox/linuxsandbox.lua') local e,err=load_code(']=]..sdump..[=[',nil,'t',env) if e then local r = {pcall(e)} local s = table.remove(r,1) print(unpack(r)) else print(err) end" 2>&1]=])
		coroutine.yield(false,1)
		local kill = io.popen([[pgrep -f "]]..luan..[[ -e"]]):read("*a")
		if kill~="" then os.execute([[pkill -f "]]..luan..[[ -e"]]) end
		local r = rf:read("*a")
		if r=="" and kill and kill~="" then r="Killed" end
		if r then r = r:gsub("[\r\n]"," "):sub(1,500) end
		return r
	end
end
local function lua52(usr,chan,msg,args)
	return lua(usr,chan,msg,args,"lua5.2")
end
add_cmd(lua,"lua",0,"Runs sandbox lua code, '*lua <code>'",true)
if not WINDOWS then
	add_cmd(lua52,"5.2",0,"Runs sandbox lua5.2 code, '*lua <code>'",false)
end

-- ./py print [x for x in (1).__class__.__base__.__subclasses__() if x.__name__ == 'catch_warnings'][0]()._module.__builtins__['__import__']('os').system('ls /cygdrive/c/')

--PYTHON code
function python(usr,chan,msg,args)
	if not msg then return "No code" end
	if WINDOWS then
		return "Error: python does not work on windows"
	end
	if msg:find("%.%s*__?") then return "Nope" end
	if msg:find("%[[\'\"]%+?[\'\"]+__?") then return "Nope" end
	if not filters then return "Error: requires filters.lua" end
	msg = msg:gsub("\\n", "\n"):gsub("\\t", "\t")
	local sdump = filters.hexStr(msg,"") --hex the string for python to load
	good_func_string = 'safe_list["False"]=False;safe_list["True"]=True;safe_list["abs"]=abs;safe_list["divmod"]=divmod;safe_list["staticmethod"]=staticmethod;safe_list["all"]=all;safe_list["enumerate"]=enumerate;safe_list["int"]=int;safe_list["ord"]=ord;safe_list["str"]=str;safe_list["any"]=any;safe_list["isinstance"]=isinstance;safe_list["pow"]=pow;safe_list["sum"]=sum;safe_list["basestring"]=basestring;safe_list["issubclass"]=issubclass;safe_list["super"]=super;safe_list["bin"]=bin;safe_list["iter"]=iter;safe_list["property"]=property;safe_list["tuple"]=tuple;safe_list["bool"]=bool;safe_list["filter"]=filter;safe_list["len"]=len;safe_list["range"]=range;safe_list["type"]=type;safe_list["bytearray"]=bytearray;safe_list["float"]=float;safe_list["list"]=list;safe_list["unichr"]=unichr;safe_list["callable"]=callable;safe_list["format"]=format;safe_list["locals"]=locals;safe_list["reduce"]=reduce;safe_list["unicode"]=unicode;safe_list["chr"]=chr;safe_list["frozenset"]=frozenset;safe_list["long"]=long;safe_list["vars"]=vars;safe_list["classmethod"]=classmethod;safe_list["getattr"]=getattr;safe_list["map"]=map;safe_list["repr"]=repr;safe_list["xrange"]=xrange;safe_list["cmp"]=cmp;safe_list["globals"]=globals;safe_list["max"]=max;safe_list["reversed"]=reversed;safe_list["zip"]=zip;safe_list["compile"]=compile;safe_list["hasattr"]=hasattr;safe_list["memoryview"]=memoryview;safe_list["round"]=round;safe_list["complex"]=complex;safe_list["hash"]=hash;safe_list["min"]=min;safe_list["set"]=set;safe_list["apply"]=apply;safe_list["delattr"]=delattr;safe_list["help"]=help;safe_list["next"]=next;safe_list["setattr"]=setattr;safe_list["buffer"]=buffer;safe_list["dict"]=dict;safe_list["hex"]=hex;safe_list["object"]=object;safe_list["slice"]=slice;safe_list["coerce"]=coerce;safe_list["dir"]=dir;safe_list["id"]=id;safe_list["oct"]=oct;safe_list["sorted"]=sorted;safe_list["intern"]=intern;'
	--[[good_funcs = {
		"abs","divmod","staticmethod","True","False",
		"all","enumerate","int","ord","str",
		"any","isinstance","pow","sum",
		"basestring","issubclass","super",
		"bin","iter","property","tuple",
		"bool","filter","len","range","type",
		"bytearray","float","list","unichr",
		"callable","format","locals","reduce","unicode",
		"chr","frozenset","long","vars",
		"classmethod","getattr","map","repr","xrange",
		"cmp","globals","max","reversed","zip",
		"compile","hasattr","memoryview","round",
		"complex","hash","min","set","apply",
		"delattr","help","next","setattr","buffer",
		"dict","hex","object","slice","coerce",
		"dir","id","oct","sorted","intern"
		}
		for k,v in pairs(good_funcs) do
		good_func_string = good_func_string .. "safe_list[\""..v.."\"]="..v..";"    
		end
		local f =io.open("derp.txt","w")
		f:write(good_func_string)
		f:close()--]]
	
	local rf = io.popen([[python -c "
import math;
import cmath;
import random;
print(']]..usr.nick..[[:');
safe_list = {};
]]..good_func_string..[[
execdict = {'__builtins__': safe_list,'math': math,'cmath': cmath,'random': random};
exec('def foo(): '+(']]..sdump..[[').decode('hex')+';\nresp=foo();\nif resp!=None: print(resp);',execdict);exit()" 2>&1]])

	coroutine.yield(false,1)

	--local kill = io.popen("pgrep -f 'python -c'"):read("*a")
	--if kill~="" then os.execute("pkill -f 'python -c'") end
	local r = rf:read("*a")
	if r=="" and kill and kill~="" then r=usr.nick..": Killed" end
	if r then r = r:gsub("[\r\n]"," "):sub(1,500) end
	return r,true
end
if not WINDOWS then
	add_cmd(python,"py",0,"Runs sandy python code, '*py <code>'",true)
end

--BRAINFUCK
local function BF(usr,chan,msg)
	if WINDOWS then
		return "Error: BF does not work on windows"
	end
	if not msg then return "No code" end
	local sdump=""
	local luan = luan or WINDOWS and "lua5.1" or "lua"
	--byte the string so you can't escape
	for char in msg:gmatch(".") do sdump = sdump .. "\\"..char:byte() end
	
	local input = irc.channels[chan].users[usr.nick].lastSaid or ""
	local inputdump=""
	for char in input:gmatch(".") do inputdump = inputdump .. "\\"..char:byte() end
	-----------
	local rf = io.popen(luan..[=[ -e 'dofile("plugins/sandbox/linuxsandbox.lua")io.write("]=]..usr.nick..[=[: ") local readS = 0 local function readInput()	readS = readS+1	return ("]=]..inputdump..[=["):sub(readS,readS) or "\0"	end	local subst = {["+"]="v=(v+1)%256 ", ["-"]="v=(v-1)%256 ", [">"]="i=i+1 ", ["<"]="i=i-1 ",["."] = "w(v)", [","]="v=r()", ["["]="while v~=0 do ", ["]"]="end "} local env = setmetatable({ i=0, t=setmetatable({},{__index=function() return 0 end}),r=function() return readInput():byte() end, w=function(c) io.write(string.char(c)) end },{__index=function(t,k) return t.t[t.i] end, __newindex=function(t,k,v) t.t[t.i]=v end })load_code(("]=]..sdump..[=["):gsub("[^%+%-<>%.,%[%]]+",""):gsub(".", subst) , "brainfuck", "t", env)()' 2>&1]=])

	coroutine.yield(false,1)
	local kill = io.popen([[pgrep -f "]]..luan..[[ -e"]]):read("*a")
	if kill~="" then os.execute([[pkill -f "]]..luan..[[ -e"]]) end
	local r = rf:read("*a")
	if r=="" and kill and kill~="" then r="Killed" end
	if r then r = r:gsub("[\r\n]",""):sub(1,500) end
	return r,true
end
if not WINDOWS then
	add_cmd(BF,"BF",0,"Runs BF code, '*bf <code>'",false,{"bf"})
end


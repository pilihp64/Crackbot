function luagetArgs(msg)
	if not msg then return {} end
	local args = {}
	local index=1
	while index<=#msg do
		local s2,e2,word2 = msg:find("\"([^\"]-)\"",index)
		local s,e,word = msg:find("([^%s]+)",index)
		if s2 and s2<=s then
			word=word2
			e=e2
		end
		table.insert(args,word)
		index = e+1 or #msg+1
	end
	return args
end
dofile("fakefs.lua")
local coroutine={create=coroutine.create,resume=coroutine.resume,running=coroutine.running,status=coroutine.status,wrap=coroutine.wrap,yield=coroutine.yield}
local string={byte=string.byte,char=string.char,find=string.find,format=string.format,gmatch=string.gmatch,gsub=string.gsub,len=string.len,lower=string.lower,match=string.match,rep=string.rep,reverse=string.reverse,sub=string.sub,upper=string.upper}
local mtable={insert=table.insert,maxn=table.maxn,remove=table.remove,sort=table.sort,concat=table.concat}
--Make the rest of the os/io functions use fakefs
local os = fakeOS()
local io = fakeIO()
local mbit32 = nil
if _VERSION == "Lua 5.2" then
	mtable={insert=table.insert,maxn=table.maxn,remove=table.remove,sort=table.sort,unpack=table.unpack,pack=table.pack,concat=table.concat}	
	mbit32={band=bit32.band,bnot=bit32.bnot,bor=bit32.bor,btest=bit32.btest,bxor=bit32.bxor,extract=bit32.extract,replace=bit32.replace,lrotate=bit32.lrotate,lshift=bit32.lshift,rrotate=bit32.rrotate,rshift=bit32.rshift}
end
local math={abs=math.abs,acos=math.acos,sin=math.sin,atan=math.atan,atan2=math.atan2,ceil=math.ceil,cos=math.cos,cosh=math.cosh,deg=math.deg,exp=math.exp,floor=math.floor,fmod=math.fmod,frexp=math.frexp,huge=math.huge,ldexp=math.ldexp,log=math.log,log10=math.log10,max=math.max,min=math.min,modf=math.modf,pi=math.pi,pow=math.pow,rad=math.rad,random=math.random,sin=math.sin,sinh=math.sinh,sqrt=math.sqrt,tan=math.tan,tanh=math.tanh}

env = {fs=fs,type=type,pcall=pcall, math=math, coroutine=coroutine, string=string, table=mtable,os = os, assert=assert,error=error,ipairs=ipairs,next=next,pairs=pairs,pcall=pcall,select=select,tonumber=tonumber,tostring=tostring,_VERSION=_VERSION,xpcall=xpcall,print=print,fempty=fempty,fproxy=fproxy,fop=fop,getArgs=getArgs,io=io}
if _VERSION == "Lua 5.2" then
	env.bit32 = mbit32
	env.load = function(s,n,t,e) --safe load function
		return load(s,n,t,e or env)
	end
	env.unpack=table.unpack
else
	env.unpack=unpack
end
env._G = env
--load a string with env for 5.1 or 5.2
function load_code(c,s,t,e)
	if _VERSION == "Lua 5.2" then
		return load(c,s,t,e)
	else
		local r,err = loadstring(c)
		if r then setfenv(r,e) end
		return r,err
	end
end

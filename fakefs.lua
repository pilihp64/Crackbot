--A fake filesystem that is silly, for ./lua
local function newFolder()
	local t={
		["files"] = {},
		["numf"] = 0,
		["insert"]=function(self,k,v)
			self.files[k]=v
			v.parent=self
			self.numf = self.numf+1
		end,
		["remove"]=function(self,rmk)
			for k,v in pairs(self.files) do
				if k==rmk then
					local tmp = v
					self.files[k]=nil
					return tmp
				end
			end
			return false
		end,
		["parent"]=nil,
	}
	setmetatable(t,{__tostring=function()return "Folder" end,__index=function(t,k) return t.files[k] end})
	return t
end
local function newFile(dat,nam)
	local t={
		["data"]=dat,
		["name"]=nam,
	}
	setmetatable(t,{__tostring=function()return "File" end })
	return t
end
fs = {["/"] = newFolder()}
local Downloads = newFolder()
Downloads:insert("merp.txt",newFile("moooo","merp.txt"))

fs["/"]:insert("bin",newFolder())
fs["/"]:insert("dev",newFolder())
fs["/"]:insert("ect",newFolder())
fs["/"]:insert("home",newFolder())
fs["/"]:insert("lib",newFolder())
fs["/"]:insert("media",newFolder())
fs["/"]:insert("opt",newFolder())
fs["/"]:insert("proc",newFolder())
fs["/"]:insert("sys",newFolder())
fs["/"]:insert("tmp",newFolder())
fs["/"]:insert("usr",newFolder())
fs["/"]:insert("var",newFolder())
fs["/"]["home"]:insert("pilihp",newFolder())
fs["/"]["home"]["pilihp"]:insert("Documents",newFolder())
fs["/"]["home"]["pilihp"]:insert("Downloads",Downloads)

local pwd = {"home","pilihp"}
local realpwd = fs["/"]["home"]["pilihp"]
function cmdLS()
	local t={}
	for k,v in pairs(realpwd.files) do
		--check if table or file
		if tostring(v)=="Folder" then
			table.insert(t,k.."/")
		else
			table.insert(t,k)
		end
	end
	return table.concat(t," ")
end
function cmdMKDIR(newFName)
	realpwd:insert(newFName,newFolder())
end
function cmdPWD()
	return "/" .. table.concat(pwd,"/")
end
function cmdCD(newDir)
	--update pwd
	local changed=false
	for dir in newDir:gmatch("([^/]+)") do
		if dir == ".." then
			if realpwd.parent then
				realpwd = realpwd.parent
			end
			changed=true
		end
		for k,v in pairs(realpwd.files) do
			if k==dir then
				table.insert(pwd,dir)
				realpwd = v
				changed=true
			end
		end
	end
	if not changed then error(newDir..": No such file or directory") end
end
--remove
function cmdRM(fileName)
	local r = realpwd:remove(fileName)
	if not r then error(fileName..": No such file or directory") end
end
--Move, or rename
function cmdMV(fileName,destFile)
	local r = realpwd:remove(fileName)
	if not r then error(fileName..": No such file or directory") end
	r.name=destFile
	realpwd:insert(destFile,r)
end
--copy
function cmdCP(fileName,destFile)

end

function fakeOS()
	local t={
		["execute"]=function(s)
			local args = getArgs(s)
			if args[1]=="ls" then
				return cmdLS()
			elseif args[1]=="pwd" then
				return cmdPWD()
			elseif args[1]=="cd" then
				return cmdCD(args[2])
			elseif args[1]=="shutdown" then
				return "Nope"
			elseif args[1]=="mkdir" then
				return cmdMKDIR(args[2])
			elseif args[1]=="mv" then
				return cmdMV(args[2],args[3])
			elseif args[1]=="rm" then
				return cmdRM(args[2])
			end
		end,
		["rename"]=function(s) local args = getArgs(s) return cmdMV(args[1],args[2]) end,
		["remove"]=function(s) return cmdRM(s) end,
		["tmpname"]=function(s) error("go away") end,
		["getenv"]=os.getenv,
		["setlocale"]=os.setlocale,
		["exit"]=os.exit,
		["time"]=os.time,
		["date"]=os.date,
		["difftime"]=os.difftime,
		["clock"]=os.clock,
	}
	return t
end

function fakeIO()
	local t={
		["close"]=function(s) end,
		["flush"]=function(s) end,
		["input"]=function(s) end,
		["lines"]=function(s) end,
		["open"]=function(s) end,
		["output"]=function(s) end,
		["popen"]=function(s) error("Go away") end,
		["read"]=function(s) end,
		["stderr"]=function(s) end,
		["stdin"]=function(s) end,
		["stdout"]=function(s) end,
		["tmpfile"]=function(s) end,
		["type"]=function(s) end,
		["write"]=print,
	}
	return t
end

local _tostring = tostring
function strstring(str)
	return type(str)=="string" and "'"..str.."'" or str
end
function tableString(x,tab)
  local s
  tab = tab or 0
  if type(x) == "table" then
    tab = tab+1
    s = '\n'..string.rep(" ",tab-1) .."{\n"..string.rep(" ",tab)
    local i, v = next(x)
    while i do
      if type(v) == "string" then
		s = s .. '[' .. strstring(i) .. "]='" .. tableString(v):gsub('([\\\'\"])','\\%1'):gsub('[\n\t\r]','') .."'"
	  else
		s = s .. '[' .. strstring(i) .. "]=" .. tableString(v,tab)..''
	  end
      i, v = next(x, i)
      if i then s = s .. ",\n"..string.rep(" ",tab)
	  else s = s .. "\n"..string.rep(" ",tab-1) end
    end
    return s .. "}"
  else return _tostring(x)
  end
end
function writeTable(path,t)
	local f = io.open(path,'w')
	f:write('return '..tableString(t))
	f:close()
end
function readTable(path)
	local f,e = loadfile(path)
	if f then
		return f()
	end
	return {}
end
function tableMerge(dest,new)
	for k,v in pairs(new) do
		if type(v)=='table' then
			dest[k] = dest[k] or {}
			tableMerge(dest[k],v)
		else
			dest[k] = v
		end
	end
end
function getArgs(msg)
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
		index = (e or #msg)+1 or #msg+1
	end
	return args
end
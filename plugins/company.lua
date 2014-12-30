module("company", package.seeall)

local defaultVars = {cash=0,employees=0,workSpeed=1,emplSpeed=1,loyalty=65,currentProject={},completedProjects=0,lastNick="",}
local defaultPVars = {name="Project0",work=0,needed=60,reward=150,time=70,timespent=0}
local function loadUsers()
	return table.load("plugins/compData.txt") or {}
end
compData = compData or loadUsers()
local function metafy(t)
	setmetatable(t,{__index=function(t,k) if defaultVars[k] then t[k]=defaultVars[k] return defaultVars[k] end end--[[can add new vars to old tables, need default here]]})
	setmetatable(t.currentProject,{__index=function(t,k) if defaultPVars[k] then t[k]=defaultPVars[k] return defaultPVars[k] end end})
end
setmetatable(compData,{__index=function(t,k) t[k]={} metafy(t[k]) return t[k] end})
for k,v in pairs(compData) do
	if type(v)=="table" then
		metafy(v)
	end
end
local activeProjects = {}
local function timedSave()
	table.save(compData,"plugins/compData.txt")
end
remUpdate("compSave")
addUpdate(timedSave,60,config.owner.nick,"compSave")
local function nextProject(comp)
	--30-90 second for a project
	local time= math.random(30,90)
	--calculate possible work/s
	local ws = comp.employees+1
	for i=1,9000 do
		if ((comp.employees)*50+100)*i + (i-1)*50 + (comp.employees+i)*time > comp.cash-((comp.employees)*50+100)*i + (i-1)*50 then
			break
		end
		ws = ws+1
	end
	--adjust work/s
	ws = ws*(math.random(90,110)/100)
	local reward= math.floor(ws*time*math.random(90,110)/100)
	local t = {name="Project"..comp.completedProjects,lostEmpl=0,work=0,needed=math.floor(ws*time),reward=reward,time=time,timespent=0}
	setmetatable(t,{__index=function(t,k) if defaultPVars[k] then t[k]=defaultVars[k] return defaultVars[k] end end})
	return t
end
local firstUpdate=false
local function updateComps()
	if not firstUpdate then
		firstUpdate=true
		for k,v in pairs(compData) do
			if v.currentProject.work>0 then
				table.insert(activeProjects,v)
			end
		end
	end
	for k,v in pairs(activeProjects) do
		proj = v.currentProject
		proj.timespent = proj.timespent+1
		proj.work = proj.work + v.workSpeed
		if v.employees>0 and v.cash>0 then
			v.cash = math.max(v.cash-v.employees,0)
			proj.work = proj.work + v.employees*v.emplSpeed
		end
		if proj.work >= proj.needed then
			activeProjects[k]=nil
			v.completedProjects = v.completedProjects+1

			local adjust = math.max(1-(math.abs(proj.timespent-proj.time)/proj.time),0.3)*2
			local reward = math.floor(proj.reward*adjust)
			local vreward = math.floor((3*adjust)-3.7)
			v.cash = v.cash + reward
			v.loyalty = v.loyalty + vreward
			local rstring = proj.name.." finished! You gained $"..reward
			if vreward ~= 0 then rstring = rstring .. " ,Loyalty:"..vreward end
			rstring = rstring.." "..(math.abs(proj.timespent-proj.time)/proj.time).."% away from goal"
			local lost=0
			for i=1,v.employees do
				if math.random(0,v.loyalty/4)==0 then
					lost=lost+1
				end
			end
			if lost>0 then v.employees=v.employees-lost rstring = rstring .. " You lost "..lost.." employees after the project." end
			ircSendChatQ(v.lastNick,rstring)
			ircSendRawQ("NOTICE "..v.lastNick.." :"..rstring)
			v.currentProject = nextProject(v)
		end
	end
end
remUpdate("company")
addUpdate(updateComps,1,"jacob1","company")

local function calcWork(comp)
	return comp.workSpeed + comp.employees*comp.emplSpeed
end

local function compSave(usr,chan,msg,args)
	timedSave()
	return "Saved!"
end
add_cmd(compSave,"compsave",101,"Saves all company data",false)

local function compHelp(usr,chan,msg,args)
	local comp = compData[usr.host]
	local rstring = "Your Comp. Cash:"..comp.cash.." CurrentWorkSpeed:"..calcWork(comp).." Project("..math.floor(comp.currentProject.work/comp.currentProject.needed*100).."%):"..comp.currentProject.name.." Employees:"..comp.employees.." Loyalty:"..comp.loyalty.." Info:"
	if comp.loyalty<30 then rstring=rstring .. "People don't trust your company"
	elseif comp.loyalty<50 then rstring=rstring .. "People are wary of your company"
	elseif comp.loyalty<70 then rstring=rstring .. "People don't mind your company"
	elseif comp.loyalty<90 then rstring=rstring .. "People like your company"
	else rstring=rstring .. "People are in love with you" end
	return rstring
end
add_cmd(compHelp,"comp",0,"Basic information of your company",true,{"company"})

local function projHelp(usr,chan,msg,args)
	local proj = compData[usr.host].currentProject
	if args[1]=="start" and not proj.started then
		proj.started=true
		table.insert(activeProjects,compData[usr.host])
		compData[usr.host].lastNick = usr.nick
		return "Started "..proj.name
	end
	local rstring = "Current ProjectName:"..proj.name.." Progress:"..proj.work.."/"..proj.needed.."("..math.floor(proj.work/proj.needed*100).."%) Reward: "..proj.reward.." TimeGoal: "..proj.time
	return rstring
end
add_cmd(projHelp,"proj",0,"Current company project information, '/proj [start]' to initiate it.",true)

local function hireEmp(usr,chan,msg,args)
	local comp = compData[usr.host]
	if not msg then return "Hiring Firm Sells: Employee(1w/s, $1/s)($"..((comp.employees)*50+100)..") Manager(+.5 w/s to 10 employees, $2/s) (unavailable right now) '/hire <amt>'" end
	local amt= tonumber(args[1])
	if amt and amt > 0 and amt == math.floor(amt) then
		local cost = ((comp.employees)*50+100)*amt + (amt-1)*50 --(amt*100)+(amt+comp.employees-1)*50
		if comp.cash>=cost then
			comp.employees = comp.employees + amt
			comp.cash = comp.cash - cost
			return "You hired "..amt.." employee(s)!"
		else
			return "Not enough money for "..amt.." employee(s)!"
		end
	else
		return "Bad amount"
	end
end
add_cmd(hireEmp,"hire",0,"Hire workers to work on projects faster '/hire [amt]' Note: Employees may leave your company at any time during a project",true)

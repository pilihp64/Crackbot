permissions = {}
permissions["!~meow@Powder/Developer/cracker64"] = 101
permissions["!~jacob1@Powder/Developer/jacob1"] = 100
permissions["!~mniip@178.219.36.155"]=100
--permissions["Powder/Developer/jacksonmj"] = 100
permissions["!jacksonmj@2a01:7e00::f03c:91ff:fedf:890f"] = 100

function permFullHost(host)
	for k,v in pairs(permissions) do
		if host:find(k) then
			return v
		end
	end
	return 0
end

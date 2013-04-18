permissions = {}
--insert !user@host into permissions here
--example: permissions["!~meow@Powder/Developer/cracker64"] = 101
--Owner should be 101

--Get perm value for part of a hostmask (usually just host)
function permFullHost(host)
	for k,v in pairs(permissions) do
		if host:find(k) then
			return v
		end
	end
	return 0
end

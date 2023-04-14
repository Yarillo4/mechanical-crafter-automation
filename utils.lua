local Utils = {}
---comment
---@param tally {[string]: number}
---@return Slot[]
function Utils.flatten(tally)
	local tmp = {}
	for name,count in pairs(tally) do
		table.insert(tmp, {name=name, count=count})
	end
	return tmp
end


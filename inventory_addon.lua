---comment
---@param tally {[string]: number}
---@return Slot[]
local function flatten(tally)
	local tmp = {}
	for name,count in pairs(tally) do
		table.insert(tmp, {name=name, count=count})
	end
	return tmp
end

--[[##############################################
###                                            ###
###             @class Inventory               ###
###                                            ###
################################################]]

function Inventory:hash()
	local contents = flatten(self:tally())
	table.sort(contents, function(a,b) return a.name < b.name end)
	return textutils.serializeJSON(contents)
end

---comment
---@param recipe Recipe
function Inventory:canMake(recipe)
	for name,count in pairs(recipe.ingredients) do
		if self:count(name) < count then
			return false
		end
	end

	return true
end

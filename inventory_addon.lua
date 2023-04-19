require("stdlib")

--[[
	This isn't the best thing to do
	But this file just adds stuff to the Inventory class which is part of stdlib.
	The stuff doesn't make sense outside of the business logic of this project 
	and I'm not going to bother coding an "Inventory2" class that composes Inventory.
--]]

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

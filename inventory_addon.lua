require("stdlib")

--[[##############################################
###                                            ###
###             @class Inventory               ###
###                                            ###
################################################]]

---comment
---@param recipe Recipe
function Inventory:canMake(recipe)
	for name,count in pairs(recipe._ingredients) do
		if self:count(name) < count then
			return false
		end
	end

	return true
end

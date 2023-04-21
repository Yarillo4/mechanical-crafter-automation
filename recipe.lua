require("stdlib")

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
###               @class Recipe                ###
###                                            ###
################################################]]

---@class Recipe
---@field pattern     Slot[][]
---@field _ingredients {[string]:number}
local Recipe = {}

---Constructor
---@param pattern     string[][]
---@return Recipe
function Recipe.new(pattern)
    local instance = {
		pattern=pattern
	}

	instance._ingredients = {}
	for row in pairs(pattern) do
		for col in pairs(pattern[row]) do
			local v = pattern[row][col]
			if instance._ingredients[v] then
				instance._ingredients[v] = instance._ingredients[v] + 1
			else
				instance._ingredients[v] = 1
			end
		end
	end

	setmetatable(instance, {__index=Recipe})
    return instance
end

---Returns the minimal amount of items required to create the recipe's pattern
---@return Inventory|nil
function Recipe:ingredients()
	local contents = flatten(self._ingredients)
	table.sort(contents, function(a,b) return a.name < b.name end)
	return Inventory.fromTable(contents);
end

return Recipe
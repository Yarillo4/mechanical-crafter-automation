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
---@field ingredients {[string]:number}
local Recipe = {}

---Constructor
---@param pattern     string[][]
---@return Recipe
function Recipe.new(pattern)
    local instance = {
		pattern=pattern
	}

	instance.ingredients = {}
	for row in pairs(pattern) do
		for col in pairs(pattern[row]) do
			local v = pattern[row][col]
			if instance.ingredients[v] then
				instance.ingredients[v] = instance.ingredients[v] + 1
			else
				instance.ingredients[v] = 1
			end
		end
	end

	setmetatable(instance, {__index=Recipe})
    return instance
end

function Recipe:hash()
	local contents = flatten(self.ingredients)
	table.sort(contents, function(a,b) return a.name < b.name end)
	return textutils.serializeJSON(contents)
end

return Recipe
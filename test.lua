term, sleep, shell, peripheral, textutils, fs, colors, redstone, http, turtle, settings, keys = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
require("stdlib")
require("inventory_addon")
local Recipe = require("recipe")

if not textutils.serialize then
	function textutils.serialize(tbl, indent)
		if not indent then indent = 0 end
		local toprint = string.rep(" ", indent) .. "{\r\n"
		indent = indent + 2 
		for k, v in pairs(tbl) do
			toprint = toprint .. string.rep(" ", indent)
			if (type(k) == "number") then
				toprint = toprint .. "[" .. k .. "] = "
			elseif (type(k) == "string") then
				toprint = toprint  .. k ..  "= "   
			end
			if (type(v) == "number") then
				toprint = toprint .. v .. ",\r\n"
			elseif (type(v) == "string") then
				toprint = toprint .. "\"" .. v .. "\",\r\n"
			elseif (type(v) == "table") then
				toprint = toprint .. textutils.serialize(v, indent + 2) .. ",\r\n"
			else
				toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
			end
		end
		toprint = toprint .. string.rep(" ", indent-2) .. "}"
		return toprint
	end
	textutils.serializeJSON = textutils.serialize
end

local recipe = Recipe.new({
	{"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
	{"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
	{"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
})

local inv = Inventory.fromTable({
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:cobdlestone", count = 64},
	{name = "minecraft:cobdlestone", count = 48},
	{name = "minecraft:cobblestone", count = 5},
	{name = "minecraft:cobblestone", count = 9}
})
assert(inv ~= nil, "Inventory creation failed for the mixed contents inv")

local canMake = inv:canMake(recipe)
assert(canMake == true, "test fail: canMake should've been true, it wasn't")

local nineStonesInv = Inventory.fromTable({
	{name = "minecraft:stone", count = 3},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 1},
	{name = "minecraft:stone", count = 4},
})
assert(nineStonesInv ~= nil, "Inventory creation failed for the nineStonesInv")

local nineStonesRecipe = Recipe.new({
	{"minecraft:stone", "minecraft:stone", "minecraft:stone"},
	{"minecraft:stone", nil, "minecraft:stone"},
	{"minecraft:stone", "minecraft:stone", "minecraft:stone"},
})

local h1 = nineStonesInv:hash()
local h2 = nineStonesRecipe:ingredients():hash()
assert(type(h1) == "string", "h1 must be a string")
assert(type(h2) == "string", "h2 must be a string")
assert(h1 == h2, "hashes don't match")




print("All tests OK!")
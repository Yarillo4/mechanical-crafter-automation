term, sleep, shell, peripheral, textutils, fs, colors, redstone, http, turtle, settings, keys = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
require("stdlib")
require("inventory_addon")
local Recipe = require("recipe")
local MechanicalCrafter = require("mechanical_crafter")

function textutils.serializeJSON(tbl, indent)
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
textutils.serialize = textutils.serializeJSON

local function mapMachineIDToCoordinates(n, nRows, nCols)
	--assert(numberOfMachines == 25, "If you change the number of machines you have to rewrite the mapping")
	--return __map[n]

	local row = nRows - math.floor(  (n-1) / nCols  ) -- 5,4,3,2,1
	local col = ((n-1) % nCols) -- [0;4]
	if (row % 2 == 1) then
		-- Snake forward
		col = col + 1                -- 1,2,3,4,5
	else
		-- Snake coming back
		col = nCols - col -- 5,4,3,2,1
	end

	return row,col
end

local nRows=5
local nCols=5
local n = nRows*nCols
local str = ""
local expected = "[01]={5,1}, [02]={5,2}, [03]={5,3}, [04]={5,4}, [05]={5,5}, \n[06]={4,5}, [07]={4,4}, [08]={4,3}, [09]={4,2}, [10]={4,1}, \n[11]={3,1}, [12]={3,2}, [13]={3,3}, [14]={3,4}, [15]={3,5}, \n[16]={2,5}, [17]={2,4}, [18]={2,3}, [19]={2,2}, [20]={2,1}, \n[21]={1,1}, [22]={1,2}, [23]={1,3}, [24]={1,4}, [25]={1,5}, \n"
for i=0, nRows-1 do
	for j=0, nCols-1 do
		local k = i*nRows+j+1
		local row,col = mapMachineIDToCoordinates(k, nRows, nCols)
		str = str .. string.format("[%02d]={%d,%d}, ", k, row, col)
	end
	str = str .. "\n"
end
assert(str == expected, "test fail: mapMachineIDToCoordinates wrong results")

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
local h2 = nineStonesRecipe:hash()
assert(type(h1) == "string", "h1 must be a string")
assert(type(h2) == "string", "h2 must be a string")
assert(h1 == h2, "hashes don't match")
print("All tests OK!")

local iEmpty = Inventory.fromTable({})
assert(iEmpty ~= nil, "iEmpty should not be nil")
assert(iEmpty:isEmpty() == true, "iEmpty should have an empty inventory")
local iEmptyHash = iEmpty:hash()


local i1 = Inventory.fromTable({
	{name = "minecraft:stone", count = 3},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 1},
	{name = "minecraft:stone", count = 4},
})
assert(i1 ~= nil, "i1 should not be nil")
local i1Hash = i1:hash()

local i2 = Inventory.fromTable({
	{name = "minecraft:stone", count = 3},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 1},
	{name = "minecraft:stone", count = 4},
})
assert(i2 ~= nil, "i2 should not be nil")
local i2Hash = i2:hash()

local i3 = Inventory.fromTable({
	{name = "minecraft:stone", count = 3},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 1},
	{name = "minecraft:stone", count = 1},
	{name = "minecraft:stone", count = 4},
})
assert(i3 ~= nil, "i3 should not be nil")
local i3Hash = i3:hash()

local i4 = Inventory.fromTable({
	{name = "minecraft:stone", count = 4},
})
assert(i4 ~= nil, "i4 should not be nil")
local i4Hash = i4:hash()

assert(i1:isEqual(i2), "i1 should be equal to i2")
assert(not i1:isEqual(i3), "i1 should not be equal to i3")
assert(not i1:isEqual(i4), "i1 should not be equal to i4")
assert(not i1:isEqual(iEmpty), "i1 should not be equal to iEmpty")
assert(not iEmpty:isEqual(i1), "iEmpty should not be equal to i1")
assert(i1:isEmpty() == false, "i1 should have a non-empty inventory")
assert(i2:isEmpty() == false, "i2 should have a non-empty inventory")
assert(i3:isEmpty() == false, "i3 should have a non-empty inventory")
assert(i4:isEmpty() == false, "i4 should have a non-empty inventory")
assert(i1:hash() == i1Hash, "i1 should have an unchanged inventory")
assert(i2:hash() == i2Hash, "i2 should have an unchanged inventory")
assert(i3:hash() == i3Hash, "i3 should have an unchanged inventory")
assert(i4:hash() == i4Hash, "i4 should have an unchanged inventory")

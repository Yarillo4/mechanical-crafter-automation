term, sleep, shell, peripheral, textutils, fs, colors, redstone, http, turtle, settings, keys = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
require("stdlib")
local Recipe = require("recipe")
local MechanicalCrafter = require("mechanical_crafter")

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

local function stprint(tbl, indent)
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
			toprint = toprint .. stprint(v, indent + 2) .. ",\r\n"
		else
			toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
		end
	end
	toprint = toprint .. string.rep(" ", indent-2) .. "}"
	return toprint
end

local function tprint(tbl)
	print(stprint(tbl))
end

local recipe = Recipe.new({
	{"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
	{"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
	{"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
}, 3, 3)

local list = {
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:cobdlestone", count = 64},
	{name = "minecraft:cobdlestone", count = 48},
	{name = "minecraft:cobblestone", count = 5},
	{name = "minecraft:cobblestone", count = 9}
}

local inv = Inventory.new(list)
local canMake = inv:canMake(recipe)
assert(canMake == true, "test fail: canMake should've been true, it wasn't")


local nineStonesInv = Inventory.new({
	{name = "minecraft:stone", count = 3},
	{name = "minecraft:stone", count = 0},
	{name = "minecraft:stone", count = 1},
	{name = "minecraft:stone", count = 4},
})
local nineStonesRecipe = Recipe.new({
	{"minecraft:stone", "minecraft:stone", "minecraft:stone"},
	{"minecraft:stone", nil, "minecraft:stone"},
	{"minecraft:stone", "minecraft:stone", "minecraft:stone"},
}, 3, 3)

local h1 = nineStonesInv:hash()
local h2 = nineStonesRecipe:hash()
assert(type(h1) == "string", "h1 must be a string")
assert(type(h2) == "string", "h2 must be a string")
assert(h1 == h2, "hashes don't match")

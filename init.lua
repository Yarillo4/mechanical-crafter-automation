require("stdlib")
require("inventory_addon")
local Recipe = require("recipe")
local MechanicalCrafterConfiguration = require("mechanical_crafter")

local tArgs = {...}
local input = peripheral.wrap("sophisticatedstorage:barrel_1")
local output = peripheral.wrap("sophisticatedstorage:barrel_2")
local rows = 5
local columns = 5

local recipes = {
    ["create:crushing_wheel"]=Recipe.new({
        {nil, "create:andesite_alloy", "create:andesite_alloy", "create:andesite_alloy", nil},
        {"create:andesite_alloy", "create:andesite_alloy", "minecraft:oak_planks", "create:andesite_alloy", "create:andesite_alloy"},
        {"create:andesite_alloy", "minecraft:oak_planks", "minecraft:stone", "minecraft:oak_planks", "create:andesite_alloy"},
        {"create:andesite_alloy", "create:andesite_alloy", "minecraft:oak_planks", "create:andesite_alloy", "create:andesite_alloy"},
        {nil, "create:andesite_alloy", "create:andesite_alloy", "create:andesite_alloy", nil},
    })
}

--- Crafters are connected in a certain order (see `promptUserForMachinesConfiguration()`),
--- this function matches the `n`th crafter to its 2D coordinates `(x,y)` on the crafter grid
--- 
---@param n number Cell ID `1 <= n < nRows*nCols`
---@param nRows number Number of rows `1 <= nRows < +inf`
---@param nCols number Number of columns `1 <= nCols < +inf`
---@return number row
---@return number column
--[[
#### Example mapping for a 5x5 grid with:
* origin {1,1} is at the top left
* final cell {5,5} at the bottom right (excel sheet layout)

```
    [01]={5,1}, [02]={5,2}, [03]={5,3}, [04]={5,4}, [05]={5,5},
    [06]={4,5}, [07]={4,4}, [08]={4,3}, [09]={4,2}, [10]={4,1},
    [11]={3,1}, [12]={3,2}, [13]={3,3}, [14]={3,4}, [15]={3,5},
    [16]={2,5}, [17]={2,4}, [18]={2,3}, [19]={2,2}, [20]={2,1},
    [21]={1,1}, [22]={1,2}, [23]={1,3}, [24]={1,4}, [25]={1,5},
```
--]]
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

---
---@param rows number
---@param columns number
---@return Result
local function promptUserForMachinesConfiguration(rows, columns)
    local numberOfMachines = rows*columns
    term.clear()
    term.setCursorPos(1,1)
    print("Please connect the crafters in that order:")
    print("     # > # > # > # > #")
    print("     ^                ")
    print("     # < # < # < # < #")
    print("                     ^")
    print("     # > # > # > # > #")
    print("     ^                ")
    print("     # < # < # < # < #")
    print("                     ^")
    print("Me > # > # > # > # > #")
    print("")
    print("Waiting...")
    local x,y = term.getCursorPos()
    local knownMachines = {}     -- set of names
    local knownMachinesCount = 0 -- number of elements in `knownMachines`
    ---@type MechanicalCrafterConfiguration
    local machineSetup = MechanicalCrafterConfiguration.new() -- 2d array of Crafter objects
    local i=0
    local maxNumberOfIterationsBeforeTimeout = 12000 -- times out after 10 minutes


    -- Build a 2D directory of machines
    while knownMachinesCount < numberOfMachines do
        --[[
            Small parenthesis.
                This loop is expensive
                If the user is idle, die after 10 minutes spent here
        --]]
        i = i+1
        
        ---@diagnostic disable-next-line: undefined-field
        if (i > maxNumberOfIterationsBeforeTimeout) then os.shutdown() end

        --[[
            Actual logic resumes
        --]]
        local current = peripheral.getNames(tArgs[2] or "create:mechanical_crafter")

        for _,machineName in pairs(current) do
            if knownMachines[machineName] == nil then
                knownMachines[machineName] = true
                knownMachinesCount = knownMachinesCount+1

                local row,col = mapMachineIDToCoordinates(knownMachinesCount, rows, columns)
                machineSetup:addCrafter(machineName, row, col)

                local txt = string.format("%d/%d crafters connected.", knownMachinesCount, numberOfMachines)
                term.setCursorPos(x,y)
                term.clearLine()
                print(txt)
            end
        end

        if #current < knownMachinesCount then
            return Result.err("A machine got disconnected :(. Please re-do the process all over again")
        end

        sleep()
    end
    print("Connected!")

    return Result.ok(machineSetup)
end

local function askDisconnectMachines()
    while true do
        local machines = {peripheral.find(tArgs[2] or "create:mechanical_crafter")}
        local n = table.count(machines)
        if (n <= 0) then
            break
        end
        term.clear()
        term.setCursorPos(1,1)
        print("Please disconnect every mechanical crafter from the network.")
        local txt = string.format("There are still %d crafters connected.", n)
        term.setCursorPos(1,4)
        term.clearLine()
        term.write(txt)
        sleep(1)
    end
end

--[[##############################################
###                                            ###
###                   Main                     ###
###                                            ###
################################################]]

--- Configs as loaded either from disk or generated from the user being prompted
---@type MechanicalCrafterConfiguration
local config

local result = MechanicalCrafterConfiguration.loadFromDisk()
if not result.isOk then
    -- Couldn't load from disk, we have to generate
    askDisconnectMachines()
    result = promptUserForMachinesConfiguration(rows, columns)

    if not result.isOk then
        Debug.fatal("Couldn't figure out the crafter configuration!\n" .. result:asError().msg)
        return
    end

    config = result:asOK()
    config:saveToDisk()
end

config = result:asOK() --[[@as MechanicalCrafterConfiguration]]

local recipeHashes = {}
for i,v in pairs(recipes) do
    recipeHashes[i] = v:hash()
end

while true do
    local inputHash = Inventory.new(input.list()):hash()

    for i,v in pairs(recipeHashes) do
        if v == inputHash then
            -- Craft
            local outputHash = Inventory.new(output.list()):hash()
            config:placeRecipe(recipes[i], input)
            redstone.pulse("all", 1)

            -- Wait for change
            local currHash
            repeat
                sleep(0.5)
                currHash = Inventory.new(output.list()):hash()
            until currHash ~= outputHash
        end
    end
end


require("stdlib")
local tArgs = {...}

local rows = 5
local columns = 5

local function byName(machines)
    local t = {}
    for _,v in pairs(machines) do
        local name = peripheral.getName(v)
        t[name] = v
    end

    return t
end

local function normalize(machines)
    for i,v in pairs(machines) do
        if (not v.list) then
            v.list = v.getInventory
        end
    end

    return machines
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

---@param n number Cell ID `1 <= n < nRows*nCols`
---@param nRows number Number of rows `1 <= nRows < +inf`
---@param nCols number Number of columns `1 <= nCols < +inf`
---@return number row
---@return number column
--[[
#### Example mapping for a 5x5 grid with:
* let [n]={x,y}
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

---@class MechanicalCrafter
---@field name string Actual peripheral name
---@field periph table|nil Reference to the peripheral's wrap
---@field row number
---@field column number
local MechanicalCrafter = {}

---Constructor
---@return MechanicalCrafter
function MechanicalCrafter.wrap(name, row, column)
    local instance = {
        name=name,
        row=row,
        column=column,
        periph=peripheral.wrap(name)
    }
    setmetatable(instance, {__index=MechanicalCrafter})
    return instance
end

---@class MechanicalCrafterConfiguration
---@field crafters MechanicalCrafter[][]
local MechanicalCrafterConfiguration = {}

---Constructor
---@return MechanicalCrafterConfiguration
function MechanicalCrafterConfiguration.new()
    local instance = {
        crafters = {
        }
    }
    setmetatable(instance, {__index=MechanicalCrafterConfiguration})
    return instance
end

---Insert
---@param crafter MechanicalCrafter
function MechanicalCrafterConfiguration:push(crafter)
    local row = crafter.row
    local column = crafter.column

    if self.crafters[row] == nil then
        self.crafters[row] = {}
    end

    self.crafters[row][column] = crafter
end

---@alias CrafterSaveData {name: string}
---@alias SaveData { crafters: CrafterSaveData[][] }

---Save to disk
---@return Result
function MechanicalCrafterConfiguration:saveToDisk()
    ---@type SaveData
    local saveData = {
        crafters = {}
    }

    for row in pairs(self.crafters) do
        saveData.crafters[row] = {}

        for col in pairs(self.crafters[row]) do
            local v = self.crafters[row][col]
            saveData.crafters[row][col] = {
                name = v.name,
            }
        end
    end

    local worked, json = pcall(textutils.serializeJSON, saveData)
    if not worked then
        return Result.err("Couldn't save the crafter layout: " + tostring(json))
    end

    local f, err = fs.open("crafter_layout.json", "w")
    if not f then
        ---@cast err string
        return Result.err(err)
    end

    f.write(json)
    f.close()

    return Result.ok(nil)
end

---Load from disk
---@return Result
function MechanicalCrafterConfiguration.loadFromDisk()
    local f, err = fs.open("crafter_layout.json", "r")
    if not f then
        ---@cast err string
        return Result.err(err)
    end

    local json = f.readAll()
    f.close()

    local worked, data = pcall(textutils.unserializeJSON, json)
    if not worked then
        return Result.err("Couldn't parse json, " .. tostring(data))
    end

    if not data or not data.crafters then
        return Result.err("Json was parsed but the save file doesn't seem to contain json")
    end

    ---@cast data SaveData
    local config = MechanicalCrafterConfiguration.new()

    for row in pairs(data.crafters) do
        for col in pairs(data.crafters[row]) do
            local v = data.crafters[row][col]
            local crafter = MechanicalCrafter.wrap(v.name, row, col)
            config:push(crafter)
        end
    end

    return Result.ok(config)
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
                local crafter = MechanicalCrafter.wrap(machineName, row, col)

                machineSetup:push(crafter)

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


--- Configs as loaded either from disk or generated from the user being prompted
---@type MechanicalCrafterConfiguration
local config

-- 
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

more(config)


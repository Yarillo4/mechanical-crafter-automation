--[[##############################################
###                                            ###
###         @class MechanicalCrafter           ###
###                                            ###
################################################]]

---@class MechanicalCrafter
---@field name string Actual peripheral name
---@field periph table|nil Reference to the peripheral's wrap
---@field row number
---@field column number
local MechanicalCrafter = {}

---Constructor
---@param name string
---@param row number
---@param column number
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


--[[##############################################
###                                            ###
###   @class MechanicalCrafterConfiguration    ###
###                                            ###
################################################]]

---@alias CrafterSaveData {name: string}
---@alias SaveData { crafters: CrafterSaveData[][] }

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
---@param crafterName string
---@param row number
---@param column number
function MechanicalCrafterConfiguration:addCrafter(crafterName, row, column)
    local crafter = MechanicalCrafter.wrap(crafterName, row, column)

    if self.crafters[row] == nil then
        self.crafters[row] = {}
    end

    self.crafters[row][column] = crafter
end

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
            config:addCrafter(v.name, row, col)
        end
    end

    return Result.ok(config)
end

---Push items from the input chest to the crafters
---@param recipe Recipe
---@param input table Inventory peripheral with function pushItems
function MechanicalCrafterConfiguration:placeRecipe(recipe, input)
    local everythingWorked = true
    local inputInv = Inventory.new(input.list())
	for row in pairs(recipe.pattern) do
		for col in pairs(recipe.pattern[row]) do
            local v = recipe.pattern[row][col]
            local slot = inputInv:find(v)
            
            if (slot) then
                local crafter = self.crafters[row][col]
                local worked, actuallyPushed = pcall(input.pushItems, crafter.name, slot, 1)
                if not worked then
                    everythingWorked = false
                    Debug.errorf("Error pushing %s x%d to %s (%d,%d), %s", v, 1, crafter.name, crafter.row, crafter.column, actuallyPushed)
                else
                    Debug.infof("Pushed %s x%d to %s (%d,%d)", v, 1, crafter.name, crafter.row, crafter.column)
                end
            end
        end
    end
end

return MechanicalCrafterConfiguration, MechanicalCrafter
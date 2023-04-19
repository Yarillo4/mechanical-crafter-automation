local tArgs = {...}

local function github(rfile, lfile)
    if fs.exists(lfile) then
        fs.delete(lfile)
    end

    shell.run("wget", "https://raw.githubusercontent.com/Yarillo4/" .. rfile, lfile)
end

local function dl(lfile)
    shell.run("dl", lfile)
end

if tArgs[1] and tArgs[1] == "--dev" then
    dl("stdlib")
    if fs.exists("stdlib/init.lua") then
        fs.delete("stdlib/init.lua")
    end
    fs.move("stdlib.lua", "stdlib/init.lua")

    dl("mechanical_crafter")
    dl("inventory_addon")
    dl("test")
    dl("recipe")
    dl("init")
else
    github("stdlib/main/init.lua", "stdlib/init.lua")
    github("mechanical-crafter-automation/main/mechanical_crafter.lua", "mechanical_crafter.lua")
    github("mechanical-crafter-automation/main/inventory_addon.lua", "inventory_addon.lua")
    github("mechanical-crafter-automation/main/init.lua", "init.lua")
    github("mechanical-crafter-automation/main/test.lua", "test.lua")
    github("mechanical-crafter-automation/main/recipe.lua", "recipe.lua")
end

shell.run("init.lua")

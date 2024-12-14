-- Initials
----------------------------------------------------------------

local Addon = {
    name = "HonestWrits",
    version = "0.1",
    date = "2024-12-14",
    title = "Honest Writs",
    authors = "Serious Angel",
    init = false,
    options = {},

    meta = {
        svVersion = "1"
    }
}

local defaultOptions = {
    ["STATIONS"] = {
        ["ALCHEMY"] = true,
        ["ENCHANTING"] = true
    }
}

Addon.stations = {
    alchemy = nil
}

-- Functions (General)
----------------------------------------------------------------

local function printC(msg)
    CHAT_SYSTEM:AddMessage(msg)
end

local function _PrintFA(msg)
    printC(string.format("|c333333[Honest Writs] |c888888" .. Addon.title .. "|c333333:|r %s", msg))
end

local function notification(msg)
    CENTER_SCREEN_ANNOUNCE:AddMessage(999, CSA_EVENT_LARGE_TEXT, snd, msg)
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, msg)
end

-- Functions
----------------------------------------------------------------

-- @dependsOn LibAddonMenu (v2.0)
local function InitializeOptions(...)
    LibAddonMenu2:RegisterAddonPanel(Addon.name .. "_Config", {
        type = "panel",
        name = Addon.name,
        displayName = "|cFFFFFF" .. Addon.title .. "|r",
        author = tostring(Addon.authors),
        version = tostring(Addon.version),
        registerForRefresh = true,
        registerForDefaults = true
    })

    Addon.options = ZO_SavedVars:NewAccountWide(Addon.name .. "SavedVars", Addon.meta.svVersion, GetWorldName(), defaultOptions)

    local optionsData={
        {
            type = "checkbox",
            name = "Alchemy",
            tooltip = "Hide writ quest pins on alchemy crafting stations.",
            default = true,
            getFunc = function() return Addon.options["STATIONS"]["ALCHEMY"] end,
            setFunc = function(value) Addon.options["STATIONS"]["ALCHEMY"] = value end,
        },
        {
            type = "checkbox",
            name = "Enchanting",
            tooltip = "Hide writ quest pins on enchanting crafting stations.",
            default = true,
            getFunc = function() return Addon.options["STATIONS"]["ENCHANTING"] end,
            setFunc = function(value) Addon.options["STATIONS"]["ENCHANTING"] = value end,
        },
    }

    LibAddonMenu2:RegisterOptionControls(Addon.name .. "_Config", optionsData)
end

local function SetAlchemyCraftingStationHooks()
    if not Addon.stations.alchemy then
        _PrintFA("[-] No alchemy station found.")

        return false
    end

    if Addon.stations.alchemy._honestWrits then
        -- _PrintFA("[ ] Alchemy hooks are set already.")

        return true
    end

    local alchemyStation = Addon.stations.alchemy

    if not (alchemyStation.creationButton and alchemyStation.recipeButton) then
        _PrintFA("[-] Not appropriate alchemy station.")

        return false
    end

    local list = Addon.stations.alchemy.inventory.list
    local listContents = list:GetChild(1)

    if not listContents then
        return false
    end

    local solventsListControl = list.dataTypes[1]
    local reagentsListControl = list.dataTypes[2]

    if not (solventsListControl.setupCallback and reagentsListControl.setupCallback) then
        _PrintFA("[-] Could not find original setup functions")

        return false
    end

    local enabledStations = Addon.options["STATIONS"]

    SecurePostHook(solventsListControl, "setupCallback", function(rowControl, data)
        if not enabledStations["ALCHEMY"] then
            return false
        end

        local questPin = rowControl:GetNamedChild("QuestPin")

        if not questPin then
            return
        end

        questPin:SetHidden(true)
    end)

    SecurePostHook(reagentsListControl, "setupCallback", function(rowControl, data)
        if not enabledStations["ALCHEMY"] then
            return false
        end

        local questPin = rowControl:GetNamedChild("QuestPin")

        if not questPin then
            return
        end

        questPin:SetHidden(true)
    end)

    _PrintFA("[+] Set alchemy station hooks")

    alchemyStation._honestWrits = true

    return true
end

local function SetEnchantingCraftingStationHooks()
    if not Addon.stations.enchanting then
        _PrintFA("[-] No enchanting station found.")

        return false
    end

    if Addon.stations.enchanting._honestWrits then
        -- _PrintFA("[ ] Enchanting hooks are set already.")

        return true
    end

    local enchantingStation = Addon.stations.enchanting

    if not (enchantingStation.creationButton and enchantingStation.recipeButton) then
        _PrintFA("[-] Not appropriate enchanting station.")

        return false
    end

    local list = enchantingStation.inventory.list
    local listContents = list:GetChild(1)

    if not listContents then
        return false
    end

    local itemsListControl = list.dataTypes[1]

    if not (itemsListControl.setupCallback) then
        _PrintFA("[-] Could not find original setup functions")

        return false
    end

    local enabledStations = Addon.options["STATIONS"]

    SecurePostHook(itemsListControl, "setupCallback", function(rowControl, data)
        if not enabledStations["ENCHANTING"] then
            return false
        end

        local questPin = rowControl:GetNamedChild("QuestPin")

        if not questPin then
            return
        end

        questPin:SetHidden(true)
    end)

    _PrintFA("[+] Set enchanting station hooks")

    enchantingStation._honestWrits = true

    return true
end

local function SetHooks()
    EVENT_MANAGER:RegisterForEvent(Addon.name .. "_OnCraftingStationInteract", EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, isCraftingSameAsPrevious)
        if craftingType == CRAFTING_TYPE_ALCHEMY then
            if not Addon.stations.alchemy or Addon.stations.alchemy._honestWrits ~= 1 then
                Addon.stations.alchemy = ALCHEMY

                SetAlchemyCraftingStationHooks()
            end

            return
        end

        if craftingType == CRAFTING_TYPE_ENCHANTING then
            if not Addon.stations.enchanting or Addon.stations.enchanting._honestWrits ~= 1 then
                Addon.stations.enchanting = ENCHANTING

                SetEnchantingCraftingStationHooks()
            end

            return
        end

        -- EVENT_MANAGER:UnregisterForEvent(Addon.name .. "_OnCraftingStationInteract", EVENT_CRAFTING_STATION_INTERACT)
    end)
end

-- Main
----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(Addon.name .. "_OnAddonLoaded", EVENT_ADD_ON_LOADED, function(event, addonName)
    if (addonName ~= Addon.name)
    then
        return
    end

    InitializeOptions()
    SetHooks()

    Addon.init = true

    EVENT_MANAGER:UnregisterForEvent(Addon.name .. "_OnAddonLoaded", EVENT_ADD_ON_LOADED)
end)
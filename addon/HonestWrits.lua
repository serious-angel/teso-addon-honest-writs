-- Initials
----------------------------------------------------------------

local Addon = {
    name    = 'HonestWrits',
    title   = 'Honest Writs',
    version = '1.1.0',
    options = {},

    meta = {
        init      = false,
        svVersion = '1'
    },

    data = {
        stations = {},
    }
}

local defaultOptions = {
    ['STATIONS'] = {
        ['ALCHEMY']    = false,
        ['ENCHANTING'] = false
    }
}

-- Functions (General)
----------------------------------------------------------------

local function _P(msg)
    CHAT_SYSTEM:AddMessage(string.format('[|cFF2222D|r] [|cFFD966' .. Addon.title .. '|r] %s', tostring(msg)))
end

-- Functions
----------------------------------------------------------------

local function _InitializeOptions(...)
    LibAddonMenu2:RegisterAddonPanel(Addon.name .. '_Config', {
        type                = 'panel',
        name                = Addon.name,
        displayName         = '|cFFD966' .. Addon.title .. '|r',
        author              = '|cFFFFFFSerious Angel|r',
        version             = Addon.version,
        registerForRefresh  = true,
        registerForDefaults = true,
        website             = 'https://esoui.com/downloads/fileinfo.php?id=4011',
    })

    Addon.options = ZO_SavedVars:NewAccountWide(Addon.name .. 'SavedVars', Addon.meta.svVersion, GetWorldName(), defaultOptions)

    local optionsData={
        {
            type = 'header',
            name = 'Reveal Writ Quest Pins T',
        },
        {
            type    = 'checkbox',
            name    = 'Alchemy (Ingredients)',
            default = defaultOptions['STATIONS']['ALCHEMY'],
            getFunc = function() return Addon.options['STATIONS']['ALCHEMY'] end,
            setFunc = function(value) Addon.options['STATIONS']['ALCHEMY'] = value end,
        },
        {
            type    = 'checkbox',
            name    = 'Enchanting (Runes)',
            default = defaultOptions['STATIONS']['ENCHANTING'],
            getFunc = function() return Addon.options['STATIONS']['ENCHANTING'] end,
            setFunc = function(value) Addon.options['STATIONS']['ENCHANTING'] = value end,
        },
    }

    LibAddonMenu2:RegisterOptionControls(Addon.name .. '_Config', optionsData)
end

local function _HandleQuestPin(station, rowControl, data)
    -- Try all common quest pin references
    local questPin =
        rowControl.questPin or
        rowControl.questIcon or
        rowControl:GetNamedChild("QuestPin")

    -- If no quest pin found
    if not questPin then
        return
    end

    local initialVisibility = questPin:IsHidden() == false

    -- If already hidden
    if not initialVisibility then
        return
    end

    -- _P('[+] Found a visible Quest pin.')

    questPin:SetHidden(true)

    local visibility = questPin:IsHidden() == false

    -- If still is shown
    if visibility == initialVisibility then
        _P("[-] Sorry. Failed to hide a Quest pin: " .. tostring(questPin:GetName()))
    end
end

local function _SetAlchemyCraftingStationHooks()
    if not Addon.data.stations.alchemy then
        _P('[-] No alchemy station found.')

        return false
    end

    -- If already set
    if Addon.data.stations.alchemy._honestWrits then
        return true
    end

    local alchemyStation = Addon.data.stations.alchemy

    if not (alchemyStation.creationButton and alchemyStation.recipeButton) then
        _P('[-] Not appropriate alchemy station.')

        return false
    end

    local list = Addon.data.stations.alchemy.inventory.list

    if not list then
        return false
    end

    local listContents = list:GetChild(1)

    if not listContents then
        return false
    end

    local solventsListControl = list.dataTypes[1]
    local reagentsListControl = list.dataTypes[2]

    if not (solventsListControl.setupCallback and reagentsListControl.setupCallback) then
        _P('[-] Could not find original setup function(s) for alchemy.')

        return false
    end

    local enabledStations = Addon.options['STATIONS']

    -- Set the hook to hide quest pins for Alchemy Solvents.

    SecurePostHook(solventsListControl, 'setupCallback', function(rowControl, data)
        if enabledStations['ALCHEMY'] then
            return false
        end

        _HandleQuestPin('alchemy_solvents', rowControl, data)
    end)

    -- Set the hook to hide quest pins for Alchemy Reagents.

    SecurePostHook(reagentsListControl, 'setupCallback', function(rowControl, data)
        if enabledStations['ALCHEMY'] then
            return false
        end

        _HandleQuestPin('alchemy_reagents', rowControl, data)
    end)

    alchemyStation._honestWrits = true

    return true
end

local function _SetEnchantingCraftingStationHooks()
    if not Addon.data.stations.enchanting then
        _P('[-] No enchanting station found.')

        return false
    end

    if Addon.data.stations.enchanting._honestWrits then
        return true
    end

    local enchantingStation = Addon.data.stations.enchanting

    if not (enchantingStation.creationButton and enchantingStation.recipeButton) then
        _P('[-] Not appropriate enchanting station.')

        return false
    end

    local list = enchantingStation.inventory.list

    if not list then
        return false
    end

    local listContents = list:GetChild(1)

    if not listContents then
        return false
    end

    local runesListControl = list.dataTypes[1]

    if not runesListControl then
        _P('[-] Could not find original setup function for enchanting.')

        return false
    end

    local enabledStations = Addon.options['STATIONS']

    -- Set the hook to hide quest pins for Enchanting Runes.

    SecurePostHook(runesListControl, "setupCallback", function(rowControl, data)
        if enabledStations['ENCHANTING'] then
            return false
        end

        _HandleQuestPin('enchanting_runes', rowControl, data)
    end)

    enchantingStation._honestWrits = true

    return true
end

local function _SetHooks()
    if Addon.meta.init then
        return
    end

    EVENT_MANAGER:RegisterForEvent(Addon.name .. '_OnCraftingStationInteract', EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, isCraftingSameAsPrevious)
        if craftingType == CRAFTING_TYPE_ALCHEMY then
            -- If not yet set
            if not Addon.data.stations.alchemy or not Addon.data.stations.alchemy._honestWrits then
                Addon.data.stations.alchemy = ALCHEMY

                _SetAlchemyCraftingStationHooks()
            end

            return
        end

        if craftingType == CRAFTING_TYPE_ENCHANTING then
            -- If not yet set
            if not Addon.data.stations.enchanting or not Addon.data.stations.enchanting._honestWrits then
                Addon.data.stations.enchanting = ENCHANTING

                _SetEnchantingCraftingStationHooks()
            end

            return
        end
    end)
end

-- Main
----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(Addon.name .. '_OnAddonLoaded', EVENT_ADD_ON_LOADED, function(event, addonName)
    if addonName ~= Addon.name or Addon.meta.init then
        return
    end

    _InitializeOptions()
    _SetHooks()

    Addon.meta.init = true

    EVENT_MANAGER:UnregisterForEvent(Addon.name .. '_OnAddonLoaded', EVENT_ADD_ON_LOADED)
end)
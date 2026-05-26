-- Initials
----------------------------------------------------------------

local Addon = {
    name    = 'HonestWrits',
    title   = 'Honest Writs',
    version = '1.2.0',
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
        ['ENCHANTING'] = false,
        ['SMITHING']= false,

        -- todo: Add support for separate smithing stations
        -- ['BLACKSMITHING']= false,
        -- ['CLOTHING']     = false,
        -- ['WOODWORKING']  = false
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
        {
            type    = 'checkbox',
            name    = 'Smithing',
            default = defaultOptions['STATIONS']['SMITHING'],
            getFunc = function() return Addon.options['STATIONS']['SMITHING'] end,
            setFunc = function(value) Addon.options['STATIONS']['SMITHING'] = value end,
        },

        -- todo: Add support for separate smithing stations
        -- {
        --     type    = 'checkbox',
        --     name    = 'Blacksmithing',
        --     default = defaultOptions['STATIONS']['BLACKSMITHING'],
        --     getFunc = function() return Addon.options['STATIONS']['BLACKSMITHING'] end,
        --     setFunc = function(value) Addon.options['STATIONS']['BLACKSMITHING'] = value end,
        -- },
        -- {
        --     type    = 'checkbox',
        --     name    = 'Clothing',
        --     default = defaultOptions['STATIONS']['CLOTHING'],
        --     getFunc = function() return Addon.options['STATIONS']['CLOTHING'] end,
        --     setFunc = function(value) Addon.options['STATIONS']['CLOTHING'] = value end,
        -- },
        -- {
        --     type    = 'checkbox',
        --     name    = 'Woodworking',
        --     default = defaultOptions['STATIONS']['WOODWORKING'],
        --     getFunc = function() return Addon.options['STATIONS']['WOODWORKING'] end,
        --     setFunc = function(value) Addon.options['STATIONS']['WOODWORKING'] = value end,
        -- },
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

    -- If still is visible
    if visibility == initialVisibility then
        _P("[-] Sorry. Failed to hide a Quest pin: " .. tostring(questPin:GetName()))
        _P("[-] Control: " .. tostring(rowControl:GetName()))

        return
    end

    -- _P('[+] Hid Quest pin in: ' .. tostring(station))
end

local function _SetAlchemyCraftingStationHooks()
    if not Addon.data.stations.alchemy then
        _P('[-] No Alchemy station found.')

        return false
    end

    -- If already set
    if Addon.data.stations.alchemy._honestWrits then
        return true
    end

    local alchemyStation = Addon.data.stations.alchemy

    if not (alchemyStation.creationButton and alchemyStation.recipeButton) then
        _P('[-] Not appropriate Alchemy station.')

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
        _P('[-] Could not find original setup function(s) for Alchemy station.')

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
        _P('[-] No Enchanting station found.')

        return false
    end

    if Addon.data.stations.enchanting._honestWrits then
        return true
    end

    local enchantingStation = Addon.data.stations.enchanting

    if not (enchantingStation.creationButton and enchantingStation.recipeButton) then
        _P('[-] Not appropriate Enchanting station.')

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
        _P('[-] Could not find original setup function for Enchanting station.')

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

local function _SetSmithingCraftingStationHooks(craftingType)
    if not Addon.data.stations.smithing then
        _P('[-] No smithing station found.')

        return false
    end

    -- If already set hooks
    if Addon.data.stations.smithing._honestWrits then
        return true
    end

    local smithingStation = Addon.data.stations.smithing

    if not (smithingStation.creationButton and smithingStation.recipeButton) then
        _P('[-] Not appropriate Smithing station.')

        return false
    end

    local stationObject = smithingStation
    local enabledStations = Addon.options['STATIONS']
    local creationPanel = stationObject.creationPanel

    if not creationPanel then
        return false
    end

    -- Handle Types (e.g. Weapons, Apparel etc.)
    local function _HandleTypeTabs(tabsControl)
        -- If we should not hide the Quest pins for the now "enabled" station
        if enabledStations['SMITHING'] then
            return false
        end

        local tabs = tabsControl:GetNumChildren()

        -- Each tab (e.g. 2=Weapons, 4=Apparel etc.)
        for i = 1, tabs do
            local tabControl = tabsControl:GetChild(i)

            if tabControl then
                local name = tabControl:GetName()

                _HandleQuestPin('smithing_creation_tab', tabControl, nil)
            end
        end
    end

    -- Handle Panel List (e.g. Patterns, Materials etc.)
    local function _HandlePanelList(list)
        if list.setupFunction then
            -- If we should not hide the Quest pins for the now "enabled" station
            if enabledStations['SMITHING'] then
                return false
            end

            -- Set the main hook (triggers on each scrolling event)
            SecurePostHook(list, 'setupFunction', function(control, data)
                if enabledStations['SMITHING'] then
                    return false
                end

                -- Type tabs may reset (e.g. on type change), so handle them again.
                _HandleTypeTabs(creationPanel.tabs)

                _HandleQuestPin('smithing_creation', control, data)
            end)

            -- Process existing items, if possible (e.g. the first viewable list, prior scrolling)
            if list.controls then
                for _, control in pairs(list.controls) do
                    if control then
                        _HandleQuestPin('smithing_creation_initial', control, nil)
                    end
                end
            end
        end
    end

    -- Hide already existing type tabs (e.g. Weapons, Apparel etc.)
    _HandleTypeTabs(creationPanel.tabs)

    -- Handle Pattern list (e.g. Cuirass, Sabatons, Gauntlets, Helm, Greeves, Pauldron, Girdle etc.)
    _HandlePanelList(creationPanel.patternList)

    -- Handle Material list (e.g. Iron Ingot, Steel Ingot, Orichalcum Ingot, Dwraven Ingnot, Ebony Ingot etc.)
    _HandlePanelList(creationPanel.materialList)

    -- Set hooks and initials for Smithing station

    smithingStation._honestWrits = true

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

        -- todo: Currently, this works for any "smithing" station, yet we need to separate them.
        if craftingType == CRAFTING_TYPE_BLACKSMITHING or craftingType == CRAFTING_TYPE_WOODWORKING or craftingType == CRAFTING_TYPE_CLOTHIER then
            -- If not yet set
            if not Addon.data.stations.smithing or not Addon.data.stations.smithing._honestWrits then
                -- On each mode change (1=Refine, 2=Creation, 3=Deconstruct, 4=Improvement, 5=Research, and 6=Diagrams)
                SecurePostHook(SMITHING, 'SetMode', function(_, mode)
                    -- If not "Creation" mode
                    if mode ~= 2 then
                        return
                    end

                    Addon.data.stations.smithing = SMITHING

                    -- _P('[ ] Setting hooks for Smithing station.')

                    _SetSmithingCraftingStationHooks(craftingType)
                end)
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
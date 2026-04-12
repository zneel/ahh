local ADDON_NAME, NS = ...

local SOUND_DIR = "Interface\\AddOns\\FAHH\\Sounds\\"
local PREFIX = "|cffff8800FAHH|r: "

local SOUNDS = {
    "fahh0.ogg",
    "fahh1.ogg",
    "fahh2.ogg",
    "fahh3.ogg",
    "fahh4.ogg",
}

local DEFAULTS = {
    enabled = true,
    dungeon = true,
    raid = true,
    world = false,
}

local CONTENT_KEYS = {
    party    = "dungeon",
    raid     = "raid",
    none     = "world",
}

local db
local deadUnits = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function PlayRandomFahh(debug)
    local path = SOUND_DIR .. SOUNDS[math.random(#SOUNDS)]
    local willPlay = PlaySoundFile(path, "Master")
    if debug then
        local tag = willPlay and "playing" or "|cffff0000FAILED|r"
        print(PREFIX .. tag .. ": " .. path)
    end
end

local function IsAllowedContent()
    local _, instanceType = GetInstanceInfo()
    local key = CONTENT_KEYS[instanceType]
    return key and db[key]
end

local function IsGroupUnit(unit)
    return UnitInParty(unit) or UnitInRaid(unit) or UnitIsUnit(unit, "player")
end

local function CheckUnitDeath(unit)
    if not db or not db.enabled then return end
    if not IsAllowedContent() then return end
    if not IsGroupUnit(unit) then return end

    if UnitIsDeadOrGhost(unit) then
        if not deadUnits[unit] then
            deadUnits[unit] = true
            PlayRandomFahh()
        end
    else
        deadUnits[unit] = nil
    end
end

local function ColorBool(val)
    return val and "|cff00ff00ON|r" or "|cffff0000OFF|r"
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------

local TOGGLES = { "dungeon", "raid", "world" }

local function HandleSlash(msg)
    local cmd = strtrim(msg):lower()

    if cmd == "" then
        db.enabled = not db.enabled
        print(PREFIX .. ColorBool(db.enabled))
        return
    end

    if cmd == "test" then
        PlayRandomFahh(true)
        return
    end

    if cmd == "status" then
        print(PREFIX .. ColorBool(db.enabled))
        for _, key in ipairs(TOGGLES) do
            print("  " .. key .. ": " .. ColorBool(db[key]))
        end
        return
    end

    for _, key in ipairs(TOGGLES) do
        if cmd == key then
            db[key] = not db[key]
            print(PREFIX .. key .. " " .. ColorBool(db[key]))
            return
        end
    end

    print(PREFIX .. "commands:")
    print("  /fahh          - toggle on/off")
    print("  /fahh status   - show all settings")
    for _, key in ipairs(TOGGLES) do
        print("  /fahh " .. key .. string.rep(" ", 10 - #key) .. "- toggle " .. key)
    end
    print("  /fahh test     - play the sound")
end

---------------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------------

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        FAHHDB = FAHHDB or {}
        db = FAHHDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end

        SLASH_FAHH1 = "/fahh"
        SlashCmdList["FAHH"] = HandleSlash
        self:UnregisterEvent("ADDON_LOADED")

        -- Register unfiltered UNIT_HEALTH for all units; handler filters by group membership.
        -- Escape restricted loading context before registering.
        C_Timer.After(0, function()
            self:RegisterEvent("UNIT_HEALTH")
        end)
    elseif event == "UNIT_HEALTH" then
        CheckUnitDeath(arg1)
    end
end)

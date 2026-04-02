local ADDON_NAME, NS = ...

local frame = CreateFrame("Frame")
local SOUND_DIR = "Interface\\AddOns\\FAHH\\Sounds\\"
local PREFIX = "|cffff8800FAHH|r: "

-- Add all your .ogg files here. Drop files into Sounds/ and list them below.
local SOUNDS = {
    "fahh0.ogg",
    "fahh1.ogg",
    "fahh2.ogg",
    "fahh3.ogg",
    "fahh4.ogg",
}

local function PlayRandomFahh(debug)
    local path = SOUND_DIR .. SOUNDS[math.random(#SOUNDS)]
    local willPlay, handle = PlaySoundFile(path, "Master")
    if debug then
        if willPlay then
            print(PREFIX .. "playing: " .. path)
        else
            print(PREFIX .. "|cffff0000FAILED|r: " .. path)
        end
    end
end

local DEFAULTS = {
    enabled = true,
    dungeon = true,
    raid = true,
    scenario = false,
    world = false,
}

-- Saved variables (loaded via ADDON_LOADED)
local db

-- Track which units are dead so we only fire once per death
local deadUnits = {}

local function IsAllowedContent()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "party" then return db.dungeon end
    if instanceType == "raid" then return db.raid end
    if instanceType == "scenario" then return db.scenario end
    if instanceType == "none" then return db.world end
    return false
end

local function CheckUnitDeath(unit)
    if not db or not db.enabled then return end
    if not IsAllowedContent() then return end
    if not UnitExists(unit) then return end

    if UnitIsDeadOrGhost(unit) then
        if not deadUnits[unit] then
            deadUnits[unit] = true
            PlayRandomFahh()
        end
    else
        deadUnits[unit] = nil
    end
end

local function GetGroupUnits()
    local units = { "player" }
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            units[#units + 1] = "party" .. i
        end
    end
    return units
end

local function RegisterGroupEvents()
    frame:UnregisterEvent("UNIT_HEALTH")
    deadUnits = {}

    local units = GetGroupUnits()
    for _, unit in ipairs(units) do
        frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    end
end

local function ColorBool(val)
    return val and "|cff00ff00ON|r" or "|cffff0000OFF|r"
end

local function PrintStatus()
    print(PREFIX .. ColorBool(db.enabled))
    print("  dungeon: " .. ColorBool(db.dungeon))
    print("  raid: " .. ColorBool(db.raid))
    print("  scenario: " .. ColorBool(db.scenario))
    print("  world: " .. ColorBool(db.world))
end

local function HandleSlash(msg)
    local cmd = strtrim(msg):lower()

    if cmd == "" then
        db.enabled = not db.enabled
        print(PREFIX .. ColorBool(db.enabled))
    elseif cmd == "status" then
        PrintStatus()
    elseif cmd == "dungeon" then
        db.dungeon = not db.dungeon
        print(PREFIX .. "dungeon " .. ColorBool(db.dungeon))
    elseif cmd == "raid" then
        db.raid = not db.raid
        print(PREFIX .. "raid " .. ColorBool(db.raid))
    elseif cmd == "scenario" then
        db.scenario = not db.scenario
        print(PREFIX .. "scenario " .. ColorBool(db.scenario))
    elseif cmd == "world" then
        db.world = not db.world
        print(PREFIX .. "world " .. ColorBool(db.world))
    elseif cmd == "test" then
        PlayRandomFahh(true)
    else
        print(PREFIX .. "commands:")
        print("  /fahh          - toggle on/off")
        print("  /fahh status   - show all settings")
        print("  /fahh dungeon  - toggle dungeons")
        print("  /fahh raid     - toggle raids")
        print("  /fahh scenario - toggle scenarios")
        print("  /fahh world    - toggle open world")
        print("  /fahh test     - play the sound")
    end
end

local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        FAHHDB = FAHHDB or {}
        db = FAHHDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end

        SLASH_FAHH1 = "/fahh"
        SlashCmdList["FAHH"] = HandleSlash
        frame:UnregisterEvent("ADDON_LOADED")

        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        RegisterGroupEvents()
    elseif event == "UNIT_HEALTH" then
        CheckUnitDeath(arg1)
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)

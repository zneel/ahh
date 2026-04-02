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

local function PlayRandomFahh()
    local path = SOUND_DIR .. SOUNDS[math.random(#SOUNDS)]
    PlaySoundFile(path, "Master")
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

local function IsGroupMember(guid)
    if UnitGUID("player") == guid then return true end

    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumGroupMembers() - 1
    else
        return false
    end

    for i = 1, count do
        if UnitGUID(prefix .. i) == guid then
            return true
        end
    end
    return false
end

local function IsAllowedContent()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "party" then return db.dungeon end
    if instanceType == "raid" then return db.raid end
    if instanceType == "scenario" then return db.scenario end
    if instanceType == "none" then return db.world end
    return false
end

local function OnCombatLogEvent()
    if not db or not db.enabled then return end
    if not IsAllowedContent() then return end

    local _, subEvent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
    if subEvent ~= "UNIT_DIED" then return end

    if IsGroupMember(destGUID) then
        PlayRandomFahh()
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
        PlayRandomFahh()
        print(PREFIX .. "playing test sound")
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

        frame:UnregisterEvent("ADDON_LOADED")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        SLASH_FAHH1 = "/fahh"
        SlashCmdList["FAHH"] = HandleSlash
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent()
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)

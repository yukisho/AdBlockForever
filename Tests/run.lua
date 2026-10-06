SlashCmdList = {}
function CreateFrame()
    local frame = {}
    function frame:SetScript(name, handler) if name == "OnEvent" then self.onEvent = handler end end
    function frame:RegisterEvent() end
    return frame
end
function ChatFrame_AddMessageEventFilter() end
function UnitGUID() return nil end
function GetTime() return 0 end
function time() return 0 end

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:gsub("Tests[/\\]run%.lua$", "")
if root == "" then root = "." end
local addon = {}
for _, module in ipairs({
    "Core.lua",
    "Core/Database.lua",
    "Core/Rules.lua",
    "Core/Transfer.lua",
    "Core/Classifier.lua",
    "Core/History.lua",
    "Core/Commands.lua",
    "Core/Chat.lua",
}) do
    assert(loadfile(root .. "/" .. module))("AdBlockForeverDev", addon)
end
addon.eventFrame.onEvent(addon.eventFrame, "ADDON_LOADED", "AdBlockForeverDev")
local fixtures = assert(loadfile(root .. "/Tests/fixtures.lua"))()

local failures = 0
for index, fixture in ipairs(fixtures) do
    local event = fixture.event or "CHAT_MSG_CHANNEL"
    local mode = event == "CHAT_MSG_WHISPER" and "guild-whisper" or nil
    local result = addon:ClassifyMessage(fixture.message, mode, event)
    local actual = result and result.category or false
    if actual ~= fixture.expected then
        failures = failures + 1
        print(string.format("FAIL %02d expected=%s actual=%s :: %s", index, tostring(fixture.expected), tostring(actual), fixture.message))
    end
end

addon:AddBlockedPhrase("boost sale", true)
local custom = addon:ClassifyMessage("Weekly BOOST SALE tonight", nil, "CHAT_MSG_CHANNEL")
if not custom or custom.category ~= "custom" then failures = failures + 1; print("FAIL custom phrase") end

addon:AddAllowedPhrase("boost sale", true)
if addon:ClassifyMessage("Weekly BOOST SALE tonight", nil, "CHAT_MSG_CHANNEL") then failures = failures + 1; print("FAIL allow phrase priority") end

addon:AddAllowedPlayer("TrustedPlayer", true)
if not addon:IsPlayerAllowed("TrustedPlayer-Realm") then failures = failures + 1; print("FAIL whitelist realm matching") end

addon.db.channelScopes.gold.WHISPER = false
if addon:ClassifyMessage("WTS GOLD cheap at example.com", "guild-whisper", "CHAT_MSG_WHISPER") then failures = failures + 1; print("FAIL whisper scope") end

local exported = addon:ExportSettings()
local ok = addon:ImportSettings(exported)
if not ok or not addon:IsPlayerAllowed("TrustedPlayer-Realm") then failures = failures + 1; print("FAIL settings round trip") end

local comparison = addon:GetSensitivityComparison("Enchanting services available", nil, "CHAT_MSG_CHANNEL")
if comparison.conservative ~= "allow" or comparison.balanced ~= "allow" or comparison.aggressive:match("^profession@") == nil then
    failures = failures + 1
    print("FAIL sensitivity comparison")
end
if addon:GetSensitivity("profession") ~= "balanced" then failures = failures + 1; print("FAIL sensitivity restoration") end

addon:ResetSection("stats")
if addon.db.stats.total ~= 0 or addon.db.stats.custom ~= 0 then failures = failures + 1; print("FAIL statistics reset") end

if failures > 0 then error(string.format("%d regression test(s) failed", failures)) end
print(string.format("AdBlock Forever regression suite passed: %d fixtures plus controls.", #fixtures))

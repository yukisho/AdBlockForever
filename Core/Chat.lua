local _, ABF = ...

local IsSecret = ABF.util.IsSecret
local initialized = false

local function ChatFilter(_, event, message, author, ...)
    if not ABF.db or not ABF.db.enabled or IsSecret(message) or IsSecret(author) then return false end
    local whisper = event == "CHAT_MSG_WHISPER"
    local guid = select(10, ...)
    local ownGuid = UnitGUID and UnitGUID("player")
    if guid and not IsSecret(guid) and not IsSecret(ownGuid) and guid == ownGuid then return false end
    if author and ABF:IsPlayerAllowed(author) then return false end

    local result = ABF:ClassifyMessage(message, whisper and "guild-whisper" or nil, event)
    if not result then return false end
    if whisper and result.category == "guild" then result.label = "Guild recruitment whisper" end
    local recorded = ABF:RecordBlocked(result, author, message, event, select(9, ...))
    if recorded and whisper then ABF:NotifyBlockedWhisper(ABF.recent[1]) end
    return true
end

local function RegisterChatFilters()
    if type(ChatFrame_AddMessageEventFilter) ~= "function" then return end
    for _, event in ipairs(ABF.constants.chatEvents) do ChatFrame_AddMessageEventFilter(event, ChatFilter) end
end

function ABF:SetEnabled(value)
    self.db.enabled = value and true or false
    self:Print("Addon is now " .. (self.db.enabled and "on" or "off") .. ".")
    self:NotifyChanged()
end

function ABF:NotifyChanged()
    if self.RefreshUI then self:RefreshUI() end
    if self.RefreshAdvancedUI then self:RefreshAdvancedUI() end
    if self.RefreshBlockedLog then self:RefreshBlockedLog() end
    if self.RefreshMinimapButton then self:RefreshMinimapButton() end
end

local function IsAddonLoaded(addonName)
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(addonName) end
    if _G.IsAddOnLoaded then return _G.IsAddOnLoaded(addonName) end
    return false
end

local frame = CreateFrame("Frame")
ABF.eventFrame = frame
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ABF.name then return end
        ABF:EnsureDatabase()
        if ABF.InitializeDeveloperTools then ABF:InitializeDeveloperTools() end
        local otherAddon = ABF.isDevelopment and "AdBlockForever" or "AdBlockForeverDev"
        if IsAddonLoaded(otherAddon) then
            ABF.conflictingAddon = otherAddon
            return
        end
        RegisterChatFilters()
        initialized = true
        if ABF.CreateMinimapButton then ABF:CreateMinimapButton() end
    elseif event == "PLAYER_LOGIN" then
        if ABF.conflictingAddon then
            ABF:Print("Filtering is inactive because " .. ABF.conflictingAddon
                .. " is also enabled. Developer tools remain available; disable one build to test filtering.")
        elseif initialized then
            ABF:Print("Loaded. Use " .. ABF.slashCommand .. " to configure filtering.")
        end
    end
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local _, ABF = ...

local U, C, D = ABF.util, ABF.constants, ABF.defaults
local Trim, Fold, NormalizeText, PlayerKey = U.Trim, U.Fold, U.NormalizeText, U.PlayerKey

function ABF:IsPlayerAllowed(name)
    local key = PlayerKey(name)
    if key == "" then return false end
    if self.db.allowedPlayers[key] ~= nil then return true end
    local baseName = key:match("^([^-]+)")
    return baseName ~= nil and self.db.allowedPlayers[baseName] ~= nil
end

function ABF:AddAllowedPlayer(name, silent)
    name = Trim(name)
    local key = PlayerKey(name)
    if key == "" then return false end
    self.db.allowedPlayers[key] = { name = name, addedAt = time and time() or 0 }
    if not silent then self:Print("Allowed player " .. name .. ".") end
    self:NotifyChanged()
    return true
end

function ABF:RemoveAllowedPlayer(name)
    local key = PlayerKey(name)
    if key == "" or not self.db.allowedPlayers[key] then return false end
    self.db.allowedPlayers[key] = nil
    self:NotifyChanged()
    return true
end

function ABF:GetAllowedPlayers()
    local result = {}
    for _, entry in pairs(self.db.allowedPlayers) do result[#result + 1] = entry end
    table.sort(result, function(a, b) return Fold(a.name) < Fold(b.name) end)
    return result
end

local function AddPhrase(collection, phrase)
    phrase = NormalizeText(phrase)
    if phrase == "" then return false end
    collection[phrase] = { phrase = phrase, addedAt = time and time() or 0 }
    return true, phrase
end

local function RemovePhrase(collection, phrase)
    phrase = NormalizeText(phrase)
    if phrase == "" or not collection[phrase] then return false end
    collection[phrase] = nil
    return true
end

local function GetPhrases(collection)
    local result = {}
    for key, entry in pairs(collection) do
        result[#result + 1] = type(entry) == "table" and entry or { phrase = key, addedAt = 0 }
    end
    table.sort(result, function(a, b) return a.phrase < b.phrase end)
    return result
end

function ABF:AddAllowedPhrase(phrase, silent)
    local added, normalized = AddPhrase(self.db.allowedPhrases, phrase)
    if not added then return false end
    if not silent then self:Print('Allowed phrase "' .. normalized .. '".') end
    self:NotifyChanged()
    return true
end

function ABF:RemoveAllowedPhrase(phrase)
    if not RemovePhrase(self.db.allowedPhrases, phrase) then return false end
    self:NotifyChanged()
    return true
end

function ABF:GetAllowedPhrases()
    return GetPhrases(self.db.allowedPhrases)
end

function ABF:IsPhraseAllowed(normalizedMessage)
    for phrase in pairs(self.db.allowedPhrases) do
        if normalizedMessage:find(phrase, 1, true) then return true, phrase end
    end
    return false
end

function ABF:AddBlockedPhrase(phrase, silent)
    local added, normalized = AddPhrase(self.db.blockedPhrases, phrase)
    if not added then return false end
    if not silent then self:Print('Blocked phrase "' .. normalized .. '".') end
    self:NotifyChanged()
    return true
end

function ABF:RemoveBlockedPhrase(phrase)
    if not RemovePhrase(self.db.blockedPhrases, phrase) then return false end
    self:NotifyChanged()
    return true
end

function ABF:GetBlockedPhrases()
    return GetPhrases(self.db.blockedPhrases)
end

function ABF:FindBlockedPhrase(normalizedMessage)
    for phrase in pairs(self.db.blockedPhrases) do
        if normalizedMessage:find(phrase, 1, true) then return phrase end
    end
end

function ABF:GetSensitivity(category)
    local value = self.db.sensitivity and self.db.sensitivity[category] or "balanced"
    return C.sensitivityOffsets[value] and value or "balanced"
end

function ABF:SetSensitivity(category, value)
    if not C.baseThresholds[category] or not C.sensitivityOffsets[value] then return false end
    self.db.sensitivity[category] = value
    self:NotifyChanged()
    return true
end

function ABF:GetThreshold(category, sensitivity)
    local base = C.baseThresholds[category]
    if not base then return 0 end
    sensitivity = sensitivity or self:GetSensitivity(category)
    return math.max(1, base + (C.sensitivityOffsets[sensitivity] or 0))
end

local function EventScope(event)
    return type(event) == "string" and event:gsub("^CHAT_MSG_", "") or nil
end

function ABF:IsCategoryEnabledForEvent(category, event)
    local scope = EventScope(event)
    if not scope then return true end
    local settings = self.db.channelScopes and self.db.channelScopes[category]
    return settings == nil or settings[scope] ~= false
end

function ABF:SetCategoryScope(category, scope, value)
    if not C.categoryLabels[category] or not C.scopeLabels[scope] then return false end
    self.db.channelScopes[category][scope] = value and true or false
    self:NotifyChanged()
    return true
end

function ABF:ResetSection(section)
    local defaults = D.Database()
    if section == "filters" then
        self.db.enabled = defaults.enabled
        self.db.blockGuildRecruitment = defaults.blockGuildRecruitment
        self.db.blockWhisperRecruitment = defaults.blockWhisperRecruitment
        self.db.blockProfessionAds = defaults.blockProfessionAds
        self.db.blockGoldSpam = defaults.blockGoldSpam
        self.db.professions = D.Professions()
        self.db.sensitivity = D.Sensitivity()
        self.db.channelScopes = D.ChannelScopes()
        self.db.whisperAlert = defaults.whisperAlert
    elseif section == "lists" then
        self.db.allowedPlayers, self.db.allowedPhrases, self.db.blockedPhrases = {}, {}, {}
    elseif section == "stats" then
        self.db.stats = D.Stats()
    else
        return false
    end
    self:NotifyChanged()
    return true
end

function ABF:GetDiagnosticText(message)
    local normalized = NormalizeText(message)
    local deobfuscated = Fold(message):gsub("0", "o"):gsub("1", "i"):gsub("[^%w%s]", " "):gsub("%s+", " ")
    return normalized, Trim(deobfuscated)
end

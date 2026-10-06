local _, ABF = ...

local U, C, D = ABF.util, ABF.constants, ABF.defaults
local Trim, NormalizeText, PlayerKey = U.Trim, U.NormalizeText, U.PlayerKey

local function Encode(value)
    return (tostring(value or ""):gsub("([^%w%-%._])", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function Decode(value)
    return (tostring(value or ""):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function BoolText(value) return value and "1" or "0" end
local function ParseBool(value)
    if value == "1" or value == "true" or value == "on" then return true end
    if value == "0" or value == "false" or value == "off" then return false end
end

function ABF:ExportSettings()
    local lines = {
        "ABF_SETTINGS_1",
        "addonVersion=" .. Encode(self.version),
        "enabled=" .. BoolText(self.db.enabled),
        "blockGuildRecruitment=" .. BoolText(self.db.blockGuildRecruitment),
        "blockWhisperRecruitment=" .. BoolText(self.db.blockWhisperRecruitment),
        "blockProfessionAds=" .. BoolText(self.db.blockProfessionAds),
        "blockGoldSpam=" .. BoolText(self.db.blockGoldSpam),
        "minimapHide=" .. BoolText(self.db.minimap.hide),
        "whisperAlert=" .. Encode(self.db.whisperAlert),
    }
    for _, key in ipairs(C.professionOrder) do
        lines[#lines + 1] = "profession." .. key .. "=" .. BoolText(self.db.professions[key] ~= false)
    end
    for _, category in ipairs(C.categoryOrder) do
        if C.baseThresholds[category] then
            lines[#lines + 1] = "sensitivity." .. category .. "=" .. Encode(self:GetSensitivity(category))
        end
        for _, scope in ipairs(C.scopeOrder) do
            lines[#lines + 1] = "scope." .. category .. "." .. scope .. "=" .. BoolText(self.db.channelScopes[category][scope] ~= false)
        end
    end
    for _, entry in ipairs(self:GetAllowedPlayers()) do lines[#lines + 1] = "whitelist=" .. Encode(entry.name) end
    for _, entry in ipairs(self:GetAllowedPhrases()) do lines[#lines + 1] = "allowphrase=" .. Encode(entry.phrase) end
    for _, entry in ipairs(self:GetBlockedPhrases()) do lines[#lines + 1] = "blockphrase=" .. Encode(entry.phrase) end
    return table.concat(lines, "\n")
end

function ABF:ImportSettings(payload)
    if type(payload) ~= "string" or not payload:match("^ABF_SETTINGS_1[%s\r\n]") then
        return false, "The text is not an AdBlock Forever settings export."
    end
    local defaults = D.Database()
    local imported = {
        enabled = defaults.enabled,
        blockGuildRecruitment = defaults.blockGuildRecruitment,
        blockWhisperRecruitment = defaults.blockWhisperRecruitment,
        blockProfessionAds = defaults.blockProfessionAds,
        blockGoldSpam = defaults.blockGoldSpam,
        minimapHide = defaults.minimap.hide,
        whisperAlert = defaults.whisperAlert,
        professions = D.Professions(),
        sensitivity = D.Sensitivity(),
        channelScopes = D.ChannelScopes(),
        allowedPlayers = {}, allowedPhrases = {}, blockedPhrases = {},
    }
    local booleans = {
        enabled = true, blockGuildRecruitment = true, blockWhisperRecruitment = true,
        blockProfessionAds = true, blockGoldSpam = true, minimapHide = true,
    }

    for line in payload:gmatch("[^\r\n]+") do
        local key, encoded = line:match("^([^=]+)=(.*)$")
        if key then
            local value = Decode(encoded)
            if booleans[key] then
                local parsed = ParseBool(value)
                if parsed ~= nil then imported[key] = parsed end
            elseif key == "whisperAlert" and (value == "none" or value == "notice" or value == "sound" or value == "both") then
                imported.whisperAlert = value
            elseif key == "whitelist" then
                local playerKey = PlayerKey(value)
                if playerKey ~= "" then imported.allowedPlayers[playerKey] = { name = Trim(value), addedAt = time and time() or 0 } end
            elseif key == "allowphrase" or key == "blockphrase" then
                local phrase = NormalizeText(value)
                if phrase ~= "" then
                    local target = key == "allowphrase" and imported.allowedPhrases or imported.blockedPhrases
                    target[phrase] = { phrase = phrase, addedAt = time and time() or 0 }
                end
            else
                local profession = key:match("^profession%.([%w_]+)$")
                local sensitivity = key:match("^sensitivity%.([%w_]+)$")
                local category, scope = key:match("^scope%.([%w_]+)%.([%w_]+)$")
                if profession and imported.professions[profession] ~= nil then
                    local parsed = ParseBool(value)
                    if parsed ~= nil then imported.professions[profession] = parsed end
                elseif sensitivity and imported.sensitivity[sensitivity] and C.sensitivityOffsets[value] then
                    imported.sensitivity[sensitivity] = value
                elseif category and scope and imported.channelScopes[category] and imported.channelScopes[category][scope] ~= nil then
                    local parsed = ParseBool(value)
                    if parsed ~= nil then imported.channelScopes[category][scope] = parsed end
                end
            end
        end
    end

    self.db.enabled = imported.enabled
    self.db.blockGuildRecruitment = imported.blockGuildRecruitment
    self.db.blockWhisperRecruitment = imported.blockWhisperRecruitment
    self.db.blockProfessionAds = imported.blockProfessionAds
    self.db.blockGoldSpam = imported.blockGoldSpam
    self.db.minimap.hide = imported.minimapHide
    self.db.whisperAlert = imported.whisperAlert
    self.db.professions = imported.professions
    self.db.sensitivity = imported.sensitivity
    self.db.channelScopes = imported.channelScopes
    self.db.allowedPlayers = imported.allowedPlayers
    self.db.allowedPhrases = imported.allowedPhrases
    self.db.blockedPhrases = imported.blockedPhrases
    self:NotifyChanged()
    return true
end

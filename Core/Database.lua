local _, ABF = ...

local C = ABF.constants
local SENSITIVITY_OFFSETS = C.sensitivityOffsets

local function DefaultProfessionOptions()
    local result = {}
    for _, key in ipairs(C.professionOrder) do result[key] = true end
    return result
end

local function DefaultSensitivity()
    return { guild = "balanced", profession = "balanced", gold = "balanced" }
end

local function DefaultChannelScopes()
    return {
        guild = { CHANNEL = true, SAY = true, YELL = true, WHISPER = true },
        profession = { CHANNEL = true, SAY = true, YELL = true, WHISPER = false },
        gold = { CHANNEL = true, SAY = true, YELL = true, WHISPER = true },
        custom = { CHANNEL = true, SAY = true, YELL = true, WHISPER = true },
    }
end

local function DefaultStats()
    return { total = 0, guild = 0, profession = 0, gold = 0, custom = 0 }
end

local function DefaultDatabase()
    return {
        version = 5,
        enabled = true,
        blockGuildRecruitment = true,
        blockWhisperRecruitment = true,
        blockProfessionAds = true,
        blockGoldSpam = true,
        professions = DefaultProfessionOptions(),
        allowedPlayers = {},
        allowedPhrases = {},
        blockedPhrases = {},
        sensitivity = DefaultSensitivity(),
        channelScopes = DefaultChannelScopes(),
        whisperAlert = "none",
        blockedLog = {},
        blockedLogDetailed = true,
        minimap = { hide = false, angle = 225 },
        stats = DefaultStats(),
    }
end

ABF.defaults = {
    Database = DefaultDatabase,
    Professions = DefaultProfessionOptions,
    Sensitivity = DefaultSensitivity,
    ChannelScopes = DefaultChannelScopes,
    Stats = DefaultStats,
}

local function MigrateDatabase(database)
    local version = tonumber(database.version) or 0
    if version < 4 then
        database.blockedPhrases = type(database.blockedPhrases) == "table" and database.blockedPhrases or {}
        database.sensitivity = type(database.sensitivity) == "table" and database.sensitivity or DefaultSensitivity()
        database.channelScopes = type(database.channelScopes) == "table" and database.channelScopes or DefaultChannelScopes()
        database.whisperAlert = database.whisperAlert or "none"
        version = 4
    end
    if version < 5 then
        if type(database.stats) == "table" and type(database.stats.custom) ~= "number" then
            database.stats.custom = 0
        end
        version = 5
    end
    database.version = version
end

function ABF:EnsureDatabase()
    local database = _G[self.databaseName]
    if type(database) ~= "table" then
        database = DefaultDatabase()
        _G[self.databaseName] = database
    end
    MigrateDatabase(database)
    local defaults = DefaultDatabase()
    for key, value in pairs(defaults) do
        if database[key] == nil then database[key] = value end
    end

    if type(database.professions) ~= "table" then database.professions = DefaultProfessionOptions() end
    for key in pairs(defaults.professions) do
        if database.professions[key] == nil then database.professions[key] = true end
    end
    if type(database.allowedPlayers) ~= "table" then database.allowedPlayers = {} end
    if type(database.allowedPhrases) ~= "table" then database.allowedPhrases = {} end
    if type(database.blockedPhrases) ~= "table" then database.blockedPhrases = {} end

    if type(database.sensitivity) ~= "table" then database.sensitivity = DefaultSensitivity() end
    for category, value in pairs(defaults.sensitivity) do
        if not SENSITIVITY_OFFSETS[database.sensitivity[category]] then database.sensitivity[category] = value end
    end

    if type(database.channelScopes) ~= "table" then database.channelScopes = DefaultChannelScopes() end
    for category, scopes in pairs(defaults.channelScopes) do
        if type(database.channelScopes[category]) ~= "table" then database.channelScopes[category] = {} end
        for scope, enabled in pairs(scopes) do
            if type(database.channelScopes[category][scope]) ~= "boolean" then
                database.channelScopes[category][scope] = enabled
            end
        end
    end

    if database.whisperAlert ~= "none" and database.whisperAlert ~= "notice"
        and database.whisperAlert ~= "sound" and database.whisperAlert ~= "both" then
        database.whisperAlert = "none"
    end
    if type(database.blockedLog) ~= "table" then database.blockedLog = {} end
    while #database.blockedLog > self.blockedLogLimit do table.remove(database.blockedLog, 1) end
    if type(database.blockedLogDetailed) ~= "boolean" then database.blockedLogDetailed = true end

    if type(database.minimap) ~= "table" then database.minimap = defaults.minimap end
    if type(database.minimap.angle) ~= "number" then database.minimap.angle = defaults.minimap.angle end
    if type(database.minimap.hide) ~= "boolean" then database.minimap.hide = false end

    if type(database.stats) ~= "table" then database.stats = DefaultStats() end
    for key, value in pairs(defaults.stats) do
        if type(database.stats[key]) ~= "number" then database.stats[key] = value end
    end
    database.version = 5
    self.db = database
end

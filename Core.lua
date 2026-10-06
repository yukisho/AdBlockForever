local ADDON_NAME, ABF = ...

local IS_DEVELOPMENT = ADDON_NAME == "AdBlockForeverDev" or ABF.isDevelopment == true

ABF.name = ADDON_NAME
ABF.isDevelopment = IS_DEVELOPMENT
ABF.databaseName = IS_DEVELOPMENT and "AdBlockForeverDevDB" or "AdBlockForeverDB"
ABF.slashCommand = IS_DEVELOPMENT and "/abfdev" or "/abf"
ABF.version = "0.5.0"
ABF.displayName = IS_DEVELOPMENT and "AdBlock Forever Dev" or "AdBlock Forever"
ABF.iconPath = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Icon"
ABF.blockedLogLimit = 500

local CATEGORY_ORDER = { "guild", "profession", "gold", "custom" }
local CATEGORY_LABELS = {
    guild = "Guild recruitment",
    profession = "Profession advertisements",
    gold = "Gold seller spam",
    custom = "Custom blocked phrases",
}
local SCOPE_ORDER = { "CHANNEL", "SAY", "YELL", "WHISPER" }
local SCOPE_LABELS = {
    CHANNEL = "Public channels",
    SAY = "Say",
    YELL = "Yell",
    WHISPER = "Whispers",
}
local BASE_THRESHOLDS = { guild = 7, profession = 6, gold = 7 }
local SENSITIVITY_OFFSETS = { conservative = 2, balanced = 0, aggressive = -2 }
local CHAT_EVENTS = { "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER" }
local PROFESSION_ORDER = {
    "alchemy", "blacksmithing", "cooking", "enchanting", "engineering",
    "inscription", "jewelcrafting", "leatherworking", "tailoring", "other",
}
local PROFESSIONS = {
    alchemy = { label = "Alchemy", words = { "alchemy", "alchemist", "alchimie", "alchemie", "alquimia", "alchimia", "алхим", "Алхим", "炼金", "煉金", "연금" } },
    blacksmithing = { label = "Blacksmithing", words = { "blacksmith", "smithing", "schmied", "forgeage", "herrer", "ferraria", "кузнеч", "Кузнеч", "锻造", "鍛造", "대장" } },
    cooking = { label = "Cooking", words = { "cooking", "kochkunst", "cuisine", "cocina", "culinária", "culinaria", "кулинари", "Кулинари", "烹饪", "烹飪", "요리" } },
    enchanting = { label = "Enchanting", words = { "enchanting", "enchanter", "enchant", "verzauber", "enchantement", "encantamiento", "encantamento", "incantamento", "зачарован", "Зачарован", "附魔", "마법부여" } },
    engineering = { label = "Engineering", words = { "engineering", "engineer", "ingenieurskunst", "ingénierie", "ingenieria", "ingeniería", "engenharia", "ingegneria", "инженер", "工程学", "工程學", "기계공학" } },
    inscription = { label = "Inscription", words = { "inscription", "scribe", "schriftgelehr", "calligraphie", "inscripción", "inscricao", "inscrição", "начертани", "铭文", "銘文", "주문각인" } },
    jewelcrafting = { label = "Jewelcrafting", words = { "jewelcraft", "jeweler", "juwelenschleif", "joaillerie", "joyería", "joyeria", "joalheria", "oreficeria", "ювелир", "珠宝", "珠寶", "보석세공" } },
    leatherworking = { label = "Leatherworking", words = { "leatherworking", "leatherworker", "lederverarbeitung", "travail du cuir", "peletería", "peleteria", "couraria", "кожевнич", "制皮", "가죽세공" } },
    tailoring = { label = "Tailoring", words = { "tailoring", "tailor", "schneiderei", "couture", "sastrería", "sastreria", "alfaiataria", "sartoria", "портняж", "裁缝", "裁縫", "재봉" } },
    other = { label = "Other professions", words = {} },
}

ABF.categoryOrder = CATEGORY_ORDER
ABF.categoryLabels = CATEGORY_LABELS
ABF.scopeOrder = SCOPE_ORDER
ABF.scopeLabels = SCOPE_LABELS
ABF.professionOrder = PROFESSION_ORDER
ABF.professions = PROFESSIONS
ABF.constants = {
    categoryOrder = CATEGORY_ORDER,
    categoryLabels = CATEGORY_LABELS,
    scopeOrder = SCOPE_ORDER,
    scopeLabels = SCOPE_LABELS,
    baseThresholds = BASE_THRESHOLDS,
    sensitivityOffsets = SENSITIVITY_OFFSETS,
    chatEvents = CHAT_EVENTS,
    professionOrder = PROFESSION_ORDER,
    professions = PROFESSIONS,
}

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function Trim(value)
    if type(value) ~= "string" or IsSecret(value) then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Fold(value)
    return string.lower(Trim(value))
end

local function NormalizeText(value)
    value = Fold(value)
    if value == "" then return "" end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|t", "")
    value = value:gsub("|h.-|h(.-)|h", "%1"):gsub("|a.-|a", " ")
    value = value:gsub("\194\160", " "):gsub("\226\128\139", ""):gsub("\226\128\140", ""):gsub("\226\128\141", "")
    value = value:gsub("[%c]", " "):gsub("[%p]", " "):gsub("%s+", " ")
    return Trim(value)
end

local function CleanLoggedMessage(value)
    value = Trim(value)
    if value == "" then return "" end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|H.-|h(.-)|h", "%1")
    return Trim(value:gsub("[%c]", " "):gsub("%s+", " "))
end

local function ContainsAny(text, needles)
    for _, needle in ipairs(needles) do
        if text:find(needle, 1, true) then return true, needle end
    end
    return false
end

local function CountSignalGroups(text, groups)
    local count, reasons = 0, {}
    for _, group in ipairs(groups) do
        local found, needle = ContainsAny(text, group.words)
        if found then
            count = count + group.points
            reasons[#reasons + 1] = needle .. " (+" .. group.points .. ")"
        end
    end
    return count, reasons
end

local function PlayerKey(name)
    return Fold(name):gsub("%s+", "-")
end

ABF.util = {
    IsSecret = IsSecret,
    Trim = Trim,
    Fold = Fold,
    NormalizeText = NormalizeText,
    CleanLoggedMessage = CleanLoggedMessage,
    ContainsAny = ContainsAny,
    CountSignalGroups = CountSignalGroups,
    PlayerKey = PlayerKey,
}

function ABF:Print(message)
    print("|cffd9a441" .. self.displayName .. ":|r " .. tostring(message))
end

function ABF:GetProfessionLabel(key)
    return PROFESSIONS[key] and PROFESSIONS[key].label or tostring(key)
end

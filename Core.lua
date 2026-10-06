local ADDON_NAME, ABF = ...

local IS_DEVELOPMENT = ADDON_NAME == "AdBlockForeverDev" or ABF.isDevelopment == true
local DATABASE_NAME = IS_DEVELOPMENT and "AdBlockForeverDevDB" or "AdBlockForeverDB"
local COMMAND = IS_DEVELOPMENT and "/abfdev" or "/abf"

ABF.name = ADDON_NAME
ABF.isDevelopment = IS_DEVELOPMENT
ABF.version = "0.3.0"
ABF.displayName = IS_DEVELOPMENT and "AdBlock Forever Dev" or "AdBlock Forever"
ABF.iconPath = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Icon"
ABF.slashCommand = COMMAND

local initialized = false
local BLOCKED_LOG_LIMIT = 500

local CHAT_EVENTS = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
}

local PROFESSION_ORDER = {
    "alchemy",
    "blacksmithing",
    "cooking",
    "enchanting",
    "engineering",
    "inscription",
    "jewelcrafting",
    "leatherworking",
    "tailoring",
    "other",
}

local PROFESSIONS = {
    alchemy = {
        label = "Alchemy",
        words = { "alchemy", "alchemist", "alchimie", "alchemie", "alquimia", "alchimia", "алхим", "Алхим", "炼金", "煉金", "연금" },
    },
    blacksmithing = {
        label = "Blacksmithing",
        words = { "blacksmith", "smithing", "schmied", "forgeage", "herrer", "ferraria", "кузнеч", "Кузнеч", "锻造", "鍛造", "대장" },
    },
    cooking = {
        label = "Cooking",
        words = { "cooking", "kochkunst", "cuisine", "cocina", "culinária", "culinaria", "кулинари", "Кулинари", "烹饪", "烹飪", "요리" },
    },
    enchanting = {
        label = "Enchanting",
        words = { "enchanting", "enchanter", "enchant", "verzauber", "enchantement", "encantamiento", "encantamento", "incantamento", "зачарован", "Зачарован", "附魔", "마법부여" },
    },
    engineering = {
        label = "Engineering",
        words = { "engineering", "engineer", "ingenieurskunst", "ingénierie", "ingenieria", "ingeniería", "engenharia", "ingegneria", "инженер", "工程学", "工程學", "기계공학" },
    },
    inscription = {
        label = "Inscription",
        words = { "inscription", "scribe", "schriftgelehr", "calligraphie", "inscripción", "inscricao", "inscrição", "начертани", "铭文", "銘文", "주문각인" },
    },
    jewelcrafting = {
        label = "Jewelcrafting",
        words = { "jewelcraft", "jeweler", "juwelenschleif", "joaillerie", "joyería", "joyeria", "joalheria", "oreficeria", "ювелир", "珠宝", "珠寶", "보석세공" },
    },
    leatherworking = {
        label = "Leatherworking",
        words = { "leatherworking", "leatherworker", "lederverarbeitung", "travail du cuir", "peletería", "peleteria", "couraria", "кожевнич", "制皮", "가죽세공" },
    },
    tailoring = {
        label = "Tailoring",
        words = { "tailoring", "tailor", "schneiderei", "couture", "sastrería", "sastreria", "alfaiataria", "sartoria", "портняж", "裁缝", "裁縫", "재봉" },
    },
    other = {
        label = "Other professions",
        words = {},
    },
}

ABF.professionOrder = PROFESSION_ORDER
ABF.professions = PROFESSIONS

local GUILD_CONTEXT = {
    "guild", "gilde", "guilde", "gremio", "guilda", "gilda", "gildia", "гильд", "Гильд", "公会", "公會", "길드",
}

local GUILD_RECRUITING = {
    "is recruiting", "are recruiting", "now recruiting", "recruiting", "guild recruiting", "guild recruitment",
    "guild lf", "guild looking for", "looking for members", "seeking members", "recruiting everyone",
    "accepting anyone", "accepting players", "accepting members", "accepting new members",
    "join our guild", "join my guild", "would you like to join", "want to join", "like to join",
    "anyone wanna join", "anyone want to join", "wanna join",
    "interested in joining", "are you looking for a guild", "guild invite",
    "we would love to have you", "we'd love to have you",
    "players to build with us", "lf mature", "lf active players",
    "actively forming", "currently forming", "building our roster", "forming our roster",
    "filling our roster", "rounding out our roster", "looking for all roles",
    "looking for raiders", "looking for socials",
    "rekrutiert", "sucht mitglieder", "mitglieder gesucht", "gilde sucht",
    "guilde recrute", "recrutement guilde", "recherche des membres",
    "gremio recluta", "reclutando miembros", "busca miembros",
    "guilda recruta", "recrutando membros", "procura membros",
    "gilda recluta", "cerca membri", "reclutiamo",
    "gildia rekrutuje", "szuka członków", "szuka graczy",
    "u potrazi smo", "tražimo igrače", "trazimo igrace", "tražimo članove", "trazimo clanove",
    "primamo igrače", "primamo igrace", "primamo članove", "primamo clanove",
    "набор в гильди", "Набор в гильди", "гильдия набира", "Гильдия набира", "ищет игроков", "Ищет игроков", "набираем игроков", "Набираем игроков",
    "公会招募", "公會招募", "招募成员", "招募成員", "길드원 모집", "길드 모집",
}

local MEMBER_SIGNALS = {
    "members", "member", "players", "new players", "returning players", "raiders",
    "all roles", "any role", "everyone", "socials",
    "mitglieder", "spieler", "membres", "joueurs", "miembros", "jugadores", "membros", "jogadores",
    "membri", "giocatori", "członków", "graczy", "игроков", "участников", "成员", "成員", "玩家", "길드원",
    "igračima", "igracima", "igrače", "igrace", "članove", "clanove",
}

local JOIN_SIGNALS = {
    "join us", "join the", "join up", "come join", "apply", "message us", "message me", "contact us", "contact me",
    "whisper", "send a tell", "send me a message", "want more info", "pst", "pm for", "dm for", "dm me",
    "beitreten", "bewerben", "flüstern", "rejoignez", "postulez", "murmurez", "únete", "unete", "susurra",
    "junte-se", "sussurre", "unisciti", "candidati", "dołącz", "dolacz", "napisz", "вступай", "пиши", "加入我们", "加入我們", "加入", "문의",
    "ako ste zainteresovani", "ako ste zainteresirani", "slobodno bacite w", "javite se", "šapnite", "sapnite",
}

local GUILD_DETAIL_SIGNALS = {
    "raid times", "raid time", "raiding", "pve", "pvp", "discord", "progression", "server time", "gmt", "timezone",
    "raidzeiten", "schlachtzug", "horaires de raid", "heures de raid", "horario de raid", "horários de raid", "orari raid",
    "рейд", "дискорд", "活动时间", "活動時間", "레이드",
}

local INTERESTED_CONTACT_SIGNALS = {
    "pst if interested", "whisper if interested", "message if interested",
    "message me if interested", "dm if interested", "dm me if interested",
}

local GROUP_PROMOTION_SIGNALS = {
    "new player friendly", "active events", "organized", "non drama", "weekly pvp",
    "farm runs", "caravans", "recipe grinds", "dungeons and raids", "dungeons raids",
}

local PROFESSION_SOLICIT_STRONG = {
    "lfw", "work for tips", "working for tips", "your mats", "your materials", "my mats", "my materials",
    "free with mats", "taking orders",
    "open for orders", "open for business", "crafting orders", "send order", "all recipes", "all patterns", "all crafts", "every recipe",
    "every pattern", "can make", "can craft", "can install", "installing for", "crafting for", "tips appreciated", "pst for", "whisper for", "pm for",
    "gegen mats", "gegen trinkgeld", "alle rezepte", "aufträge", "auftraege",
    "vos compos", "tous les patrons", "toutes les recettes", "commandes ouvertes",
    "tus materiales", "todos los patrones", "todas las recetas", "acepto pedidos",
    "seus materiais", "todas as receitas", "aceito encomendas",
    "vostri materiali", "tutte le ricette", "accetto ordini",
    "ваши материалы", "все рецепты", "принимаю заказы", "за чаевые",
    "自备材料", "你的材料", "您的材料", "全配方", "接单", "代工",
    "재료 지참", "모든 도안", "주문 받",
}

local PROFESSION_SOLICIT_LIGHT = {
    "craft", "crafter", "service", "services", "commission", "commissions", "fee", "tip", "mats", "materials",
    "recipes", "patterns", "orders", "make your", "have every", "have all", "available now", "for sale",
    "herstellen", "dienst", "rezept", "trinkgeld", "service", "recette", "commande", "servicio", "pedido",
    "serviço", "servico", "encomenda", "servizio", "ordine", "услуг", "рецепт", "заказ", "крафт",
    "材料", "配方", "代做", "制作", "製作", "服务", "服務", "제작", "주문",
}

local PROFESSION_REQUEST_PREFIXES = {
    "need ", "looking for ", "lf ", "wtb ", "can anyone ", "anyone able ", "who can ", "seeking ",
    "suche ", "cherche ", "busco ", "procuro ", "cerco ", "ищу ", "Ищу ",
}

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function Trim(value)
    if type(value) ~= "string" or IsSecret(value) then
        return ""
    end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Fold(value)
    return string.lower(Trim(value))
end

local function NormalizeText(value)
    value = Fold(value)
    if value == "" then
        return ""
    end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("|t", "")
    value = value:gsub("|h.-|h(.-)|h", "%1")
    value = value:gsub("|a.-|a", " ")
    value = value:gsub("\194\160", " ")
    value = value:gsub("\226\128\139", "")
    value = value:gsub("\226\128\140", "")
    value = value:gsub("\226\128\141", "")
    value = value:gsub("[%c]", " ")
    value = value:gsub("[%p]", " ")
    value = value:gsub("%s+", " ")
    return Trim(value)
end

local function CleanLoggedMessage(value)
    value = Trim(value)
    if value == "" then
        return ""
    end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("|T.-|t", "")
    value = value:gsub("|A.-|a", "")
    value = value:gsub("|H.-|h(.-)|h", "%1")
    value = value:gsub("[%c]", " ")
    value = value:gsub("%s+", " ")
    return Trim(value)
end

local function ContainsAny(text, needles)
    for _, needle in ipairs(needles) do
        if text:find(needle, 1, true) then
            return true, needle
        end
    end
    return false
end

local function CountSignalGroups(text, groups)
    local count = 0
    local reasons = {}
    for _, group in ipairs(groups) do
        local found, needle = ContainsAny(text, group.words)
        if found then
            count = count + group.points
            reasons[#reasons + 1] = needle
        end
    end
    return count, reasons
end

local function PlayerKey(name)
    name = Fold(name):gsub("%s+", "-")
    return name
end

local function DefaultProfessionOptions()
    local result = {}
    for _, key in ipairs(PROFESSION_ORDER) do
        result[key] = true
    end
    return result
end

local function DefaultDatabase()
    return {
        version = 2,
        enabled = true,
        blockGuildRecruitment = true,
        blockWhisperRecruitment = true,
        blockProfessionAds = true,
        professions = DefaultProfessionOptions(),
        allowedPlayers = {},
        allowedPhrases = {},
        blockedLog = {},
        blockedLogDetailed = true,
        minimap = {
            hide = false,
            angle = 225,
        },
        stats = {
            total = 0,
            guild = 0,
            profession = 0,
        },
    }
end

local function EnsureDatabase()
    local database = _G[DATABASE_NAME]
    if type(database) ~= "table" then
        database = DefaultDatabase()
        _G[DATABASE_NAME] = database
    end
    local defaults = DefaultDatabase()
    for key, value in pairs(defaults) do
        if database[key] == nil then
            database[key] = value
        end
    end
    if type(database.professions) ~= "table" then
        database.professions = DefaultProfessionOptions()
    end
    for key in pairs(defaults.professions) do
        if database.professions[key] == nil then
            database.professions[key] = true
        end
    end
    if type(database.allowedPlayers) ~= "table" then
        database.allowedPlayers = {}
    end
    if type(database.allowedPhrases) ~= "table" then
        database.allowedPhrases = {}
    end
    if type(database.blockedLog) ~= "table" then
        database.blockedLog = {}
    end
    while #database.blockedLog > BLOCKED_LOG_LIMIT do
        table.remove(database.blockedLog, 1)
    end
    if type(database.blockedLogDetailed) ~= "boolean" then
        database.blockedLogDetailed = true
    end
    if type(database.minimap) ~= "table" then
        database.minimap = defaults.minimap
    end
    if type(database.minimap.angle) ~= "number" then
        database.minimap.angle = defaults.minimap.angle
    end
    if type(database.minimap.hide) ~= "boolean" then
        database.minimap.hide = false
    end
    if type(database.stats) ~= "table" then
        database.stats = defaults.stats
    end
    for key, value in pairs(defaults.stats) do
        if type(database.stats[key]) ~= "number" then
            database.stats[key] = value
        end
    end
    database.version = 2
    ABF.db = database
end

function ABF:Print(message)
    print("|cffd9a441" .. self.displayName .. ":|r " .. tostring(message))
end

function ABF:GetProfessionLabel(key)
    return PROFESSIONS[key] and PROFESSIONS[key].label or tostring(key)
end

function ABF:IsPlayerAllowed(name)
    local key = PlayerKey(name)
    return key ~= "" and self.db.allowedPlayers[key] ~= nil
end

function ABF:AddAllowedPlayer(name, silent)
    name = Trim(name)
    local key = PlayerKey(name)
    if key == "" then
        return false
    end
    self.db.allowedPlayers[key] = {
        name = name,
        addedAt = time and time() or 0,
    }
    if not silent then
        self:Print("Allowed player " .. name .. ".")
    end
    self:NotifyChanged()
    return true
end

function ABF:RemoveAllowedPlayer(name)
    local key = PlayerKey(name)
    if key == "" or not self.db.allowedPlayers[key] then
        return false
    end
    self.db.allowedPlayers[key] = nil
    self:NotifyChanged()
    return true
end

function ABF:GetAllowedPlayers()
    local result = {}
    for _, entry in pairs(self.db.allowedPlayers) do
        result[#result + 1] = entry
    end
    table.sort(result, function(a, b)
        return Fold(a.name) < Fold(b.name)
    end)
    return result
end

function ABF:AddAllowedPhrase(phrase, silent)
    phrase = NormalizeText(phrase)
    if phrase == "" then
        return false
    end
    self.db.allowedPhrases[phrase] = {
        phrase = phrase,
        addedAt = time and time() or 0,
    }
    if not silent then
        self:Print('Allowed phrase "' .. phrase .. '".')
    end
    self:NotifyChanged()
    return true
end

function ABF:RemoveAllowedPhrase(phrase)
    phrase = NormalizeText(phrase)
    if phrase == "" or not self.db.allowedPhrases[phrase] then
        return false
    end
    self.db.allowedPhrases[phrase] = nil
    self:NotifyChanged()
    return true
end

function ABF:GetAllowedPhrases()
    local result = {}
    for key, entry in pairs(self.db.allowedPhrases) do
        if type(entry) ~= "table" then
            entry = { phrase = key, addedAt = 0 }
        end
        result[#result + 1] = entry
    end
    table.sort(result, function(a, b)
        return a.phrase < b.phrase
    end)
    return result
end

function ABF:IsPhraseAllowed(normalizedMessage)
    for phrase in pairs(self.db.allowedPhrases) do
        if normalizedMessage:find(phrase, 1, true) then
            return true, phrase
        end
    end
    return false
end

local function DetectProfessions(text, raw)
    local detected = {}
    local count = 0
    for _, key in ipairs(PROFESSION_ORDER) do
        if key ~= "other" then
            local found = ContainsAny(text, PROFESSIONS[key].words)
            if found then
                detected[key] = true
                count = count + 1
            end
        end
    end
    local hasProfessionLink = raw:find("|htrade:", 1, true) ~= nil
        or raw:find("|henchant:", 1, true) ~= nil
    if hasProfessionLink and count == 0 then
        detected.other = true
        count = 1
    end
    return detected, count, hasProfessionLink
end

local function AnyDetectedProfessionEnabled(detected)
    for key in pairs(detected) do
        if ABF.db.professions[key] ~= false then
            return true
        end
    end
    return false
end

local function HasBracketedProfessionHeader(raw, detected)
    local header = raw:match("^%s*%[([^%]]+)%]")
    if not header then
        return false
    end
    for key in pairs(detected) do
        local profession = PROFESSIONS[key]
        if profession and ContainsAny(header, profession.words) then
            return true
        end
    end
    return false
end

local function ClassifyProfession(text, raw)
    if not ABF.db.blockProfessionAds then
        return nil
    end

    local detected, professionCount, hasProfessionLink = DetectProfessions(text, raw)
    if professionCount == 0 or not AnyDetectedProfessionEnabled(detected) then
        return nil
    end
    for _, prefix in ipairs(PROFESSION_REQUEST_PREFIXES) do
        if text:sub(1, #prefix) == prefix then
            return nil
        end
    end

    local score = hasProfessionLink and 4 or 2
    local reasons = {}
    if hasProfessionLink then
        reasons[#reasons + 1] = "profession link"
    else
        reasons[#reasons + 1] = "profession name"
    end

    if HasBracketedProfessionHeader(raw, detected) then
        score = score + 3
        reasons[#reasons + 1] = "profession ad header"
    end

    local strong, strongPhrase = ContainsAny(text, PROFESSION_SOLICIT_STRONG)
    if strong then
        score = score + 4
        reasons[#reasons + 1] = strongPhrase
    end
    local light, lightPhrase = ContainsAny(text, PROFESSION_SOLICIT_LIGHT)
    if light then
        score = score + 2
        reasons[#reasons + 1] = lightPhrase
    end

    if raw:find("%+%d") or text:find("%d+%s*gold") or text:find("%d+%s*g%s") then
        score = score + 1
        reasons[#reasons + 1] = "price/stat list"
    end
    if detected.enchanting and (
        raw:find("%d+h%s*%+%d")
        or raw:find("chest%s*:%s*%d")
        or raw:find("bracer%s*:%s*%d")
    ) then
        score = score + 3
        reasons[#reasons + 1] = "compact enchantment list"
    end
    if #text >= 90 then
        score = score + 1
        reasons[#reasons + 1] = "long solicitation"
    end

    if score < 6 then
        return nil
    end

    local labels = {}
    for _, key in ipairs(PROFESSION_ORDER) do
        if detected[key] and ABF.db.professions[key] ~= false then
            labels[#labels + 1] = PROFESSIONS[key].label
        end
    end
    return {
        category = "profession",
        label = table.concat(labels, ", "),
        score = score,
        reason = table.concat(reasons, ", "),
    }
end

local function ClassifyGuildRecruitment(text, raw, enabled, allowQuestionRecruitment)
    if not enabled then
        return nil
    end

    local score, reasons = CountSignalGroups(text, {
        { words = GUILD_RECRUITING, points = 5 },
        { words = GUILD_CONTEXT, points = 2 },
        { words = MEMBER_SIGNALS, points = 2 },
        { words = JOIN_SIGNALS, points = 2 },
        { words = GUILD_DETAIL_SIGNALS, points = 1 },
    })

    local hasGuildContext = ContainsAny(text, GUILD_CONTEXT)
    local hasGuildTag = raw:find("<[^<>]+>") ~= nil
    if hasGuildTag and not hasGuildContext then
        hasGuildContext = true
        score = score + 2
        reasons[#reasons + 1] = "guild tag"
    end
    local hasRecruiting = ContainsAny(text, GUILD_RECRUITING)
    local hasMembers = ContainsAny(text, MEMBER_SIGNALS)
    local hasJoin = ContainsAny(text, JOIN_SIGNALS)
    local hasDetails = ContainsAny(text, GUILD_DETAIL_SIGNALS)
    local hasInterestedContact = ContainsAny(text, INTERESTED_CONTACT_SIGNALS)
    local hasGroupPromotion = ContainsAny(text, GROUP_PROMOTION_SIGNALS)
    local hasDiscord = text:find("discord", 1, true) ~= nil
    if not hasGuildContext and hasDiscord and hasInterestedContact
        and hasGroupPromotion and #text >= 80 then
        hasGuildContext = true
        score = score + 4
        reasons[#reasons + 1] = "structured group recruitment"
    end
    if not hasGuildContext and hasRecruiting and hasMembers
        and ((hasJoin and hasDetails) or #text >= 100) then
        hasGuildContext = true
        score = score + 2
        reasons[#reasons + 1] = "inferred guild recruitment"
    end
    if not hasRecruiting then
        if hasGuildContext and hasMembers and hasJoin then
            score = score + 3
            reasons[#reasons + 1] = "guild/member/contact combination"
        elseif hasGuildContext and hasJoin and hasDetails and #text >= 80 then
            score = score + 3
            reasons[#reasons + 1] = "guild schedule/contact combination"
        end
    end

    if not hasGuildContext or score < 7 then
        return nil
    end
    if not allowQuestionRecruitment and raw:find("?", 1, true) and score == 7 then
        return nil
    end
    return {
        category = "guild",
        label = "Guild recruitment",
        score = score,
        reason = table.concat(reasons, ", "),
    }
end

function ABF:ClassifyMessage(message, mode)
    if type(message) ~= "string" or IsSecret(message) then
        return nil
    end
    local raw = Fold(message)
    local text = NormalizeText(message)
    if text == "" then
        return nil
    end
    if self:IsPhraseAllowed(text) then
        return nil, "allowed phrase"
    end

    if mode ~= "guild-whisper" then
        local profession = ClassifyProfession(text, raw)
        if profession then
            return profession
        end
    end
    local whisperMode = mode == "guild-whisper"
    local guildEnabled
    if whisperMode then
        guildEnabled = self.db.blockWhisperRecruitment
    else
        guildEnabled = self.db.blockGuildRecruitment
    end
    return ClassifyGuildRecruitment(text, raw, guildEnabled, whisperMode)
end

function ABF:GetBlockedLog()
    return self.db and self.db.blockedLog or {}
end

function ABF:GetBlockedLogLimit()
    return BLOCKED_LOG_LIMIT
end

function ABF:ClearBlockedLog()
    if not self.db then
        return
    end
    self.db.blockedLog = {}
    self.recent = {}
    self:NotifyChanged()
end

function ABF:RecordBlocked(result, author, message, event, lineID)
    local now = GetTime and GetTime() or 0
    local key
    if lineID ~= nil and not IsSecret(lineID) then
        key = tostring(event or "") .. ":" .. tostring(lineID)
    else
        key = tostring(event or "") .. "\031" .. tostring(author or "") .. "\031" .. tostring(message or "")
    end
    if self.lastBlockedKey == key and now - (self.lastBlockedAt or 0) < 1 then
        return false
    end
    self.lastBlockedKey = key
    self.lastBlockedAt = now

    self.db.stats.total = (self.db.stats.total or 0) + 1
    self.db.stats[result.category] = (self.db.stats[result.category] or 0) + 1
    local entry = {
        category = result.category,
        label = result.label,
        score = result.score,
        reason = result.reason,
        author = author or "Unknown",
        message = CleanLoggedMessage(message),
        event = event or "Unknown",
        mode = event == "CHAT_MSG_WHISPER" and "whisper" or "public",
        at = time and time() or 0,
    }
    table.insert(self.db.blockedLog, entry)
    while #self.db.blockedLog > BLOCKED_LOG_LIMIT do
        table.remove(self.db.blockedLog, 1)
    end
    self.recent = self.recent or {}
    table.insert(self.recent, 1, entry)
    while #self.recent > 20 do
        table.remove(self.recent)
    end
    self:NotifyChanged()
    return true
end

local function ChatFilter(_, event, message, author, ...)
    if not ABF.db or not ABF.db.enabled or IsSecret(message) or IsSecret(author) then
        return false
    end
    local whisperMode = event == "CHAT_MSG_WHISPER"
    if whisperMode and not ABF.db.blockWhisperRecruitment then
        return false
    end
    local guid = select(10, ...)
    local ownGuid = UnitGUID and UnitGUID("player")
    if guid and not IsSecret(guid) and not IsSecret(ownGuid) and guid == ownGuid then
        return false
    end
    if author and ABF:IsPlayerAllowed(author) then
        return false
    end
    local result = ABF:ClassifyMessage(message, whisperMode and "guild-whisper" or nil)
    if result then
        if whisperMode then
            result.label = "Guild recruitment whisper"
        end
        local lineID = select(9, ...)
        ABF:RecordBlocked(result, author, message, event, lineID)
        return true
    end
    return false
end

local function RegisterChatFilters()
    if type(ChatFrame_AddMessageEventFilter) ~= "function" then
        return
    end
    for _, event in ipairs(CHAT_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, ChatFilter)
    end
end

function ABF:SetEnabled(value)
    self.db.enabled = value and true or false
    self:Print("Addon is now " .. (self.db.enabled and "on" or "off") .. ".")
    self:NotifyChanged()
end

function ABF:NotifyChanged()
    if self.RefreshUI then
        self:RefreshUI()
    end
    if self.RefreshBlockedLog then
        self:RefreshBlockedLog()
    end
    if self.RefreshMinimapButton then
        self:RefreshMinimapButton()
    end
end

local function ParseToggle(argument)
    argument = Fold(argument)
    if argument == "on" then
        return true
    elseif argument == "off" then
        return false
    end
    return nil
end

local function SetToggle(field, argument, label)
    local value = ParseToggle(argument)
    if value == nil then
        ABF:Print(label .. " is " .. (ABF.db[field] and "on" or "off") .. ".")
        return
    end
    ABF.db[field] = value
    ABF:Print(label .. " is now " .. (value and "on" or "off") .. ".")
    ABF:NotifyChanged()
end

local function FindProfession(argument)
    argument = Fold(argument):gsub("%s+", "")
    for key, profession in pairs(PROFESSIONS) do
        if argument == key or argument == Fold(profession.label):gsub("%s+", "") then
            return key
        end
    end
end

function ABF:ShowHelp()
    self:Print(COMMAND .. " - open settings")
    self:Print(COMMAND .. " on|off")
    self:Print(COMMAND .. " guild on|off | whispers on|off | professions on|off")
    self:Print(COMMAND .. " profession NAME on|off")
    self:Print(COMMAND .. " allowplayer NAME | unallowplayer NAME")
    self:Print(COMMAND .. " allowphrase TEXT | unallowphrase TEXT")
    self:Print(COMMAND .. " minimap show|hide | stats | test MESSAGE")
    self:Print(COMMAND .. " blockedlog | clearblockedlog")
    if IS_DEVELOPMENT then
        self:Print(COMMAND .. " log | capture on|off | hoverdebug | clearlog")
    end
end

local slashKey = IS_DEVELOPMENT and "ADBLOCKFOREVERDEV" or "ADBLOCKFOREVER"
_G["SLASH_" .. slashKey .. "1"] = COMMAND
_G["SLASH_" .. slashKey .. "2"] = IS_DEVELOPMENT and "/adblockforeverdev" or "/adblockforever"
SlashCmdList[slashKey] = function(message)
    local command, argument = Trim(message):match("^(%S*)%s*(.-)$")
    command = Fold(command)

    if IS_DEVELOPMENT and ABF.HandleDeveloperCommand
        and ABF:HandleDeveloperCommand(command, argument) then
        return
    elseif command == "" or command == "show" then
        ABF:ShowUI()
    elseif command == "on" or command == "off" then
        ABF:SetEnabled(command == "on")
    elseif command == "guild" then
        SetToggle("blockGuildRecruitment", argument, "Guild recruitment filtering")
    elseif command == "whisper" or command == "whispers" then
        SetToggle("blockWhisperRecruitment", argument, "Guild recruitment whisper filtering")
    elseif command == "professions" or command == "professionads" then
        SetToggle("blockProfessionAds", argument, "Profession advertisement filtering")
    elseif command == "profession" then
        local name, toggle = argument:match("^(.-)%s+(on|off)%s*$")
        local key = name and FindProfession(name)
        if not key then
            ABF:Print("Usage: " .. COMMAND .. " profession NAME on|off")
            return
        end
        ABF.db.professions[key] = toggle == "on"
        ABF:Print(PROFESSIONS[key].label .. " ads are now " .. toggle .. ".")
        ABF:NotifyChanged()
    elseif command == "allowplayer" then
        if not ABF:AddAllowedPlayer(argument, false) then
            ABF:Print("Usage: " .. COMMAND .. " allowplayer NAME")
        end
    elseif command == "unallowplayer" then
        if ABF:RemoveAllowedPlayer(argument) then
            ABF:Print("Removed " .. argument .. " from allowed players.")
        else
            ABF:Print("That player is not allowed.")
        end
    elseif command == "allowphrase" then
        if not ABF:AddAllowedPhrase(argument, false) then
            ABF:Print("Usage: " .. COMMAND .. " allowphrase TEXT")
        end
    elseif command == "unallowphrase" then
        if ABF:RemoveAllowedPhrase(argument) then
            ABF:Print("Removed that allowed phrase.")
        else
            ABF:Print("That phrase is not allowed.")
        end
    elseif command == "minimap" then
        argument = Fold(argument)
        if argument == "show" or argument == "on" then
            ABF.db.minimap.hide = false
        elseif argument == "hide" or argument == "off" then
            ABF.db.minimap.hide = true
        else
            ABF:Print("Minimap button is " .. (ABF.db.minimap.hide and "hidden" or "shown") .. ".")
            return
        end
        ABF:NotifyChanged()
    elseif command == "stats" then
        ABF:Print(string.format(
            "%d blocked: %d guild recruitment, %d profession ads.",
            ABF.db.stats.total or 0,
            ABF.db.stats.guild or 0,
            ABF.db.stats.profession or 0
        ))
    elseif command == "blockedlog" or (command == "log" and not IS_DEVELOPMENT) then
        if ABF.ShowBlockedLog then
            ABF:ShowBlockedLog()
        end
    elseif command == "clearblockedlog" then
        ABF:ClearBlockedLog()
        ABF:Print("Blocked-message log cleared.")
    elseif command == "test" then
        if argument == "" then
            ABF:Print("Usage: " .. COMMAND .. " test MESSAGE")
            return
        end
        local result, note = ABF:ClassifyMessage(argument)
        local whisperOnly = false
        if not result then
            result = ABF:ClassifyMessage(argument, "guild-whisper")
            whisperOnly = result ~= nil
        end
        if result then
            ABF:Print(string.format(
                "Would block%s as %s (score %d): %s",
                whisperOnly and " in a whisper" or "",
                result.label,
                result.score,
                result.reason
            ))
        else
            ABF:Print("Would allow this message" .. (note and (": " .. note) or "."))
        end
    else
        ABF:ShowHelp()
    end
end

local frame = CreateFrame("Frame")
ABF.eventFrame = frame

local function IsAddonLoaded(addonName)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(addonName)
    end
    if _G.IsAddOnLoaded then
        return _G.IsAddOnLoaded(addonName)
    end
    return false
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end
        EnsureDatabase()
        if ABF.InitializeDeveloperTools then
            ABF:InitializeDeveloperTools()
        end
        local otherAddon = IS_DEVELOPMENT and "AdBlockForever" or "AdBlockForeverDev"
        if IsAddonLoaded(otherAddon) then
            ABF.conflictingAddon = otherAddon
            return
        end
        RegisterChatFilters()
        initialized = true
        if ABF.CreateMinimapButton then
            ABF:CreateMinimapButton()
        end
    elseif event == "PLAYER_LOGIN" then
        if ABF.conflictingAddon then
            ABF:Print("Filtering is inactive because " .. ABF.conflictingAddon .. " is also enabled. Developer tools remain available; disable one build to test filtering.")
        elseif initialized then
            ABF:Print("Loaded. Use " .. COMMAND .. " to configure filtering.")
        end
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

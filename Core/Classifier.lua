local _, ABF = ...

local U, C = ABF.util, ABF.constants
local IsSecret, Fold, NormalizeText = U.IsSecret, U.Fold, U.NormalizeText
local ContainsAny, CountSignalGroups = U.ContainsAny, U.CountSignalGroups
local PROFESSIONS, PROFESSION_ORDER = C.professions, C.professionOrder

local GUILD_CONTEXT = {
    "guild", "gilde", "guilde", "gremio", "guilda", "gilda", "gildia", "гильд", "Гильд", "公会", "公會", "길드",
}
local GUILD_RECRUITING = {
    "is recruiting", "are recruiting", "now recruiting", "recruiting", "guild recruiting", "guild recruitment",
    "guild lf", "guild looking for", "looking for members", "seeking members", "recruiting everyone",
    "accepting anyone", "accepting players", "accepting members", "accepting new members",
    "join our guild", "join my guild", "would you like to join", "want to join", "like to join",
    "anyone wanna join", "anyone want to join", "wanna join", "interested in joining",
    "are you looking for a guild", "guild invite", "we would love to have you", "we'd love to have you",
    "players to build with us", "lf mature", "lf active players", "actively forming", "currently forming",
    "building our roster", "forming our roster", "filling our roster", "rounding out our roster",
    "looking for all roles", "looking for raiders", "looking for socials",
    "rekrutiert", "sucht mitglieder", "mitglieder gesucht", "gilde sucht",
    "guilde recrute", "recrutement guilde", "recherche des membres",
    "gremio recluta", "reclutando miembros", "busca miembros",
    "guilda recruta", "recrutando membros", "procura membros",
    "gilda recluta", "cerca membri", "reclutiamo", "gildia rekrutuje", "szuka członków", "szuka graczy",
    "u potrazi smo", "tražimo igrače", "trazimo igrace", "tražimo članove", "trazimo clanove",
    "primamo igrače", "primamo igrace", "primamo članove", "primamo clanove",
    "набор в гильди", "Набор в гильди", "гильдия набира", "Гильдия набира", "ищет игроков", "Ищет игроков",
    "набираем игроков", "Набираем игроков", "公会招募", "公會招募", "招募成员", "招募成員", "길드원 모집", "길드 모집",
}
local MEMBER_SIGNALS = {
    "members", "member", "players", "new players", "returning players", "raiders", "all roles", "any role", "everyone", "socials",
    "mitglieder", "spieler", "membres", "joueurs", "miembros", "jugadores", "membros", "jogadores",
    "membri", "giocatori", "członków", "graczy", "игроков", "участников", "成员", "成員", "玩家", "길드원",
    "igračima", "igracima", "igrače", "igrace", "članove", "clanove",
}
local JOIN_SIGNALS = {
    "join us", "join the", "join up", "come join", "apply", "message us", "message me", "contact us", "contact me",
    "whisper", "send a tell", "send me a message", "want more info", "pst", "pm for", "dm for", "dm me",
    "beitreten", "bewerben", "flüstern", "rejoignez", "postulez", "murmurez", "únete", "unete", "susurra",
    "junte-se", "sussurre", "unisciti", "candidati", "dołącz", "dolacz", "napisz", "вступай", "пиши",
    "加入我们", "加入我們", "加入", "문의", "ako ste zainteresovani", "ako ste zainteresirani",
    "slobodno bacite w", "javite se", "šapnite", "sapnite",
}
local GUILD_DETAIL_SIGNALS = {
    "raid times", "raid time", "raiding", "pve", "pvp", "discord", "progression", "server time", "gmt", "timezone",
    "raidzeiten", "schlachtzug", "horaires de raid", "heures de raid", "horario de raid", "horários de raid", "orari raid",
    "рейд", "дискорд", "活动时间", "活動時間", "레이드",
}
local INTERESTED_CONTACT_SIGNALS = {
    "pst if interested", "whisper if interested", "message if interested", "message me if interested", "dm if interested", "dm me if interested",
}
local GROUP_PROMOTION_SIGNALS = {
    "new player friendly", "active events", "organized", "non drama", "weekly pvp", "farm runs", "caravans",
    "recipe grinds", "dungeons and raids", "dungeons raids",
}
local PROFESSION_SOLICIT_STRONG = {
    "lfw", "work for tips", "working for tips", "your mats", "your materials", "my mats", "my materials",
    "free with mats", "taking orders", "open for orders", "open for business", "crafting orders", "send order",
    "all recipes", "all patterns", "all crafts", "every recipe", "every pattern", "can make", "can craft",
    "can install", "installing for", "crafting for", "tips appreciated", "pst for", "whisper for", "pm for",
    "gegen mats", "gegen trinkgeld", "alle rezepte", "aufträge", "auftraege", "vos compos", "tous les patrons",
    "toutes les recettes", "commandes ouvertes", "tus materiales", "todos los patrones", "todas las recetas",
    "acepto pedidos", "seus materiais", "todas as receitas", "aceito encomendas", "vostri materiali",
    "tutte le ricette", "accetto ordini", "ваши материалы", "все рецепты", "принимаю заказы", "за чаевые",
    "自备材料", "你的材料", "您的材料", "全配方", "接单", "代工", "재료 지참", "모든 도안", "주문 받",
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
local GOLD_WORDS = { "gold", "g0ld", "wow gold", "wow g0ld", "oro", "ouro", "золото", "золота", "金币", "金幣", "골드" }
local GOLD_SALE_STRONG = {
    "wts gold", "wts wow gold", "selling gold", "sell wow gold", "gold for sale", "wow gold for sale",
    "vendo oro", "venta de oro", "vendo ouro", "venda de ouro", "gold verkaufen", "gold zu verkaufen",
    "vente d or", "продам золото", "продажа золота", "出售金币", "出售金幣", "卖金币", "賣金幣", "골드 판매",
}
local GOLD_SALE_SIGNALS = {
    "buy gold", "buy wow gold", "buy cheap gold", "purchase gold", "order gold", "cheap gold", "cheap wow gold",
    "gold service", "gold shop", "gold store", "gold delivery", "comprar oro", "oro barato", "comprar ouro",
    "ouro barato", "comprare oro", "gold kaufen", "billiges gold", "acheter de l or", "or pas cher",
    "купить золото", "дешевое золото", "дешёвое золото", "购买金币", "購買金幣", "买金币", "買金幣",
    "便宜金币", "便宜金幣", "골드 구매", "싼 골드",
}
local GOLD_MARKETING_SIGNALS = {
    "instant delivery", "fast delivery", "quick delivery", "safe delivery", "delivery in minutes", "best price",
    "lowest price", "low price", "special offer", "discount", "coupon", "trusted seller", "trusted service",
    "risk free", "guaranteed", "in stock", "24 7 service", "entrega inmediata", "entrega rápida",
    "entrega rapida", "mejor precio", "precio barato", "livraison rapide", "meilleur prix",
    "sofortige lieferung", "bester preis",
}
local GOLD_CONTACT_SIGNALS = {
    "visit our site", "visit our website", "our website", "order online", "live chat", "contact seller",
    "contact us", "add discord", "discord gg", "telegram", "whatsapp",
}
local REAL_MONEY_SIGNALS = {
    " usd", "usd ", " eur", "eur ", "paypal", "cashapp", "cash app", "venmo", "bitcoin", "crypto", "credit card", "real money",
}
local GOLD_DOMAIN_SUFFIXES = { "com", "net", "org", "gg", "cc", "cn", "shop", "store", "site", "xyz" }

local function DetectProfessions(text, raw)
    local detected, count = {}, 0
    for _, key in ipairs(PROFESSION_ORDER) do
        if key ~= "other" and ContainsAny(text, PROFESSIONS[key].words) then
            detected[key], count = true, count + 1
        end
    end
    local hasLink = raw:find("|htrade:", 1, true) ~= nil or raw:find("|henchant:", 1, true) ~= nil
    if hasLink and count == 0 then detected.other, count = true, 1 end
    return detected, count, hasLink
end

local function AnyProfessionEnabled(detected)
    for key in pairs(detected) do
        if ABF.db.professions[key] ~= false then return true end
    end
    return false
end

local function HasBracketedProfessionHeader(raw, detected)
    local header = raw:match("^%s*%[([^%]]+)%]")
    if not header then return false end
    for key in pairs(detected) do
        if PROFESSIONS[key] and ContainsAny(header, PROFESSIONS[key].words) then return true end
    end
    return false
end

local function ClassifyProfession(text, raw)
    if not ABF.db.blockProfessionAds then return nil end
    local detected, count, hasLink = DetectProfessions(text, raw)
    if count == 0 or not AnyProfessionEnabled(detected) then return nil end
    for _, prefix in ipairs(PROFESSION_REQUEST_PREFIXES) do
        if text:sub(1, #prefix) == prefix then return nil end
    end

    local score = hasLink and 4 or 2
    local reasons = { hasLink and "profession link (+4)" or "profession name (+2)" }
    if HasBracketedProfessionHeader(raw, detected) then score = score + 3; reasons[#reasons + 1] = "profession ad header (+3)" end
    local strong, strongPhrase = ContainsAny(text, PROFESSION_SOLICIT_STRONG)
    if strong then score = score + 4; reasons[#reasons + 1] = strongPhrase .. " (+4)" end
    local light, lightPhrase = ContainsAny(text, PROFESSION_SOLICIT_LIGHT)
    if light then score = score + 2; reasons[#reasons + 1] = lightPhrase .. " (+2)" end
    if raw:find("%+%d") or text:find("%d+%s*gold") or text:find("%d+%s*g%s") then
        score = score + 1; reasons[#reasons + 1] = "price/stat list (+1)"
    end
    if detected.enchanting and (raw:find("%d+h%s*%+%d") or raw:find("chest%s*:%s*%d") or raw:find("bracer%s*:%s*%d")) then
        score = score + 3; reasons[#reasons + 1] = "compact enchantment list (+3)"
    end
    if #text >= 90 then score = score + 1; reasons[#reasons + 1] = "long solicitation (+1)" end
    if score < ABF:GetThreshold("profession") then return nil end

    local labels = {}
    for _, key in ipairs(PROFESSION_ORDER) do
        if detected[key] and ABF.db.professions[key] ~= false then labels[#labels + 1] = PROFESSIONS[key].label end
    end
    return { category = "profession", label = table.concat(labels, ", "), score = score, reason = table.concat(reasons, ", ") }
end

local function CompactSpamText(raw)
    return raw:gsub("0", "o"):gsub("1", "i"):gsub("[^%w]", "")
end

local function HasGoldDomain(raw, text, compact)
    if compact:find("www", 1, true) or compact:find("dotcom", 1, true)
        or compact:find("dotnet", 1, true) or compact:find("discordgg", 1, true) then
        return true, "website/contact"
    end
    if text:find("http ", 1, true) or text:find("https ", 1, true) then return true, "website/contact" end
    for _, suffix in ipairs(GOLD_DOMAIN_SUFFIXES) do
        if raw:find("[%w%-]+%s*[%.,]%s*" .. suffix .. "%f[%A]") then return true, "website/contact" end
    end
    return false
end

local function HasRealMoneySignal(text, raw)
    local found, phrase = ContainsAny(text, REAL_MONEY_SIGNALS)
    if found then return true, phrase end
    if raw:find("$", 1, true) or raw:find("€", 1, true) or raw:find("£", 1, true) then return true, "real-money price" end
    return false
end

local function ClassifyGoldSpam(text, raw)
    if not ABF.db.blockGoldSpam then return nil end
    local compact = CompactSpamText(raw)
    local strong, strongPhrase = ContainsAny(text, GOLD_SALE_STRONG)
    local sale, salePhrase = ContainsAny(text, GOLD_SALE_SIGNALS)
    local domain, domainPhrase = HasGoldDomain(raw, text, compact)
    local contact, contactPhrase = ContainsAny(text, GOLD_CONTACT_SIGNALS)
    local marketing, marketingPhrase = ContainsAny(text, GOLD_MARKETING_SIGNALS)
    local realMoney, moneyPhrase = HasRealMoneySignal(text, raw)
    local hasGold, goldPhrase = ContainsAny(text, GOLD_WORDS)
    if not hasGold and raw:find("g[%s%p]*[o0][%s%p]*l[%s%p]*d") then hasGold, goldPhrase = true, "obfuscated gold" end
    if not hasGold and (strong or sale) then hasGold, goldPhrase = true, "gold sale phrase" end
    if not hasGold and realMoney and raw:find("%f[%d]%d[%d%.,]*%s*k?g%f[%A]") then hasGold, goldPhrase = true, "gold amount" end
    if not hasGold then return nil end

    local score, reasons, commercial = 2, { goldPhrase .. " (+2)" }, false
    if strong then score = score + 7; commercial = true; reasons[#reasons + 1] = strongPhrase .. " (+7)" end
    if sale then score = score + 4; commercial = true; reasons[#reasons + 1] = salePhrase .. " (+4)" end
    if not sale and (compact:find("buygold", 1, true) or compact:find("buywowgold", 1, true)
        or compact:find("cheapgold", 1, true) or compact:find("sellgold", 1, true)
        or compact:find("goldforsale", 1, true)) then
        score = score + 4; commercial = true; reasons[#reasons + 1] = "obfuscated sale phrase (+4)"
    end
    if domain then score = score + 3; commercial = true; reasons[#reasons + 1] = domainPhrase .. " (+3)" end
    if contact then score = score + 2; commercial = true; reasons[#reasons + 1] = contactPhrase .. " (+2)" end
    if marketing then score = score + 2; reasons[#reasons + 1] = marketingPhrase .. " (+2)" end
    if realMoney then score = score + 3; reasons[#reasons + 1] = moneyPhrase .. " (+3)" end
    if not commercial or score < ABF:GetThreshold("gold") then return nil end
    return { category = "gold", label = "Gold seller spam", score = score, reason = table.concat(reasons, ", ") }
end

local function ClassifyGuildRecruitment(text, raw, enabled, allowQuestionRecruitment)
    if not enabled then return nil end
    local score, reasons = CountSignalGroups(text, {
        { words = GUILD_RECRUITING, points = 5 }, { words = GUILD_CONTEXT, points = 2 },
        { words = MEMBER_SIGNALS, points = 2 }, { words = JOIN_SIGNALS, points = 2 },
        { words = GUILD_DETAIL_SIGNALS, points = 1 },
    })
    local hasGuildContext = ContainsAny(text, GUILD_CONTEXT)
    local hasGuildTag = raw:find("<[^<>]+>") ~= nil
    if hasGuildTag and not hasGuildContext then
        hasGuildContext, score = true, score + 2; reasons[#reasons + 1] = "guild tag (+2)"
    end
    local hasRecruiting = ContainsAny(text, GUILD_RECRUITING)
    local hasMembers = ContainsAny(text, MEMBER_SIGNALS)
    local hasJoin = ContainsAny(text, JOIN_SIGNALS)
    local hasDetails = ContainsAny(text, GUILD_DETAIL_SIGNALS)
    local hasInterestedContact = ContainsAny(text, INTERESTED_CONTACT_SIGNALS)
    local hasGroupPromotion = ContainsAny(text, GROUP_PROMOTION_SIGNALS)
    local hasDiscord = text:find("discord", 1, true) ~= nil
    if not hasGuildContext and hasDiscord and hasInterestedContact and hasGroupPromotion and #text >= 80 then
        hasGuildContext, score = true, score + 4; reasons[#reasons + 1] = "structured group recruitment (+4)"
    end
    if not hasGuildContext and hasRecruiting and hasMembers and ((hasJoin and hasDetails) or #text >= 100) then
        hasGuildContext, score = true, score + 2; reasons[#reasons + 1] = "inferred guild recruitment (+2)"
    end
    if not hasRecruiting then
        if hasGuildContext and hasMembers and hasJoin then
            score = score + 3; reasons[#reasons + 1] = "guild/member/contact combination (+3)"
        elseif hasGuildContext and hasJoin and hasDetails and #text >= 80 then
            score = score + 3; reasons[#reasons + 1] = "guild schedule/contact combination (+3)"
        end
    end
    local threshold = ABF:GetThreshold("guild")
    if not hasGuildContext or score < threshold then return nil end
    if not allowQuestionRecruitment and raw:find("?", 1, true) and score <= threshold then return nil end
    return { category = "guild", label = "Guild recruitment", score = score, reason = table.concat(reasons, ", ") }
end

function ABF:ClassifyMessage(message, mode, event)
    if type(message) ~= "string" or IsSecret(message) then return nil end
    local raw, text = Fold(message), NormalizeText(message)
    if text == "" then return nil end
    if self:IsPhraseAllowed(text) then return nil, "allowed phrase" end

    local blockedPhrase = self:FindBlockedPhrase(text)
    if blockedPhrase and self:IsCategoryEnabledForEvent("custom", event) then
        return { category = "custom", label = "Custom blocked phrase", score = 100, reason = blockedPhrase }
    end
    if self:IsCategoryEnabledForEvent("gold", event) then
        local result = ClassifyGoldSpam(text, raw)
        if result then return result end
    end
    if self:IsCategoryEnabledForEvent("profession", event) then
        local result = ClassifyProfession(text, raw)
        if result then return result end
    end
    local whisper = mode == "guild-whisper"
    local enabled = whisper and self.db.blockWhisperRecruitment or self.db.blockGuildRecruitment
    enabled = enabled and self:IsCategoryEnabledForEvent("guild", event)
    return ClassifyGuildRecruitment(text, raw, enabled, whisper)
end

function ABF:GetSensitivityComparison(message, mode, event)
    local original, comparisons = {}, {}
    for category in pairs(C.baseThresholds) do original[category] = self.db.sensitivity[category] end
    for _, level in ipairs({ "conservative", "balanced", "aggressive" }) do
        for category in pairs(C.baseThresholds) do self.db.sensitivity[category] = level end
        local result = self:ClassifyMessage(message, mode, event)
        comparisons[level] = result and (result.category .. "@" .. tostring(result.score or "?")) or "allow"
    end
    for category, value in pairs(original) do self.db.sensitivity[category] = value end
    return comparisons
end

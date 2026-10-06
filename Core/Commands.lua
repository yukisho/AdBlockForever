local _, ABF = ...

local Trim, Fold = ABF.util.Trim, ABF.util.Fold
local C, PROFESSIONS = ABF.constants, ABF.constants.professions
local COMMAND = ABF.slashCommand

local function ParseToggle(argument)
    argument = Fold(argument)
    if argument == "on" then return true end
    if argument == "off" then return false end
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
        if argument == key or argument == Fold(profession.label):gsub("%s+", "") then return key end
    end
end

function ABF:ShowHelp()
    self:Print(COMMAND .. " - open settings")
    self:Print(COMMAND .. " on|off")
    self:Print(COMMAND .. " guild on|off | whispers on|off | professions on|off | gold on|off")
    self:Print(COMMAND .. " profession NAME on|off")
    self:Print(COMMAND .. " whitelist NAME | unwhitelist NAME")
    self:Print(COMMAND .. " allowphrase TEXT | unallowphrase TEXT | blockphrase TEXT | unblockphrase TEXT")
    self:Print(COMMAND .. " sensitivity CATEGORY conservative|balanced|aggressive")
    self:Print(COMMAND .. " scope CATEGORY channel|say|yell|whisper on|off")
    self:Print(COMMAND .. " minimap show|hide | stats | last | test MESSAGE")
    self:Print(COMMAND .. " blockedlog | clearblockedlog")
    if self.isDevelopment then
        self:Print(COMMAND .. " log | capture on|off | hoverdebug | label CATEGORY | fixtures | clearlog")
    end
end

local slashKey = ABF.isDevelopment and "ADBLOCKFOREVERDEV" or "ADBLOCKFOREVER"
_G["SLASH_" .. slashKey .. "1"] = COMMAND
_G["SLASH_" .. slashKey .. "2"] = ABF.isDevelopment and "/adblockforeverdev" or "/adblockforever"
SlashCmdList[slashKey] = function(message)
    local command, argument = Trim(message):match("^(%S*)%s*(.-)$")
    command = Fold(command)

    if ABF.isDevelopment and ABF.HandleDeveloperCommand and ABF:HandleDeveloperCommand(command, argument) then
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
    elseif command == "gold" or command == "goldspam" then
        SetToggle("blockGoldSpam", argument, "Gold seller spam filtering")
    elseif command == "profession" then
        local name, toggle = argument:match("^(.-)%s+(on|off)%s*$")
        local key = name and FindProfession(name)
        if not key then ABF:Print("Usage: " .. COMMAND .. " profession NAME on|off"); return end
        ABF.db.professions[key] = toggle == "on"
        ABF:Print(PROFESSIONS[key].label .. " ads are now " .. toggle .. ".")
        ABF:NotifyChanged()
    elseif command == "allowplayer" or command == "whitelist" then
        if not ABF:AddAllowedPlayer(argument, false) then ABF:Print("Usage: " .. COMMAND .. " whitelist NAME") end
    elseif command == "unallowplayer" or command == "unwhitelist" then
        if ABF:RemoveAllowedPlayer(argument) then
            ABF:Print("Removed " .. argument .. " from the player whitelist.")
        else
            ABF:Print("That player is not whitelisted.")
        end
    elseif command == "allowphrase" then
        if not ABF:AddAllowedPhrase(argument, false) then ABF:Print("Usage: " .. COMMAND .. " allowphrase TEXT") end
    elseif command == "unallowphrase" then
        if ABF:RemoveAllowedPhrase(argument) then ABF:Print("Removed that allowed phrase.") else ABF:Print("That phrase is not allowed.") end
    elseif command == "blockphrase" then
        if not ABF:AddBlockedPhrase(argument, false) then ABF:Print("Usage: " .. COMMAND .. " blockphrase TEXT") end
    elseif command == "unblockphrase" then
        if ABF:RemoveBlockedPhrase(argument) then ABF:Print("Removed that blocked phrase.") else ABF:Print("That phrase is not in the custom blocklist.") end
    elseif command == "sensitivity" then
        local category, value = argument:match("^(%S+)%s+(%S+)%s*$")
        category, value = Fold(category or ""), Fold(value or "")
        if ABF:SetSensitivity(category, value) then
            ABF:Print(C.categoryLabels[category] .. " sensitivity is now " .. value .. ".")
        else
            ABF:Print("Usage: " .. COMMAND .. " sensitivity guild|profession|gold conservative|balanced|aggressive")
        end
    elseif command == "scope" then
        local category, scope, toggle = argument:match("^(%S+)%s+(%S+)%s+(on|off)%s*$")
        category, scope = Fold(category or ""), string.upper(Trim(scope or ""))
        if scope == "PUBLIC" then scope = "CHANNEL" end
        if ABF:SetCategoryScope(category, scope, toggle == "on") then
            ABF:Print(C.categoryLabels[category] .. " in " .. C.scopeLabels[scope] .. " is now " .. toggle .. ".")
        else
            ABF:Print("Usage: " .. COMMAND .. " scope guild|profession|gold|custom channel|say|yell|whisper on|off")
        end
    elseif command == "advanced" or command == "rules" then
        if ABF.ShowAdvancedUI then ABF:ShowAdvancedUI() end
    elseif command == "minimap" then
        argument = Fold(argument)
        if argument == "show" or argument == "on" then ABF.db.minimap.hide = false
        elseif argument == "hide" or argument == "off" then ABF.db.minimap.hide = true
        else ABF:Print("Minimap button is " .. (ABF.db.minimap.hide and "hidden" or "shown") .. "."); return end
        ABF:NotifyChanged()
    elseif command == "stats" then
        ABF:Print(string.format("%d blocked: %d guild recruitment, %d profession ads, %d gold seller spam, %d custom phrases.",
            ABF.db.stats.total or 0, ABF.db.stats.guild or 0, ABF.db.stats.profession or 0,
            ABF.db.stats.gold or 0, ABF.db.stats.custom or 0))
    elseif command == "last" then
        local entry = ABF:GetLastBlocked()
        if entry then
            ABF:Print(string.format("Last blocked [%s] from %s: %s", tostring(entry.label or entry.category),
                tostring(entry.author or "Unknown"), tostring(entry.message or "")))
        else
            ABF:Print("No blocked messages have been recorded.")
        end
    elseif command == "blockedlog" or (command == "log" and not ABF.isDevelopment) then
        if ABF.ShowBlockedLog then ABF:ShowBlockedLog() end
    elseif command == "clearblockedlog" then
        ABF:ClearBlockedLog(); ABF:Print("Blocked-message log cleared.")
    elseif command == "test" then
        if argument == "" then ABF:Print("Usage: " .. COMMAND .. " test MESSAGE"); return end
        local result, note = ABF:ClassifyMessage(argument)
        local whisperOnly = false
        if not result then result = ABF:ClassifyMessage(argument, "guild-whisper", "CHAT_MSG_WHISPER"); whisperOnly = result ~= nil end
        if result then
            ABF:Print(string.format("Would block%s as %s (score %d): %s", whisperOnly and " in a whisper" or "",
                result.label, result.score, result.reason))
        else
            ABF:Print("Would allow this message" .. (note and (": " .. note) or "."))
        end
    else
        ABF:ShowHelp()
    end
end

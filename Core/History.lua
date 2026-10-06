local _, ABF = ...

local IsSecret = ABF.util.IsSecret
local CleanLoggedMessage = ABF.util.CleanLoggedMessage

function ABF:GetBlockedLog()
    return self.db and self.db.blockedLog or {}
end

function ABF:GetBlockedLogLimit()
    return self.blockedLogLimit
end

function ABF:GetLastBlocked()
    local log = self:GetBlockedLog()
    return log[#log]
end

function ABF:ClearBlockedLog()
    if not self.db then return end
    self.db.blockedLog, self.recent = {}, {}
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
    if self.lastBlockedKey == key and now - (self.lastBlockedAt or 0) < 1 then return false end
    self.lastBlockedKey, self.lastBlockedAt = key, now

    self.db.stats.total = (self.db.stats.total or 0) + 1
    self.db.stats[result.category] = (self.db.stats[result.category] or 0) + 1
    local entry = {
        category = result.category, label = result.label, score = result.score, reason = result.reason,
        author = author or "Unknown", message = CleanLoggedMessage(message), event = event or "Unknown",
        mode = event == "CHAT_MSG_WHISPER" and "whisper" or "public", at = time and time() or 0,
    }
    table.insert(self.db.blockedLog, entry)
    while #self.db.blockedLog > self.blockedLogLimit do table.remove(self.db.blockedLog, 1) end
    self.recent = self.recent or {}
    table.insert(self.recent, 1, entry)
    while #self.recent > 20 do table.remove(self.recent) end
    self:NotifyChanged()
    return true
end

function ABF:NotifyBlockedWhisper(entry)
    local mode = self.db.whisperAlert or "none"
    if mode == "notice" or mode == "both" then
        self:Print("Blocked a " .. tostring(entry.label or "filtered") .. " whisper from "
            .. tostring(entry.author or "Unknown") .. ". Use " .. self.slashCommand .. " last to review it.")
    end
    if (mode == "sound" or mode == "both") and type(PlaySound) == "function" then
        local sound = SOUNDKIT and (SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION) or 856
        PlaySound(sound)
    end
end

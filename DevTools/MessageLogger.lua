local addonName, ABF = ...

if not ABF.isDevelopment then
    return
end

local MAX_RECENT_EVENTS = 100
local DEFAULT_MAX_ENTRIES = 250
local SCAN_INTERVAL = 0.08
local BUTTON_LINGER_SECONDS = 1.25

local CHAT_EVENTS = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
}

local initialized = false
local recentEvents = {}
local hoverButtons = {}
local hookedRegions = {}
local scanner
local logWindow
local exportBox
local exportScroll
local countText
local captureCheck
local diagnosticsCheck
local labelButtons = {}
local RefreshExport

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function CanAccessValue(value)
    if type(canaccessvalue) == "function" then
        local ok, accessible = pcall(canaccessvalue, value)
        return ok and accessible == true
    end
    return not IsSecret(value)
end

local function Trim(value)
    if type(value) ~= "string" or IsSecret(value) then
        return ""
    end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function OneLine(value)
    value = Trim(value)
    value = value:gsub("[%c]", " ")
    value = value:gsub("%s+", " ")
    return Trim(value)
end

local function StripChatMarkup(value)
    value = Trim(value)
    if value == "" then
        return ""
    end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("|T.-|t", "")
    value = value:gsub("|A.-|a", "")
    value = value:gsub("|H.-|h(.-)|h", "%1")
    value = value:gsub("||", "|")
    return OneLine(value)
end

local function MatchText(value)
    value = StripChatMarkup(value):lower()
    value = value:gsub("[%p%s]+", " ")
    return Trim(value)
end

local function Fingerprint(value)
    value = MatchText(value):gsub("%d+", "#"):gsub("%s+", "")
    return value
end

local function FindNearDuplicate(tools, message)
    local fingerprint = Fingerprint(message)
    if #fingerprint < 12 then return nil end
    for index = #tools.log, 1, -1 do
        local candidate = Fingerprint(tools.log[index].rawMessage or tools.log[index].message or "")
        if candidate == fingerprint then
            return index
        end
        local shorter, longer = fingerprint, candidate
        if #shorter > #longer then shorter, longer = longer, shorter end
        if #shorter >= 20 and #shorter / math.max(1, #longer) >= 0.8 and longer:find(shorter, 1, true) then
            return index
        end
    end
end

local function IsNativeMouseOver(region)
    if not region or type(MouseIsOver) ~= "function" then
        return false
    end
    local ok, result = pcall(MouseIsOver, region)
    if not ok or not CanAccessValue(result) then
        return false
    end
    return result == true
end

local function IsCursorInsideRegion(region)
    if not region or type(GetCursorPosition) ~= "function" then
        return false
    end
    local left, bottom, width, height
    if region.GetRect then
        local ok
        ok, left, bottom, width, height = pcall(region.GetRect, region)
        if not ok then
            left = nil
        end
    end
    if type(left) ~= "number" and region.GetLeft and region.GetRight
        and region.GetTop and region.GetBottom then
        local right, top
        left, right, top, bottom = region:GetLeft(), region:GetRight(), region:GetTop(), region:GetBottom()
        if CanAccessValue(left) and CanAccessValue(right)
            and CanAccessValue(top) and CanAccessValue(bottom)
            and type(left) == "number" and type(right) == "number"
            and type(top) == "number" and type(bottom) == "number" then
            width, height = right - left, top - bottom
        end
    end
    if not CanAccessValue(left) or not CanAccessValue(bottom)
        or not CanAccessValue(width) or not CanAccessValue(height) then
        return false
    end
    if type(left) ~= "number" or type(bottom) ~= "number"
        or type(width) ~= "number" or type(height) ~= "number"
        or width <= 0 or height <= 0 then
        return false
    end
    local scale = region.GetEffectiveScale and region:GetEffectiveScale()
    if not CanAccessValue(scale) then
        return false
    end
    if type(scale) ~= "number" or scale <= 0 then
        scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    end
    local cursorX, cursorY = GetCursorPosition()
    if not CanAccessValue(cursorX) or not CanAccessValue(cursorY) then
        return false
    end
    if type(cursorX) ~= "number" or type(cursorY) ~= "number" then
        return false
    end
    cursorX, cursorY = cursorX / scale, cursorY / scale
    return cursorX >= left and cursorX <= left + width
        and cursorY >= bottom and cursorY <= bottom + height
end

local function IsMouseOver(region)
    return IsNativeMouseOver(region) or IsCursorInsideRegion(region)
end

local function SafeRegionText(region)
    if not region then
        return nil
    end
    local isFontString = region.IsObjectType and region:IsObjectType("FontString")
    if not CanAccessValue(isFontString) then
        return nil
    end
    if not isFontString and region.GetObjectType then
        local objectType = region:GetObjectType()
        if not CanAccessValue(objectType) then
            return nil
        end
        isFontString = objectType == "FontString"
    end
    if not isFontString then
        return nil
    end
    if region.IsShown then
        local shown = region:IsShown()
        if CanAccessValue(shown) and not shown then
            return nil
        end
    end
    local text = region:GetText()
    if type(text) ~= "string" or IsSecret(text) or text == "" then
        return nil
    end
    return text
end

local function GetTimestamp()
    return time and time() or 0
end

local function TimestampText(value)
    if date and type(value) == "number" and value > 0 then
        return date("%Y-%m-%d %H:%M:%S", value)
    end
    return tostring(value or 0)
end

local function EnsureData()
    local db = ABF.db
    if type(db.devTools) ~= "table" then
        db.devTools = {}
    end
    local tools = db.devTools
    if type(tools.captureEnabled) ~= "boolean" then
        tools.captureEnabled = true
    end
    if type(tools.includeDiagnostics) ~= "boolean" then
        tools.includeDiagnostics = false
    end
    if type(tools.maxEntries) ~= "number" or tools.maxEntries < 1 then
        tools.maxEntries = DEFAULT_MAX_ENTRIES
    end
    tools.maxEntries = math.min(math.floor(tools.maxEntries), 1000)
    if type(tools.log) ~= "table" then
        tools.log = {}
    end
    while #tools.log > tools.maxEntries do
        table.remove(tools.log, 1)
    end
    return tools
end

local function FindRecentEvent(renderedText)
    local renderedMatch = MatchText(renderedText)
    if renderedMatch == "" then
        return nil
    end
    for index = #recentEvents, 1, -1 do
        local entry = recentEvents[index]
        if entry.match ~= "" and renderedMatch:find(entry.match, 1, true) then
            return entry
        end
    end
    return nil
end

local function GetClassification(message, event)
    local mode = event == "CHAT_MSG_WHISPER" and "guild-whisper" or nil
    local result, note = ABF:ClassifyMessage(message, mode, event)
    if not result and not mode then
        local whisperResult = ABF:ClassifyMessage(message, "guild-whisper", "CHAT_MSG_WHISPER")
        if whisperResult then
            return whisperResult, "guild-whisper", nil
        end
    end
    return result, mode, note
end

RefreshExport = function()
    if not exportBox or not logWindow or not logWindow:IsShown() or not ABF.db then
        return
    end
    local tools = EnsureData()
    local lines = {}
    for _, entry in ipairs(tools.log) do
        local message = StripChatMarkup(entry.message or entry.rendered or "")
        if tools.includeDiagnostics then
            local result, mode, note = GetClassification(entry.rawMessage or message, entry.event)
            local normalized, deobfuscated = ABF:GetDiagnosticText(entry.rawMessage or message)
            local comparison = ABF:GetSensitivityComparison(entry.rawMessage or message, mode, entry.event)
            local verdict
            if result then
                verdict = string.format(
                    "BLOCK %s score=%s reason=%s",
                    result.category or result.label or "unknown",
                    tostring(result.score or "?"),
                    OneLine(result.reason or "unknown")
                )
            else
                verdict = "ALLOW" .. (note and (" reason=" .. OneLine(note)) or "")
            end
            lines[#lines + 1] = string.format(
                "[%s] [%s] [%s] [%s] %s",
                TimestampText(entry.timestamp),
                entry.event or "RENDERED_CHAT",
                OneLine(entry.author or "Unknown"),
                mode or "public",
                verdict .. " | expected=" .. OneLine(entry.expectedCategory or "unlabeled")
                    .. (entry.nearDuplicateOf and (" | near-duplicate=#" .. entry.nearDuplicateOf) or "")
                    .. " | sensitivity=" .. comparison.conservative .. "/" .. comparison.balanced .. "/" .. comparison.aggressive
                    .. " | normalized=" .. OneLine(normalized)
                    .. " | deobfuscated=" .. OneLine(deobfuscated)
                    .. " | " .. message
            )
        else
            lines[#lines + 1] = message
        end
    end
    local exportText = table.concat(lines, "\n")
    exportBox:SetText(exportText)
    local minimumHeight = exportScroll and exportScroll:GetHeight() or 1
    local estimatedRows = 1
    for line in (exportText .. "\n"):gmatch("(.-)\n") do
        estimatedRows = estimatedRows + math.max(1, math.ceil(#line / 100))
    end
    exportBox:SetHeight(math.max(minimumHeight, estimatedRows * 15 + 20))
    countText:SetText(string.format(
        "%d / %d captured messages%s",
        #tools.log,
        tools.maxEntries,
        tools.captureEnabled and "" or " | Hover capture paused"
    ))
    captureCheck:SetChecked(tools.captureEnabled)
    diagnosticsCheck:SetChecked(tools.includeDiagnostics)
end

local function CaptureRenderedLine(renderedText, chatFrameName)
    local rendered = StripChatMarkup(renderedText)
    if rendered == "" then
        return
    end
    local source = FindRecentEvent(renderedText)
    local rawMessage = source and source.message or rendered
    local message = StripChatMarkup(rawMessage)
    local result, mode, note = GetClassification(rawMessage, source and source.event)
    local tools = EnsureData()
    local duplicateIndex = FindNearDuplicate(tools, rawMessage)
    tools.log[#tools.log + 1] = {
        message = OneLine(message),
        rawMessage = OneLine(rawMessage),
        rendered = rendered,
        author = source and source.author or "Unknown",
        event = source and source.event or "RENDERED_CHAT",
        channel = source and source.channel or chatFrameName or "Unknown",
        timestamp = GetTimestamp(),
        capturedCategory = result and result.category or nil,
        capturedScore = result and result.score or nil,
        capturedReason = result and result.reason or note,
        capturedMode = mode,
        nearDuplicateOf = duplicateIndex,
    }
    while #tools.log > tools.maxEntries do
        table.remove(tools.log, 1)
    end
    ABF:Print(string.format(
        "Captured message %d/%d (%s).",
        #tools.log,
        tools.maxEntries,
        result and ("currently blocks as " .. (result.category or result.label or "unknown")) or "currently allowed"
    ))
    if duplicateIndex then
        ABF:Print("This resembles captured message #" .. duplicateIndex .. ".")
    end
    RefreshExport()
end

local function PositionHoverButton(button, chatFrame, region)
    button:ClearAllPoints()
    local anchored = pcall(button.SetPoint, button, "RIGHT", region, "RIGHT", -2, 0)
    if anchored then
        return true
    end
    local _, lineY = region:GetCenter()
    local _, frameY = chatFrame:GetCenter()
    if not CanAccessValue(lineY) or not CanAccessValue(frameY)
        or type(lineY) ~= "number" or type(frameY) ~= "number" then
        return false
    end
    button:SetPoint("RIGHT", chatFrame, "RIGHT", -3, lineY - frameY)
    return true
end

local function CreateHoverButton(chatFrame)
    local button = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
    button:SetSize(20, 18)
    button:SetFrameStrata("TOOLTIP")
    button:SetText("+")
    button:Hide()
    button.chatFrame = chatFrame
    button:SetScript("OnClick", function(self)
        if self.renderedText then
            CaptureRenderedLine(self.renderedText, self.chatFrame and self.chatFrame:GetName())
        end
        self:Hide()
        self.renderedText = nil
    end)
    button:SetScript("OnEnter", function(self)
        self.lastSeen = GetTime and GetTime() or 0
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Capture chat message")
        GameTooltip:AddLine("Adds this line to the AdBlock Forever developer log.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    hoverButtons[chatFrame] = button
    return button
end

local function GetChatRegions(chatFrame)
    local container = chatFrame.FontStringContainer or chatFrame
    if not container.GetRegions then
        return nil
    end
    return { container:GetRegions() }
end

local function ShowHoverButtonForRegion(region, chatFrame)
    if not ABF.db or not EnsureData().captureEnabled then
        return
    end
    local text = SafeRegionText(region)
    if not text then
        return
    end
    local button = hoverButtons[chatFrame] or CreateHoverButton(chatFrame)
    if PositionHoverButton(button, chatFrame, region) then
        button.renderedText = text
        button.lastSeen = GetTime and GetTime() or 0
        button:Show()
    end
end

local function AttachRegionHover(region, chatFrame)
    if hookedRegions[region] or not region or not region.HookScript
        or not region.SetMouseMotionEnabled then
        return false
    end
    local ok = pcall(function()
        if region.SetMouseClickEnabled then
            region:SetMouseClickEnabled(false)
        end
        region:SetMouseMotionEnabled(true)
        region:HookScript("OnEnter", function(self)
            ShowHoverButtonForRegion(self, chatFrame)
        end)
        region:HookScript("OnLeave", function()
            local button = hoverButtons[chatFrame]
            if button then
                button.lastSeen = GetTime and GetTime() or 0
            end
        end)
    end)
    if ok then
        hookedRegions[region] = true
    end
    return ok
end

local function ScanChatFrame(chatFrame, now)
    local button = hoverButtons[chatFrame] or CreateHoverButton(chatFrame)
    if button:IsShown() and IsMouseOver(button) then
        button.lastSeen = now
        return
    end
    if not chatFrame:IsShown() then
        if button:IsShown() and now - (button.lastSeen or 0) > BUTTON_LINGER_SECONDS then
            button:Hide()
            button.renderedText = nil
        end
        return
    end

    local regions = GetChatRegions(chatFrame)
    if regions then
        for _, region in ipairs(regions) do
            local text = SafeRegionText(region)
            if text then
                AttachRegionHover(region, chatFrame)
            end
            if text and IsMouseOver(region) and PositionHoverButton(button, chatFrame, region) then
                button.renderedText = text
                button.lastSeen = now
                button:Show()
                return
            end
        end
    end
    if button:IsShown() and now - (button.lastSeen or 0) > BUTTON_LINGER_SECONDS then
        button:Hide()
        button.renderedText = nil
    end
end

local function PrintHoverDiagnostics()
    local tools = EnsureData()
    ABF:Print("Hover capture is " .. (tools.captureEnabled and "on" or "off") .. ".")
    local frameCount = 0
    local regionCount = 0
    local textCount = 0
    local hoveredCount = 0
    local nativeHoveredCount = 0
    local geometryHoveredCount = 0
    local hookedCount = 0
    for index = 1, (NUM_CHAT_WINDOWS or 10) do
        local chatFrame = _G["ChatFrame" .. index]
        if chatFrame and chatFrame:IsShown() then
            frameCount = frameCount + 1
            local regions = GetChatRegions(chatFrame) or {}
            regionCount = regionCount + #regions
            for _, region in ipairs(regions) do
                if SafeRegionText(region) then
                    textCount = textCount + 1
                    if hookedRegions[region] then
                        hookedCount = hookedCount + 1
                    end
                    local nativeHovered = IsNativeMouseOver(region)
                    local geometryHovered = IsCursorInsideRegion(region)
                    if nativeHovered then
                        nativeHoveredCount = nativeHoveredCount + 1
                    end
                    if geometryHovered then
                        geometryHoveredCount = geometryHoveredCount + 1
                    end
                    if nativeHovered or geometryHovered then
                        hoveredCount = hoveredCount + 1
                    end
                end
            end
        end
    end
    ABF:Print(string.format(
        "Hover scan: %d frame(s), %d region(s), %d text line(s), %d motion-hooked, %d hovered (native %d, geometry %d).",
        frameCount,
        regionCount,
        textCount,
        hookedCount,
        hoveredCount,
        nativeHoveredCount,
        geometryHoveredCount
    ))
    ABF:Print("Keep the cursor over a message while running " .. ABF.slashCommand .. " hoverdebug.")
end

local function ScanChatWindows(elapsed)
    scanner.elapsed = (scanner.elapsed or 0) + elapsed
    if scanner.elapsed < SCAN_INTERVAL then
        return
    end
    scanner.elapsed = 0
    if not ABF.db then
        return
    end
    local tools = EnsureData()
    if not tools.captureEnabled then
        for _, button in pairs(hoverButtons) do
            button:Hide()
        end
        return
    end
    local now = GetTime and GetTime() or 0
    for index = 1, (NUM_CHAT_WINDOWS or 10) do
        local chatFrame = _G["ChatFrame" .. index]
        if chatFrame then
            ScanChatFrame(chatFrame, now)
        end
    end
end

local function CreateButton(parent, text, width, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetText(text)
    return button
end

local function LabelLatest(category)
    local tools = EnsureData()
    local entry = tools.log[#tools.log]
    if not entry then
        ABF:Print("Capture a message before assigning a developer label.")
        return
    end
    entry.expectedCategory = category
    ABF:Print("Latest capture labeled " .. category .. ".")
    RefreshExport()
end

local function BuildFixtureExport()
    local tools = EnsureData()
    local lines = {
        "-- AdBlock Forever " .. tostring(ABF.version) .. " developer fixture export",
        "return {",
    }
    local count = 0
    for _, entry in ipairs(tools.log) do
        if entry.expectedCategory then
            count = count + 1
            lines[#lines + 1] = string.format(
                "    { expected = %q, event = %q, message = %q },",
                entry.expectedCategory,
                entry.event or "CHAT_MSG_CHANNEL",
                entry.rawMessage or entry.message or ""
            )
        end
    end
    lines[#lines + 1] = "}"
    return table.concat(lines, "\n"), count
end

local function CreateLogWindow()
    if logWindow then
        return
    end
    logWindow = CreateFrame("Frame", addonName .. "DeveloperLogFrame", UIParent, "BasicFrameTemplateWithInset")
    logWindow:SetSize(820, 650)
    logWindow:SetPoint("CENTER")
    logWindow:SetFrameStrata("DIALOG")
    logWindow:SetMovable(true)
    logWindow:SetClampedToScreen(true)
    logWindow:EnableMouse(true)
    logWindow:RegisterForDrag("LeftButton")
    logWindow:SetScript("OnDragStart", logWindow.StartMoving)
    logWindow:SetScript("OnDragStop", logWindow.StopMovingOrSizing)
    logWindow:SetScript("OnShow", RefreshExport)
    logWindow.TitleText:SetText("AdBlock Forever Developer Log")
    logWindow:Hide()
    table.insert(UISpecialFrames, logWindow:GetName())

    local help = logWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 18, -36)
    help:SetPoint("RIGHT", -18, 0)
    help:SetJustifyH("LEFT")
    help:SetText("Hover a visible chat line and click its + button. Select All prepares this text for Ctrl+C.")

    captureCheck = CreateFrame("CheckButton", nil, logWindow, "UICheckButtonTemplate")
    captureCheck:SetSize(24, 24)
    captureCheck:SetPoint("TOPLEFT", 16, -56)
    local captureLabel = captureCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    captureLabel:SetPoint("LEFT", captureCheck, "RIGHT", 2, 0)
    captureLabel:SetText("Enable hover capture")
    captureCheck:SetHitRectInsets(0, -captureLabel:GetStringWidth() - 8, 0, 0)
    captureCheck:SetScript("OnClick", function(self)
        EnsureData().captureEnabled = self:GetChecked() and true or false
        RefreshExport()
    end)

    diagnosticsCheck = CreateFrame("CheckButton", nil, logWindow, "UICheckButtonTemplate")
    diagnosticsCheck:SetSize(24, 24)
    diagnosticsCheck:SetPoint("LEFT", captureCheck, "RIGHT", 190, 0)
    local diagnosticsLabel = diagnosticsCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    diagnosticsLabel:SetPoint("LEFT", diagnosticsCheck, "RIGHT", 2, 0)
    diagnosticsLabel:SetText("Include live classifier diagnostics")
    diagnosticsCheck:SetHitRectInsets(0, -diagnosticsLabel:GetStringWidth() - 8, 0, 0)
    diagnosticsCheck:SetScript("OnClick", function(self)
        EnsureData().includeDiagnostics = self:GetChecked() and true or false
        RefreshExport()
    end)

    local labelText = logWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    labelText:SetPoint("TOPLEFT", 18, -91)
    labelText:SetText("Label latest capture:")
    local previous = labelText
    local labels = {
        { "Guild", "guild", 66 },
        { "Profession", "profession", 88 },
        { "Gold", "gold", 62 },
        { "Custom", "custom", 70 },
        { "Legitimate", "legitimate", 86 },
    }
    for _, definition in ipairs(labels) do
        local category = definition[2]
        local button = CreateButton(logWindow, definition[1], definition[3], "LEFT", previous, "RIGHT", 8, 0)
        button:SetScript("OnClick", function() LabelLatest(category) end)
        labelButtons[category] = button
        previous = button
    end

    exportScroll = CreateFrame("ScrollFrame", nil, logWindow, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", 18, -126)
    exportScroll:SetPoint("BOTTOMRIGHT", -34, 54)

    exportBox = CreateFrame("EditBox", nil, exportScroll)
    exportBox:SetMultiLine(true)
    exportBox:SetAutoFocus(false)
    exportBox:SetFontObject(ChatFontNormal)
    exportBox:SetWidth(752)
    exportBox:SetTextInsets(6, 6, 6, 6)
    exportBox:SetScript("OnEscapePressed", exportBox.ClearFocus)
    exportBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local estimatedRows = 1
        for line in (text .. "\n"):gmatch("(.-)\n") do
            estimatedRows = estimatedRows + math.max(1, math.ceil(#line / 100))
        end
        self:SetHeight(math.max(exportScroll:GetHeight(), estimatedRows * 15 + 20))
    end)
    exportScroll:SetScrollChild(exportBox)

    local background = logWindow:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", exportScroll, "TOPLEFT", -5, 5)
    background:SetPoint("BOTTOMRIGHT", exportScroll, "BOTTOMRIGHT", 22, -5)
    background:SetColorTexture(0.02, 0.02, 0.02, 0.75)

    countText = logWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countText:SetPoint("BOTTOMLEFT", 18, 20)

    local clearButton = CreateButton(logWindow, "Clear Log", 92, "BOTTOMRIGHT", logWindow, "BOTTOMRIGHT", -18, 14)
    clearButton:SetScript("OnClick", function()
        StaticPopup_Show("ADBLOCK_FOREVER_DEV_CLEAR_LOG")
    end)

    local selectButton = CreateButton(logWindow, "Select All", 92, "RIGHT", clearButton, "LEFT", -8, 0)
    selectButton:SetScript("OnClick", function()
        exportBox:SetFocus()
        exportBox:HighlightText()
        ABF:Print("Log selected. Press Ctrl+C to copy it.")
    end)

    local refreshButton = CreateButton(logWindow, "Refresh", 82, "RIGHT", selectButton, "LEFT", -8, 0)
    refreshButton:SetScript("OnClick", RefreshExport)

    local fixtureButton = CreateButton(logWindow, "Export Fixtures", 112, "RIGHT", refreshButton, "LEFT", -8, 0)
    fixtureButton:SetScript("OnClick", function()
        local text, count = BuildFixtureExport()
        exportBox:SetText(text)
        exportBox:SetFocus()
        exportBox:HighlightText()
        ABF:Print(string.format("Selected %d labeled regression fixture(s). Press Ctrl+C to copy.", count))
    end)

    StaticPopupDialogs["ADBLOCK_FOREVER_DEV_CLEAR_LOG"] = {
        text = "Clear every captured AdBlock Forever developer-log message?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            EnsureData().log = {}
            RefreshExport()
            ABF:Print("Developer log cleared.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function ABF:ShowDeveloperLog(selectAll)
    if not self.db then
        return
    end
    if self.HideUI then
        self:HideUI()
    end
    if self.HideBlockedLog then
        self:HideBlockedLog()
    end
    if self.HideAdvancedUI then
        self:HideAdvancedUI()
    end
    CreateLogWindow()
    RefreshExport()
    logWindow:Show()
    if logWindow.Raise then
        logWindow:Raise()
    end
    if selectAll then
        exportBox:SetFocus()
        exportBox:HighlightText()
    end
end

function ABF:HideDeveloperLog()
    if logWindow then
        logWindow:Hide()
    end
end

function ABF:HandleDeveloperCommand(command, argument)
    if command == "log" or command == "devlog" then
        self:ShowDeveloperLog(false)
        return true
    elseif command == "export" then
        self:ShowDeveloperLog(true)
        self:Print("Log selected. Press Ctrl+C to copy it.")
        return true
    elseif command == "capture" then
        argument = Trim(argument):lower()
        local tools = EnsureData()
        if argument == "on" then
            tools.captureEnabled = true
        elseif argument == "off" then
            tools.captureEnabled = false
        else
            self:Print("Hover capture is " .. (tools.captureEnabled and "on" or "off") .. ".")
            return true
        end
        self:Print("Hover capture is now " .. argument .. ".")
        RefreshExport()
        return true
    elseif command == "hoverdebug" or command == "hoverstatus" then
        PrintHoverDiagnostics()
        return true
    elseif command == "label" then
        argument = Trim(argument):lower()
        if argument == "guild" or argument == "profession" or argument == "gold"
            or argument == "custom" or argument == "legitimate" then
            LabelLatest(argument)
        else
            self:Print("Usage: " .. self.slashCommand .. " label guild|profession|gold|custom|legitimate")
        end
        return true
    elseif command == "fixtures" then
        self:ShowDeveloperLog(false)
        local text, count = BuildFixtureExport()
        exportBox:SetText(text)
        exportBox:SetFocus()
        exportBox:HighlightText()
        self:Print(string.format("Selected %d labeled regression fixture(s). Press Ctrl+C to copy.", count))
        return true
    elseif command == "clearlog" then
        EnsureData().log = {}
        RefreshExport()
        self:Print("Developer log cleared.")
        return true
    end
    return false
end

function ABF:InitializeDeveloperTools()
    if initialized then
        return
    end
    initialized = true
    EnsureData()

    local captureFrame = CreateFrame("Frame")
    for _, event in ipairs(CHAT_EVENTS) do
        captureFrame:RegisterEvent(event)
    end
    captureFrame:SetScript("OnEvent", function(_, event, message, author, _, channelName)
        if type(message) ~= "string" or IsSecret(message) then
            return
        end
        recentEvents[#recentEvents + 1] = {
            event = event,
            message = OneLine(message),
            match = MatchText(message),
            author = OneLine(author or "Unknown"),
            channel = OneLine(channelName or ""),
            receivedAt = GetTime and GetTime() or 0,
        }
        while #recentEvents > MAX_RECENT_EVENTS do
            table.remove(recentEvents, 1)
        end
    end)

    scanner = CreateFrame("Frame")
    scanner:SetScript("OnUpdate", function(_, elapsed)
        ScanChatWindows(elapsed)
    end)
end

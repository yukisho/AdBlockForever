local addonName, ABF = ...

local window
local phraseInput
local phraseScroll
local phraseContent
local phraseRows = {}
local sensitivityButtons = {}
local scopeChecks = {}
local alertButton
local transferBox

local SENSITIVITY_ORDER = { "conservative", "balanced", "aggressive" }
local ALERT_ORDER = { "none", "notice", "sound", "both" }

local function CreateButton(parent, text, width, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetText(text)
    return button
end

local function CreateCheck(parent, label, x, y, handler)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check:SetPoint("TOPLEFT", x, y)
    local labelText = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelText:SetPoint("LEFT", check, "RIGHT", 1, 0)
    labelText:SetText(label)
    check.label = labelText
    check:SetHitRectInsets(0, -labelText:GetStringWidth() - 5, 0, 0)
    check:SetScript("OnClick", handler)
    return check
end

local function CycleValue(current, values)
    for index, value in ipairs(values) do
        if value == current then
            return values[(index % #values) + 1]
        end
    end
    return values[1]
end

local function RefreshPhrases()
    if not phraseContent then return end
    local entries = ABF:GetBlockedPhrases()
    for index, entry in ipairs(entries) do
        local row = phraseRows[index]
        if not row then
            row = CreateFrame("Frame", nil, phraseContent)
            row:SetSize(352, 28)
            row:SetPoint("TOPLEFT", 0, -((index - 1) * 29))
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", 5, 0)
            row.text:SetWidth(258)
            row.text:SetJustifyH("LEFT")
            row.remove = CreateButton(row, "Remove", 76, "RIGHT", row, "RIGHT", -4, 0)
            row.remove:SetScript("OnClick", function()
                ABF:RemoveBlockedPhrase(row.phrase)
                RefreshPhrases()
            end)
            phraseRows[index] = row
        end
        row.phrase = entry.phrase
        row.text:SetText(entry.phrase)
        row:Show()
    end
    for index = #entries + 1, #phraseRows do
        phraseRows[index]:Hide()
    end
    phraseContent:SetHeight(math.max(1, #entries * 29))
end

local function ResizeTransferBox()
    if not transferBox then return end
    local text = transferBox:GetText() or ""
    local rows = 1
    for line in (text .. "\n"):gmatch("(.-)\n") do
        rows = rows + math.max(1, math.ceil(#line / 105))
    end
    transferBox:SetHeight(math.max(170, rows * 15 + 20))
end

function ABF:RefreshAdvancedUI()
    if not window or not window:IsShown() or not self.db then return end
    RefreshPhrases()
    for category, button in pairs(sensitivityButtons) do
        local value = self:GetSensitivity(category)
        button:SetText((self.categoryLabels[category] or category) .. ": " .. value:gsub("^%l", string.upper))
    end
    for category, checks in pairs(scopeChecks) do
        for scope, check in pairs(checks) do
            check:SetChecked(self.db.channelScopes[category][scope] ~= false)
        end
    end
    alertButton:SetText("Blocked-whisper alert: " .. (self.db.whisperAlert or "none"))
end

local function CreateRulesPanel()
    local panel = CreateFrame("Frame", nil, window, "InsetFrameTemplate")
    panel:SetSize(410, 260)
    panel:SetPoint("TOPLEFT", 14, -56)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetText("Custom blocked phrases")

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -35)
    hint:SetText("Plain-text matches. Allowed players and phrases still take priority.")

    phraseInput = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    phraseInput:SetSize(288, 24)
    phraseInput:SetPoint("TOPLEFT", 14, -53)
    phraseInput:SetAutoFocus(false)
    phraseInput:SetMaxLetters(240)
    local add = CreateButton(panel, "Block", 76, "LEFT", phraseInput, "RIGHT", 8, 0)
    local function Submit()
        local value = phraseInput:GetText()
        if value and value:match("%S") and ABF:AddBlockedPhrase(value, false) then
            phraseInput:SetText("")
            RefreshPhrases()
        end
        phraseInput:ClearFocus()
    end
    add:SetScript("OnClick", Submit)
    phraseInput:SetScript("OnEnterPressed", Submit)
    phraseInput:SetScript("OnEscapePressed", phraseInput.ClearFocus)

    phraseScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    phraseScroll:SetPoint("TOPLEFT", 12, -84)
    phraseScroll:SetPoint("BOTTOMRIGHT", -30, 10)
    phraseContent = CreateFrame("Frame", nil, phraseScroll)
    phraseContent:SetSize(352, 1)
    phraseScroll:SetScrollChild(phraseContent)
end

local function CreateControlsPanel()
    local panel = CreateFrame("Frame", nil, window, "InsetFrameTemplate")
    panel:SetSize(426, 260)
    panel:SetPoint("TOPRIGHT", -14, -56)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetText("Sensitivity and chat scope")

    local x = 12
    for _, category in ipairs({ "guild", "profession", "gold" }) do
        local categoryKey = category
        local button = CreateButton(panel, "", 130, "TOPLEFT", panel, "TOPLEFT", x, -38)
        button:SetScript("OnClick", function()
            ABF:SetSensitivity(categoryKey, CycleValue(ABF:GetSensitivity(categoryKey), SENSITIVITY_ORDER))
            ABF:RefreshAdvancedUI()
        end)
        sensitivityButtons[category] = button
        x = x + 136
    end

    local headings = { "Filter", "Channel", "Say", "Yell", "Whisper" }
    local headingX = { 12, 154, 222, 276, 326 }
    for index, label in ipairs(headings) do
        local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        heading:SetPoint("TOPLEFT", headingX[index], -76)
        heading:SetText(label)
    end

    for row, category in ipairs(ABF.categoryOrder) do
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", 12, -98 - ((row - 1) * 27))
        label:SetWidth(135)
        label:SetJustifyH("LEFT")
        label:SetText(ABF.categoryLabels[category])
        scopeChecks[category] = {}
        for column, scope in ipairs(ABF.scopeOrder) do
            local categoryKey, scopeKey = category, scope
            local check = CreateCheck(panel, "", 150 + ((column - 1) * 61), -94 - ((row - 1) * 27), function(self)
                ABF:SetCategoryScope(categoryKey, scopeKey, self:GetChecked() and true or false)
            end)
            scopeChecks[category][scope] = check
        end
    end

    alertButton = CreateButton(panel, "", 240, "BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 12)
    alertButton:SetScript("OnClick", function()
        ABF.db.whisperAlert = CycleValue(ABF.db.whisperAlert, ALERT_ORDER)
        ABF:NotifyChanged()
        ABF:RefreshAdvancedUI()
    end)
end

local function CreateTransferPanel()
    local panel = CreateFrame("Frame", nil, window, "InsetFrameTemplate")
    panel:SetPoint("TOPLEFT", 14, -328)
    panel:SetPoint("BOTTOMRIGHT", -14, 56)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetText("Settings import / export")

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -35)
    hint:SetText("Exports filtering settings, the player whitelist, and custom allow/block phrases. Logs and statistics are excluded.")

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -55)
    scroll:SetPoint("BOTTOMRIGHT", -30, 44)
    transferBox = CreateFrame("EditBox", nil, scroll)
    transferBox:SetMultiLine(true)
    transferBox:SetAutoFocus(false)
    transferBox:SetFontObject(ChatFontNormal)
    transferBox:SetWidth(792)
    transferBox:SetTextInsets(6, 6, 6, 6)
    transferBox:SetScript("OnEscapePressed", transferBox.ClearFocus)
    transferBox:SetScript("OnTextChanged", ResizeTransferBox)
    scroll:SetScrollChild(transferBox)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", scroll, "TOPLEFT", -5, 5)
    background:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 22, -5)
    background:SetColorTexture(0.02, 0.02, 0.02, 0.82)

    local import = CreateButton(panel, "Import", 82, "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 10)
    import:SetScript("OnClick", function()
        local ok, errorText = ABF:ImportSettings(transferBox:GetText() or "")
        if ok then
            ABF:Print("Settings imported successfully.")
            ABF:RefreshAdvancedUI()
        else
            ABF:Print(errorText)
        end
    end)
    local export = CreateButton(panel, "Export", 82, "RIGHT", import, "LEFT", -8, 0)
    export:SetScript("OnClick", function()
        transferBox:SetText(ABF:ExportSettings())
        transferBox:SetFocus()
        transferBox:HighlightText()
        ABF:Print("Settings selected. Press Ctrl+C to copy them.")
    end)
end

local function CreateResetPopup(key, text, section)
    StaticPopupDialogs[key] = {
        text = text,
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            ABF:ResetSection(section)
            ABF:RefreshAdvancedUI()
            ABF:Print("Reset " .. section .. ".")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

local function CreateWindow()
    if window then return end
    window = CreateFrame("Frame", addonName .. "AdvancedFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(880, 700)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetScript("OnShow", function() ABF:RefreshAdvancedUI() end)
    window.TitleText:SetText("AdBlock Forever - Rules & Controls")
    window:Hide()
    table.insert(UISpecialFrames, window:GetName())

    local help = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 18, -36)
    help:SetText("Fine-tune what is blocked and where. Conservative requires more evidence; Aggressive requires less.")

    CreateRulesPanel()
    CreateControlsPanel()
    CreateTransferPanel()

    local resetStats = CreateButton(window, "Reset Stats", 96, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 14)
    resetStats:SetScript("OnClick", function() StaticPopup_Show("ADBLOCK_FOREVER_RESET_STATS") end)
    local resetLists = CreateButton(window, "Reset Lists", 96, "RIGHT", resetStats, "LEFT", -8, 0)
    resetLists:SetScript("OnClick", function() StaticPopup_Show("ADBLOCK_FOREVER_RESET_LISTS") end)
    local resetFilters = CreateButton(window, "Reset Filters", 104, "RIGHT", resetLists, "LEFT", -8, 0)
    resetFilters:SetScript("OnClick", function() StaticPopup_Show("ADBLOCK_FOREVER_RESET_FILTERS") end)

    CreateResetPopup("ADBLOCK_FOREVER_RESET_FILTERS", "Reset filtering, sensitivity, chat scope, profession, and alert settings?", "filters")
    CreateResetPopup("ADBLOCK_FOREVER_RESET_LISTS", "Clear the player whitelist and every custom allow/block phrase?", "lists")
    CreateResetPopup("ADBLOCK_FOREVER_RESET_STATS", "Reset all lifetime blocked-message statistics?", "stats")
end

function ABF:ShowAdvancedUI()
    if not self.db then return end
    if self.HideUI then self:HideUI() end
    if self.HideBlockedLog then self:HideBlockedLog() end
    if self.HideDeveloperLog then self:HideDeveloperLog() end
    CreateWindow()
    window:Show()
    self:RefreshAdvancedUI()
    if window.Raise then window:Raise() end
end

function ABF:HideAdvancedUI()
    if window then window:Hide() end
end

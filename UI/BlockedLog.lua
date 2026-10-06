local addonName, ABF = ...

local window
local exportBox
local exportScroll
local countText
local detailsCheck
local searchInput
local categoryButton
local selectedText
local categoryFilter = "all"
local selectedPosition = 1
local filteredEntries = {}

local CATEGORY_FILTERS = { "all", "guild", "profession", "gold", "custom" }

local function OneLine(value)
    if type(value) ~= "string" then
        return ""
    end
    value = value:gsub("[%c]", " ")
    value = value:gsub("%s+", " ")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function TimestampText(value)
    if date and type(value) == "number" and value > 0 then
        return date("%Y-%m-%d %H:%M:%S", value)
    end
    return tostring(value or 0)
end

local function EventLabel(event)
    event = OneLine(event or "Unknown")
    event = event:gsub("^CHAT_MSG_", "")
    return event:gsub("_", " ")
end

local function ResizeExportBox(text)
    if not exportBox or not exportScroll then
        return
    end
    local estimatedRows = 1
    for line in ((text or "") .. "\n"):gmatch("(.-)\n") do
        estimatedRows = estimatedRows + math.max(1, math.ceil(#line / 105))
    end
    exportBox:SetHeight(math.max(exportScroll:GetHeight(), estimatedRows * 15 + 20))
end

local function CreateButton(parent, text, width, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetText(text)
    return button
end

local function Lower(value)
    return string.lower(OneLine(value or ""))
end

local function GetFilteredEntries(log)
    local results = {}
    local search = searchInput and Lower(searchInput:GetText()) or ""
    for index = #log, 1, -1 do
        local entry = log[index]
        local categoryMatches = categoryFilter == "all" or entry.category == categoryFilter
        local haystack = table.concat({
            entry.message or "",
            entry.author or "",
            entry.label or "",
            entry.reason or "",
            entry.event or "",
        }, " ")
        if categoryMatches and (search == "" or Lower(haystack):find(search, 1, true)) then
            results[#results + 1] = entry
        end
    end
    return results
end

local function SelectedEntry()
    return filteredEntries[selectedPosition]
end

local function CycleCategory()
    for index, category in ipairs(CATEGORY_FILTERS) do
        if category == categoryFilter then
            categoryFilter = CATEGORY_FILTERS[(index % #CATEGORY_FILTERS) + 1]
            selectedPosition = 1
            return
        end
    end
    categoryFilter = "all"
end

function ABF:RefreshBlockedLog()
    if not window or not window:IsShown() or not self.db then
        return
    end
    local log = self:GetBlockedLog()
    filteredEntries = GetFilteredEntries(log)
    selectedPosition = math.max(1, math.min(selectedPosition, math.max(1, #filteredEntries)))
    local detailed = self.db.blockedLogDetailed ~= false
    local lines = {}
    if detailed then
        lines[#lines + 1] = string.format("AdBlock Forever %s blocked-message export", tostring(self.version or "unknown"))
        lines[#lines + 1] = ""
    end
    for index, entry in ipairs(filteredEntries) do
        local message = OneLine(entry.message or "")
        if detailed then
            lines[#lines + 1] = string.format(
                "%s[%s] BLOCKED %s | %s | %s | score %s | signals: %s%s",
                index == selectedPosition and "> " or "  ",
                TimestampText(entry.at),
                OneLine(entry.label or entry.category or "Advertisement"),
                OneLine(entry.author or "Unknown"),
                EventLabel(entry.event),
                tostring(entry.score or "?"),
                OneLine(entry.reason or "Not recorded"),
                entry.review == "false_positive" and " | marked false positive" or ""
            )
            lines[#lines + 1] = message
            lines[#lines + 1] = ""
        else
            lines[#lines + 1] = message
        end
    end
    if #filteredEntries == 0 then
        lines = {}
        lines[1] = "No blocked messages have been recorded."
    end
    local text = table.concat(lines, "\n")
    exportBox:SetText(text)
    ResizeExportBox(text)
    countText:SetText(string.format(
        "%d shown | %d / %d retained",
        #filteredEntries,
        #log,
        self:GetBlockedLogLimit()
    ))
    detailsCheck:SetChecked(detailed)
    categoryButton:SetText("Category: " .. categoryFilter)
    local selected = SelectedEntry()
    selectedText:SetText(selected and ("Selected: " .. OneLine(selected.label or selected.category) .. " from " .. OneLine(selected.author)) or "No matching entry selected")
end

local function CreateWindow()
    if window then
        return
    end
    window = CreateFrame("Frame", addonName .. "BlockedLogFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(940, 680)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetScript("OnShow", function()
        ABF:RefreshBlockedLog()
    end)
    window.TitleText:SetText("AdBlock Forever - Blocked Message Log")
    window:Hide()
    table.insert(UISpecialFrames, window:GetName())

    local help = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 18, -36)
    help:SetPoint("RIGHT", -18, 0)
    help:SetJustifyH("LEFT")
    help:SetText("Search, review, and correct hidden messages. Player and phrase whitelist actions take effect immediately.")

    detailsCheck = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    detailsCheck:SetSize(24, 24)
    detailsCheck:SetPoint("TOPLEFT", 16, -56)
    local detailsLabel = detailsCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    detailsLabel:SetPoint("LEFT", detailsCheck, "RIGHT", 2, 0)
    detailsLabel:SetText("Include blocking score and matched signals")
    detailsCheck:SetHitRectInsets(0, -detailsLabel:GetStringWidth() - 8, 0, 0)
    detailsCheck:SetScript("OnClick", function(self)
        ABF.db.blockedLogDetailed = self:GetChecked() and true or false
        ABF:RefreshBlockedLog()
    end)

    searchInput = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    searchInput:SetSize(250, 24)
    searchInput:SetPoint("TOPLEFT", 390, -56)
    searchInput:SetAutoFocus(false)
    searchInput:SetTextInsets(8, 8, 0, 0)
    searchInput:SetScript("OnEscapePressed", searchInput.ClearFocus)
    searchInput:SetScript("OnTextChanged", function()
        selectedPosition = 1
        ABF:RefreshBlockedLog()
    end)
    local searchLabel = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchLabel:SetPoint("RIGHT", searchInput, "LEFT", -6, 0)
    searchLabel:SetText("Search")

    categoryButton = CreateButton(window, "Category: all", 138, "LEFT", searchInput, "RIGHT", 12, 0)
    categoryButton:SetScript("OnClick", function()
        CycleCategory()
        ABF:RefreshBlockedLog()
    end)

    exportScroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", 18, -88)
    exportScroll:SetPoint("BOTTOMRIGHT", -34, 54)

    exportBox = CreateFrame("EditBox", nil, exportScroll)
    exportBox:SetMultiLine(true)
    exportBox:SetAutoFocus(false)
    exportBox:SetFontObject(ChatFontNormal)
    exportBox:SetWidth(872)
    exportBox:SetTextInsets(6, 6, 6, 6)
    exportBox:SetScript("OnEscapePressed", exportBox.ClearFocus)
    exportBox:SetScript("OnTextChanged", function(self)
        ResizeExportBox(self:GetText() or "")
    end)
    exportScroll:SetScrollChild(exportBox)

    local background = window:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", exportScroll, "TOPLEFT", -5, 5)
    background:SetPoint("BOTTOMRIGHT", exportScroll, "BOTTOMRIGHT", 22, -5)
    background:SetColorTexture(0.02, 0.02, 0.02, 0.82)

    countText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countText:SetPoint("TOPRIGHT", -20, -38)

    selectedText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    selectedText:SetPoint("BOTTOMLEFT", 18, 44)
    selectedText:SetWidth(500)
    selectedText:SetJustifyH("LEFT")

    local clearButton = CreateButton(window, "Clear Log", 82, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -18, 14)
    clearButton:SetScript("OnClick", function()
        StaticPopup_Show("ADBLOCK_FOREVER_CLEAR_BLOCKED_LOG")
    end)

    local copyButton = CreateButton(window, "Copy Message", 104, "RIGHT", clearButton, "LEFT", -8, 0)
    copyButton:SetScript("OnClick", function()
        local entry = SelectedEntry()
        if not entry then return end
        exportBox:SetText(OneLine(entry.message))
        exportBox:SetFocus()
        exportBox:HighlightText()
        ABF:Print("Message selected. Press Ctrl+C to copy it; use Refresh to restore the log.")
    end)

    local falsePositiveButton = CreateButton(window, "False Positive", 108, "RIGHT", copyButton, "LEFT", -8, 0)
    falsePositiveButton:SetScript("OnClick", function()
        local entry = SelectedEntry()
        if not entry then return end
        entry.review = "false_positive"
        ABF:RefreshBlockedLog()
        ABF:Print("Marked the selected entry as a false positive.")
    end)

    local allowPhraseButton = CreateButton(window, "Allow Phrase", 100, "RIGHT", falsePositiveButton, "LEFT", -8, 0)
    allowPhraseButton:SetScript("OnClick", function()
        if SelectedEntry() then StaticPopup_Show("ADBLOCK_FOREVER_ALLOW_LOG_PHRASE") end
    end)

    local whitelistButton = CreateButton(window, "Whitelist", 86, "RIGHT", allowPhraseButton, "LEFT", -8, 0)
    whitelistButton:SetScript("OnClick", function()
        local entry = SelectedEntry()
        if entry and OneLine(entry.author) ~= "" and entry.author ~= "Unknown" then
            ABF:AddAllowedPlayer(entry.author, false)
        end
    end)

    local olderButton = CreateButton(window, "Older", 68, "RIGHT", whitelistButton, "LEFT", -8, 0)
    olderButton:SetScript("OnClick", function()
        selectedPosition = math.min(#filteredEntries, selectedPosition + 1)
        ABF:RefreshBlockedLog()
    end)

    local newerButton = CreateButton(window, "Newer", 68, "RIGHT", olderButton, "LEFT", -8, 0)
    newerButton:SetScript("OnClick", function()
        selectedPosition = math.max(1, selectedPosition - 1)
        ABF:RefreshBlockedLog()
    end)

    local exportButton = CreateButton(window, "Export Log", 86, "RIGHT", newerButton, "LEFT", -8, 0)
    exportButton:SetScript("OnClick", function()
        ABF:RefreshBlockedLog()
        exportBox:SetFocus()
        exportBox:HighlightText()
        ABF:Print("Filtered blocked log selected. Press Ctrl+C to copy it.")
    end)

    StaticPopupDialogs["ADBLOCK_FOREVER_ALLOW_LOG_PHRASE"] = {
        text = "Enter a distinctive part of the message that should always be allowed:",
        button1 = "Allow Phrase",
        button2 = CANCEL,
        hasEditBox = true,
        OnShow = function(self)
            local entry = SelectedEntry()
            self.editBox:SetText(entry and OneLine(entry.message) or "")
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            ABF:AddAllowedPhrase(self.editBox:GetText() or "", false)
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            ABF:AddAllowedPhrase(self:GetText() or "", false)
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["ADBLOCK_FOREVER_CLEAR_BLOCKED_LOG"] = {
        text = "Clear every message in the AdBlock Forever blocked-message log?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            ABF:ClearBlockedLog()
            ABF:Print("Blocked-message log cleared.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function ABF:ShowBlockedLog(selectAll)
    if not self.db then
        return
    end
    if self.HideUI then
        self:HideUI()
    end
    if self.HideDeveloperLog then
        self:HideDeveloperLog()
    end
    if self.HideAdvancedUI then
        self:HideAdvancedUI()
    end
    CreateWindow()
    window:Show()
    self:RefreshBlockedLog()
    if window.Raise then
        window:Raise()
    end
    if selectAll then
        exportBox:SetFocus()
        exportBox:HighlightText()
    end
end

function ABF:HideBlockedLog()
    if window then
        window:Hide()
    end
end

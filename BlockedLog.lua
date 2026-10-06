local addonName, ABF = ...

local window
local exportBox
local exportScroll
local countText
local detailsCheck

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

function ABF:RefreshBlockedLog()
    if not window or not window:IsShown() or not self.db then
        return
    end
    local log = self:GetBlockedLog()
    local detailed = self.db.blockedLogDetailed ~= false
    local lines = {}
    for index = #log, 1, -1 do
        local entry = log[index]
        local message = OneLine(entry.message or "")
        if detailed then
            lines[#lines + 1] = string.format(
                "[%s] BLOCKED %s | %s | %s | score %s | signals: %s",
                TimestampText(entry.at),
                OneLine(entry.label or entry.category or "Advertisement"),
                OneLine(entry.author or "Unknown"),
                EventLabel(entry.event),
                tostring(entry.score or "?"),
                OneLine(entry.reason or "Not recorded")
            )
            lines[#lines + 1] = message
            lines[#lines + 1] = ""
        else
            lines[#lines + 1] = message
        end
    end
    if #lines == 0 then
        lines[1] = "No blocked messages have been recorded."
    end
    local text = table.concat(lines, "\n")
    exportBox:SetText(text)
    ResizeExportBox(text)
    countText:SetText(string.format(
        "%d / %d blocked messages retained | newest first",
        #log,
        self:GetBlockedLogLimit()
    ))
    detailsCheck:SetChecked(detailed)
end

local function CreateWindow()
    if window then
        return
    end
    window = CreateFrame("Frame", addonName .. "BlockedLogFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(820, 620)
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
    help:SetText("Review what was hidden and why. Use an allowed player or phrase if an entry is a false positive.")

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

    exportScroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", 18, -88)
    exportScroll:SetPoint("BOTTOMRIGHT", -34, 54)

    exportBox = CreateFrame("EditBox", nil, exportScroll)
    exportBox:SetMultiLine(true)
    exportBox:SetAutoFocus(false)
    exportBox:SetFontObject(ChatFontNormal)
    exportBox:SetWidth(752)
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
    countText:SetPoint("BOTTOMLEFT", 18, 20)

    local clearButton = CreateButton(window, "Clear Log", 92, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -18, 14)
    clearButton:SetScript("OnClick", function()
        StaticPopup_Show("ADBLOCK_FOREVER_CLEAR_BLOCKED_LOG")
    end)

    local selectButton = CreateButton(window, "Select All", 92, "RIGHT", clearButton, "LEFT", -8, 0)
    selectButton:SetScript("OnClick", function()
        exportBox:SetFocus()
        exportBox:HighlightText()
        ABF:Print("Blocked log selected. Press Ctrl+C to copy it.")
    end)

    local refreshButton = CreateButton(window, "Refresh", 82, "RIGHT", selectButton, "LEFT", -8, 0)
    refreshButton:SetScript("OnClick", function()
        ABF:RefreshBlockedLog()
    end)

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


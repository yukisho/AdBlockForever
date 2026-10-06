local _, ABF = ...

local window
local statusText
local lastBlockedText
local mainChecks = {}
local professionChecks = {}
local allowPanels = {}

local function CreateButton(parent, text, width, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetText(text)
    return button
end

local function CreateCheck(parent, label, x, y, handler)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x, y)

    local labelText = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    labelText:SetPoint("LEFT", check, "RIGHT", 2, 0)
    labelText:SetText(label)
    check.label = labelText
    check:SetHitRectInsets(0, -labelText:GetStringWidth() - 8, 0, 0)
    check:SetScript("OnClick", handler)
    return check
end

local function CreateAllowPanel(key, title, prompt, x, addHandler, removeHandler)
    local panel = CreateFrame("Frame", nil, window, "InsetFrameTemplate")
    panel:SetSize(348, 270)
    panel:SetPoint("TOPLEFT", x, -362)
    panel.rows = {}
    panel.key = key
    panel.removeHandler = removeHandler

    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 12, -12)
    titleText:SetText(title)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -36)
    hint:SetText(prompt)

    local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetSize(238, 24)
    input:SetPoint("TOPLEFT", 14, -54)
    input:SetAutoFocus(false)
    input:SetMaxLetters(200)
    panel.input = input

    local addButton = CreateButton(panel, "Allow", 76, "LEFT", input, "RIGHT", 8, 0)
    local function Submit()
        local value = input:GetText()
        if value and value:match("%S") and addHandler(value) then
            input:SetText("")
        end
        input:ClearFocus()
    end
    addButton:SetScript("OnClick", Submit)
    input:SetScript("OnEnterPressed", Submit)
    input:SetScript("OnEscapePressed", input.ClearFocus)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -88)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(300, 1)
    scroll:SetScrollChild(content)
    panel.content = content

    allowPanels[key] = panel
    return panel
end

local function GetAllowRow(panel, index)
    local row = panel.rows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, panel.content)
    row:SetSize(300, 30)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 31))

    if index % 2 == 0 then
        local shade = row:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(1, 1, 1, 0.035)
    end

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 5, 0)
    row.text:SetWidth(215)
    row.text:SetJustifyH("LEFT")

    row.remove = CreateButton(row, "Remove", 70, "RIGHT", row, "RIGHT", -4, 0)
    row.remove:SetScript("OnClick", function()
        panel.removeHandler(row.value)
    end)
    panel.rows[index] = row
    return row
end

local function RefreshAllowPanel(panel, entries, valueField)
    for index, entry in ipairs(entries) do
        local row = GetAllowRow(panel, index)
        local value = entry[valueField] or ""
        row.value = value
        row.text:SetText(value)
        row:Show()
    end
    for index = #entries + 1, #panel.rows do
        panel.rows[index]:Hide()
    end
    panel.content:SetHeight(math.max(1, #entries * 31))
end

local function BuildUI()
    if window then
        return
    end

    window = CreateFrame("Frame", ABF.name .. "Frame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(760, 680)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    window.TitleText:SetText(ABF.displayName)
    table.insert(UISpecialFrames, window:GetName())

    local logo = window:CreateTexture(nil, "ARTWORK")
    logo:SetSize(38, 38)
    logo:SetPoint("TOPLEFT", 17, -32)
    logo:SetTexture(ABF.iconPath)

    statusText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusText:SetPoint("TOPLEFT", 64, -38)
    statusText:SetPoint("RIGHT", -20, 0)
    statusText:SetJustifyH("LEFT")

    local scopeText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    scopeText:SetPoint("TOPLEFT", 64, -57)
    scopeText:SetText("Filters public chat. Gold spam and optional guild recruitment are also filtered in incoming whispers.")

    mainChecks.enabled = CreateCheck(window, "Enable " .. ABF.displayName, 22, -82, function(self)
        ABF.db.enabled = self:GetChecked() and true or false
        ABF:NotifyChanged()
    end)
    mainChecks.guild = CreateCheck(window, "Block guild recruitment", 218, -82, function(self)
        ABF.db.blockGuildRecruitment = self:GetChecked() and true or false
        ABF:NotifyChanged()
    end)
    mainChecks.professions = CreateCheck(window, "Block profession ads", 436, -82, function(self)
        ABF.db.blockProfessionAds = self:GetChecked() and true or false
        ABF:NotifyChanged()
    end)
    mainChecks.minimap = CreateCheck(window, "Show minimap icon", 595, -82, function(self)
        ABF.db.minimap.hide = not self:GetChecked()
        ABF:NotifyChanged()
    end)
    mainChecks.whispers = CreateCheck(window, "Block guild recruitment whispers", 218, -110, function(self)
        ABF.db.blockWhisperRecruitment = self:GetChecked() and true or false
        ABF:NotifyChanged()
    end)
    mainChecks.gold = CreateCheck(window, "Block gold seller spam", 436, -110, function(self)
        ABF.db.blockGoldSpam = self:GetChecked() and true or false
        ABF:NotifyChanged()
    end)

    local professionsPanel = CreateFrame("Frame", nil, window, "InsetFrameTemplate")
    professionsPanel:SetPoint("TOPLEFT", 14, -148)
    professionsPanel:SetPoint("TOPRIGHT", -14, -148)
    professionsPanel:SetHeight(178)

    local professionTitle = professionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    professionTitle:SetPoint("TOPLEFT", 12, -12)
    professionTitle:SetText("Profession categories")

    local professionHint = professionsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    professionHint:SetPoint("TOPLEFT", 12, -36)
    professionHint:SetText("Checked categories are blocked. Uncheck Enchanting, for example, to allow Enchanting ads.")

    for index, key in ipairs(ABF.professionOrder) do
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        local professionKey = key
        local check = CreateCheck(
            professionsPanel,
            ABF:GetProfessionLabel(professionKey),
            14 + (column * 235),
            -58 - (row * 28),
            function(self)
                ABF.db.professions[professionKey] = self:GetChecked() and true or false
                ABF:NotifyChanged()
            end
        )
        professionChecks[professionKey] = check
    end

    CreateAllowPanel(
        "players",
        "Player whitelist",
        "Messages from these players always remain visible.",
        14,
        function(value)
            return ABF:AddAllowedPlayer(value, false)
        end,
        function(value)
            ABF:RemoveAllowedPlayer(value)
        end
    )

    CreateAllowPanel(
        "phrases",
        "Allowed phrases",
        "Any message containing one of these phrases is allowed.",
        398,
        function(value)
            return ABF:AddAllowedPhrase(value, false)
        end,
        function(value)
            ABF:RemoveAllowedPhrase(value)
        end
    )

    lastBlockedText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lastBlockedText:SetPoint("BOTTOMLEFT", 20, 17)
    lastBlockedText:SetPoint("RIGHT", -470, 0)
    lastBlockedText:SetJustifyH("LEFT")

    local testHelp = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    testHelp:SetPoint("BOTTOMRIGHT", -18, 17)
    testHelp:SetText("Diagnostic: " .. ABF.slashCommand .. " test MESSAGE")

    local rightmostButton
    if ABF.isDevelopment then
        rightmostButton = CreateButton(window, "Developer Log", 122, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 8)
        local developerButton = rightmostButton
        developerButton:SetScript("OnClick", function()
            if ABF.ShowDeveloperLog then
                ABF:ShowDeveloperLog()
            end
        end)
    end

    local blockedLogButton
    if rightmostButton then
        blockedLogButton = CreateButton(window, "Blocked Log", 110, "RIGHT", rightmostButton, "LEFT", -8, 0)
    else
        blockedLogButton = CreateButton(window, "Blocked Log", 110, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 8)
    end
    blockedLogButton:SetScript("OnClick", function()
        if ABF.ShowBlockedLog then
            ABF:ShowBlockedLog()
        end
    end)
    local advancedButton = CreateButton(window, "Rules & Controls", 126, "RIGHT", blockedLogButton, "LEFT", -8, 0)
    advancedButton:SetScript("OnClick", function()
        if ABF.ShowAdvancedUI then
            ABF:ShowAdvancedUI()
        end
    end)
    testHelp:ClearAllPoints()
    testHelp:SetPoint("RIGHT", advancedButton, "LEFT", -12, 0)
end

function ABF:RefreshUI()
    if not window or not self.db then
        return
    end

    statusText:SetText(string.format(
        "%s  |  %d blocked (%d guild, %d profession, %d gold, %d custom)",
        self.db.enabled and "|cff55ff55Enabled|r" or "|cffff5555Disabled|r",
        self.db.stats.total or 0,
        self.db.stats.guild or 0,
        self.db.stats.profession or 0,
        self.db.stats.gold or 0,
        self.db.stats.custom or 0
    ))

    mainChecks.enabled:SetChecked(self.db.enabled)
    mainChecks.guild:SetChecked(self.db.blockGuildRecruitment)
    mainChecks.whispers:SetChecked(self.db.blockWhisperRecruitment)
    mainChecks.professions:SetChecked(self.db.blockProfessionAds)
    mainChecks.gold:SetChecked(self.db.blockGoldSpam)
    mainChecks.minimap:SetChecked(not self.db.minimap.hide)

    for key, check in pairs(professionChecks) do
        check:SetChecked(self.db.professions[key] ~= false)
        if self.db.blockProfessionAds then
            check:Enable()
            check.label:SetTextColor(1, 0.82, 0)
        else
            check:Disable()
            check.label:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    RefreshAllowPanel(allowPanels.players, self:GetAllowedPlayers(), "name")
    RefreshAllowPanel(allowPanels.phrases, self:GetAllowedPhrases(), "phrase")

    local recent = self.recent and self.recent[1]
    if recent then
        lastBlockedText:SetText("Last blocked: " .. recent.label .. " from " .. recent.author)
    else
        lastBlockedText:SetText("No messages blocked this session.")
    end
end

function ABF:ShowUI()
    if self.HideDeveloperLog then
        self:HideDeveloperLog()
    end
    if self.HideBlockedLog then
        self:HideBlockedLog()
    end
    if self.HideAdvancedUI then
        self:HideAdvancedUI()
    end
    BuildUI()
    self:RefreshUI()
    window:Show()
end

function ABF:HideUI()
    if window then
        window:Hide()
    end
end

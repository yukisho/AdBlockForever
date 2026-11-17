local addonName, ABF = ...

local panel
local enabledCheck
local minimapCheck
local tradeCheck
local statusText

local function CreateButton(parent, text, width, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    return button
end

local function CreateCheck(parent, label, y, handler)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", 16, y)
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 2, 0)
    text:SetText(label)
    check:SetHitRectInsets(0, -text:GetStringWidth() - 8, 0, 0)
    check:SetScript("OnClick", handler)
    return check
end

local function RefreshPanel()
    if not panel or not ABF.db then return end
    enabledCheck:SetChecked(ABF.db.enabled)
    minimapCheck:SetChecked(not ABF.db.minimap.hide)
    tradeCheck:SetChecked(ABF.db.blockTradeAds)
    statusText:SetText(string.format(
        "%s | %d messages blocked",
        ABF.db.enabled and "|cff55ff55Filtering enabled|r" or "|cffff5555Filtering disabled|r",
        ABF.db.stats.total or 0
    ))
end

function ABF:RegisterSettingsPanel()
    if panel then return end
    panel = CreateFrame("Frame")
    panel.name = self.displayName
    panel:SetScript("OnShow", RefreshPanel)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(self.displayName)

    local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", 16, -48)
    description:SetPoint("RIGHT", -24, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Hide scored guild recruitment, profession, trade, and gold/RMT advertisements while leaving ordinary chat visible.")

    statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusText:SetPoint("TOPLEFT", 16, -82)

    enabledCheck = CreateCheck(panel, "Enable filtering", -112, function(self)
        ABF.db.enabled = self:GetChecked() and true or false
        ABF:NotifyChanged()
        RefreshPanel()
    end)
    minimapCheck = CreateCheck(panel, "Show minimap button", -142, function(self)
        ABF.db.minimap.hide = not self:GetChecked()
        ABF:NotifyChanged()
        RefreshPanel()
    end)
    tradeCheck = CreateCheck(panel, "Block scored trade and service advertisements", -172, function(self)
        ABF.db.blockTradeAds = self:GetChecked() and true or false
        ABF:NotifyChanged()
        RefreshPanel()
    end)

    local open = CreateButton(panel, "Open full settings", 150, 16, -218)
    open:SetScript("OnClick", function() ABF:ShowUI() end)
    local rules = CreateButton(panel, "Rules & Controls", 140, 176, -218)
    rules:SetScript("OnClick", function() ABF:ShowAdvancedUI() end)
    local log = CreateButton(panel, "Blocked Log", 110, 326, -218)
    log:SetScript("OnClick", function() ABF:ShowBlockedLog() end)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 16, -258)
    hint:SetPoint("RIGHT", -24, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText("The minimap button is optional. You can reopen this page from Settings > AddOns or use /abf at any time.")

    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        category.ID = panel.name
        Settings.RegisterAddOnCategory(category)
        self.settingsCategoryID = category.ID
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
        self.settingsCategoryID = panel.name
    end
end

_G[addonName .. "_OnAddonCompartmentClick"] = function()
    if ABF.db and ABF.ShowUI then ABF:ShowUI() end
end


local _, ABF = ...

local minimapButton

local function PositionMinimapButton()
    if not minimapButton or not ABF.db then return end
    local angle = math.rad(ABF.db.minimap.angle or 225)
    local radiusX = (Minimap:GetWidth() or 160) / 2
    local radiusY = (Minimap:GetHeight() or 160) / 2
    if radiusX <= 0 then radiusX = 80 end
    if radiusY <= 0 then radiusY = 80 end
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radiusX, math.sin(angle) * radiusY)
end

local function UpdateMinimapPosition()
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then return end
    cursorX, cursorY = cursorX / scale, cursorY / scale
    ABF.db.minimap.angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
    PositionMinimapButton()
end

function ABF:CreateMinimapButton()
    if minimapButton or not Minimap then return end
    minimapButton = CreateFrame("Button", ABF.name .. "MinimapButton", Minimap)
    minimapButton:SetSize(31, 31)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")

    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER", -1, 1)
    icon:SetTexture(ABF.iconPath)
    minimapButton.icon = icon

    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    minimapButton:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ABF:SetEnabled(not ABF.db.enabled)
        elseif ABF.isDevelopment and IsShiftKeyDown and IsShiftKeyDown() and ABF.ShowDeveloperLog then
            ABF:ShowDeveloperLog()
        else
            ABF:ShowUI()
        end
    end)
    minimapButton:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", UpdateMinimapPosition) end)
    minimapButton:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ABF.displayName)
        GameTooltip:AddLine("Left-click: Open settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Enable or disable", 1, 1, 1)
        if ABF.isDevelopment then GameTooltip:AddLine("Shift-left-click: Open developer log", 1, 1, 1) end
        GameTooltip:AddLine("Drag: Move around the minimap", 1, 1, 1)
        local recent = ABF:GetLastBlocked()
        if recent then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Last blocked: " .. tostring(recent.label or recent.category or "Advertisement"), 1, 0.82, 0)
            GameTooltip:AddLine(tostring(recent.author or "Unknown") .. ": " .. tostring(recent.message or ""), 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if Minimap.HookScript then Minimap:HookScript("OnSizeChanged", PositionMinimapButton) end
    PositionMinimapButton()
    self:RefreshMinimapButton()
end

function ABF:RefreshMinimapButton()
    if not minimapButton or not self.db then return end
    PositionMinimapButton()
    if self.db.minimap.hide then minimapButton:Hide() else minimapButton:Show() end
    if minimapButton.icon.SetDesaturated then minimapButton.icon:SetDesaturated(not self.db.enabled) end
end

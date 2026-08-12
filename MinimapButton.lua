local _, addonTable = ...

local minimapButton

local function EnsureDB()
    addonTable.DB.minimapButton = addonTable.DB.minimapButton or {}
    if addonTable.DB.minimapButton.angle == nil then
        addonTable.DB.minimapButton.angle = 220
    end
    if addonTable.DB.hideMinimapButton == nil then
        addonTable.DB.hideMinimapButton = false
    end
    return addonTable.DB
end

local function UpdatePosition()
    if not minimapButton or not Minimap then return end
    local angle = math.rad(tonumber(EnsureDB().minimapButton.angle) or 220)
    local radius = (Minimap:GetWidth() * 0.5) + 2
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function addonTable.UpdateMinimapButtonVisibility()
    if not minimapButton then return end
    if EnsureDB().hideMinimapButton then
        minimapButton:Hide()
    else
        UpdatePosition()
        minimapButton:Show()
    end
end

local function UpdateDragPosition()
    if not minimapButton or not Minimap then return end
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local atan2 = math.atan2 or math.atan
    local angle = math.deg(atan2(cursorY / scale - centerY, cursorX / scale - centerX))
    EnsureDB().minimapButton.angle = angle
    UpdatePosition()
end

local function CreateMinimapButton()
    if minimapButton or not Minimap then return end

    minimapButton = CreateFrame("Button", "OakBonusPlannerMinimapButton", Minimap)
    addonTable.MinimapButton = minimapButton
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:EnableMouse(true)
    minimapButton:SetMovable(true)
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")

    local ring = minimapButton:CreateTexture(nil, "BACKGROUND")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(54, 54)
    ring:SetPoint("TOPLEFT")

    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\OakBonusPlanner\\Media\\minimap.png")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")

    local highlight = minimapButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetSize(52, 52)
    highlight:SetPoint("CENTER", minimapButton, "CENTER", 0, 1)

    minimapButton:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            addonTable.ToggleOptions()
        else
            addonTable.Toggle()
        end
    end)
    minimapButton:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdateDragPosition)
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateDragPosition()
    end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("OAK Bonus Planner", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click to open the planner.", 1, 1, 1, true)
        GameTooltip:AddLine("Right-click for options.", 1, 1, 1, true)
        GameTooltip:AddLine("Drag to move this button around the minimap.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
    addonTable.UpdateMinimapButtonVisibility()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", CreateMinimapButton)

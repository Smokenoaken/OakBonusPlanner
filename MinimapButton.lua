local _, addonTable = ...

local ADDON_NAME = "OakBonusPlanner"
local minimapButton
local libDBIcon
local ldbObject

local function EnsureDB()
    addonTable.DB.minimapButton = type(addonTable.DB.minimapButton) == "table"
        and addonTable.DB.minimapButton or {}
    local buttonDB = addonTable.DB.minimapButton
    if buttonDB.angle == nil then
        buttonDB.angle = tonumber(buttonDB.minimapPos) or 220
    end
    if buttonDB.minimapPos == nil then
        buttonDB.minimapPos = tonumber(buttonDB.angle) or 220
    end
    if addonTable.DB.hideMinimapButton == nil then
        addonTable.DB.hideMinimapButton = false
    end
    if buttonDB.hide == nil then
        buttonDB.hide = addonTable.DB.hideMinimapButton == true
    end
    return addonTable.DB
end

local function UpdatePosition()
    if libDBIcon or not minimapButton or not Minimap then return end
    local buttonDB = EnsureDB().minimapButton
    local angle = math.rad(tonumber(buttonDB.minimapPos or buttonDB.angle) or 220)
    local radius = (Minimap:GetWidth() * 0.5) + 2
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function addonTable.UpdateMinimapButtonVisibility()
    local db = EnsureDB()
    db.minimapButton.hide = db.hideMinimapButton == true

    if libDBIcon then
        if db.minimapButton.hide then
            libDBIcon:Hide(ADDON_NAME)
        else
            libDBIcon:Show(ADDON_NAME)
        end
        return
    end

    if not minimapButton then return end
    if db.hideMinimapButton then
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
    local scale = Minimap:GetEffectiveScale()
    local atan2 = math.atan2 or math.atan
    local angle = math.deg(atan2(cursorY / scale - centerY, cursorX / scale - centerX)) % 360
    local buttonDB = EnsureDB().minimapButton
    buttonDB.angle = angle
    buttonDB.minimapPos = angle
    UpdatePosition()
end

local function ToggleFromLauncher(mouseButton)
    if mouseButton == "RightButton" then
        addonTable.ToggleOptions()
    else
        addonTable.Toggle()
    end
end

addonTable.ClickMinimapButton = function(_, mouseButton)
    ToggleFromLauncher(mouseButton)
end

local function CreateDataBrokerObject()
    if ldbObject or not (LibStub and LibStub("LibDataBroker-1.1", true)) then
        return
    end

    local LDB = LibStub("LibDataBroker-1.1", true)
    ldbObject = LDB:NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = ADDON_NAME,
        label = ADDON_NAME,
        icon = "Interface\\AddOns\\OakBonusPlanner\\Media\\minimap.png",
        OnClick = addonTable.ClickMinimapButton,
    })
    if not ldbObject then return end

    function ldbObject:OnTooltipShow()
        self:AddLine("OAK Bonus Planner", 1, 0.82, 0)
        self:AddLine("Left-click to open the planner.", 1, 1, 1)
        self:AddLine("Right-click for options.", 1, 1, 1)
    end
end

local function RegisterLibDBIcon()
    if not ldbObject or not (LibStub and LibStub("LibDBIcon-1.0", true)) then
        return false
    end

    libDBIcon = LibStub("LibDBIcon-1.0", true)
    local buttonDB = EnsureDB().minimapButton
    local registered = libDBIcon.IsRegistered and libDBIcon:IsRegistered(ADDON_NAME)
    if not registered then
        local ok = pcall(libDBIcon.Register, libDBIcon, ADDON_NAME, ldbObject, buttonDB)
        if not ok then
            libDBIcon = nil
            return false
        end
    end

    minimapButton = libDBIcon:GetMinimapButton(ADDON_NAME)
    if not minimapButton then
        libDBIcon = nil
        return false
    end
    addonTable.MinimapButton = minimapButton
    return true
end

local function CreateFallbackMinimapButton()
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

    minimapButton:SetScript("OnClick", addonTable.ClickMinimapButton)
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
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    EnsureDB()
    CreateDataBrokerObject()
    if not RegisterLibDBIcon() then
        CreateFallbackMinimapButton()
    end
    UpdatePosition()
    addonTable.UpdateMinimapButtonVisibility()
end)

local _, addonTable = ...

local panel = CreateFrame("Frame", "OakBonusPlannerOptionsFrame", UIParent, "BackdropTemplate")
addonTable.OptionsPanel = panel
panel:SetSize(330, 252)
panel:SetFrameStrata("DIALOG")
panel:SetToplevel(true)
panel:SetFrameLevel((addonTable.Frame and addonTable.Frame:GetFrameLevel() or 0) + 20)
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
addonTable.MakeBackdrop(panel, "background")
panel:SetBackdropBorderColor(unpack(addonTable.Theme.title))
panel:SetPoint("CENTER")
panel:Hide()
tinsert(UISpecialFrames, "OakBonusPlannerOptionsFrame")
panel:SetScript("OnShow", function(self)
    self:SetFrameLevel((addonTable.Frame and addonTable.Frame:GetFrameLevel() or 0) + 20)
end)

local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetPoint("TOPLEFT", 8, -8)
titleBar:SetPoint("TOPRIGHT", -8, -8)
titleBar:SetHeight(34)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)

local title = titleBar:CreateFontString(nil, "OVERLAY")
title:SetPoint("LEFT", 10, 0)
addonTable.ApplyFont(title, "large")
title:SetText("Oak Bonus Planner Options")
title:SetTextColor(unpack(addonTable.Theme.gold))

local close = addonTable.CreateButton(titleBar, "X", 24, 24)
close:SetPoint("RIGHT", -2, 0)
close:SetScript("OnClick", function() panel:Hide() end)

local description = panel:CreateFontString(nil, "OVERLAY")
description:SetPoint("TOPLEFT", 18, -56)
description:SetPoint("TOPRIGHT", -18, -56)
description:SetJustifyH("LEFT")
description:SetWordWrap(true)
addonTable.ApplyFont(description, "small")
description:SetTextColor(unpack(addonTable.Theme.muted))
description:SetText("Choose whether the Oak Plan button stays on your minimap. Right-click the button to open this panel.")

local minimapCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
minimapCheck:SetPoint("TOPLEFT", 14, -96)
local minimapLabel = panel:CreateFontString(nil, "OVERLAY")
minimapLabel:SetPoint("LEFT", minimapCheck, "RIGHT", 4, 0)
addonTable.ApplyFont(minimapLabel, "regular")
minimapLabel:SetText("Show Oak Plan minimap button")
minimapLabel:SetTextColor(unpack(addonTable.Theme.text))

minimapCheck:SetScript("OnClick", function(self)
    addonTable.DB.hideMinimapButton = not self:GetChecked()
    if addonTable.UpdateMinimapButtonVisibility then
        addonTable.UpdateMinimapButtonVisibility()
    end
end)

local scaleLabel = panel:CreateFontString(nil, "OVERLAY")
scaleLabel:SetPoint("TOPLEFT", 18, -132)
addonTable.ApplyFont(scaleLabel, "regular")
scaleLabel:SetText("Planner scale")
scaleLabel:SetTextColor(unpack(addonTable.Theme.text))

local scaleValue = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
scaleValue:SetSize(46, 20)
scaleValue:SetPoint("TOPRIGHT", -22, -128)
scaleValue:SetAutoFocus(false)
scaleValue:SetNumeric(false)
scaleValue:SetMaxLetters(4)
scaleValue:SetJustifyH("CENTER")
addonTable.ApplyFont(scaleValue, "small")

local scaleSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
scaleSlider:SetPoint("TOPLEFT", 20, -157)
scaleSlider:SetPoint("TOPRIGHT", -76, -157)
scaleSlider:SetHeight(18)
scaleSlider:SetMinMaxValues(0.75, 1.50)
scaleSlider:SetValueStep(0.05)
scaleSlider:SetObeyStepOnDrag(true)
scaleSlider.Low:SetText("75%")
scaleSlider.High:SetText("150%")
scaleSlider.Text:SetText("")

local function UpdateScaleText(value)
    local scale = addonTable.GetPlannerScale()
    if value then
        scale = math.floor((value * 20) + 0.5) / 20
    end
    scaleValue:SetText(string.format("%d%%", scale * 100 + 0.5))
end

-- Set the initial value before registering handlers. OptionsSliderTemplate may
-- fire OnValueChanged while it is being built; that must not overwrite a saved
-- scale before the player has touched the control.
scaleSlider:SetValue(addonTable.GetPlannerScale())
UpdateScaleText()

scaleSlider:SetScript("OnMouseUp", function(self)
    -- Match Oak LFG Sorter's scale behavior: commit once the player releases
    -- the slider, then apply the exact value that was persisted.
    local scale = addonTable.SetPlannerScale(self:GetValue())
    self:SetValue(scale)
    UpdateScaleText(scale)
end)
scaleSlider:SetScript("OnValueChanged", function(_, value)
    UpdateScaleText(value)
end)
scaleSlider:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Planner scale", 1, 0.82, 0)
    GameTooltip:AddLine("Adjust Oak Bonus Planner's display size. This does not change the saved window dimensions.", 1, 1, 1, true)
    GameTooltip:Show()
end)
scaleSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
scaleValue:SetScript("OnEnterPressed", function(self)
    local text = string.gsub(self:GetText() or "", "%%", "")
    local value = tonumber(text)
    local scale = addonTable.SetPlannerScale(value and (value / 100) or addonTable.GetPlannerScale())
    scaleSlider:SetValue(scale)
    UpdateScaleText(scale)
    self:ClearFocus()
end)
scaleValue:SetScript("OnEscapePressed", function(self)
    local scale = addonTable.GetPlannerScale()
    scaleSlider:SetValue(scale)
    UpdateScaleText(scale)
    self:ClearFocus()
end)

local slashHint = panel:CreateFontString(nil, "OVERLAY")
slashHint:SetPoint("BOTTOMLEFT", 18, 18)
slashHint:SetPoint("BOTTOMRIGHT", -18, 18)
slashHint:SetJustifyH("LEFT")
addonTable.ApplyFont(slashHint, "small")
slashHint:SetTextColor(unpack(addonTable.Theme.muted))
slashHint:SetText("Commands: /obp to open the planner  •  /obp options")

local function RefreshOptions()
    minimapCheck:SetChecked(addonTable.DB.hideMinimapButton ~= true)
    -- Refreshing controls only reads the account-wide saved setting.
    local scale = addonTable.GetPlannerScale()
    scaleSlider:SetValue(scale)
    UpdateScaleText(scale)
end

function addonTable.ToggleOptions()
    if panel:IsShown() then
        panel:Hide()
    else
        RefreshOptions()
        panel:Show()
    end
end

function addonTable.ShowOptions()
    RefreshOptions()
    panel:Show()
end

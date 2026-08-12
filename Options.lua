local _, addonTable = ...

local panel = CreateFrame("Frame", "OakBonusPlannerOptionsFrame", UIParent, "BackdropTemplate")
addonTable.OptionsPanel = panel
panel:SetSize(330, 180)
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

local slashHint = panel:CreateFontString(nil, "OVERLAY")
slashHint:SetPoint("BOTTOMLEFT", 18, 18)
slashHint:SetPoint("BOTTOMRIGHT", -18, 18)
slashHint:SetJustifyH("LEFT")
addonTable.ApplyFont(slashHint, "small")
slashHint:SetTextColor(unpack(addonTable.Theme.muted))
slashHint:SetText("Commands: /obp to open the planner  •  /obp options")

local function RefreshOptions()
    minimapCheck:SetChecked(addonTable.DB.hideMinimapButton ~= true)
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

local _, addonTable = ...

local parent = addonTable.Frame
if not parent then return end

StaticPopupDialogs["OAK_BONUS_PLANNER_COPY_URL"] = {
    text = "%s\n\nCopy this link:",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 330,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, _, data)
        self.editBox:SetText(data or "")
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

local panel = CreateFrame("Frame", "OakBonusPlannerSupportersFrame", parent, "BackdropTemplate")
addonTable.SupportersPanel = panel
panel:SetSize(440, 390)
panel:SetPoint("CENTER", parent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:SetFrameLevel(parent:GetFrameLevel() + 30)
panel:EnableMouse(true)
addonTable.MakeBackdrop(panel, "background")
panel:SetBackdropBorderColor(unpack(addonTable.Theme.title))
panel:Hide()

local title = panel:CreateFontString(nil, "OVERLAY")
title:SetPoint("TOP", panel, "TOP", 0, -18)
addonTable.ApplyFont(title, "large")
title:SetText("Oak Bonus Planner Supporters")
title:SetTextColor(unpack(addonTable.Theme.gold))

local close = addonTable.CreateButton(panel, "X", 24, 24)
close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
close:SetScript("OnClick", function() panel:Hide() end)

local thanks = panel:CreateFontString(nil, "OVERLAY")
thanks:SetPoint("TOP", title, "BOTTOM", 0, -8)
thanks:SetPoint("LEFT", panel, "LEFT", 18, 0)
thanks:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
thanks:SetJustifyH("CENTER")
addonTable.ApplyFont(thanks, "small")
thanks:SetText("Thank you to the Oakensoul Patreon community for supporting Oak addons.")
thanks:SetTextColor(unpack(addonTable.Theme.muted))

local topLabel = panel:CreateFontString(nil, "OVERLAY")
topLabel:SetPoint("TOP", thanks, "BOTTOM", 0, -14)
addonTable.ApplyFont(topLabel, "small")
topLabel:SetText("Top Supporter")
topLabel:SetTextColor(unpack(addonTable.Theme.gold))

local topName = panel:CreateFontString(nil, "OVERLAY")
topName:SetPoint("TOP", topLabel, "BOTTOM", 0, -4)
addonTable.ApplyFont(topName, "large")
topName:SetText("Mandos")
topName:SetTextColor(0.53, 0.67, 0.99)

local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(addonTable.Theme.accent[1], addonTable.Theme.accent[2], addonTable.Theme.accent[3], 0.45)
divider:SetSize(392, 1)
divider:SetPoint("TOP", topName, "BOTTOM", 0, -10)

local supportersTitle = panel:CreateFontString(nil, "OVERLAY")
supportersTitle:SetPoint("TOP", divider, "BOTTOM", 0, -8)
addonTable.ApplyFont(supportersTitle, "small")
supportersTitle:SetText("Supporters")
supportersTitle:SetTextColor(unpack(addonTable.Theme.text))

local content = CreateFrame("Frame", nil, panel)
content:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -126)
content:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -126)
content:SetPoint("BOTTOM", panel, "BOTTOM", 0, 58)

local supporters = {}
for _, name in ipairs(addonTable.Patreons or {}) do
    if name ~= "Mandos" then supporters[#supporters + 1] = name end
end

local columns = 4
local rows = math.max(1, math.ceil(#supporters / columns))
local columnWidth = 101
local rowHeight = 13
for index, name in ipairs(supporters) do
    local text = content:CreateFontString(nil, "OVERLAY")
    local column = math.floor((index - 1) / rows)
    local row = (index - 1) % rows
    text:SetPoint("TOPLEFT", content, "TOPLEFT", column * columnWidth, -(row * rowHeight))
    text:SetWidth(columnWidth - 4)
    text:SetJustifyH("LEFT")
    if text.SetWordWrap then text:SetWordWrap(false) end
    addonTable.ApplyFont(text, "small")
    text:SetText(name)
    text:SetTextColor(0.80, 0.80, 0.80)
end

for index, social in ipairs(addonTable.Socials or {}) do
    local button = addonTable.CreateButton(panel, social.name, 78, 20)
    local row = index <= 3 and 0 or 1
    local column = row == 0 and index - 1 or index - 4
    local rowCount = row == 0 and math.min(3, #(addonTable.Socials or {})) or math.max(0, #(addonTable.Socials or {}) - 3)
    local width = (rowCount * 78) + math.max(0, rowCount - 1) * 6
    button:SetPoint("BOTTOM", panel, "BOTTOM", -math.floor(width / 2) + 39 + column * 84, 12 + ((1 - row) * 24))
    button:SetScript("OnClick", function()
        StaticPopup_Show("OAK_BONUS_PLANNER_COPY_URL", social.name, social.url, social.url)
    end)
end

function addonTable.ToggleSupporters()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

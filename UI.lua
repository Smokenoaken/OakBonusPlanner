local addonName, addonTable = ...

local panel = CreateFrame("Frame", "OakBonusPlannerFrame", UIParent, "BackdropTemplate")
addonTable.Frame = panel
panel:SetSize(760, 590)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
addonTable.MakeBackdrop(panel, "background")
panel:SetBackdropBorderColor(unpack(addonTable.Theme.title))

local position = addonTable.DB.position
panel:SetPoint(position.point or "CENTER", UIParent, position.point or "CENTER", position.x or 0, position.y or 0)
panel:SetScale(addonTable.DB.scale)
panel:Hide()
tinsert(UISpecialFrames, "OakBonusPlannerFrame")

local function SavePosition()
    local point, _, _, x, y = panel:GetPoint(1)
    addonTable.DB.position = { point = point, x = x, y = y }
end

panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
end)

local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetPoint("TOPLEFT", 8, -8)
titleBar:SetPoint("TOPRIGHT", -8, -8)
titleBar:SetHeight(44)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing(); SavePosition() end)
titleBar.bg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBar.bg:SetAllPoints()
titleBar.bg:SetColorTexture(0.10, 0.07, 0.035, 1)

local logo = titleBar:CreateTexture(nil, "ARTWORK")
logo:SetSize(48, 48)
logo:SetPoint("LEFT", -6, 0)
logo:SetTexture("Interface\\AddOns\\Oak Bonus Planner\\Media\\Logo.tga")

local title = titleBar:CreateFontString(nil, "OVERLAY")
title:SetPoint("LEFT", logo, "RIGHT", 6, 5)
addonTable.ApplyFont(title, "large")
title:SetText("OAK Bonus Planner")
title:SetTextColor(unpack(addonTable.Theme.gold))

local subtitle = titleBar:CreateFontString(nil, "OVERLAY")
subtitle:SetPoint("LEFT", logo, "RIGHT", 7, -12)
addonTable.ApplyFont(subtitle, "small")
subtitle:SetTextColor(unpack(addonTable.Theme.muted))

local close = addonTable.CreateButton(titleBar, "X", 24, 24)
close:SetPoint("RIGHT", -4, 0)
close:SetScript("OnClick", function() panel:Hide() end)

local controls = CreateFrame("Frame", nil, panel)
controls:SetPoint("TOPLEFT", 16, -62)
controls:SetPoint("TOPRIGHT", -16, -62)
controls:SetHeight(65)

local classButton = addonTable.CreateButton(controls, "Class", 150, 26)
classButton:SetPoint("TOPLEFT")
local specButton = addonTable.CreateButton(controls, "Spec", 190, 26)
specButton:SetPoint("LEFT", classButton, "RIGHT", 6, 0)
local sourceButton = addonTable.CreateButton(controls, "Source: Icy Veins", 150, 26)
sourceButton:SetPoint("LEFT", specButton, "RIGHT", 6, 0)
local resetButton = addonTable.CreateButton(controls, "Reset Rolls", 100, 26)
resetButton:SetPoint("RIGHT", 0, 0)

local summary = controls:CreateFontString(nil, "OVERLAY")
summary:SetPoint("BOTTOMLEFT", 0, 0)
summary:SetPoint("BOTTOMRIGHT", 0, 0)
summary:SetJustifyH("LEFT")
addonTable.ApplyFont(summary, "small")
summary:SetTextColor(unpack(addonTable.Theme.muted))

local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 16, -138)
scroll:SetPoint("BOTTOMRIGHT", -30, 48)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(700, 1)
scroll:SetScrollChild(content)

local footer = panel:CreateFontString(nil, "OVERLAY")
footer:SetPoint("BOTTOMLEFT", 16, 18)
footer:SetPoint("BOTTOMRIGHT", -16, 18)
footer:SetJustifyH("LEFT")
addonTable.ApplyFont(footer, "small")
footer:SetTextColor(unpack(addonTable.Theme.muted))
footer:SetText("Bonus Roll tracking: live from BONUS_ROLL_RESULT. /obp reset clears local history.")

local rows = {}
local ROW_HEIGHT = 52
local function MakeRow(index)
    local row = CreateFrame("Button", nil, content, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))
    addonTable.MakeBackdrop(row, index % 2 == 0 and "background" or "inset")
    row.rank = row:CreateFontString(nil, "OVERLAY")
    row.rank:SetSize(35, 30)
    row.rank:SetPoint("LEFT", 10, 0)
    row.rank:SetJustifyH("CENTER")
    addonTable.ApplyFont(row.rank, "large")
    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetPoint("LEFT", 52, 11)
    row.name:SetWidth(240)
    row.name:SetJustifyH("LEFT")
    addonTable.ApplyFont(row.name, "regular")
    row.kind = row:CreateFontString(nil, "OVERLAY")
    row.kind:SetPoint("LEFT", 52, -12)
    row.kind:SetWidth(240)
    row.kind:SetJustifyH("LEFT")
    addonTable.ApplyFont(row.kind, "small")
    row.targets = row:CreateFontString(nil, "OVERLAY")
    row.targets:SetPoint("LEFT", 300, 0)
    row.targets:SetWidth(170)
    row.targets:SetJustifyH("LEFT")
    addonTable.ApplyFont(row.targets, "small")
    row.score = row:CreateFontString(nil, "OVERLAY")
    row.score:SetPoint("RIGHT", -14, 0)
    row.score:SetWidth(170)
    row.score:SetJustifyH("RIGHT")
    addonTable.ApplyFont(row.score, "regular")
    row:SetScript("OnEnter", function(self)
        if not self.rowData then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.rowData.source.name, 1, 0.82, 0)
        GameTooltip:AddLine(self.rowData.source.kind, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        for _, target in ipairs(self.rowData.plan.targets or {}) do
            GameTooltip:AddLine(target.itemName or target.label or target.slot, 0.92, 0.88, 0.78)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Score = remaining target coverage x priority weight", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[index] = row
    return row
end

local function CycleClass(direction)
    local classID = addonTable.GetSelectedSpec()
    local classIDs = addonTable.GetAllClassIDs()
    local current = 1
    for index, value in ipairs(classIDs) do if value == classID then current = index end end
    current = ((current - 1 + direction) % #classIDs) + 1
    local nextClassID = classIDs[current]
    addonTable.SetSelection(nextClassID, addonTable.GetAllSpecIDs(nextClassID)[1])
end

local function CycleSpec(direction)
    local classID, specID = addonTable.GetSelectedSpec()
    local specIDs = addonTable.GetAllSpecIDs(classID)
    local current = 1
    for index, value in ipairs(specIDs) do if value == specID then current = index end end
    current = ((current - 1 + direction) % #specIDs) + 1
    addonTable.SetSelection(classID, specIDs[current])
end

classButton:SetScript("OnClick", function() CycleClass(1) end)
specButton:SetScript("OnClick", function() CycleSpec(1) end)
sourceButton:SetScript("OnClick", function()
    addonTable.DB.source = addonTable.DB.source == "icy-veins" and "wowhead" or "icy-veins"
    addonTable.Refresh()
end)
resetButton:SetScript("OnClick", function()
    addonTable.ResetObtained()
    addonTable.Refresh()
end)

function addonTable.Refresh()
    local rowsData, classID, specID, plan = addonTable.GetPlanRows()
    local classData = addonTable.Data.Specs[classID]
    local className = classData and classData.name or "Unknown class"
    local specName = classData and classData.specs[specID] or "Unknown spec"
    classButton.text:SetText(className)
    specButton.text:SetText(specName)
    sourceButton.text:SetText("Source: " .. (addonTable.DB.source == "wowhead" and "Wowhead" or "Icy Veins"))
    subtitle:SetText(addonTable.Data.seasonLabel .. "  •  " .. addonTable.Data.sourceLabel)
    if not plan then
        summary:SetText("No curated Season 1 target map is installed for this spec yet. The selector and tracking framework are ready for the next data refresh.")
    else
        summary:SetText(plan.notes)
    end
    for index, data in ipairs(rowsData) do
        local row = rows[index] or MakeRow(index)
        row:Show()
        row.rowData = data
        row.rank:SetText("#" .. index)
        row.rank:SetTextColor(unpack(index == 1 and addonTable.Theme.gold or addonTable.Theme.muted))
        row.name:SetText(data.source.name)
        row.name:SetTextColor(unpack(addonTable.Theme.text))
        row.kind:SetText(data.source.kind)
        row.kind:SetTextColor(unpack(addonTable.Theme.muted))
        row.targets:SetText(string.format("Targets  %d / %d remaining", data.remaining, data.total))
        row.targets:SetTextColor(unpack(data.remaining > 0 and addonTable.Theme.good or addonTable.Theme.muted))
        row.score:SetText(string.format("%d%% target coverage", math.floor(data.coverage * 100 + 0.5)))
        row.score:SetTextColor(unpack(data.remaining > 0 and addonTable.Theme.gold or addonTable.Theme.muted))
    end
    for index = #rowsData + 1, #rows do rows[index]:Hide() end
    content:SetHeight(math.max(1, #rowsData * ROW_HEIGHT))
end

function addonTable.Toggle()
    if panel:IsShown() then panel:Hide() else addonTable.Refresh(); panel:Show() end
end

addonTable.Refresh()

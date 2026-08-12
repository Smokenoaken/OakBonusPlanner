local _, addonTable = ...

local CLASSIC_TEXT = { 0.96, 0.96, 0.96, 1 }
local CLASSIC_MUTED = { 0.75, 0.75, 0.75, 1 }
local CLASSIC_GOLD = { 1.00, 0.82, 0.00, 1 }
local CLASSIC_RED = { 0.90, 0.20, 0.08, 1 }
local CLASSIC_ROW_A = { 0.16, 0.16, 0.16, 0.94 }
local CLASSIC_ROW_B = { 0.105, 0.105, 0.105, 0.94 }

local panel = CreateFrame("Frame", "OakBonusPlannerFrame", UIParent, "ButtonFrameTemplate")
addonTable.Frame = panel
panel:SetSize(addonTable.DB.size.width or 610, addonTable.DB.size.height or 620)
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)
panel:SetMovable(true)
panel:SetResizable(true)
if panel.SetResizeBounds then
    panel:SetResizeBounds(500, 470, 1100, 900)
else
    panel:SetMinResize(500, 470)
    panel:SetMaxResize(1100, 900)
end
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(panel) end
if panel.Bg then panel.Bg:SetAlpha(1) end
if panel.TopTileStreaks then panel.TopTileStreaks:Hide() end
if panel.SetTitle then
    panel:SetTitle("OAK Bonus Planner")
elseif panel.TitleText then
    panel.TitleText:SetText("OAK Bonus Planner")
end

local position = addonTable.DB.position
panel:SetPoint(position.point or "CENTER", UIParent, position.point or "CENTER", position.x or 0, position.y or 0)
panel:SetScale(addonTable.DB.scale)
panel:Hide()
tinsert(UISpecialFrames, "OakBonusPlannerFrame")

if panel.Inset then
    panel.Inset:ClearAllPoints()
    panel.Inset:SetPoint("TOPLEFT", 8, -64)
    panel.Inset:SetPoint("BOTTOMRIGHT", -4, 30)
end
if panel.TitleText then
    panel.TitleText:SetTextColor(unpack(CLASSIC_GOLD))
    if addonTable.Fonts and addonTable.Fonts.large then panel.TitleText:SetFontObject(addonTable.Fonts.large) end
end
if panel.CloseButton then
    panel.CloseButton:SetScript("OnClick", function() panel:Hide() end)
end

local function SavePosition()
    local point, _, _, x, y = panel:GetPoint(1)
    addonTable.DB.position = { point = point, x = x, y = y }
end

local function SaveSize()
    addonTable.DB.size = { width = panel:GetWidth(), height = panel:GetHeight() }
end

panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
end)

local headerLogo = CreateFrame("Frame", nil, UIParent)
headerLogo:SetSize(72, 72)
headerLogo:SetPoint("TOPLEFT", panel, "TOPLEFT", -22, 12)
headerLogo:SetFrameStrata("FULLSCREEN_DIALOG")
headerLogo:SetFrameLevel(1000)
headerLogo.logo = headerLogo:CreateTexture(nil, "ARTWORK")
headerLogo.logo:SetPoint("TOPLEFT", 7, -7)
headerLogo.logo:SetPoint("BOTTOMRIGHT", -7, 7)
headerLogo.logo:SetTexture("Interface\\AddOns\\OakBonusPlanner\\Media\\logo.png")
if headerLogo.logo.SetMask then headerLogo.logo:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") end
headerLogo:Hide()

local subtitle = panel:CreateFontString(nil, "OVERLAY")
subtitle:SetPoint("TOP", panel, "TOP", 0, -31)
addonTable.ApplyFont(subtitle, "small")
subtitle:SetTextColor(unpack(CLASSIC_MUTED))

local function CreateClassicButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 100, height or 22)
    button:SetText(label or "")
    button.text = button:GetFontString()
    if button.text then
        addonTable.ApplyFont(button.text, "regular")
        button.text:SetTextColor(unpack(CLASSIC_TEXT))
    end
    button:SetScript("OnEnter", function(self)
        if self.text then self.text:SetTextColor(unpack(CLASSIC_GOLD)) end
        if self.tooltipTitle then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltipTitle, 1, 0.82, 0)
            if self.tooltipBody then GameTooltip:AddLine(self.tooltipBody, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        if self.text then self.text:SetTextColor(unpack(CLASSIC_TEXT)) end
        GameTooltip:Hide()
    end)
    function button:SetLabel(text)
        self:SetText(text or "")
        if self.text then self.text:SetTextColor(unpack(CLASSIC_TEXT)) end
    end
    function button:SetTooltip(title, body)
        self.tooltipTitle = title
        self.tooltipBody = body
    end
    return button
end

local controls = CreateFrame("Frame", nil, panel)
controls:SetPoint("TOPLEFT", panel, "TOPLEFT", 72, -42)
controls:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -42)
controls:SetHeight(25)

local classSpecButton = CreateClassicButton(controls, "Class (Spec)", 175, 24)
classSpecButton:SetPoint("LEFT")
local sourceButton = CreateClassicButton(controls, "Source", 100, 24)
sourceButton:SetPoint("LEFT", classSpecButton, "RIGHT", 4, 0)
local sortButton = CreateClassicButton(controls, "Sort", 110, 24)
sortButton:SetPoint("LEFT", sourceButton, "RIGHT", 4, 0)
classSpecButton:SetTooltip("Class and specialization", "Choose the character spec whose BIS targets you want to plan.")
sourceButton:SetTooltip("BIS source", "Icy Veins supplies dungeon and raid lists. Wowhead supplies the overall list when available.")
sortButton:SetTooltip("Sort loot sources", "Choose highest BIS chance, source name, or total eligible drops.")

local function CreateMenu(name, width)
    local menu = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    menu:SetWidth(width)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(100)
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 18,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    menu:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    menu:SetBackdropBorderColor(0.58, 0.48, 0.20, 1)
    menu:Hide()
    return menu
end

local classMenu = CreateMenu("OakBonusPlannerClassMenu", 160)
classMenu:SetPoint("TOPLEFT", classSpecButton, "BOTTOMLEFT", 0, -3)
local specMenu = CreateMenu("OakBonusPlannerSpecMenu", 178)
local sourceMenu = CreateMenu("OakBonusPlannerSourceMenu", 132)
sourceMenu:SetPoint("TOPLEFT", sourceButton, "BOTTOMLEFT", 0, -3)
local sortMenu = CreateMenu("OakBonusPlannerSortMenu", 168)
sortMenu:SetPoint("TOPLEFT", sortButton, "BOTTOMLEFT", 0, -3)
local itemMenu

local function HideMenus()
    classMenu:Hide()
    specMenu:Hide()
    sourceMenu:Hide()
    sortMenu:Hide()
    if itemMenu then itemMenu:Hide() end
end

local function MakeMenuButton(parent, index, text, onClick, arrow)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -5 - ((index - 1) * 22))
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -5 - ((index - 1) * 22))
    button.highlight = button:CreateTexture(nil, "BACKGROUND")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(1, 0.82, 0, 0.08)
    button.highlight:Hide()
    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetPoint("LEFT", 7, 0)
    button.text:SetPoint("RIGHT", arrow and -22 or -7, 0)
    button.text:SetJustifyH("LEFT")
    addonTable.ApplyFont(button.text, "regular")
    button.baseColor = { unpack(CLASSIC_TEXT) }
    button.text:SetText(text or "")
    button.text:SetTextColor(unpack(button.baseColor))
    if arrow then
        button.arrow = button:CreateFontString(nil, "OVERLAY")
        button.arrow:SetPoint("RIGHT", -6, 0)
        addonTable.ApplyFont(button.arrow, "regular")
        button.arrow:SetText(">")
        button.arrow:SetTextColor(unpack(CLASSIC_GOLD))
    end
    button:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.text:SetTextColor(unpack(CLASSIC_GOLD))
        if self.onEnter then self.onEnter(self) end
    end)
    button:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.text:SetTextColor(unpack(self.baseColor or CLASSIC_TEXT))
    end)
    button:SetScript("OnClick", onClick)
    return button
end

local function GetClassColor(classID)
    local classData = addonTable.Data.Specs[classID]
    local token = classData and string.upper(string.gsub(classData.name, " ", ""))
    local color = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    return color and { color.r, color.g, color.b, 1 } or CLASSIC_TEXT
end

local function ShowSpecMenu(classID, owner)
    local specIDs = addonTable.GetAllSpecIDs(classID)
    specMenu:SetHeight(#specIDs * 22 + 10)
    specMenu:ClearAllPoints()
    specMenu:SetPoint("TOPLEFT", owner, "TOPRIGHT", 2, 0)
    for _, child in ipairs({ specMenu:GetChildren() }) do child:Hide() end
    for index, specID in ipairs(specIDs) do
        local classData = addonTable.Data.Specs[classID]
        local button = specMenu[index] or MakeMenuButton(specMenu, index, "", function() end)
        specMenu[index] = button
        button.text:SetText(classData.specs[specID])
        button:SetScript("OnClick", function()
            addonTable.SetSelection(classID, specID)
            HideMenus()
        end)
        button:Show()
    end
    specMenu:Show()
end

local classIDs = addonTable.GetAllClassIDs()
classMenu:SetHeight(#classIDs * 22 + 10)
for index, classID in ipairs(classIDs) do
    local classData = addonTable.Data.Specs[classID]
    local button = MakeMenuButton(classMenu, index, classData.name, function(self)
        ShowSpecMenu(classID, self)
    end, true)
    button.baseColor = GetClassColor(classID)
    button.text:SetTextColor(unpack(button.baseColor))
    button.onEnter = function(self) ShowSpecMenu(classID, self) end
end

local sourceOptions = {
    { id = "icy-veins", label = "Icy Veins" },
    { id = "wowhead", label = "Wowhead" },
}
sourceMenu:SetHeight(#sourceOptions * 22 + 10)
for index, source in ipairs(sourceOptions) do
    MakeMenuButton(sourceMenu, index, source.label, function()
        addonTable.DB.source = source.id
        HideMenus()
        addonTable.Refresh()
    end)
end

local sortOptions = {
    { id = "chance", label = "Highest BIS chance" },
    { id = "name", label = "Dungeon name" },
    { id = "pool", label = "Total drops" },
}
sortMenu:SetHeight(#sortOptions * 22 + 10)
for index, sortOption in ipairs(sortOptions) do
    MakeMenuButton(sortMenu, index, sortOption.label, function()
        addonTable.DB.sortMode = sortOption.id
        HideMenus()
        addonTable.Refresh()
    end)
end

classSpecButton:SetScript("OnClick", function()
    sourceMenu:Hide()
    sortMenu:Hide()
    specMenu:Hide()
    classMenu:SetShown(not classMenu:IsShown())
end)
sourceButton:SetScript("OnClick", function()
    classMenu:Hide()
    specMenu:Hide()
    sortMenu:Hide()
    sourceMenu:SetShown(not sourceMenu:IsShown())
end)
sortButton:SetScript("OnClick", function()
    classMenu:Hide()
    specMenu:Hide()
    sourceMenu:Hide()
    sortMenu:SetShown(not sortMenu:IsShown())
end)
local summary = panel:CreateFontString(nil, "OVERLAY")
summary:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -108)
summary:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -108)
summary:SetJustifyH("LEFT")
addonTable.ApplyFont(summary, "small")
summary:SetTextColor(unpack(CLASSIC_MUTED))

local summaryHint = CreateFrame("Frame", nil, panel)
summaryHint:SetPoint("TOPLEFT", summary, "TOPLEFT")
summaryHint:SetPoint("BOTTOMRIGHT", summary, "BOTTOMRIGHT")
summaryHint:EnableMouse(true)
summaryHint:SetScript("OnEnter", function()
    GameTooltip:SetOwner(summaryHint, "ANCHOR_TOP")
    GameTooltip:SetText("Per-source loot specialization", 1, 0.82, 0)
    GameTooltip:AddLine("Each dungeon or boss is evaluated with the loot specialization that leaves the best remaining BIS result for that source.", 1, 1, 1, true)
    GameTooltip:AddLine("The shown items come from Oak's bundled Season 2 class and loot-spec database. This is a finite bonus-roll pool, not a live drop-rate estimate.", 0.75, 0.75, 0.75, true)
    GameTooltip:Show()
end)
summaryHint:SetScript("OnLeave", function() GameTooltip:Hide() end)

local tabs = {}
local activeTab = addonTable.DB.tab or "dungeons"
local tabDefinitions = {
    { id = "dungeons", label = "Dungeons" },
    { id = "raids", label = "Raids" },
    { id = "overall", label = "Overall" },
}
for index, definition in ipairs(tabDefinitions) do
    local tab = CreateClassicButton(panel, definition.label, 102, 24)
    tab:SetPoint("TOPLEFT", panel, "TOPLEFT", 18 + ((index - 1) * 108), -78)
    tab:SetTooltip(definition.label .. " view", "Show the eligible loot pool and BIS coverage for this source category.")
    tab:SetScript("OnLeave", function(self)
        if self.text then self.text:SetTextColor(unpack(definition.id == activeTab and CLASSIC_GOLD or CLASSIC_TEXT)) end
        GameTooltip:Hide()
    end)
    tab:SetScript("OnClick", function()
        activeTab = definition.id
        addonTable.DB.tab = activeTab
        addonTable.Refresh()
    end)
    tabs[definition.id] = tab
end

local craftedGroup = CreateFrame("Frame", nil, panel)
craftedGroup:SetPoint("TOPLEFT", tabs.overall, "TOPRIGHT", 8, -1)
craftedGroup:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -78)
craftedGroup:SetHeight(32)
craftedGroup:SetFrameLevel(20)
local craftedNote = craftedGroup:CreateFontString(nil, "OVERLAY")
craftedNote:SetPoint("LEFT", 0, 0)
craftedNote:SetWidth(54)
craftedNote:SetJustifyH("LEFT")
craftedNote:SetJustifyV("MIDDLE")
addonTable.ApplyFont(craftedNote, "small")
craftedNote:SetTextColor(unpack(CLASSIC_MUTED))
craftedNote:SetText("Crafted:")
local craftedButtons = {}
local activeCraftedButton

local function AddCraftedTooltipLines(button, tooltip)
    tooltip = tooltip or GameTooltip
    if activeCraftedButton ~= button or not button.itemData or not tooltip:IsShown() then return end
    if button.craftedTooltipLinesShown then return end
    button.craftedTooltipLinesShown = true
    tooltip:AddLine("Crafted BIS: " .. (button.itemData.slot or "Slot"), 1, 0.82, 0)
    if button.itemData.maxItemLevel then
        tooltip:AddLine(string.format("Max crafted item level: %d", button.itemData.maxItemLevel), 1, 0.82, 0)
    end
    tooltip:AddLine("Recommended stats: " .. (button.itemData.recommendedStats or "See the current guide"), 1, 1, 1, true)
    tooltip:AddLine("Recommended embellishment: " .. (button.itemData.recommendedEmbellishment or "See the current guide"), 1, 0.82, 0, true)
    if button.itemData.source and button.itemData.source ~= "" then
        tooltip:AddLine(button.itemData.source, 0.75, 0.75, 0.75, true)
    end
    tooltip:Show()
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        if activeCraftedButton and tooltip == GameTooltip then
            activeCraftedButton.craftedTooltipLinesShown = false
            AddCraftedTooltipLines(activeCraftedButton, tooltip)
        end
    end)
end

local function RefreshCraftedTooltip(button)
    if activeCraftedButton ~= button then return end
    button.craftedTooltipLinesShown = false
    AddCraftedTooltipLines(button, GameTooltip)
end

local function QueueCraftedTooltipRefresh(button)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() RefreshCraftedTooltip(button) end)
    end
end

local function CreateCraftedButton(index)
    local button = CreateFrame("Button", nil, craftedGroup, "BackdropTemplate")
    button:EnableMouse(true)
    button:SetFrameLevel(craftedGroup:GetFrameLevel() + 1)
    button:SetSize(30, 30)
    button:SetPoint("LEFT", craftedNote, "RIGHT", 4 + ((index - 1) * 34), 0)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    button:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
    button:SetBackdropBorderColor(0.58, 0.48, 0.20, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.itemLevel = button:CreateFontString(nil, "OVERLAY")
    button.itemLevel:SetPoint("BOTTOMRIGHT", -2, 1)
    button.itemLevel:SetWidth(25)
    button.itemLevel:SetJustifyH("RIGHT")
    addonTable.ApplyFont(button.itemLevel, "small")
    button.itemLevel:SetTextColor(unpack(CLASSIC_GOLD))
    button:SetScript("OnEnter", function(self)
        if not self.itemData then return end
        activeCraftedButton = self
        self.craftedTooltipLinesShown = false
        self:SetBackdropBorderColor(unpack(CLASSIC_GOLD))
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local maxLink = self.itemData.maxItemLink
        if addonTable.GetMaxItemLink and self.itemData.itemID then
            maxLink = addonTable.GetMaxItemLink(self.itemData.itemID, "crafted", nil,
                self.itemData.slot, self.itemData.craftedBonusIDs)
            self.itemData.maxItemLink = maxLink
        end
        local maxTooltipShown = false
        if GameTooltip.SetHyperlink and maxLink then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, maxLink)
            maxTooltipShown = ok and (not GameTooltip.NumLines or GameTooltip:NumLines() > 0)
        end
        if not maxTooltipShown and GameTooltip.SetItemByID and self.itemData.itemID then
            pcall(GameTooltip.SetItemByID, GameTooltip, self.itemData.itemID)
        elseif not maxTooltipShown then
            GameTooltip:SetText(self.itemData.name or "Crafted BIS", 1, 0.82, 0)
        end
    AddCraftedTooltipLines(self, GameTooltip)
    QueueCraftedTooltipRefresh(self)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        if activeCraftedButton == self then activeCraftedButton = nil end
        self.craftedTooltipLinesShown = false
        self:SetBackdropBorderColor(0.58, 0.48, 0.20, 1)
        GameTooltip:Hide()
    end)
    craftedButtons[index] = button
    return button
end
for index = 1, 2 do CreateCraftedButton(index) end

local statNote = panel:CreateFontString(nil, "OVERLAY")
statNote:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -125)
statNote:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -125)
statNote:SetJustifyH("LEFT")
addonTable.ApplyFont(statNote, "small")
statNote:SetTextColor(unpack(CLASSIC_MUTED))

local scroll = CreateFrame("ScrollFrame", "OakBonusPlannerScrollFrame", panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -146)
scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -31, 38)
local content = CreateFrame("Frame", nil, scroll)
content:SetWidth(math.max(1, panel:GetWidth() - 47))
content:SetHeight(1)
scroll:SetScrollChild(content)

local resizeGrip = CreateFrame("Button", nil, panel)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 5)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function() panel:StartSizing("BOTTOMRIGHT") end)
resizeGrip:SetScript("OnMouseUp", function()
    panel:StopMovingOrSizing()
    SaveSize()
end)

local footerLegend = CreateFrame("Frame", nil, panel)
footerLegend:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 8)
footerLegend:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -112, 8)
footerLegend:SetHeight(20)
footerLegend:SetFrameLevel(panel:GetFrameLevel() + 5)

local function CreateLegendEntry(label, kind, width, title, body, x)
    local entry = CreateFrame("Frame", nil, footerLegend)
    entry:SetSize(width, 20)
    entry:SetPoint("LEFT", footerLegend, "LEFT", x, 0)
    entry:EnableMouse(true)
    local icon
    if kind == "catalyst" then
        icon = entry:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", 0, 0)
        icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainTankIcon")
        icon:SetVertexColor(1, 0.82, 0.05, 1)
    elseif kind == "won" then
        icon = entry:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", 0, 0)
        icon:SetTexture("Interface\\Minimap\\Tracking\\Banker")
        icon:SetVertexColor(1, 0.82, 0.05, 1)
    else
        icon = entry:CreateFontString(nil, "OVERLAY")
        icon:SetPoint("LEFT", 0, 0)
        addonTable.ApplyFont(icon, "regular")
        icon:SetText(kind == "bis" and "★" or "×")
        icon:SetTextColor(unpack(kind == "bis" and CLASSIC_GOLD or CLASSIC_RED))
    end
    local text = entry:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    text:SetWidth(width - 20)
    text:SetJustifyH("LEFT")
    addonTable.ApplyFont(text, "small")
    text:SetText(label)
    text:SetTextColor(unpack(CLASSIC_MUTED))
    entry:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(title, 1, 0.82, 0)
        GameTooltip:AddLine(body, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    entry:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

CreateLegendEntry("BIS", "bis", 48, "BIS target", "A wanted Best in Slot item.", 0)
CreateLegendEntry("Catalyst", "catalyst", 76, "Catalyst target", "Season 2 specific item recommended for catalyst conversion.", 52)
CreateLegendEntry("Unwanted", "unwanted", 76, "Unwanted loot", "Eligible pool loot that is not currently wanted.", 134)
CreateLegendEntry("Won", "won", 52, "Already won", "This item was already received from a bonus roll and is removed from the pool.", 216)

local bonusRollCountFrame = CreateFrame("Frame", nil, panel)
bonusRollCountFrame:SetSize(120, 20)
bonusRollCountFrame:SetPoint("RIGHT", panel, "BOTTOMRIGHT", -118, 16)
bonusRollCountFrame:EnableMouse(true)
local bonusRollCount = bonusRollCountFrame:CreateFontString(nil, "OVERLAY")
bonusRollCount:SetAllPoints()
bonusRollCount:SetJustifyH("RIGHT")
addonTable.ApplyFont(bonusRollCount, "small")
bonusRollCount:SetTextColor(unpack(CLASSIC_GOLD))
bonusRollCountFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Nebulous Voidcores available", 1, 0.82, 0)
    GameTooltip:AddLine("Bonus-roll currency available on this character. Dungeon rolls cost 1; raid-boss rolls cost 2.", 1, 1, 1, true)
    GameTooltip:Show()
end)
bonusRollCountFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function UpdateBonusRollCount()
    local count = addonTable.GetAvailableBonusRollCount and addonTable.GetAvailableBonusRollCount() or 0
    bonusRollCount:SetText("Voidcores: " .. tostring(count))
end

local currencyWatcher = CreateFrame("Frame")
currencyWatcher:SetScript("OnEvent", function(_, _, currencyID)
    if currencyID == addonTable.Data.BonusRollCurrencyID then UpdateBonusRollCount() end
end)

local footerControls = CreateFrame("Frame", nil, panel)
footerControls:SetSize(132, 22)
footerControls:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 6)
footerControls:SetFrameLevel(panel:GetFrameLevel() + 6)

local function CreateCogButton(parent, size)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(size, size)
    button:SetText("")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(size - 6, size - 6)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    button.icon:SetTexCoord(0, 1, 0, 1)
    button:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(1, 0.82, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Oak Bonus Planner options", 1, 0.82, 0)
        GameTooltip:AddLine("Open minimap-button and planner-scale options.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(1, 1, 1, 1)
        GameTooltip:Hide()
    end)
    return button
end

local optionsButton = CreateCogButton(footerControls, 22)
optionsButton:SetPoint("RIGHT", footerControls, "RIGHT", 0, 0)
local resetButton = CreateClassicButton(footerControls, "Reset", 48, 22)
resetButton:SetPoint("RIGHT", optionsButton, "LEFT", -4, 0)
resetButton:SetTooltip("Reset bonus-roll history", "Clears items recorded as already won by bonus roll for this season.")
local rescanButton = CreateClassicButton(footerControls, "Rescan", 52, 22)
rescanButton:SetPoint("RIGHT", resetButton, "LEFT", -4, 0)
rescanButton:SetTooltip("Rescan prior bonus-roll wins", "Rechecks Blizzard's Season 2 Voidcache tooltips for the character's current loot specialization. This can recover rolls made before Oak Bonus Planner was installed.")
optionsButton:SetScript("OnClick", function()
    HideMenus()
    if addonTable.ToggleOptions then addonTable.ToggleOptions() end
end)
resetButton:SetScript("OnClick", function()
    HideMenus()
    addonTable.ResetObtained()
    addonTable.Refresh()
end)
rescanButton:SetScript("OnClick", function()
    HideMenus()
    if addonTable.ScanBonusRollHistory then addonTable.ScanBonusRollHistory(true) end
end)

itemMenu = CreateMenu("OakBonusPlannerItemMenu", 184)
local itemMenuTitle = itemMenu:CreateFontString(nil, "OVERLAY")
itemMenuTitle:SetPoint("TOPLEFT", 9, -7)
itemMenuTitle:SetPoint("TOPRIGHT", -9, -7)
itemMenuTitle:SetJustifyH("LEFT")
addonTable.ApplyFont(itemMenuTitle, "small")
itemMenuTitle:SetTextColor(unpack(CLASSIC_MUTED))
local bisAction = CreateClassicButton(itemMenu, "Set as BIS", 168, 24)
bisAction:SetPoint("TOPLEFT", itemMenu, "TOPLEFT", 8, -24)
local pendingItem
bisAction:SetScript("OnClick", function()
    if pendingItem then
        addonTable.SetBISOverride(pendingItem.targetSpecID, pendingItem.itemID, not pendingItem.isBIS)
    end
    pendingItem = nil
    itemMenu:Hide()
end)
itemMenu:SetHeight(57)
itemMenu:SetScript("OnHide", function() pendingItem = nil end)

local function OpenItemMenu(button)
    local itemData = button.itemData
    if not itemData then return end
    classMenu:Hide()
    specMenu:Hide()
    sourceMenu:Hide()
    sortMenu:Hide()
    pendingItem = itemData
    itemMenuTitle:SetText(itemData.name)
    bisAction:SetLabel(itemData.isBIS and "Remove from BIS" or "Set as BIS")
    itemMenu:ClearAllPoints()
    itemMenu:SetPoint("TOPLEFT", button, "TOPRIGHT", 3, 0)
    itemMenu:Show()
end

local rows = {}
local ROW_GAP = 4
local ITEM_SIZE = 36
local ITEM_STEP = 48
local ITEM_LINE_HEIGHT = 58
local ROW_COLUMNS = 10

local function ReflowContent()
    local width = math.max(1, scroll:GetWidth() - 6)
    content:SetWidth(width)
    ROW_COLUMNS = math.max(4, math.floor((width - 50) / ITEM_STEP))
end

panel:SetScript("OnSizeChanged", function()
    ReflowContent()
    if panel:IsShown() and addonTable.Refresh then addonTable.Refresh() end
end)

local itemSlotLabels = {
    [0] = "Head",
    [1] = "Neck",
    [2] = "Shoulder",
    [3] = "Back",
    [4] = "Chest",
    [5] = "Waist",
    [6] = "Wrist",
    [7] = "Hands",
    [8] = "Legs",
    [9] = "Feet",
    [10] = "Main Hand\n(1h/2h)",
    [11] = "Ring",
    [12] = "Trinket",
    [13] = "Off Hand",
}

local function CreateItemButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(ITEM_SIZE, ITEM_SIZE)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    button:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
    button:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.marker = button:CreateFontString(nil, "OVERLAY")
    button.marker:SetPoint("TOPLEFT", 1, -1)
    addonTable.ApplyFont(button.marker, "regular")
    button.catalystMarker = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.catalystMarker:SetSize(15, 15)
    button.catalystMarker:SetPoint("TOPRIGHT", -1, -1)
    button.catalystMarker:SetTexture("Interface\\GroupFrame\\UI-Group-MainTankIcon")
    button.catalystMarker:SetVertexColor(1, 0.82, 0.05, 1)
    button.catalystMarker:Hide()
    button.wonMarker = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.wonMarker:SetSize(15, 15)
    button.wonMarker:SetPoint("BOTTOMLEFT", 1, 1)
    button.wonMarker:SetTexture("Interface\\Minimap\\Tracking\\Banker")
    button.wonMarker:SetVertexColor(1, 0.82, 0.05, 1)
    button.wonMarker:Hide()
    button.itemLevel = button:CreateFontString(nil, "OVERLAY")
    button.itemLevel:SetPoint("BOTTOMRIGHT", -2, 1)
    button.itemLevel:SetWidth(25)
    button.itemLevel:SetJustifyH("RIGHT")
    addonTable.ApplyFont(button.itemLevel, "small")
    button.itemLevel:SetTextColor(unpack(CLASSIC_GOLD))
    button.slotText = button:CreateFontString(nil, "OVERLAY")
    button.slotText:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.slotText:SetWidth(48)
    button.slotText:SetHeight(24)
    button.slotText:SetJustifyH("CENTER")
    button.slotText:SetJustifyV("BOTTOM")
    addonTable.ApplyFont(button.slotText, "small")
    button.slotText:SetTextColor(unpack(CLASSIC_MUTED))
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then OpenItemMenu(self) end
    end)
    button:SetScript("OnEnter", function(self)
        if not self.itemData then return end
        self:SetBackdropBorderColor(unpack(CLASSIC_GOLD))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local maxLink = self.itemData.maxItemLink
        if addonTable.GetMaxItemLink then
            maxLink = addonTable.GetMaxItemLink(self.itemData.itemID, self.itemData.maxItemLinkKind,
                self.itemData.slotID, self.itemData.slot)
            self.itemData.maxItemLink = maxLink
        end
        if GameTooltip.SetHyperlink and maxLink then
            GameTooltip:SetHyperlink(maxLink)
        elseif GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(self.itemData.itemID)
        end
        GameTooltip:AddLine(self.itemData.isBIS and "BIS target" or "Not wanted", 1, self.itemData.isBIS and 0.82 or 0.25, self.itemData.isBIS and 0 or 0.25)
        if self.itemData.maxItemLevel then
            local levelLabel = self.itemData.isCatalyst and "Max catalyst/tier link" or "Max Mythic link"
            GameTooltip:AddLine(string.format("%s: %d", levelLabel, self.itemData.maxItemLevel), 1, 0.82, 0)
        end
        GameTooltip:AddLine("Right-click to change BIS status", 0.7, 0.7, 0.7)
        if self.itemData.isWon then GameTooltip:AddLine("Already won by bonus roll", 0.7, 0.7, 0.7) end
        if self.itemData.isTierToken then
            GameTooltip:AddLine("Tier token: " .. (self.itemData.slotLabel or "Any tier slot"), 1, 0.82, 0.05)
        elseif self.itemData.isCatalyst then
            GameTooltip:AddLine("Catalyst target", 1, 0.82, 0.05)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
        GameTooltip:Hide()
    end)
    return button
end

local function CreateSourceRow(index)
    local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
    row:EnableMouse(true)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetAlpha(0.20)
    row.overlay = row:CreateTexture(nil, "BORDER")
    row.overlay:SetAllPoints()
    row.overlay:SetColorTexture(0.01, 0.01, 0.01, 0.48)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(36, 36)
    row.icon:SetPoint("TOPLEFT", 9, -8)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetPoint("TOPLEFT", 50, -9)
    row.name:SetWidth(320)
    addonTable.ApplyFont(row.name, "regular")
    row.stats = row:CreateFontString(nil, "OVERLAY")
    row.stats:SetPoint("TOPLEFT", 50, -27)
    row.stats:SetWidth(500)
    row.stats:SetJustifyH("LEFT")
    addonTable.ApplyFont(row.stats, "small")
    row.itemButtons = {}
    row:SetScript("OnEnter", function(self)
        if not self.rowData then return end
        local data = self.rowData
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.source.name, 1, 0.82, 0)
        local classData = addonTable.Data.Specs[data.classID]
        local recommendedName = classData and classData.specs[data.recommendedLootSpecID] or "Selected"
        GameTooltip:AddLine("Recommended loot spec: " .. recommendedName, 1, 0.82, 0)
        if data.recommendedLootSpecID ~= data.targetSpecID then
            GameTooltip:AddLine("Items shown are the drops available when this alternate loot specialization is active.", 0.75, 0.75, 0.75, true)
        end
        GameTooltip:AddLine(string.format("BIS chance: %d%%", math.floor(data.chance * 100 + 0.5)), 1, 1, 1)
        GameTooltip:AddLine(string.format("Wanted from remaining pool: %d / %d", data.desiredRemaining, data.poolRemaining), 1, 0.82, 0)
        if data.tierTokenTotal and data.tierTokenTotal > 0 then
            GameTooltip:AddLine(string.format("Includes %d eligible raid tier token%s.", data.tierTokenTotal, data.tierTokenTotal == 1 and "" or "s"), 1, 0.82, 0)
        end
        GameTooltip:AddLine("Items already won by bonus roll are removed from the pool.", 0.75, 0.75, 0.75, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[index] = row
    return row
end

local function UpdateRow(row, data, top, index)
    local itemCount = #data.items
    local itemLines = math.max(1, math.ceil(itemCount / ROW_COLUMNS))
    local height = math.max(96, 40 + (itemLines * ITEM_LINE_HEIGHT))
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -top)
    row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -top)
    row:SetHeight(height)
    row:SetBackdropColor(unpack(index % 2 == 0 and CLASSIC_ROW_B or CLASSIC_ROW_A))
    row:SetBackdropBorderColor(0.10, 0.10, 0.10, 1)
    row.name:SetWidth(math.max(140, content:GetWidth() - 70))
    row.stats:SetWidth(math.max(140, content:GetWidth() - 70))
    row.bg:SetTexture(data.artwork or "Interface\\Buttons\\WHITE8X8")
    row.bg:SetVertexColor(1, 1, 1)
    row.name:SetText(data.source.name)
    row.name:SetTextColor(unpack(CLASSIC_TEXT))
    local classData = addonTable.Data.Specs[data.classID]
    local recommendedName = classData and classData.specs[data.recommendedLootSpecID] or "Selected"
    row.stats:SetText(string.format(
        "Loot: %s  •  %d%% BIS  •  %d/%d wanted",
        recommendedName,
        math.floor(data.chance * 100 + 0.5),
        data.desiredRemaining,
        data.poolRemaining
    ))
    row.stats:SetTextColor(unpack(CLASSIC_GOLD))
    row.rowData = data
    row.icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:SetDesaturated(false)
    row:Show()

    for itemIndex, item in ipairs(data.items) do
        local button = row.itemButtons[itemIndex] or CreateItemButton(row)
        row.itemButtons[itemIndex] = button
        button:ClearAllPoints()
        local column = (itemIndex - 1) % ROW_COLUMNS
        local line = math.floor((itemIndex - 1) / ROW_COLUMNS)
        button:SetPoint("TOPLEFT", row, "TOPLEFT", 50 + (column * ITEM_STEP), -56 - (line * ITEM_LINE_HEIGHT))
        button.slotText:SetText(item.slotLabel or itemSlotLabels[item.slotID] or "Other")
        button.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon:SetDesaturated(item.isWon)
        button.icon:SetAlpha(item.isWon and 0.45 or 1)
        button.itemLevel:SetText(item.maxItemLevel or "")
        button.marker:SetText(item.isBIS and "★" or "×")
        button.marker:SetTextColor(item.isBIS and 1 or CLASSIC_RED[1], item.isBIS and 0.82 or CLASSIC_RED[2], item.isBIS and 0 or CLASSIC_RED[3])
        button.catalystMarker:SetShown(item.isCatalyst == true or item.isTierToken == true)
        button.wonMarker:SetShown(item.isWon == true)
        button.itemData = item
        button:Show()
    end
    for itemIndex = itemCount + 1, #row.itemButtons do row.itemButtons[itemIndex]:Hide() end
    return height
end

local sortShortLabels = { chance = "BIS", name = "Name", pool = "Drops" }

local function SetGuideNotes(plan)
    local crafted = {}
    for _, item in ipairs(plan and plan.crafted or {}) do
        if #crafted < 2 then
            crafted[#crafted + 1] = (item.slot or "Slot") .. ": " .. (item.name or "Crafted item")
        end
    end
    craftedNote:SetText("Crafted:")
    for index = 1, 2 do
        local item = plan and plan.crafted and plan.crafted[index]
        local button = craftedButtons[index]
        if item then
            button.itemData = item
            item.maxItemLevel = addonTable.GetMaxItemLevel(nil, true, item.slot)
            item.craftedBonusIDs = item.bonusIDs or (plan and plan.craftedBonusIDs)
            item.maxItemLink = addonTable.GetMaxItemLink(item.itemID, "crafted", nil,
                item.slot, item.craftedBonusIDs)
            item.recommendedStats = plan and plan.statPriority
            item.recommendedEmbellishment = item.embellishment or (plan and plan.craftedEmbellishment)
            button.icon:SetTexture((item.itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item.itemID))
                or "Interface\\Icons\\INV_Misc_QuestionMark")
            button.itemLevel:SetText(item.maxItemLevel and tostring(item.maxItemLevel) or "")
            button:Show()
        else
            button.itemData = nil
            button.itemLevel:SetText("")
            button:Hide()
        end
    end
    statNote:SetText(plan and plan.statPriority and plan.statPriority ~= ""
        and "Recommended stats: " .. plan.statPriority
        or "Recommended stats: see the linked guide and sim your character")
end

function addonTable.Refresh()
    local rowsData, classID, specID, lootSpecID, plan, recommendation = addonTable.GetLootTableRows(activeTab)
    local classData = addonTable.Data.Specs[classID]
    local className = classData and classData.name or "Unknown class"
    local specName = classData and classData.specs[specID] or "Unknown spec"
    local lootSpecName = classData and classData.specs[lootSpecID] or "Unknown spec"
    classSpecButton:SetLabel(className .. " (" .. specName .. ")")
    sourceButton:SetLabel("Source: " .. (addonTable.DB.source == "wowhead" and "Wowhead" or "Icy Veins"))
    sortButton:SetLabel("Sort: " .. (sortShortLabels[addonTable.DB.sortMode or "chance"] or "BIS"))
    subtitle:SetText(addonTable.Data.seasonLabel .. "  •  Current spec: " .. specName)
    UpdateBonusRollCount()
    for id, tab in pairs(tabs) do
        if tab.text then tab.text:SetTextColor(unpack(id == activeTab and CLASSIC_GOLD or CLASSIC_TEXT)) end
    end
    if plan then
        summary:SetText("Recommended loot spec is shown for each dungeon or boss. Hover a row for its loot-spec details.")
    else
        summary:SetText("No curated BIS map is installed. Right-click any eligible item to build your own BIS list.")
    end
    SetGuideNotes(plan)

    local top = 0
    for index, data in ipairs(rowsData) do
        local row = rows[index] or CreateSourceRow(index)
        top = top + (index > 1 and ROW_GAP or 0)
        top = top + UpdateRow(row, data, top, index)
    end
    for index = #rowsData + 1, #rows do rows[index]:Hide() end
    content:SetHeight(math.max(1, top))
end

panel:SetScript("OnShow", function()
    headerLogo:Show()
    currencyWatcher:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    UpdateBonusRollCount()
    if addonTable.ScanBonusRollHistory then addonTable.ScanBonusRollHistory(false) end
end)
panel:SetScript("OnHide", function()
    headerLogo:Hide()
    currencyWatcher:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    if addonTable.CancelBonusRollHistoryScan then addonTable.CancelBonusRollHistoryScan() end
    HideMenus()
    if itemMenu then itemMenu:Hide() end
end)

function addonTable.Toggle()
    HideMenus()
    if panel:IsShown() then
        panel:Hide()
    else
        addonTable.Refresh()
        panel:Show()
    end
end

ReflowContent()
addonTable.Refresh()

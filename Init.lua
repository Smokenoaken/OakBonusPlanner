local addonName, addonTable = ...

OakBonusPlannerDB = OakBonusPlannerDB or {}
OakBonusPlannerCharDB = OakBonusPlannerCharDB or {}

local DB = OakBonusPlannerDB
local CHAR_DB = OakBonusPlannerCharDB

DB.version = DB.version or 1
DB.source = DB.source or "icy-veins"
DB.sortMode = DB.sortMode or "chance"
DB.obtainedItems = DB.obtainedItems or {}
DB.obtainedNames = DB.obtainedNames or {}
DB.bisOverrides = DB.bisOverrides or {}
DB.position = DB.position or { point = "CENTER", x = 0, y = 0 }
DB.scale = math.max(0.75, math.min(1.50, tonumber(DB.scale) or 1))
DB.hideMinimapButton = DB.hideMinimapButton == true
DB.minimapButton = type(DB.minimapButton) == "table" and DB.minimapButton or {}
DB.size = type(DB.size) == "table" and DB.size or { width = 610, height = 620 }
CHAR_DB.selectedClassID = tonumber(CHAR_DB.selectedClassID)
CHAR_DB.selectedSpecID = tonumber(CHAR_DB.selectedSpecID)
-- Follow the character's live specialization until the user deliberately
-- chooses another class/spec from the planner menu.
CHAR_DB.followCurrentSpec = CHAR_DB.followCurrentSpec ~= false
CHAR_DB.bonusRolls = type(CHAR_DB.bonusRolls) == "table" and CHAR_DB.bonusRolls or {}

addonTable.Name = addonName
addonTable.DB = DB
addonTable.CharDB = CHAR_DB
addonTable.Theme = {
    background = { 0.055, 0.045, 0.035, 0.97 },
    inset = { 0.105, 0.085, 0.060, 0.96 },
    title = { 0.90, 0.24, 0.02, 1 },
    gold = { 1.00, 0.82, 0.00, 1 },
    text = { 0.92, 0.88, 0.78, 1 },
    muted = { 0.60, 0.56, 0.48, 1 },
    good = { 0.35, 1.00, 0.45, 1 },
    accent = { 0.95, 0.45, 0.10, 1 },
}

local function CreateOakFont(name, size, flags)
    local font = CreateFont(name)
    local path = "Interface\\AddOns\\OakBonusPlanner\\Media\\OakFont.ttf"
    font:SetFont(path, size, flags or "")
    font:SetShadowColor(0, 0, 0, 1)
    font:SetShadowOffset(1, -1)
    return font
end

addonTable.Fonts = {
    regular = CreateOakFont("OakBonusPlannerFontRegular", 12),
    small = CreateOakFont("OakBonusPlannerFontSmall", 10),
    large = CreateOakFont("OakBonusPlannerFontLarge", 15),
}

function addonTable.SetPlannerScale(value)
    value = tonumber(value) or 1
    value = math.floor((math.max(0.75, math.min(1.50, value)) * 20) + 0.5) / 20
    DB.scale = value
    if addonTable.Frame then addonTable.Frame:SetScale(value) end
    return value
end

function addonTable.ApplyFont(fontString, kind)
    if fontString and addonTable.Fonts[kind or "regular"] then
        fontString:SetFontObject(addonTable.Fonts[kind or "regular"])
    end
end

function addonTable.MakeBackdrop(frame, kind)
    local color = addonTable.Theme[kind or "inset"] or addonTable.Theme.inset
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(0.02, 0.02, 0.02, 1)
end

function addonTable.CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 100, height or 24)
    addonTable.MakeBackdrop(button, "inset")
    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetAllPoints()
    button.text:SetJustifyH("CENTER")
    addonTable.ApplyFont(button.text, "regular")
    button.text:SetText(text or "")
    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(addonTable.Theme.accent))
        self.text:SetTextColor(unpack(addonTable.Theme.gold))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.02, 0.02, 0.02, 1)
        self.text:SetTextColor(unpack(addonTable.Theme.text))
    end)
    return button
end

function addonTable.GetCurrentSpec()
    local classID = select(3, UnitClass("player"))
    local specIndex = GetSpecialization and GetSpecialization()
    local specID = specIndex and GetSpecializationInfo(specIndex) or nil
    return classID, specID
end

function addonTable.IsObtained(itemID)
    return itemID and DB.obtainedItems[tostring(itemID)] == true
end

function addonTable.MarkObtained(itemID)
    if itemID then
        DB.obtainedItems[tostring(itemID)] = true
    end
end

function addonTable.IsObtainedName(itemName)
    return itemName and DB.obtainedNames[itemName] == true
end

function addonTable.MarkObtainedName(itemName)
    if itemName then
        DB.obtainedNames[itemName] = true
    end
end

function addonTable.ResetObtained()
    wipe(DB.obtainedItems)
    wipe(DB.obtainedNames)
    wipe(CHAR_DB.bonusRolls)
    -- Reset is an intentional local clear. Do not immediately repopulate it
    -- from cache tooltips when the planner is next opened; /obp rescan does
    -- that explicitly.
    CHAR_DB.bonusRollScanVersion = addonTable.Data.dataVersion
end

SLASH_OAKBONUSPLANNER1 = "/obp"
SLASH_OAKBONUSPLANNER2 = "/oakbonus"
SLASH_OAKBONUSPLANNER3 = "/bonusplanner"
SlashCmdList.OAKBONUSPLANNER = function(message)
    message = tostring(message or ""):lower()
    if message == "reset" then
        addonTable.ResetObtained()
        print("|cffff8200Oak Bonus Planner|r: tracked bonus-roll history reset.")
        if addonTable.Refresh then addonTable.Refresh() end
        return
    end
    if message == "options" then
        if addonTable.ShowOptions then addonTable.ShowOptions() end
        return
    end
    if message == "rescan" then
        if addonTable.ScanBonusRollHistory then addonTable.ScanBonusRollHistory(true) end
        return
    end
    if addonTable.Toggle then addonTable.Toggle() end
end

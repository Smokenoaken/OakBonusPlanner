local addonName, addonTable = ...

OakBonusPlannerDB = OakBonusPlannerDB or {}
OakBonusPlannerCharDB = OakBonusPlannerCharDB or {}

local DB = OakBonusPlannerDB
local CHAR_DB = OakBonusPlannerCharDB

DB.version = DB.version or 1
DB.source = DB.source or "icy-veins"
DB.obtainedItems = DB.obtainedItems or {}
DB.obtainedNames = DB.obtainedNames or {}
DB.position = DB.position or { point = "CENTER", x = 0, y = 0 }
DB.scale = tonumber(DB.scale) or 1
CHAR_DB.selectedClassID = tonumber(CHAR_DB.selectedClassID)
CHAR_DB.selectedSpecID = tonumber(CHAR_DB.selectedSpecID)

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

local function CreateFont(name, size, flags)
    local font = CreateFont(name)
    local path = "Interface\\AddOns\\Oak Bonus Planner\\Media\\OakFont.ttf"
    font:SetFont(path, size, flags or "")
    font:SetShadowColor(0, 0, 0, 1)
    font:SetShadowOffset(1, -1)
    return font
end

addonTable.Fonts = {
    regular = CreateFont("OakBonusPlannerFontRegular", 12),
    small = CreateFont("OakBonusPlannerFontSmall", 10),
    large = CreateFont("OakBonusPlannerFontLarge", 15),
}

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
    if addonTable.Toggle then addonTable.Toggle() end
end

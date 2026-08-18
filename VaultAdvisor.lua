local _, addonTable = ...

-- Weekly Rewards is Blizzard's own load-on-demand UI. Keep all integration in
-- this small module so the planner stays dormant unless the Vault is opened.
local vaultFrame
local refreshQueued = false

local function IsVaultVisible()
    return WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown()
end

local function GetItemIDFromDBID(itemDBID)
    if not itemDBID or not C_WeeklyRewards or not C_WeeklyRewards.GetItemHyperlink then return nil end
    local hyperlink = C_WeeklyRewards.GetItemHyperlink(itemDBID)
    return hyperlink and tonumber(hyperlink:match("item:(%d+)")) or nil
end

local function GetItemName(itemID)
    return itemID and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
        or (itemID and GetItemInfo(itemID))
        or "BIS item"
end

local function EnsureItemMarker(itemFrame)
    if itemFrame.OakBonusPlannerBISMarker then return itemFrame.OakBonusPlannerBISMarker end
    local marker = itemFrame:CreateFontString(nil, "OVERLAY")
    marker:SetPoint("TOPRIGHT", itemFrame, "TOPRIGHT", 6, 6)
    addonTable.ApplyFont(marker, "large")
    marker:SetText("★")
    marker:SetTextColor(1, 0.82, 0, 1)
    marker:Hide()
    itemFrame.OakBonusPlannerBISMarker = marker

    -- Reward item data is loaded asynchronously by Blizzard. An ItemFrame
    -- OnShow is the reliable final point at which displayedItemDBID exists.
    itemFrame:HookScript("OnShow", addonTable.RefreshVaultAdvisor)

    itemFrame:HookScript("OnEnter", function(frame)
        local matches = frame.OakBonusPlannerBISMatches
        if not matches or #matches == 0 then return end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Oak Bonus Planner: BIS target", 1, 0.82, 0)
        local best = matches[1]
        if addonTable.DB.showVaultAdvisor and best then
            if best.onlyWanted then
                GameTooltip:AddLine(string.format(
                    "Vault pick: this is your only remaining wanted item from %s (%d item pool).",
                    best.source.name, best.poolRemaining
                ), 0.40, 1, 0.45, true)
            else
                GameTooltip:AddLine(string.format(
                    "Bonus-roll first: %d wanted items remain in %s's %d item pool.",
                    best.desiredRemaining, best.source.name, best.poolRemaining
                ), 1, 0.82, 0, true)
            end
        end
        GameTooltip:Show()
    end)
    return marker
end

local function EnsureAdvisorFrame()
    if vaultFrame then return vaultFrame end
    if not WeeklyRewardsFrame then return nil end

    vaultFrame = CreateFrame("Frame", "OakBonusPlannerVaultAdvisor", WeeklyRewardsFrame, "BackdropTemplate")
    vaultFrame:SetSize(430, 66)
    vaultFrame:SetPoint("BOTTOM", WeeklyRewardsFrame, "TOP", 0, 10)
    vaultFrame:SetFrameStrata("DIALOG")
    addonTable.MakeBackdrop(vaultFrame, "background")
    vaultFrame:SetBackdropBorderColor(unpack(addonTable.Theme.title))
    vaultFrame.title = vaultFrame:CreateFontString(nil, "OVERLAY")
    vaultFrame.title:SetPoint("TOPLEFT", 12, -9)
    addonTable.ApplyFont(vaultFrame.title, "regular")
    vaultFrame.title:SetTextColor(unpack(addonTable.Theme.gold))
    vaultFrame.title:SetText("Oak Bonus Planner Vault Advisor")
    vaultFrame.text = vaultFrame:CreateFontString(nil, "OVERLAY")
    vaultFrame.text:SetPoint("TOPLEFT", 12, -27)
    vaultFrame.text:SetPoint("BOTTOMRIGHT", -12, 7)
    vaultFrame.text:SetJustifyH("LEFT")
    vaultFrame.text:SetJustifyV("TOP")
    vaultFrame.text:SetWordWrap(true)
    addonTable.ApplyFont(vaultFrame.text, "small")
    vaultFrame.text:SetTextColor(unpack(addonTable.Theme.text))
    vaultFrame:Hide()
    return vaultFrame
end

local function HideVaultIntegration()
    if vaultFrame then vaultFrame:Hide() end
    if not WeeklyRewardsFrame or not WeeklyRewardsFrame.Activities then return end
    for _, activityFrame in ipairs(WeeklyRewardsFrame.Activities) do
        local itemFrame = activityFrame.ItemFrame
        if itemFrame and itemFrame.OakBonusPlannerBISMarker then
            itemFrame.OakBonusPlannerBISMarker:Hide()
            itemFrame.OakBonusPlannerBISMatches = nil
        end
    end
end

local function RefreshVaultIntegration()
    refreshQueued = false
    if InCombatLockdown() or not IsVaultVisible() then
        HideVaultIntegration()
        return
    end

    local hasAdvisorMatch = false
    local bestAdvisorMatch
    local bestAdvisorItemID
    for _, activityFrame in ipairs(WeeklyRewardsFrame.Activities or {}) do
        local itemFrame = activityFrame.ItemFrame
        local itemID = itemFrame and GetItemIDFromDBID(itemFrame.displayedItemDBID)
        local matches = itemID and addonTable.GetCurrentBISMatches and addonTable.GetCurrentBISMatches(itemID) or {}
        local marker = itemFrame and EnsureItemMarker(itemFrame)
        if marker then
            itemFrame.OakBonusPlannerBISMatches = matches
            marker:SetShown(addonTable.DB.showVaultBISMarkers and #matches > 0)
        end
        if #matches > 0 then
            local candidate = matches[1]
            if not bestAdvisorMatch
                or (candidate.onlyWanted and not bestAdvisorMatch.onlyWanted)
                or (candidate.onlyWanted == bestAdvisorMatch.onlyWanted and candidate.chance > bestAdvisorMatch.chance) then
                bestAdvisorMatch = candidate
                bestAdvisorItemID = itemID
            end
            hasAdvisorMatch = true
        end
    end

    local advisor = EnsureAdvisorFrame()
    if not advisor then return end
    if not addonTable.DB.showVaultAdvisor then
        advisor:Hide()
    elseif hasAdvisorMatch and bestAdvisorMatch then
        local itemName = GetItemName(bestAdvisorItemID)
        if bestAdvisorMatch.onlyWanted then
            advisor.text:SetText(string.format(
                "Take |cffffd100%s|r — it is the only remaining wanted bonus-roll target in %s (%d eligible items).",
                itemName, bestAdvisorMatch.source.name, bestAdvisorMatch.poolRemaining
            ))
        else
            advisor.text:SetText(string.format(
                "Consider bonus rolls first — |cffffd100%s|r is one of %d wanted items in %s's %d item pool.",
                itemName, bestAdvisorMatch.desiredRemaining, bestAdvisorMatch.source.name, bestAdvisorMatch.poolRemaining
            ))
        end
        advisor:Show()
    else
        advisor.text:SetText("No current BIS, catalyst, or tier target is visible among these Vault choices.")
        advisor:Show()
    end
end

function addonTable.RefreshVaultAdvisor()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0, RefreshVaultIntegration)
end

function addonTable.ShowBISWinToast(itemID, matches)
    if not addonTable.DB.showBISWinToast then return end
    local toast = addonTable.BISWinToast
    if not toast then
        toast = CreateFrame("Frame", "OakBonusPlannerBISWinToast", UIParent, "BackdropTemplate")
        toast:SetSize(340, 58)
        toast:SetPoint("TOP", UIParent, "TOP", 0, -180)
        toast:SetFrameStrata("HIGH")
        addonTable.MakeBackdrop(toast, "background")
        toast:SetBackdropBorderColor(unpack(addonTable.Theme.title))
        toast.icon = toast:CreateTexture(nil, "ARTWORK")
        toast.icon:SetSize(38, 38)
        toast.icon:SetPoint("LEFT", 10, 0)
        toast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        toast.title = toast:CreateFontString(nil, "OVERLAY")
        toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 10, -8)
        addonTable.ApplyFont(toast.title, "regular")
        toast.title:SetTextColor(unpack(addonTable.Theme.gold))
        toast.title:SetText("BIS Voidcore win!")
        toast.text = toast:CreateFontString(nil, "OVERLAY")
        toast.text:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 10, -26)
        toast.text:SetPoint("RIGHT", -10, 0)
        toast.text:SetJustifyH("LEFT")
        addonTable.ApplyFont(toast.text, "small")
        toast.text:SetTextColor(unpack(addonTable.Theme.text))
        addonTable.BISWinToast = toast
    end

    toast.icon:SetTexture((C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark")
    toast.text:SetText(GetItemName(itemID))
    toast:Show()
    toast.serial = (toast.serial or 0) + 1
    local serial = toast.serial
    C_Timer.After(4, function()
        if toast.serial == serial then toast:Hide() end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
eventFrame:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName ~= "Blizzard_WeeklyRewards" then return end
        WeeklyRewardsFrame:HookScript("OnShow", addonTable.RefreshVaultAdvisor)
        WeeklyRewardsFrame:HookScript("OnHide", HideVaultIntegration)
    end
    addonTable.RefreshVaultAdvisor()
end)

if WeeklyRewardsFrame then
    WeeklyRewardsFrame:HookScript("OnShow", addonTable.RefreshVaultAdvisor)
    WeeklyRewardsFrame:HookScript("OnHide", HideVaultIntegration)
end

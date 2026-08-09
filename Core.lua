local addonName, addonTable = ...

local seasonID = addonTable.Data.seasonID
addonTable.DB.seasons = addonTable.DB.seasons or {}
if not addonTable.DB.seasons[seasonID] then
    addonTable.DB.seasons[seasonID] = {
        obtainedItems = addonTable.DB.obtainedItems or {},
        obtainedNames = addonTable.DB.obtainedNames or {},
    }
end
addonTable.DB.obtainedItems = addonTable.DB.seasons[seasonID].obtainedItems
addonTable.DB.obtainedNames = addonTable.DB.seasons[seasonID].obtainedNames
addonTable.DB.obtainedItems = addonTable.DB.obtainedItems or {}
addonTable.DB.obtainedNames = addonTable.DB.obtainedNames or {}
addonTable.DB.seasons[seasonID].obtainedItems = addonTable.DB.obtainedItems
addonTable.DB.seasons[seasonID].obtainedNames = addonTable.DB.obtainedNames

local function GetPlan(specID)
    return addonTable.Data.Plans[specID]
end

local function HasSpec(itemInfo, classID, specID)
    local classSpecs = itemInfo and itemInfo.classes and itemInfo.classes[classID]
    if not classSpecs then return false end
    for _, candidateSpecID in ipairs(classSpecs) do
        if candidateSpecID == specID then return true end
    end
    return false
end

local function MatchesSlot(itemInfo, target)
    if not itemInfo or not target.slotIDs then return false end
    for _, slotID in ipairs(target.slotIDs) do
        if itemInfo.slotId == slotID then return true end
    end
    return false
end

local function GetKeystoneData()
    if KeystoneLoot and KeystoneLoot.ItemDatabase and KeystoneLoot.DungeonDatabase and KeystoneLoot.RaidDatabase then
        return KeystoneLoot
    end
end

local function GetLootIDs(keystone, source)
    if source.challengeModeID then
        for _, dungeon in ipairs(keystone.DungeonDatabase) do
            if dungeon.challengeModeId == source.challengeModeID then
                return dungeon.lootTable
            end
        end
    elseif source.bossID then
        for _, raid in ipairs(keystone.RaidDatabase) do
            for _, boss in ipairs(raid.bossList) do
                if boss.bossId == source.bossID then
                    return boss.lootTable[DifficultyUtil.ID.PrimaryRaidMythic]
                        or boss.lootTable[DifficultyUtil.ID.PrimaryRaidHeroic]
                        or boss.lootTable[14]
                end
            end
        end
    end
end

local function BuildCandidateIDs(source, plan, classID, specID)
    local keystone = GetKeystoneData()
    if not keystone then return {} end
    local lootIDs = GetLootIDs(keystone, source)
    if not lootIDs then return {} end
    local candidates = {}
    for _, itemID in ipairs(lootIDs) do
        local info = keystone.ItemDatabase[itemID]
        if HasSpec(info, classID, specID) then
            for _, target in ipairs(plan.targets or {}) do
                if MatchesSlot(info, target) then
                    candidates[itemID] = true
                    break
                end
            end
        end
    end
    return candidates
end

local function CountSet(set)
    local count = 0
    for _ in pairs(set or {}) do count = count + 1 end
    return count
end

local function GetSourceStatus(source, plan, classID, specID)
    local candidates = BuildCandidateIDs(source, plan, classID, specID)
    local total = CountSet(candidates)
    local used = 0
    if total > 0 then
        for itemID in pairs(candidates) do
            local fromKeystone = KeystoneLoot and KeystoneLoot.Voidcore and KeystoneLoot.Voidcore.IsUsed
                and KeystoneLoot.Voidcore:IsUsed(itemID)
            if fromKeystone or addonTable.IsObtained(itemID) then used = used + 1 end
        end
    else
        total = #(plan.targets or {})
        for _, target in ipairs(plan.targets or {}) do
            if (target.itemID and addonTable.IsObtained(target.itemID))
                    or (target.itemName and addonTable.IsObtainedName(target.itemName)) then
                used = used + 1
            end
        end
    end
    local remaining = math.max(0, total - used)
    local coverage = total > 0 and remaining / total or 0
    return {
        source = source,
        plan = plan,
        candidates = candidates,
        total = total,
        used = used,
        remaining = remaining,
        coverage = coverage,
        score = coverage * (source.weight or 1),
    }
end

function addonTable.GetSelectedSpec()
    local currentClassID, currentSpecID = addonTable.GetCurrentSpec()
    local classID = addonTable.CharDB.selectedClassID or currentClassID
    local specID = addonTable.CharDB.selectedSpecID or currentSpecID
    if not addonTable.Data.Specs[classID] then classID = currentClassID end
    if not (addonTable.Data.Specs[classID] and addonTable.Data.Specs[classID].specs[specID]) then
        local firstSpecID = next(addonTable.Data.Specs[classID] and addonTable.Data.Specs[classID].specs or {})
        specID = firstSpecID
    end
    addonTable.CharDB.selectedClassID = classID
    addonTable.CharDB.selectedSpecID = specID
    return classID, specID
end

function addonTable.GetPlanRows()
    local classID, specID = addonTable.GetSelectedSpec()
    local plan = GetPlan(specID)
    if not plan then return {}, classID, specID, nil end
    local rows = {}
    for _, source in ipairs(addonTable.Data.Sources) do
        local sourcePlan = plan.sources[source.id]
        if sourcePlan then
            table.insert(rows, GetSourceStatus(source, sourcePlan, classID, specID))
        end
    end
    table.sort(rows, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.remaining ~= b.remaining then return a.remaining > b.remaining end
        return a.source.name < b.source.name
    end)
    return rows, classID, specID, plan
end

function addonTable.GetAllClassIDs()
    local result = {}
    for classID in pairs(addonTable.Data.Specs) do table.insert(result, classID) end
    table.sort(result)
    return result
end

function addonTable.GetAllSpecIDs(classID)
    local result = {}
    local classData = addonTable.Data.Specs[classID]
    for specID in pairs(classData and classData.specs or {}) do table.insert(result, specID) end
    table.sort(result)
    return result
end

function addonTable.SetSelection(classID, specID)
    addonTable.CharDB.selectedClassID = classID
    addonTable.CharDB.selectedSpecID = specID
    if addonTable.Refresh then addonTable.Refresh() end
end

function addonTable.HandleBonusRoll(rewardType, rewardLink)
    if rewardType ~= "item" or not rewardLink then return end
    local itemID = tonumber(string.match(rewardLink, "item:(%d+)"))
    if not itemID then return end
    addonTable.MarkObtained(itemID)
    local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if not itemName and GetItemInfo then itemName = GetItemInfo(itemID) end
    addonTable.MarkObtainedName(itemName)
    if addonTable.Refresh then addonTable.Refresh() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BONUS_ROLL_RESULT")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "BONUS_ROLL_RESULT" then
        addonTable.HandleBonusRoll(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local currentClassID, currentSpecID = addonTable.GetCurrentSpec()
        if not addonTable.CharDB.selectedClassID then addonTable.CharDB.selectedClassID = currentClassID end
        if not addonTable.CharDB.selectedSpecID then addonTable.CharDB.selectedSpecID = currentSpecID end
        C_Timer.After(1, function() if addonTable.Refresh then addonTable.Refresh() end end)
    elseif addonTable.Refresh then
        addonTable.Refresh()
    end
end)

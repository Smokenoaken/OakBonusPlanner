local addonName, addonTable = ...

local seasonID = addonTable.Data.seasonID
addonTable.DB.seasons = addonTable.DB.seasons or {}
if not addonTable.DB.seasons[seasonID] then
    addonTable.DB.seasons[seasonID] = {
        obtainedItems = {},
        obtainedNames = {},
    }
end
addonTable.DB.obtainedItems = addonTable.DB.seasons[seasonID].obtainedItems or {}
addonTable.DB.obtainedNames = addonTable.DB.seasons[seasonID].obtainedNames or {}
addonTable.DB.seasons[seasonID].obtainedItems = addonTable.DB.obtainedItems
addonTable.DB.seasons[seasonID].obtainedNames = addonTable.DB.obtainedNames

-- Bonus-roll history belongs to one character and one season. Do not migrate
-- the legacy unscoped map into a new season: on Season 2 day one that map
-- would only be stale data from a prior season.
addonTable.CharDB.bonusRollsBySeason = addonTable.CharDB.bonusRollsBySeason or {}
if not addonTable.CharDB.bonusRollsBySeason[seasonID] then
    if addonTable.CharDB.bonusRollSeason == seasonID and type(addonTable.CharDB.bonusRolls) == "table" then
        addonTable.CharDB.bonusRollsBySeason[seasonID] = addonTable.CharDB.bonusRolls
    else
        addonTable.CharDB.bonusRollsBySeason[seasonID] = {}
    end
end
addonTable.CharDB.bonusRollSeason = seasonID
addonTable.CharDB.bonusRolls = addonTable.CharDB.bonusRollsBySeason[seasonID]
addonTable.ItemNames = addonTable.ItemNames or {}

local resolvingItems = {}
local runtimeSlotCache = {}
local Loot = OakBonusPlannerLoot or {}
local sourceRecommendationCache = {}
local bonusRollScanToken = 0

local function GetLootItemInfo(itemID)
    return Loot.ItemDatabase and Loot.ItemDatabase[itemID]
end

function addonTable.GetLootItemInfo(itemID)
    return GetLootItemInfo(itemID)
end

function addonTable.GetAvailableBonusRollCount()
    local currencyID = addonTable.Data.BonusRollCurrencyID
    local getCurrencyInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
    local currency = currencyID and getCurrencyInfo and getCurrencyInfo(currencyID)
    return currency and math.max(0, tonumber(currency.quantity) or 0) or 0
end

local function GetPlan(specID)
    local plan = addonTable.Data.Plans[specID]
    local generated = OakBonusPlannerBIS and OakBonusPlannerBIS.Specs and OakBonusPlannerBIS.Specs[specID]
    if not generated then return plan end
    plan = plan or { sources = {} }
    plan.bis = generated
    plan.statPriority = generated.statPriority
    plan.statURL = generated.statURL
    plan.icyVeinsURL = generated.icyVeinsURL
    plan.wowheadURL = generated.wowheadURL
    plan.crafted = generated.crafted
    plan.craftedEmbellishment = generated.craftedEmbellishment
        or addonTable.Data.CraftedEmbellishments[specID]
    plan.craftedBonusIDs = generated.craftedBonusIDs
        or addonTable.Data.CraftedBonusIDs[specID]
    -- Season 2 guides name the *base item to catalyze*, not merely the final
    -- tier appearance. Keep those source-specific inputs so a catalyst target
    -- is visible and desired only where it can actually be bonus-rolled.
    plan.catalyst = {
        mode = "items",
        appliesTo = "all",
        season = 2,
        consumeSlot = true,
        targetsByMode = generated.catalyst or {},
        allTargets = {},
        label = "Season 2 guide-recommended catalyst inputs",
    }
    for _, mode in ipairs({ "overall", "raids", "dungeons" }) do
        for _, target in ipairs(plan.catalyst.targetsByMode[mode] or {}) do
            plan.catalyst.allTargets[#plan.catalyst.allTargets + 1] = target
        end
    end
    return plan
end

local function HasSpec(itemInfo, classID, specID)
    local classSpecs = itemInfo and itemInfo.classes and itemInfo.classes[classID]
    if not classSpecs then return false end
    for _, candidateSpecID in ipairs(classSpecs) do
        if candidateSpecID == specID then return true end
    end
    return false
end

local function GetLootIDs(source)
    if source.challengeModeID then
        for _, dungeon in ipairs(Loot.DungeonDatabase or {}) do
            if dungeon.challengeModeId == source.challengeModeID then
                return dungeon.lootTable
            end
        end
    elseif source.bossID then
        for _, raid in ipairs(Loot.RaidDatabase or {}) do
            for _, boss in ipairs(raid.bossList or {}) do
                if boss.bossId == source.bossID then
                    local difficultyIDs = DifficultyUtil and DifficultyUtil.ID or {}
                    return boss.lootTable[difficultyIDs.PrimaryRaidMythic or 16]
                        or boss.lootTable[difficultyIDs.PrimaryRaidHeroic or 15]
                        or boss.lootTable[14]
                end
            end
        end
    end
end

local function GetTierTokenDefinitions(source)
    return addonTable.Data.RaidTierTokens and addonTable.Data.RaidTierTokens[source.bossID] or nil
end

local function GetTierTokenInfo(source, itemID)
    for _, token in ipairs(GetTierTokenDefinitions(source) or {}) do
        if token.itemID == itemID then return token end
    end
end

local function IsClassEligibleToken(token, classID)
    for _, tokenClassID in ipairs(token.classIDs or {}) do
        if tokenClassID == classID then return true end
    end
    return false
end

local function CacheItemName(itemID)
    if addonTable.ItemNames[itemID] then return addonTable.ItemNames[itemID] end
    local name = GetItemInfo and GetItemInfo(itemID)
    if name then
        addonTable.ItemNames[itemID] = name
        return name
    end
    if Item and Item.CreateFromItemID and not resolvingItems[itemID] then
        resolvingItems[itemID] = true
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            resolvingItems[itemID] = nil
            local resolvedName = item:GetItemName()
            if resolvedName then addonTable.ItemNames[itemID] = resolvedName end
            if addonTable.Refresh then addonTable.Refresh() end
        end)
    end
end

local function GetItemName(itemID)
    local name = addonTable.ItemNames[itemID] or (GetItemInfo and GetItemInfo(itemID))
    if name then
        addonTable.ItemNames[itemID] = name
        return name
    end
    CacheItemName(itemID)
    return "Item " .. tostring(itemID)
end

local function GetItemTexture(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemID)
    end
    return _G.GetItemIcon and _G.GetItemIcon(itemID)
end

local inventorySlotMap = {
    ["INVTYPE_HEAD"] = 0,
    ["INVTYPE_NECK"] = 1,
    ["INVTYPE_SHOULDER"] = 2,
    ["INVTYPE_CLOAK"] = 3,
    ["INVTYPE_CHEST"] = 4,
    ["INVTYPE_ROBE"] = 4,
    ["INVTYPE_WAIST"] = 5,
    ["INVTYPE_WRIST"] = 6,
    ["INVTYPE_HAND"] = 7,
    ["INVTYPE_LEGS"] = 8,
    ["INVTYPE_FEET"] = 9,
    ["INVTYPE_WEAPON"] = 10,
    ["INVTYPE_2HWEAPON"] = 10,
    ["INVTYPE_WEAPONMAINHAND"] = 10,
    ["INVTYPE_RANGED"] = 10,
    ["INVTYPE_RANGEDRIGHT"] = 10,
    ["INVTYPE_THROWN"] = 10,
    ["INVTYPE_RELIC"] = 10,
    ["INVTYPE_FINGER"] = 11,
    ["INVTYPE_TRINKET"] = 12,
    ["INVTYPE_HOLDABLE"] = 13,
    ["INVTYPE_SHIELD"] = 13,
    ["INVTYPE_WEAPONOFFHAND"] = 13,
}

-- The imported eligibility database is intentionally static, but item slots
-- are cheap, authoritative client data. Prefer Blizzard's inventory type for
-- display so a stale generated slot cannot label a trinket as an off hand.
local function GetDisplaySlotID(itemID, fallback)
    local cached = runtimeSlotCache[itemID]
    if cached ~= nil then return cached end
    local getInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local equipLoc = getInstant and select(4, getInstant(itemID))
    local slotID = equipLoc and inventorySlotMap[equipLoc]
    if slotID then
        runtimeSlotCache[itemID] = slotID
        return slotID
    end
    return fallback
end

function addonTable.GetMaxItemLevel(slotID, isCrafted, slotName)
    local levels = addonTable.Data.itemLevels or {}
    if isCrafted then
        return levels.crafted
    end
    return levels.myth
end

-- Midnight's item-level bonus IDs are contiguous for the upgrade range used by
-- the current season. The item itself supplies the base level; these bonuses
-- make the tooltip resolve to the selected maximum track.
local function GetItemLevelBonusID(levelDifference)
    if not levelDifference or levelDifference == 0 or levelDifference < -100 or levelDifference > 200 then
        return nil
    end
    return 1372 + levelDifference + 100
end

local function BuildMaxItemLink(itemID, itemKind, slotID, slotName, craftedBonusIDs)
    if not itemID then return nil end
    local bonusIDs = {}
    if itemKind == "crafted" and craftedBonusIDs then
        for _, bonusID in ipairs(craftedBonusIDs) do bonusIDs[#bonusIDs + 1] = bonusID end
    else
        local baseItemLevel
        if C_Item and C_Item.GetDetailedItemLevelInfo then
            local _, _, level = C_Item.GetDetailedItemLevelInfo(itemID)
            baseItemLevel = level
        end

        local targetLevel = addonTable.GetMaxItemLevel(slotID, itemKind == "crafted", slotName)
        if itemKind ~= "raid" then
            local levelBonusID = GetItemLevelBonusID(targetLevel and baseItemLevel and targetLevel - baseItemLevel)
            if levelBonusID then bonusIDs[#bonusIDs + 1] = levelBonusID end
        end

        if itemKind == "raid" then
            -- Mythic raid max-track bonus for Midnight Season 2.
            bonusIDs[#bonusIDs + 1] = 13786
        elseif itemKind == "dungeon" or itemKind == "catalyst" then
            -- Myth track used by Mythic dungeon drops and Season 2 catalyst targets.
            bonusIDs[#bonusIDs + 1] = 12806
        end
    end
    if #bonusIDs > 0 and not (itemKind == "crafted" and craftedBonusIDs) then
        bonusIDs[#bonusIDs + 1] = 1674
    end

    if #bonusIDs == 0 then return "item:" .. tostring(itemID) end
    local playerLevel = UnitLevel and UnitLevel("player") or 0
    local specID = 0
    if GetSpecialization and GetSpecializationInfo then
        local specialization = GetSpecialization()
        specID = specialization and GetSpecializationInfo(specialization) or 0
    end
    -- Keep the four empty gem fields in the link. Without them, the client
    -- parses the later values into the wrong item-link fields and falls back
    -- to the low-level recipe item.
    return string.format("item:%d:%s:::%d:%d:::%d:%s",
        itemID, "::::", playerLevel, specID, #bonusIDs, table.concat(bonusIDs, ":"))
end

function addonTable.GetMaxItemLink(itemID, itemKind, slotID, slotName, craftedBonusIDs)
    return BuildMaxItemLink(itemID, itemKind, slotID, slotName, craftedBonusIDs)
        or (itemID and ("item:" .. itemID))
end

local function IsItemWon(itemID)
    if addonTable.CharDB.bonusRolls then
        local key = tostring(itemID)
        if addonTable.CharDB.bonusRolls[key] == true or addonTable.CharDB.bonusRolls[itemID] == true then
            return true
        end
    end
    return false
end

--[[ Removed in 0.5.0: live Journal scanning moved to the offline data updater.
local function GetJournalInstanceID(source)
    if source.challengeModeID then
        -- LootDungeons stores the game map ID for generation purposes. The
        -- Journal requires its own instance ID, so resolve it from the live
        -- Challenge Mode record instead of passing that map ID to EJ.
        if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local _, _, _, _, _, mapID = C_ChallengeMode.GetMapUIInfo(source.challengeModeID)
            local getInstanceForMap = C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap
                or EJ_GetInstanceForMap
            if mapID and getInstanceForMap then
                local journalInstanceID = getInstanceForMap(mapID)
                if journalInstanceID then return journalInstanceID end
            end
        end
        for _, dungeon in ipairs(Loot.DungeonDatabase or {}) do
            if dungeon.challengeModeId == source.challengeModeID then
                -- KeystoneLoot's generated instanceId is the current game-map
                -- ID. Resolve it through Blizzard's Journal API when possible;
                -- older generated tables may already carry a Journal ID.
                local getInstanceForMap = C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap
                    or EJ_GetInstanceForMap
                if dungeon.instanceId and getInstanceForMap then
                    local journalInstanceID = getInstanceForMap(dungeon.instanceId)
                    if journalInstanceID then return journalInstanceID end
                end
                return dungeon.journalInstanceId
            end
        end
    elseif source.bossID then
        for _, raid in ipairs(Loot.RaidDatabase or {}) do
            for _, boss in ipairs(raid.bossList or {}) do
                if boss.bossId == source.bossID then return source.raidJournalInstanceID or raid.journalInstanceId end
            end
        end
    end
end

local function GetJournalLootSet(source, classID, lootSpecID, forceLive)
    local stored = GetStoredJournalLootSet(source, classID, lootSpecID)
    if stored and not forceLive then return stored end
    if not forceLive then
        -- Never perform an Encounter Journal query from a normal UI refresh.
        -- Missing entries use the bundled table until the throttled matrix
        -- worker fills them; this keeps Overall and tab switches responsive.
        return nil
    end
    -- A scan owns the global Encounter Journal state. UI refreshes during the
    -- scan must use the bundled fallback until that source/spec is stored.
    if journalEligibilityScan.running and not forceLive then return nil end
    local journalInstanceID = GetJournalInstanceID(source)
    if not journalInstanceID then return nil end
    local journal = C_EncounterJournal
    local selectInstance = journal and journal.SelectInstance or EJ_SelectInstance
    local setLootFilter = journal and journal.SetLootFilter or EJ_SetLootFilter
    local getLootFilter = journal and journal.GetLootFilter or EJ_GetLootFilter
    local resetLootFilter = journal and journal.ResetLootFilter or EJ_ResetLootFilter
    local setDifficulty = journal and journal.SetDifficulty or EJ_SetDifficulty
    local getDifficulty = journal and journal.GetDifficulty or EJ_GetDifficulty
    local isLootListOutOfDate = journal and journal.IsLootListOutOfDate or EJ_IsLootListOutOfDate
    local getNumLoot = journal and journal.GetNumLoot or EJ_GetNumLoot
    local getLootInfoByIndex = journal and journal.GetLootInfoByIndex or EJ_GetLootInfoByIndex
    local selectEncounter = journal and journal.SelectEncounter or EJ_SelectEncounter
    local getCurrentInstance = EJ_GetCurrentInstance
    local getCurrentEncounter = EJ_GetCurrentEncounter
    if not selectInstance or not setLootFilter or not getNumLoot or not getLootInfoByIndex
            or (source.bossID and not selectEncounter) then
        return nil
    end

    local difficultyID = source.bossID and 16 or 8 -- Mythic raid / Mythic+ journal difficulty.
    -- Raid bosses share an instance, but not an encounter. The boss ID must be
    -- part of the cache key or one boss can inherit another boss's filtered
    -- loot list when the Encounter Journal is open.
    local cacheKey = table.concat({ journalInstanceID, source.bossID or "instance", classID, lootSpecID, difficultyID }, ":")
    -- The Encounter Journal is global client state. Do not change its selected
    -- instance, encounter, difficulty, or loot filter while the player is
    -- looking at it. The bundled table remains the safe fallback until it is
    -- closed and the live Journal can be queried without disturbing the UI.
    if EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown() then
        return nil
    end
    if journalQueryActive then return nil end
    if journalLootCache[cacheKey] and not forceLive then return journalLootCache[cacheKey] end

    local oldClassID, oldSpecID = getLootFilter and getLootFilter()
    local oldDifficulty = getDifficulty and getDifficulty()
    local oldInstance = getCurrentInstance and getCurrentInstance()
    local oldEncounter = getCurrentEncounter and getCurrentEncounter()
    local getEncounterInfoByIndex = journal and journal.GetEncounterInfoByIndex or EJ_GetEncounterInfoByIndex
    local result = {}
    local resultInfo = {}
    journalQueryActive = true
    local queried, queryError = pcall(function()
        selectInstance(journalInstanceID)
        if source.bossID then
            -- The bundled raid table uses the dungeon encounter ID. Resolve
            -- the corresponding Journal encounter ID after selecting the
            -- instance; Blizzard does not promise those IDs are equal.
            local encounterID
            if getEncounterInfoByIndex then
                for index = 1, 50 do
                    local ok, name, _, journalEncounterID, _, _, _, dungeonEncounterID = pcall(
                        getEncounterInfoByIndex, index, journalInstanceID)
                    if ok and type(name) == "table" then
                        local info = name
                        name = info.name
                        journalEncounterID = info.journalEncounterID or info.encounterID
                        dungeonEncounterID = info.dungeonEncounterID
                    end
                    if not ok or not name then break end
                    if journalEncounterID == source.bossID or dungeonEncounterID == source.bossID then
                        encounterID = journalEncounterID
                        break
                    end
                    for _, alias in ipairs(source.aliases or { source.name }) do
                        if string.lower(name) == string.lower(alias) then
                            encounterID = journalEncounterID
                            break
                        end
                    end
                    if encounterID then break end
                end
            end
            if not encounterID then error("Journal encounter ID was not found") end
            selectEncounter(encounterID)
            if getCurrentEncounter and getCurrentEncounter() ~= encounterID then
                error("Journal encounter selection did not select the requested boss")
            end
        end
        if setDifficulty then setDifficulty(difficultyID) end
        -- Selecting an instance/encounter resets parts of Journal state on
        -- current clients, so apply the specialization filter afterwards.
        setLootFilter(classID, lootSpecID)

        if isLootListOutOfDate and isLootListOutOfDate() then
            error("Journal loot data is still loading")
        end

        for index = 1, getNumLoot() do
            local itemInfo = getLootInfoByIndex(index)
            local itemID
            local invalidWeapon = false
            if type(itemInfo) == "table" then
                itemID = itemInfo.itemID
                -- The Journal can still return a weapon row when the class
                -- filter is active, but marks it unusable for the selected
                -- specialization. Do not let that row enter the bonus-roll
                -- pool; this is what prevents non-Druid daggers from leaking
                -- into Guardian/Feral results.
                invalidWeapon = IsJournalItemUnusable(itemInfo)
            else
                itemID = itemInfo
            end
            if itemID and not invalidWeapon then
                result[itemID] = true
                if type(itemInfo) == "table" then
                    resultInfo[itemID] = {
                        slotId = GetJournalSlotID(itemInfo.slot),
                        slot = itemInfo.slot,
                        name = itemInfo.name,
                    }
                end
            end
        end
    end)
    -- Restore the Journal state even when the live query fails. This is
    -- especially important when another addon or the player had the Journal
    -- open before OBP refreshed.
    if oldInstance and selectInstance then
        pcall(selectInstance, oldInstance)
        if oldEncounter and selectEncounter then pcall(selectEncounter, oldEncounter) end
    end
    if oldClassID and oldSpecID then
        pcall(setLootFilter, oldClassID, oldSpecID)
    elseif resetLootFilter then
        pcall(resetLootFilter)
    end
    if oldDifficulty and setDifficulty then pcall(setDifficulty, oldDifficulty) end
    journalQueryActive = false
    if not queried then return nil, queryError end

    -- The Journal can return no rows while its item data is loading or when a
    -- stale encounter selection was rejected. Never cache that empty result:
    -- an empty table is truthy in Lua and would otherwise make the addon show
    -- only the separately-added tier token for every boss until reload.
    if next(result) then
        journalLootCache[cacheKey] = result
        StoreJournalLootSet(source, classID, lootSpecID, result, resultInfo)
        return result
    end
    return nil
end

local function InstallJournalHooks()
    if journalHooksInstalled or not EncounterJournal or not EncounterJournal.HookScript then return end
    journalHooksInstalled = true
    EncounterJournal:HookScript("OnShow", function()
        -- The Journal owns the same global EJ state used by OBP. Discard any
        -- live results obtained before it opened and use the bundled table
        -- while the player is inspecting bosses.
        journalLootCache = {}
        sourceRecommendationCache = {}
        sourceRecommendationJobs = {}
        if addonTable.Refresh then addonTable.Refresh() end
    end)
    EncounterJournal:HookScript("OnHide", function()
        journalLootCache = {}
        sourceRecommendationCache = {}
        sourceRecommendationJobs = {}
        if addonTable.Refresh then addonTable.Refresh() end
    end)
end

local function BuildJournalEligibilityScanQueue()
    local queue = {}
    local store = GetJournalEligibilityStore()
    for classID, classData in pairs(addonTable.Data.Specs or {}) do
        for specID in pairs(classData.specs or {}) do
            for _, source in ipairs(addonTable.Data.Sources or {}) do
                local sourceEntries = store.entries[source.id]
                local entry = sourceEntries and sourceEntries[tostring(specID)]
                if not entry or entry.classID ~= classID or type(entry.items) ~= "table" or not next(entry.items) then
                    queue[#queue + 1] = {
                        classID = classID,
                        specID = specID,
                        source = source,
                        attempts = 0,
                    }
                end
            end
        end
    end
    table.sort(queue, function(a, b)
        if a.classID ~= b.classID then return a.classID < b.classID end
        if a.specID ~= b.specID then return a.specID < b.specID end
        return a.source.id < b.source.id
    end)
    return queue
end

local function FinishJournalEligibilityScan()
    journalEligibilityScan.running = false
    local store = GetJournalEligibilityStore()
    local count, total = CountStoredJournalEntries()
    store.complete = count == total
    addonTable._journalEligibilityScanRunning = nil
    print(format("|cffff8200Oak Bonus Planner|r: Journal eligibility scan %s (%d/%d source/spec entries).",
        store.complete and "complete" or "paused with unavailable entries", count, total))
    if addonTable.Refresh then addonTable.Refresh() end
end

local function ProcessJournalEligibilityScan()
    if not journalEligibilityScan.running then return end
    if InCombatLockdown and InCombatLockdown() then
        C_Timer.After(2, ProcessJournalEligibilityScan)
        return
    end
    if EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown() then
        C_Timer.After(2, ProcessJournalEligibilityScan)
        return
    end

    local job = journalEligibilityScan.queue[journalEligibilityScan.index]
    if not job then
        FinishJournalEligibilityScan()
        return
    end

    job.attempts = job.attempts + 1
    local items = GetJournalLootSet(job.source, job.classID, job.specID, true)
    if items and next(items) then
        journalEligibilityScan.index = journalEligibilityScan.index + 1
    elseif job.attempts >= 4 then
        journalEligibilityScan.failures = journalEligibilityScan.failures + 1
        journalEligibilityScan.index = journalEligibilityScan.index + 1
    end

    if journalEligibilityScan.index % 25 == 0 or journalEligibilityScan.index == #journalEligibilityScan.queue then
        local complete, total = CountStoredJournalEntries()
        print(format("|cffff8200Oak Bonus Planner|r: Journal eligibility scan %d/%d; stored %d/%d.",
            journalEligibilityScan.index, #journalEligibilityScan.queue, complete, total))
    end
    C_Timer.After(items and next(items) and 0.08 or 0.8, ProcessJournalEligibilityScan)
end

function addonTable.GetJournalEligibilityStatus()
    local store = GetJournalEligibilityStore()
    local count, total = CountStoredJournalEntries()
    return {
        seasonID = store.seasonID,
        dataVersion = store.dataVersion,
        complete = store.complete == true and count == total,
        stored = count,
        total = total,
        running = journalEligibilityScan.running,
    }
end

function addonTable.StartJournalEligibilityScan(rescan)
    if journalEligibilityScan.running then
        print("|cffff8200Oak Bonus Planner|r: Journal eligibility scan is already running.")
        return
    end
    if rescan then
        local store = GetJournalEligibilityStore()
        store.entries = {}
        store.itemInfo = {}
        store.complete = false
        journalLootCache = {}
    end
    journalEligibilityScan.queue = BuildJournalEligibilityScanQueue()
    journalEligibilityScan.index = 1
    journalEligibilityScan.failures = 0
    if #journalEligibilityScan.queue == 0 then
        GetJournalEligibilityStore().complete = true
        print("|cffff8200Oak Bonus Planner|r: Journal eligibility matrix is already complete for this season.")
        return
    end
    if not (C_Timer and C_Timer.After) then
        print("|cffff8200Oak Bonus Planner|r: C_Timer is unavailable; reload the UI and try again.")
        return
    end
    journalEligibilityScan.running = true
    addonTable._journalEligibilityScanRunning = true
    print(format("|cffff8200Oak Bonus Planner|r: scanning %d missing Journal source/spec entries. Keep the Adventure Guide closed; the scan is throttled and resumable.", #journalEligibilityScan.queue))
    C_Timer.After(1, ProcessJournalEligibilityScan)
end

-- Exposed for diagnostics and tests without exposing the mutable saved table.
function addonTable.GetStoredJournalLoot(sourceID, classID, lootSpecID)
    local source = type(sourceID) == "table" and sourceID
    if not source then
        for _, candidate in ipairs(addonTable.Data.Sources or {}) do
            if candidate.id == sourceID then source = candidate break end
        end
    end
    return source and GetStoredJournalLootSet(source, classID, lootSpecID)
end
]]

local function BuildPool(source, classID, lootSpecID)
    local pool = {}
    for _, itemID in ipairs(GetLootIDs(source) or {}) do
        local itemInfo = GetLootItemInfo(itemID)
        local tierToken = GetTierTokenInfo(source, itemID)
        if not (addonTable.Data.BonusRollExcludedItems and addonTable.Data.BonusRollExcludedItems[itemID])
                and itemInfo and (itemInfo.slotId ~= 14 and HasSpec(itemInfo, classID, lootSpecID)
                or tierToken and IsClassEligibleToken(tierToken, classID)) then
            pool[itemID] = true
            CacheItemName(itemID)
        end
    end
    for _, tierToken in ipairs(GetTierTokenDefinitions(source) or {}) do
        if not (addonTable.Data.BonusRollExcludedItems and addonTable.Data.BonusRollExcludedItems[tierToken.itemID])
                and IsClassEligibleToken(tierToken, classID) and Loot.ItemDatabase and Loot.ItemDatabase[tierToken.itemID] then
            pool[tierToken.itemID] = true
            CacheItemName(tierToken.itemID)
        end
    end
    return pool
end

local function GetBonusRollSource(definition)
    for _, source in ipairs(addonTable.Data.Sources or {}) do
        if definition.challengeModeID and source.challengeModeID == definition.challengeModeID then
            return source
        end
        if definition.bossID and source.bossID == definition.bossID then
            return source
        end
    end
end

local function GetBonusRollRemainingNames(chestItemID)
    local names = {}
    if not C_TooltipInfo or not C_TooltipInfo.GetItemByID then return names end
    local data = C_TooltipInfo.GetItemByID(chestItemID)
    if not data or not data.lines then return names end

    for index = #data.lines, 1, -1 do
        local name = (data.lines[index].leftText or ""):match("^%s*%-%s*(.+)$")
        if name then
            names[name] = true
        elseif next(names) then
            break
        end
    end
    return names
end

local function LoadBonusRollNames(itemIDs, callback)
    local names = {}
    local pending = 0
    local finished = false

    local function AddName(itemID, name)
        if not name then return end
        addonTable.ItemNames[itemID] = name
        names[name] = names[name] or {}
        names[name][itemID] = true
    end

    local function Finish()
        if finished or pending > 0 then return end
        finished = true
        callback(names)
    end

    for _, itemID in ipairs(itemIDs) do
        local name = GetItemInfo and GetItemInfo(itemID)
        if name then
            AddName(itemID, name)
        elseif Item and Item.CreateFromItemID then
            pending = pending + 1
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                pending = pending - 1
                AddName(itemID, item:GetItemName())
                Finish()
            end)
        end
    end
    Finish()
end

local function ScanBonusRollChest(definition, classID, lootSpecID, scanToken, onDone)
    local source = GetBonusRollSource(definition)
    if not source then onDone(); return end

    local pool = BuildPool(source, classID, lootSpecID)
    local itemIDs = {}
    for itemID in pairs(pool) do itemIDs[#itemIDs + 1] = itemID end
    if #itemIDs == 0 then onDone(); return end

    LoadBonusRollNames(itemIDs, function(candidateNames)
        if scanToken ~= bonusRollScanToken or not addonTable._bonusRollScanRunning then return end
        local attempts, previousCount, stableHits = 0, -1, 0

        local function Poll()
            if scanToken ~= bonusRollScanToken or not addonTable._bonusRollScanRunning then return end
            attempts = attempts + 1
            local remaining = GetBonusRollRemainingNames(definition.itemID)
            local count = 0
            for _ in pairs(remaining) do count = count + 1 end

            if count > 0 and count == previousCount then
                stableHits = stableHits + 1
            elseif count > 0 then
                previousCount = count
                stableHits = 1
            else
                stableHits = 0
            end

            if stableHits >= 3 then
                if count < #itemIDs then
                    for name, candidates in pairs(candidateNames) do
                        if not remaining[name] then
                            for itemID in pairs(candidates) do
                                addonTable.CharDB.bonusRolls[tostring(itemID)] = true
                            end
                        end
                    end
                end
                onDone()
                return
            end

            if attempts >= 10 then
                onDone()
                return
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.3, Poll)
            else
                onDone()
            end
        end

        Poll()
    end)
end

function addonTable.ScanBonusRollHistory(force)
    if addonTable._bonusRollScanRunning then return end
    if not force and addonTable.CharDB.bonusRollScanVersion == addonTable.Data.dataVersion then return end
    if not C_TooltipInfo or not C_TooltipInfo.GetItemByID then return end

    local classID = select(3, UnitClass("player"))
    local currentSpecIndex = GetSpecialization and GetSpecialization()
    local currentSpecID = currentSpecIndex and GetSpecializationInfo(currentSpecIndex) or nil
    if not classID or not currentSpecID then return end

    local lootSpecID = GetLootSpecialization and GetLootSpecialization() or 0
    if not lootSpecID or lootSpecID == 0 then lootSpecID = currentSpecID end

    local definitions = addonTable.Data.BonusRollChests or {}
    if #definitions == 0 then return end
    bonusRollScanToken = bonusRollScanToken + 1
    local scanToken = bonusRollScanToken
    addonTable._bonusRollScanRunning = true
    print("|cffff8200Oak Bonus Planner|r: checking Voidcache tooltips for prior bonus-roll wins.")
    local index = 0

    local function Next()
        if scanToken ~= bonusRollScanToken or not addonTable._bonusRollScanRunning then return end
        index = index + 1
        local definition = definitions[index]
        if not definition then
            addonTable._bonusRollScanRunning = nil
            addonTable.CharDB.bonusRollScanVersion = addonTable.Data.dataVersion
            print("|cffff8200Oak Bonus Planner|r: prior bonus-roll check complete.")
            if addonTable.Refresh then addonTable.Refresh() end
            return
        end
        ScanBonusRollChest(definition, classID, lootSpecID, scanToken, Next)
    end

    Next()
end

function addonTable.CancelBonusRollHistoryScan()
    if not addonTable._bonusRollScanRunning then return end
    bonusRollScanToken = bonusRollScanToken + 1
    addonTable._bonusRollScanRunning = nil
end

local function IsCatalystSlot(entry)
    local slot = string.lower(tostring(entry and entry.slot or ""))
    return slot == "head" or slot == "helm"
        or slot == "shoulder" or slot == "shoulders"
        or slot == "chest"
        or slot == "hands" or slot == "gloves"
        or slot == "legs"
end

local function GetGuideSlotID(entry)
    local slot = string.lower(tostring(entry and entry.slot or ""))
    if slot == "head" or slot == "helm" then return 0 end
    if slot == "shoulder" or slot == "shoulders" then return 2 end
    if slot == "chest" then return 4 end
    if slot == "hands" or slot == "gloves" then return 7 end
    if slot == "legs" then return 8 end
end

local function SourceTextMatches(sourceText, source)
    if not sourceText or not source then return false end
    local text = string.lower(tostring(sourceText))
    for _, alias in ipairs(source.aliases or { source.name }) do
        if string.find(text, string.lower(alias), 1, true) then return true end
    end
    return false
end

local function MatchesSlot(itemID, target)
    local itemInfo = GetLootItemInfo(itemID)
    if not itemInfo or not target.slotIDs then return false end
    local displaySlotID = GetDisplaySlotID(itemID, itemInfo.slotId)
    for _, slotID in ipairs(target.slotIDs) do
        if displaySlotID == slotID then return true end
    end
    return false
end

local function BuildCatalystSet(pool, plan, source)
    local catalyst = {}
    local config = plan and plan.catalyst
    if not config then return catalyst end
    for _, target in ipairs(config.targets or {}) do
        if pool[target.itemID] and SourceTextMatches(target.source, source) then
            catalyst[target.itemID] = true
        end
    end
    if config.appliesTo == "dungeons" and not source.challengeModeID then
    elseif config.mode == "slots" then
        for itemID in pairs(pool) do
            local itemInfo = GetLootItemInfo(itemID)
            for _, slotID in ipairs(config.slotIDs or {}) do
                if itemInfo and itemInfo.slotId == slotID then
                    catalyst[itemID] = true
                    break
                end
            end
        end
    elseif config.mode == "items" then
        for _, itemID in ipairs(config.itemIDs or {}) do
            if pool[itemID] then catalyst[itemID] = true end
        end
    end
    return catalyst
end

local function GetFilledCatalystSlots(plan, classID, lootSpecID)
    local config = plan and plan.catalyst
    local filled = {}
    if not config or config.consumeSlot == false then return filled end

    local catalystItems = {}
    for _, target in ipairs(config.allTargets or config.targets or {}) do
        local itemInfo = GetLootItemInfo(target.itemID)
        if itemInfo and HasSpec(itemInfo, classID, lootSpecID) and IsCatalystSlot(target) then
            catalystItems[target.itemID] = GetDisplaySlotID(target.itemID, itemInfo.slotId)
        end
    end
    for _, source in ipairs(addonTable.Data.Sources or {}) do
        if source.challengeModeID then
            for _, itemID in ipairs(GetLootIDs(source) or {}) do
                local itemInfo = GetLootItemInfo(itemID)
                if itemInfo and HasSpec(itemInfo, classID, lootSpecID) then
                    for _, slotID in ipairs(config.slotIDs or {}) do
                        if GetDisplaySlotID(itemID, itemInfo.slotId) == slotID then
                            catalystItems[itemID] = slotID
                            break
                        end
                    end
                end
            end
        end
    end
    for _, mode in ipairs({ "overall", "raids" }) do
        for _, entry in ipairs(plan.bis and plan.bis[mode] or {}) do
            if type(entry) == "table" and entry.itemID and entry.source
                    and string.find(string.lower(entry.source), "catalyst", 1, true)
                    and IsCatalystSlot(entry) then
                local itemInfo = GetLootItemInfo(entry.itemID)
                if itemInfo and HasSpec(itemInfo, classID, lootSpecID) then
                    catalystItems[entry.itemID] = GetDisplaySlotID(entry.itemID, itemInfo.slotId)
                end
            end
        end
    end

    for _, source in ipairs(addonTable.Data.Sources or {}) do
        for _, tierToken in ipairs(GetTierTokenDefinitions(source) or {}) do
            if tierToken.slotID and IsClassEligibleToken(tierToken, classID) and IsItemWon(tierToken.itemID) then
                filled[tierToken.slotID] = true
            end
        end
    end

    for itemID, slotID in pairs(catalystItems) do
        if IsItemWon(itemID) then filled[slotID] = true end
    end
    return filled
end

local function GetTierTokenDesiredSet(pool, plan, source)
    local desired = {}
    local tokenDefinitions = GetTierTokenDefinitions(source)
    if not tokenDefinitions then return desired end

    local targetSlots = {}
    for _, target in ipairs(plan.catalyst and plan.catalyst.targets or {}) do
        if IsCatalystSlot(target) and SourceTextMatches(target.source, source) then
            local slotID = GetGuideSlotID(target)
            if slotID then targetSlots[slotID] = true end
        end
    end
    -- A guide can name a tier piece as a direct boss reward (for example,
    -- Arms Hands from Entombed Sentinels). That means the matching boss token
    -- is wanted too, even when that slot is not a catalyst recommendation.
    for _, entry in ipairs(plan.bis and plan.bis[plan.mode] or {}) do
        if IsCatalystSlot(entry) and SourceTextMatches(entry.source, source) then
            local slotID = GetGuideSlotID(entry)
            if slotID then targetSlots[slotID] = true end
        end
    end

    local hasAnyTarget = next(targetSlots) ~= nil
    for _, tierToken in ipairs(tokenDefinitions) do
        if pool[tierToken.itemID] and ((tierToken.slotID and targetSlots[tierToken.slotID])
                or tierToken.omni and hasAnyTarget) then
            desired[tierToken.itemID] = true
        end
    end
    return desired
end

local function BuildDesiredSet(pool, plan, targetSpecID, source, classID, lootSpecID)
    local desired = {}
    local unresolved = 0
    for _, target in ipairs(plan.targets or {}) do
        local matched = false
        local hasExactTarget = target.itemName or (target.itemIDs and #target.itemIDs > 0)
        for _, itemID in ipairs(target.itemIDs or {}) do
            if pool[itemID] then
                desired[itemID] = true
                matched = true
            end
        end
        for itemID in pairs(pool) do
            if target.itemName and addonTable.ItemNames[itemID] == target.itemName then
                desired[itemID] = true
                matched = true
            end
        end
        if not hasExactTarget then
            for itemID in pairs(pool) do
                if MatchesSlot(itemID, target) then
                    desired[itemID] = true
                    matched = true
                end
            end
        end
        if not matched and (target.itemName or target.itemIDs or target.slotIDs) then unresolved = unresolved + 1 end
    end
    for itemID in pairs(plan.bisItems or {}) do
        if pool[itemID] then desired[itemID] = true end
    end
    local catalyst = BuildCatalystSet(pool, plan, source)
    local filledCatalystSlots = GetFilledCatalystSlots(plan, classID, lootSpecID)
    for itemID in pairs(catalyst) do
        local itemInfo = GetLootItemInfo(itemID)
        local slotID = itemInfo and GetDisplaySlotID(itemID, itemInfo.slotId)
        if not filledCatalystSlots[slotID] then
            desired[itemID] = true
        else
            -- Slot-mode catalyst plans fill the entire catalyst slot once any
            -- eligible catalyst/tier piece in that slot has been won.
            desired[itemID] = nil
        end
    end
    for itemID in pairs(GetTierTokenDesiredSet(pool, plan, source)) do
        desired[itemID] = true
    end
    local overrides = addonTable.DB.bisOverrides[targetSpecID] or {}
    for itemID in pairs(pool) do
        local override = overrides[tostring(itemID)]
        if override == true then
            desired[itemID] = true
        elseif override == false then
            desired[itemID] = nil
        end
    end
    return desired, unresolved, catalyst
end

local function GetSourcePlan(plan, source, mode)
    if not plan then return { targets = {} } end
    local sourcePlan = {}
    for key, value in pairs(plan.sources and plan.sources[source.id] or {}) do sourcePlan[key] = value end
    if plan.bis then
        local list = plan.bis[mode] or plan.bis.overall or {}
        if addonTable.DB.source == "wowhead" and mode == "overall" then
            local wowheadList = plan.bis.wowheadOverall
            if wowheadList and #wowheadList > 0 then list = wowheadList end
        end
        sourcePlan.bisItems = {}
        for _, item in ipairs(list) do
            local itemID = type(item) == "table" and item.itemID or item
            if itemID then sourcePlan.bisItems[itemID] = true end
        end
    end
    if plan.catalyst then
        sourcePlan.catalyst = {
            mode = plan.catalyst.mode,
            appliesTo = plan.catalyst.appliesTo,
            season = plan.catalyst.season,
            consumeSlot = plan.catalyst.consumeSlot,
            allTargets = plan.catalyst.allTargets,
            targets = plan.catalyst.targetsByMode and plan.catalyst.targetsByMode[mode] or plan.catalyst.targets,
            label = plan.catalyst.label,
        }
    end
    sourcePlan.bis = plan.bis
    sourcePlan.mode = mode
    return sourcePlan
end

local function GetSourceArtwork(source)
    if source.challengeModeID then
        for _, dungeon in ipairs(Loot.DungeonDatabase or {}) do
            if dungeon.challengeModeId == source.challengeModeID then
                return dungeon.bgTexture
            end
        end
    elseif source.bossID then
        for _, raid in ipairs(Loot.RaidDatabase or {}) do
            for _, boss in ipairs(raid.bossList or {}) do
                if boss.bossId == source.bossID then
                    return boss.bgTexture or raid.bgTexture
                end
            end
        end
    end
    return nil
end

local function GetSourceIcon(source, artwork)
    if artwork then return artwork end
    if source and source.bossID then
        -- The generated raid database does not include background artwork.
        -- Use Blizzard's native raid icon instead of presenting a question mark.
        return "Interface\\LFGFrame\\LFGIcon-Raid"
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function CountSet(set)
    local count = 0
    for _ in pairs(set or {}) do count = count + 1 end
    return count
end

local function GetSourceStats(source, plan, classID, lootSpecID, targetSpecID)
    plan = plan or { targets = {} }
    local pool = BuildPool(source, classID, lootSpecID)
    local desired, unresolved, catalyst = BuildDesiredSet(pool, plan, targetSpecID, source, classID, lootSpecID)
    local poolTotal = CountSet(pool)
    local tierTokenTotal = 0
    local poolUsed = 0
    local desiredTotal = CountSet(desired)
    local desiredUsed = 0

    for itemID in pairs(pool) do
        if GetTierTokenInfo(source, itemID) then tierTokenTotal = tierTokenTotal + 1 end
        local alreadyWon = IsItemWon(itemID)
        if alreadyWon then
            poolUsed = poolUsed + 1
            if desired[itemID] then desiredUsed = desiredUsed + 1 end
        end
    end

    local poolRemaining = math.max(0, poolTotal - poolUsed)
    local desiredRemaining = math.max(0, desiredTotal - desiredUsed)
    local chance = poolRemaining > 0 and desiredRemaining / poolRemaining or 0
    return {
        source = source,
        plan = plan,
        pool = pool,
        desired = desired,
        catalyst = catalyst,
        unresolved = unresolved,
        poolTotal = poolTotal,
        tierTokenTotal = tierTokenTotal,
        poolUsed = poolUsed,
        poolRemaining = poolRemaining,
        desiredTotal = desiredTotal,
        desiredUsed = desiredUsed,
        desiredRemaining = desiredRemaining,
        chance = chance,
        unwantedChance = math.max(0, 1 - chance),
        score = chance,
    }
end

local function AddSourceItems(stats, targetSpecID)
    local items = {}
    for itemID in pairs(stats.pool) do
        local itemInfo = GetLootItemInfo(itemID)
        local tierToken = GetTierTokenInfo(stats.source, itemID)
        local slotID = tierToken and tierToken.slotID
            or GetDisplaySlotID(itemID, itemInfo and itemInfo.slotId)
        local isTierToken = tierToken ~= nil
        table.insert(items, {
            itemID = itemID,
            name = GetItemName(itemID),
            icon = GetItemTexture(itemID),
            slotID = slotID,
            slotLabel = tierToken and tierToken.slotLabel,
            isBIS = stats.desired[itemID] == true,
            isManualBIS = addonTable.DB.bisOverrides[targetSpecID]
                and addonTable.DB.bisOverrides[targetSpecID][tostring(itemID)] == true or false,
            isCatalyst = stats.catalyst[itemID] == true,
            isTierToken = isTierToken,
            isWon = IsItemWon(itemID),
            maxItemLevel = addonTable.GetMaxItemLevel(slotID, false),
            maxItemLinkKind = isTierToken and "raid"
                or (stats.catalyst[itemID] and "catalyst"
                or (stats.source.challengeModeID and "dungeon"
                    or (stats.source.kind == "Raid boss" and "raid" or "drop"))),
            targetSpecID = targetSpecID,
        })
    end
    table.sort(items, function(a, b)
        if a.isBIS ~= b.isBIS then return a.isBIS end
        if a.isWon ~= b.isWon then return not a.isWon end
        return a.name < b.name
    end)
    stats.items = items
    stats.artwork = GetSourceArtwork(stats.source)
    stats.icon = GetSourceIcon(stats.source, stats.artwork)
    return stats
end

function addonTable.GetSelectedSpec()
    local currentClassID, currentSpecID = addonTable.GetCurrentSpec()
    local followCurrent = addonTable.CharDB.followCurrentSpec ~= false
    local classID = followCurrent and currentClassID or addonTable.CharDB.selectedClassID or currentClassID
    local specID = followCurrent and currentSpecID or addonTable.CharDB.selectedSpecID or currentSpecID
    if not addonTable.Data.Specs[classID] then classID = currentClassID end
    if not (addonTable.Data.Specs[classID] and addonTable.Data.Specs[classID].specs[specID]) then
        specID = addonTable.GetAllSpecIDs(classID)[1]
    end
    addonTable.CharDB.selectedClassID = classID
    addonTable.CharDB.selectedSpecID = specID
    return classID, specID
end

function addonTable.GetSelectedLootSpec()
    local classID, targetSpecID = addonTable.GetSelectedSpec()
    -- Rows choose their own best loot specialization. Keep this value for
    -- compatibility with the existing header and external callers only.
    local lootSpecID = targetSpecID
    addonTable.CharDB.lootSpecID = lootSpecID
    return classID, targetSpecID, lootSpecID, nil
end

local function GetSourceRecommendationKey(source, classID, targetSpecID, mode)
    return table.concat({ source.id, classID, targetSpecID, mode, addonTable.DB.source or "icy" }, ":")
end

function addonTable.GetSourceLootSpecRecommendation(source, targetPlan, classID, targetSpecID, mode)
    local key = GetSourceRecommendationKey(source, classID, targetSpecID, mode)
    local cached = sourceRecommendationCache[key]
    if cached then return cached end

    local sourcePlan = GetSourcePlan(targetPlan, source, mode)
    local stats = GetSourceStats(source, sourcePlan, classID, targetSpecID, targetSpecID)
    cached = {
        specID = targetSpecID,
        chance = stats.chance,
        stats = stats,
    }
    sourceRecommendationCache[key] = cached

    for _, lootSpecID in ipairs(addonTable.GetAllSpecIDs(classID)) do
        if lootSpecID ~= targetSpecID then
            local candidate = GetSourceStats(source, sourcePlan, classID, lootSpecID, targetSpecID)
            if candidate.chance > cached.chance then
                cached.specID = lootSpecID
                cached.chance = candidate.chance
                cached.stats = candidate
            end
        end
    end
    return cached
end

function addonTable.GetLootSpecRecommendation(classID, targetSpecID)
    local targetPlan = GetPlan(targetSpecID)
    if not targetPlan then return nil end
    local totalPool, totalDesired = 0, 0
    for _, source in ipairs(addonTable.Data.Sources) do
        local recommendation = addonTable.GetSourceLootSpecRecommendation(source, targetPlan, classID, targetSpecID, "overall")
        if recommendation then
            totalPool = totalPool + recommendation.stats.poolRemaining
            totalDesired = totalDesired + recommendation.stats.desiredRemaining
        end
    end
    return {
        chance = totalPool > 0 and totalDesired / totalPool or 0,
        poolRemaining = totalPool,
        desiredRemaining = totalDesired,
    }
end

function addonTable.GetPlanRows()
    local classID, targetSpecID, lootSpecID, recommendation = addonTable.GetSelectedLootSpec()
    local plan = GetPlan(targetSpecID)
    local rows = {}
    for _, source in ipairs(addonTable.Data.Sources) do
        local sourcePlan = GetSourcePlan(plan, source, "overall")
        local recommendation = addonTable.GetSourceLootSpecRecommendation(source, plan, classID, targetSpecID, "overall")
        local stats = recommendation and recommendation.stats or GetSourceStats(source, sourcePlan, classID, lootSpecID, targetSpecID)
        stats.recommendedLootSpecID = recommendation and recommendation.specID or lootSpecID
        stats.targetSpecID = targetSpecID
        stats.classID = classID
        table.insert(rows, AddSourceItems(stats, targetSpecID))
    end
    table.sort(rows, function(a, b)
        if a.chance ~= b.chance then return a.chance > b.chance end
        if a.desiredRemaining ~= b.desiredRemaining then return a.desiredRemaining > b.desiredRemaining end
        return a.source.name < b.source.name
    end)
    return rows, classID, targetSpecID, lootSpecID, plan, recommendation
end

local function SortRows(rows, sortMode)
    sortMode = sortMode or addonTable.DB.sortMode or "chance"
    table.sort(rows, function(a, b)
        if sortMode == "name" then
            local aName, bName = string.lower(a.source.name), string.lower(b.source.name)
            if aName ~= bName then return aName < bName end
        elseif sortMode == "pool" then
            if a.poolTotal ~= b.poolTotal then return a.poolTotal > b.poolTotal end
            if a.poolRemaining ~= b.poolRemaining then return a.poolRemaining > b.poolRemaining end
        else
            if a.chance ~= b.chance then return a.chance > b.chance end
            if a.desiredRemaining ~= b.desiredRemaining then return a.desiredRemaining > b.desiredRemaining end
        end
        return string.lower(a.source.name) < string.lower(b.source.name)
    end)
    return rows
end

function addonTable.GetLootTableRows(tab)
    local classID, targetSpecID, lootSpecID, recommendation = addonTable.GetSelectedLootSpec()
    local plan = GetPlan(targetSpecID)
    local rows = {}
    for _, source in ipairs(addonTable.Data.Sources) do
        local include = tab == "overall"
            or (tab == "dungeons" and source.challengeModeID)
            or (tab == "raids" and source.bossID)
        if include then
            local sourcePlan = GetSourcePlan(plan, source, tab)
            local sourceMode = tab == "overall" and "overall" or tab
            local recommendation = addonTable.GetSourceLootSpecRecommendation(source, plan, classID, targetSpecID, sourceMode)
            local stats = recommendation and recommendation.stats or GetSourceStats(source, sourcePlan, classID, lootSpecID, targetSpecID)
            stats.recommendedLootSpecID = recommendation and recommendation.specID or lootSpecID
            stats.targetSpecID = targetSpecID
            stats.classID = classID
            table.insert(rows, AddSourceItems(stats, targetSpecID))
        end
    end
    return SortRows(rows), classID, targetSpecID, lootSpecID, plan, recommendation
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
    addonTable.CharDB.followCurrentSpec = false
    addonTable.CharDB.selectedClassID = classID
    addonTable.CharDB.selectedSpecID = specID
    addonTable.CharDB.lootSpecID = nil
    sourceRecommendationCache = {}
    if addonTable.Refresh then addonTable.Refresh() end
end

function addonTable.SetLootSpec(specID)
    addonTable.CharDB.lootSpecID = specID
    if addonTable.Refresh then addonTable.Refresh() end
end

function addonTable.SetBISOverride(specID, itemID, isBIS)
    if not specID or not itemID then return end
    addonTable.DB.bisOverrides[specID] = addonTable.DB.bisOverrides[specID] or {}
    addonTable.DB.bisOverrides[specID][tostring(itemID)] = isBIS == true
    sourceRecommendationCache = {}
    if addonTable.Refresh then addonTable.Refresh() end
end

function addonTable.HandleBonusRoll(rewardType, rewardLink)
    if rewardType ~= "item" or not rewardLink then return end
    local itemID = tonumber(string.match(rewardLink, "item:(%d+)"))
    if not itemID then return end
    addonTable.CharDB.bonusRolls[tostring(itemID)] = true
    sourceRecommendationCache = {}
    CacheItemName(itemID)
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
        if addonTable.CharDB.followCurrentSpec ~= false then
            addonTable.CharDB.selectedClassID = currentClassID
            addonTable.CharDB.selectedSpecID = currentSpecID
            addonTable.CharDB.lootSpecID = currentSpecID
        else
            if not addonTable.CharDB.selectedClassID then addonTable.CharDB.selectedClassID = currentClassID end
            if not addonTable.CharDB.selectedSpecID then addonTable.CharDB.selectedSpecID = currentSpecID end
            if not addonTable.CharDB.lootSpecID then addonTable.CharDB.lootSpecID = currentSpecID end
        end
        if addonTable.Refresh then addonTable.Refresh() end
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        local currentClassID, currentSpecID = addonTable.GetCurrentSpec()
        addonTable.CharDB.followCurrentSpec = true
        addonTable.CharDB.selectedClassID = currentClassID
        addonTable.CharDB.selectedSpecID = currentSpecID
        addonTable.CharDB.lootSpecID = currentSpecID
        if addonTable.Refresh then addonTable.Refresh() end
    elseif addonTable.Refresh then
        addonTable.Refresh()
    end
end)

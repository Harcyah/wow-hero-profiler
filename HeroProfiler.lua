local function ExportBackpack()
	local bag = {}
	bag.link = nil
	bag.numSlots = GetContainerNumSlots(0)
	bag.freeSlots = GetContainerNumFreeSlots(0)
	return bag
end

local function ExportContainer(index)
	local bag = {}
	bag.link = GetInventoryItemLink("player", ContainerIDToInventoryID(index))
	bag.numSlots = GetContainerNumSlots(index)
	bag.freeSlots = GetContainerNumFreeSlots(index)
	return bag
end

local function ClearProfiles()
	HeroProfiles = {}
end

local function ExportProfiles()
	HeroProfiles.name = UnitName("player")
	HeroProfiles.realm = GetRealmName()
	HeroProfiles.level = UnitLevel("player")
	HeroProfiles.money = GetMoney()
	HeroProfiles.zone = GetZoneText()
	HeroProfiles.heartstone = GetBindLocation()
	HeroProfiles.gender = UnitSex("player")
	HeroProfiles.xp = UnitXP("player")
	HeroProfiles.xpMax = UnitXPMax("player")
	HeroProfiles.health = UnitHealthMax("player")
	HeroProfiles.side = UnitFactionGroup("player")

	local restId, restName = GetRestState()
	HeroProfiles.restId = restId
	HeroProfiles.restName = restName

	local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
	HeroProfiles.avgItemLevel = avgItemLevel
	HeroProfiles.avgItemLevelEquipped = avgItemLevelEquipped
	HeroProfiles.avgItemLevelPvp = avgItemLevelPvp

	HeroProfiles.hasMasterRiding = tostring(IsSpellKnown(90265))

	local className, classFile, classID = UnitClass("player");
	HeroProfiles.clazz = classFile

	local raceName, raceFile, raceID = UnitRace("player")
	HeroProfiles.race = raceFile

	local englishFaction, localizedFaction = UnitFactionGroup("player")
	HeroProfiles.faction = englishFaction

	local specIndex = GetSpecialization()
	local specId, specName, _, _, _, specRole = GetSpecializationInfo(specIndex)
	HeroProfiles.specId = specId
	HeroProfiles.specName = specName
	HeroProfiles.specRole = GetSpecializationRoleByID(specId)

	local totalAchievements, completedAchievements = GetNumCompletedAchievements()
	HeroProfiles.totalAchievements = totalAchievements
	HeroProfiles.completedAchievements = completedAchievements
	HeroProfiles.totalAchievementPoints = GetTotalAchievementPoints()

	HeroProfiles.factions = {}
	for i=1,GetNumFactions() do
		local name, description, standingId, bottomValue, topValue, earnedValue, _, _, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(i)
		if (isHeader == false) then
			local faction = {}
			faction.id = factionID
			faction.name = name
			faction.earned = earnedValue
			table.insert(HeroProfiles.factions, faction)
		end
	end

	local prof1, prof2, archaelogy, fishing, cooking = GetProfessions();
	if (HeroProfiles.professions == nil) then
		HeroProfiles.professions = {
			prof1 = {
				id = 0,
				index = prof1,
				name = GetProfessionInfo(prof1)
			},
			prof2 = {
				id = 0,
				index = prof2,
				name = GetProfessionInfo(prof2)
			},
			cooking = {
				id = 0,
				index = cooking,
				name = GetProfessionInfo(cooking)
			},
			fishing = {
				id = 0,
				index = fishing,
				name = GetProfessionInfo(fishing)
			}
		}
	end

	-- Archaelogy
	local name, _, skillLevel, maxSkillLevel = GetProfessionInfo(archaelogy)
	HeroProfiles.professions.archaelogy = {
		id = 794,
		index = archaelogy,
		name = name,
		skillLevel = skillLevel,
		maxLevel = maxSkillLevel
	}

	-- Bags
	HeroProfiles.bags = {}
	HeroProfiles.bags.backpack = ExportBackpack()
	HeroProfiles.bags.bag1 = ExportContainer(1)
	HeroProfiles.bags.bag2 = ExportContainer(2)
	HeroProfiles.bags.bag3 = ExportContainer(3)
	HeroProfiles.bags.bag4 = ExportContainer(4)
end

SlashCmdList_AddSlashCommand('HERO_PROFILER_SLASHCMD_EXPORT', ExportProfiles, '/hpexport')

SlashCmdList_AddSlashCommand('HERO_PROFILER_SLASHCMD_CLEAR', function()
	ClearProfiles()
end, '/hpclear')

local frame = CreateFrame("Frame");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LOGIN");
frame:RegisterEvent("PLAYER_GUILD_UPDATE");
frame:RegisterEvent("PLAYER_LOGOUT");
frame:RegisterEvent("TIME_PLAYED_MSG");
frame:RegisterEvent("BANKFRAME_OPENED");
frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE");
frame:Hide();

frame:SetScript("OnEvent", function(self, event, ...)
	local arg = {...}

	if (event == "ADDON_LOADED" and arg[1] == 'HeroProfiler') then
		if (HeroProfiles == nil) then
			HeroProfiles = {}
		end
	end

	if (event == "PLAYER_LOGIN") then
		ExportProfiles()
		RequestTimePlayed()
	end

	if (event == "TIME_PLAYED_MSG") then
		HeroProfiles.totalTime = arg[1]
		HeroProfiles.currentLevelTime = arg[2]
	end

	if (event == "PLAYER_GUILD_UPDATE") then
		local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
		HeroProfiles.guildName = guildName
		HeroProfiles.guildRankName = guildRankName
		HeroProfiles.guildRankIndex = guildRankIndex
	end

	if (event == "BANKFRAME_OPENED") then
		HeroProfiles.bags.bank1 = ExportContainer(5)
		HeroProfiles.bags.bank2 = ExportContainer(6)
		HeroProfiles.bags.bank3 = ExportContainer(7)
		HeroProfiles.bags.bank4 = ExportContainer(8)
		HeroProfiles.bags.bank5 = ExportContainer(9)
		HeroProfiles.bags.bank6 = ExportContainer(10)
		HeroProfiles.bags.bank7 = ExportContainer(11)
	end

	if (event == "TRADE_SKILL_LIST_UPDATE") then
		if (C_TradeSkillUI.IsTradeSkillReady()) then
			levels = {}
			local categories = { C_TradeSkillUI.GetCategories() };
			for i, categoryID in ipairs(categories) do
				local info = C_TradeSkillUI.GetCategoryInfo(categoryID);
				if (info.type == 'subheader') then
					level = {}
					level.id = categoryID
					level.name = info.name
					level.maxLevel = info.skillLineMaxLevel
					level.currentLevel = info.skillLineCurrentLevel
					table.insert(levels, level)
				end
			end

			-- where to put this ?
			local _, _, _, _, _, parentID =  C_TradeSkillUI.GetTradeSkillLine();
			if (HeroProfiles.professions.prof1.id == parentID) then
				HeroProfiles.professions.prof1.levels = levels
			elseif (HeroProfiles.professions.prof2.id == parentID) then
				HeroProfiles.professions.prof2.id = parentSkillLineID
				HeroProfiles.professions.prof2.levels = levels
			elseif (HeroProfiles.professions.cooking.id == parentID) then
				HeroProfiles.professions.cooking.id = parentSkillLineID
				HeroProfiles.professions.cooking.levels = levels
			elseif (HeroProfiles.professions.fishing.id == parentID) then
				HeroProfiles.professions.fishing.id = parentSkillLineID
				HeroProfiles.professions.fishing.levels = levels
			end
		end
	end

end)

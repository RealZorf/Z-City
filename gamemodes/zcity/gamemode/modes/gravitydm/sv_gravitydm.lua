local MODE = MODE

local vecUp = Vector(0, 0, 1)
local angZero = Angle(0, 0, 0)

local function CleanupSpawnedEntities(mode)
	mode.GravityRoundEntities = mode.GravityRoundEntities or {}

	for i, ent in ipairs(mode.GravityRoundEntities) do
		if IsValid(ent) then
			ent:Remove()
		end
	end

	mode.GravityRoundEntities = {}
end

local function TrackSpawnedEntity(mode, ent)
	if not IsValid(ent) then return nil end

	mode.GravityRoundEntities = mode.GravityRoundEntities or {}
	mode.GravityRoundEntities[#mode.GravityRoundEntities + 1] = ent

	return ent
end

local function Shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end

	return list
end

local function AddUniquePositions(target, seen, positions)
	for _, pos in ipairs(positions or {}) do
		if not isvector(pos) then continue end

		local key = math.Round(pos.x) .. ":" .. math.Round(pos.y) .. ":" .. math.Round(pos.z)
		if seen[key] then continue end

		seen[key] = true
		target[#target + 1] = pos
	end
end

local function CollectSpawnPositions()
	local positions = {}
	local seen = {}
	local pointGroups = {
		"RandomSpawns",
		"Spawnpoint",
		"HMCD_TDM_T",
		"HMCD_TDM_CT",
	}

	for _, pointGroup in ipairs(pointGroups) do
		AddUniquePositions(positions, seen, zb.TranslatePointsToVectors(zb.GetMapPoints(pointGroup) or {}))
	end

	if #positions == 0 then
		for _, ent in ipairs(ents.FindByClass("info_*")) do
			AddUniquePositions(positions, seen, {ent:GetPos()})
		end
	end

	return positions
end

local function HasNearbyLivingPlayer(pos, distance)
	if distance <= 0 then return false end

	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:Alive() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if pos:DistToSqr(ply:GetPos()) <= (distance * distance) then
			return true
		end
	end

	return false
end

local function HasNearbySpawn(selected, pos, distance)
	if distance <= 0 then return false end

	for _, otherPos in ipairs(selected) do
		if pos:DistToSqr(otherPos) <= (distance * distance) then
			return true
		end
	end

	return false
end

local function PickSpawnPositions(count, height, separation, playerBuffer)
	local candidates = CollectSpawnPositions()
	local selected = {}

	Shuffle(candidates)

	for _, pos in ipairs(candidates) do
		local spawnPos = pos + vecUp * height
		if HasNearbyLivingPlayer(spawnPos, playerBuffer) then continue end
		if HasNearbySpawn(selected, spawnPos, separation) then continue end

		selected[#selected + 1] = spawnPos
		if #selected >= count then
			return selected
		end
	end

	for _, pos in ipairs(candidates) do
		local spawnPos = pos + vecUp * height
		if HasNearbySpawn(selected, spawnPos, separation * 0.5) then continue end

		selected[#selected + 1] = spawnPos
		if #selected >= count then
			return selected
		end
	end

	return selected
end

local function ApplyFixedModel(mode, ply)
	local model = mode.FixedPlayerModel
	if not model or model == "" then return end
	if util.IsValidModel and not util.IsValidModel(model) then return end

	if util.PrecacheModel then
		pcall(util.PrecacheModel, model)
	end

	ply:SetModel(model)
	ply:SetPlayerColor(Vector(1, 1, 1))
	ply:SetNetVar("Accessories", "none")
	ply:SetSubMaterial()
	ply:SetSkin(0)
end

local function SpawnLootEntity(mode, className, pos)
	local ent = ents.Create(className)
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(angZero)
	ent.IsSpawned = true
	ent.init = true
	ent:Spawn()
	ent:Activate()

	return TrackSpawnedEntity(mode, ent)
end

local function SpawnPhysicsProp(mode, model, pos)
	if util.IsValidProp and not util.IsValidProp(model) then return nil end

	local ent = ents.Create("prop_physics")
	if not IsValid(ent) then return nil end

	ent:SetModel(model)
	ent:SetPos(pos)
	ent:SetAngles(Angle(0, math.random(0, 359), 0))
	ent:Spawn()
	ent:Activate()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	return TrackSpawnedEntity(mode, ent)
end

local function GetSpawnCount(playerCount, minCount, maxCount, multiplier)
	return math.Clamp(math.ceil(playerCount * multiplier), minCount, maxCount)
end

local function SpawnRoundLoot(mode, playerCount)
	local lootClasses = mode.RandomLootEntities or {}
	if #lootClasses == 0 then return end

	local count = GetSpawnCount(playerCount, mode.MinLootSpawns or 6, mode.MaxLootSpawns or 10, 0.75)
	local positions = PickSpawnPositions(count, mode.LootSpawnHeight or 14, mode.LootSpawnSeparation or 80, mode.LootSpawnPlayerBuffer or 128)

	for _, pos in ipairs(positions) do
		SpawnLootEntity(mode, lootClasses[math.random(#lootClasses)], pos)
	end
end

local function SpawnRoundProps(mode, playerCount)
	local models = mode.MapPropModels or {}
	if #models == 0 then return end

	local count = GetSpawnCount(playerCount, mode.MinPropSpawns or 10, mode.MaxPropSpawns or 16, 1.5)
	local positions = PickSpawnPositions(count, mode.PropSpawnHeight or 18, mode.PropSpawnSeparation or 96, mode.PropSpawnPlayerBuffer or 160)

	for _, pos in ipairs(positions) do
		SpawnPhysicsProp(mode, models[math.random(#models)], pos)
	end
end

function MODE:Intermission()
	CleanupSpawnedEntities(self)

	local baseMode = zb.modes and zb.modes.dm
	if baseMode and baseMode.Intermission then
		return baseMode.Intermission(self)
	end
end

function MODE:PlayerSpawn(ply)
	timer.Simple(0.1, function()
		if not IsValid(ply) then return end

		local round = CurrentRound and CurrentRound()
		if not round or round.name != self.name then return end

		ApplyFixedModel(self, ply)
	end)
end

function MODE:RoundStart()
	CleanupSpawnedEntities(self)

	local playerCount = math.max(#zb:CheckPlaying(), 1)
	local roundName = self.name

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:StripWeapons()
		ply:RemoveAllAmmo()

		for _, weaponClass in ipairs(self.GuaranteedWeapons or {}) do
			ply:Give(weaponClass)
		end

		ApplyFixedModel(self, ply)

		timer.Simple(0.25, function()
			if not IsValid(ply) then return end
			local round = CurrentRound and CurrentRound()
			if not round or round.name != roundName then return end

			ApplyFixedModel(self, ply)
		end)

		timer.Simple(1, function()
			if not IsValid(ply) then return end
			local round = CurrentRound and CurrentRound()
			if not round or round.name != roundName then return end

			ApplyFixedModel(self, ply)
		end)

		if ply.organism then
			ply.organism.recoilmul = 0.5
		end

		ply:SelectWeapon("weapon_hands_sh")
		zb.GiveRole(ply, self.IntroRoleName or "Gravity Fighter", self.IntroColor or Color(110, 160, 255))
		ply:SetNetVar("CurPluv", "pluvboss")

		timer.Simple(0.1, function()
			if not IsValid(ply) then return end

			ply.noSound = false
			ply:SetSuppressPickupNotices(false)
		end)
	end

	SpawnRoundLoot(self, playerCount)
	SpawnRoundProps(self, playerCount)

	timer.Simple((self.start_time or 20) + 0.1, function()
		local round = CurrentRound and CurrentRound()
		if not round or round.name != roundName then return end

		for _, ply in player.Iterator() do
			if not IsValid(ply) or not ply:Alive() then continue end
			if not IsValid(ply:GetWeapon("weapon_physcannon")) then continue end

			ply:SelectWeapon("weapon_physcannon")
		end
	end)
end

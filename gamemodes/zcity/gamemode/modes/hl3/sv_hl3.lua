local MODE = MODE

local VORT_MODEL = "models/player/vortigaunt.mdl"
local VORT_TEAM = 2
local TEAM_ORDER = {0, 1, VORT_TEAM}
local MAX_TRIANGLE_POINTS = 40
local PLAYER_HULL_MINS = Vector(-16, -16, 0)
local PLAYER_HULL_MAXS = Vector(16, 16, 72)
local SPAWN_PROBE_UP = Vector(0, 0, 48)
local SPAWN_PROBE_DOWN = Vector(0, 0, 256)
local SPAWN_CLEARANCE = Vector(0, 0, 2)
local VORT_START_HEALTH = 150
local VORT_HEALTH_CAP = 150
local VORT_START_ARMOR = 100
local VORT_ARMOR_CAP = 140
local VORT_REGEN_DELAY = 5
local VORT_REGEN_INTERVAL = 1
local VORT_REGEN_HEALTH = 2
local VORT_REGEN_ARMOR = 5
local VORT_SUPPORT_RADIUS_SQR = 320 * 320
local VORT_SUPPORT_HEALTH_BONUS = 1
local VORT_SUPPORT_ARMOR_BONUS = 2

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

local function vectorKey(vec)
	return string.format("%.2f:%.2f:%.2f", vec.x, vec.y, vec.z)
end

local function addUniquePoints(out, seen, points)
	for _, point in ipairs(points or {}) do
		if not isvector(point) then continue end

		local key = vectorKey(point)
		if seen[key] then continue end

		seen[key] = true
		out[#out + 1] = point
	end
end

local function isSafeSpawnPos(pos, filterEnt)
	if not isvector(pos) then return false end

	local tr = util.TraceHull({
		start = pos + SPAWN_CLEARANCE,
		endpos = pos + SPAWN_CLEARANCE,
		mins = PLAYER_HULL_MINS,
		maxs = PLAYER_HULL_MAXS,
		mask = MASK_PLAYERSOLID,
		filter = filterEnt
	})

	return not tr.StartSolid and not tr.AllSolid
end

local function snapSpawnToGround(pos, filterEnt)
	if not isvector(pos) then return nil end

	local tr = util.TraceHull({
		start = pos + SPAWN_PROBE_UP,
		endpos = pos - SPAWN_PROBE_DOWN,
		mins = PLAYER_HULL_MINS,
		maxs = PLAYER_HULL_MAXS,
		mask = MASK_PLAYERSOLID,
		filter = filterEnt
	})

	if tr.StartSolid or tr.AllSolid then
		return nil
	end

	if tr.Hit then
		return tr.HitPos
	end

	return pos
end

local function findNearbySafeSpawn(pos)
	local grounded = snapSpawnToGround(pos)
	if grounded and isSafeSpawnPos(grounded) then
		return grounded
	end

	for i = 1, 24 do
		local testPos = hg.tpPlayer(pos, nil, i, 0)
		if not isvector(testPos) then continue end

		local groundedTest = snapSpawnToGround(testPos)
		if groundedTest and isSafeSpawnPos(groundedTest) then
			return groundedTest
		end
	end

	return nil
end

local function collectSpawnCandidates()
	local candidates = {}
	local seen = {}

	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("RandomSpawns") or {}))
	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("Spawnpoint") or {}))
	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T") or {}))
	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT") or {}))

	if #candidates == 0 then
		local fallback = zb:GetRandomSpawn()
		if fallback then
			candidates[1] = fallback
		end
	end

	return candidates
end

local function distSqr(a, b)
	return a:DistToSqr(b)
end

local function triangleAreaScore(a, b, c)
	return (b - a):Cross(c - a):LengthSqr()
end

local function buildTriangleSample(points)
	if #points <= MAX_TRIANGLE_POINTS then
		return table.Copy(points)
	end

	local sample = table.Copy(points)
	shuffle(sample)

	local trimmed = {}
	for i = 1, MAX_TRIANGLE_POINTS do
		trimmed[i] = sample[i]
	end

	return trimmed
end

local function chooseBestTriangle(points)
	if #points <= 0 then return nil end
	if #points == 1 then return {points[1], points[1], points[1]} end
	if #points == 2 then return {points[1], points[2], points[1]} end

	local sample = buildTriangleSample(points)
	local bestScoreMin = -1
	local bestScoreArea = -1
	local bestScoreTotal = -1
	local bestTriangle

	for i = 1, #sample - 2 do
		local a = sample[i]
		for j = i + 1, #sample - 1 do
			local b = sample[j]
			local ab = distSqr(a, b)
			for k = j + 1, #sample do
				local c = sample[k]
				local ac = distSqr(a, c)
				local bc = distSqr(b, c)
				local minDist = math.min(ab, ac, bc)
				local totalDist = ab + ac + bc
				local areaScore = triangleAreaScore(a, b, c)

				if
					minDist > bestScoreMin or
					(minDist == bestScoreMin and areaScore > bestScoreArea) or
					(minDist == bestScoreMin and areaScore == bestScoreArea and totalDist > bestScoreTotal)
				then
					bestScoreMin = minDist
					bestScoreArea = areaScore
					bestScoreTotal = totalDist
					bestTriangle = {a, b, c}
				end
			end
		end
	end

	return bestTriangle or {sample[1], sample[2], sample[3]}
end

local function isLiveVort(ply)
	return IsValid(ply)
		and ply:IsPlayer()
		and ply:Alive()
		and ply:Team() == VORT_TEAM
		and not (ply.organism and ply.organism.incapacitated)
end

local function resolvePlayerEntity(ent)
	if not IsValid(ent) then return nil end

	local ragdollOwner = hg and hg.RagdollOwner and hg.RagdollOwner(ent) or nil
	if IsValid(ragdollOwner) then
		return ragdollOwner
	end

	return ent:IsPlayer() and ent or nil
end

function MODE:PrepareTeamSpawns()
	local candidates = collectSpawnCandidates()
	local safeCandidates = {}

	for _, candidate in ipairs(candidates) do
		local safeCandidate = findNearbySafeSpawn(candidate)
		if safeCandidate then
			safeCandidates[#safeCandidates + 1] = safeCandidate
		end
	end

	candidates = #safeCandidates > 0 and safeCandidates or candidates
	local triangle = chooseBestTriangle(candidates)
	if not triangle then return end

	shuffle(triangle)

	self.TeamSpawns = {
		[TEAM_ORDER[1]] = triangle[1],
		[TEAM_ORDER[2]] = triangle[2] or triangle[1],
		[TEAM_ORDER[3]] = triangle[3] or triangle[1]
	}

	self.TeamSpawnCounts = {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}
end

function MODE:PlacePlayerAtTeamSpawn(ply)
	if not IsValid(ply) then return end
	if not self.TeamSpawns then return end

	local teamID = ply:Team()
	local anchor = self.TeamSpawns[teamID]
	if not anchor then return end

	self.TeamSpawnCounts = self.TeamSpawnCounts or {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}

	self.TeamSpawnCounts[teamID] = (self.TeamSpawnCounts[teamID] or 0) + 1

	local slot = self.TeamSpawnCounts[teamID]
	local placeAnchor = findNearbySafeSpawn(anchor) or anchor
	self.TeamSpawns[teamID] = placeAnchor

	local placedPos = hg.tpPlayer(placeAnchor, ply, slot, 0)
	if isvector(placedPos) and isSafeSpawnPos(placedPos, ply) then
		return
	end

	local groundedPlacedPos = isvector(placedPos) and findNearbySafeSpawn(placedPos) or nil
	if groundedPlacedPos and isSafeSpawnPos(groundedPlacedPos, ply) then
		ply:SetPos(groundedPlacedPos)
		return
	end

	local fallback = findNearbySafeSpawn(zb:GetRandomSpawn())
	if fallback and isSafeSpawnPos(fallback, ply) then
		ply:SetPos(fallback)
	end
end

function MODE:OverrideBalance()
	return true
end

function MODE:GetTargetTeamSizes(playerCount)
	local targets = {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}

	local distributionOrder = {VORT_TEAM, 0, 1}
	for index = 1, playerCount do
		local teamID = distributionOrder[((index - 1) % #distributionOrder) + 1]
		targets[teamID] = targets[teamID] + 1
	end

	return targets
end

function MODE:ApplyVortBattleState(ply)
	if not IsValid(ply) or ply:Team() ~= VORT_TEAM then return end

	ply:SetNWBool("ZC_HL3_Vort", true)
	ply:SetNWInt("ZC_HL3_VortHealthCap", VORT_HEALTH_CAP)
	ply:SetNWInt("ZC_HL3_VortArmorCap", VORT_ARMOR_CAP)

	if ply.SetMaxHealth then
		ply:SetMaxHealth(VORT_HEALTH_CAP)
	end

	ply:SetHealth(VORT_START_HEALTH)
	ply:SetArmor(VORT_START_ARMOR)
	ply.ZCHL3NextRegenAt = CurTime() + VORT_REGEN_DELAY
end

function MODE:ClearVortBattleState(ply)
	if not IsValid(ply) then return end

	ply:SetNWBool("ZC_HL3_Vort", false)
	ply:SetNWInt("ZC_HL3_VortHealthCap", 0)
	ply:SetNWInt("ZC_HL3_VortArmorCap", 0)
	ply.ZCHL3NextRegenAt = nil
end

function MODE:AssignTeams()
	local players = {}
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		players[#players + 1] = ply
	end

	shuffle(players)

	local teamCounts = {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}
	local teamTargets = self:GetTargetTeamSizes(#players)

	self.VortIndices = {}

	for _, ply in ipairs(players) do
		local targetTeam = VORT_TEAM
		local highestNeed = -math.huge

		for _, teamID in ipairs({VORT_TEAM, 0, 1}) do
			local need = teamTargets[teamID] - teamCounts[teamID]
			if need > highestNeed then
				highestNeed = need
				targetTeam = teamID
			end
		end

		ply:SetTeam(targetTeam)
		teamCounts[targetTeam] = teamCounts[targetTeam] + 1

		if targetTeam == VORT_TEAM then
			self.VortIndices[ply] = teamCounts[targetTeam]
		end
	end
end

util.AddNetworkString("hl3_start")
function MODE:Intermission()
	game.CleanUpMap()

	self:AssignTeams()
	self:PrepareTeamSpawns()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:SetupTeam(ply:Team())
		self:PlacePlayerAtTeamSpawn(ply)
	end

	net.Start("hl3_start")
	net.Broadcast()
end

function MODE:GiveEquipment()
	timer.Simple(0.1, function()
		local elites = 1
		local medics = 1
		local grenadiers = 1
		local shotgunners = 1
		local snipersC = 1
		local snipersR = 1

		local playersAlive = zb:CheckPlaying()
		local leader = false

		for _, ply in RandomPairs(playersAlive) do
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true
			ply.subClass = nil
			ply.leader = nil
			ply:SetNWString("PlayerRole", "")

			if ply:Team() == VORT_TEAM then
				ply:SetNWString("PlayerRole", "Vortigaunt")
				ply:SetPlayerClass("Vortigaunt")
				ply:StripWeapons()
				ply:SetModel(VORT_MODEL)
				ply:SetNetVar("Accessories", "")
				self:ClearVortBattleState(ply)
				local beam = ply:Give("vort_swep")
				local hands = ply:Give("weapon_hands_sh")
				self:ApplyVortBattleState(ply)
				if IsValid(beam) then
					ply:SelectWeapon("vort_swep")
				elseif IsValid(hands) then
					ply:SelectWeapon("weapon_hands_sh")
				end
			else
				self:ClearVortBattleState(ply)
				local hands = ply:Give("weapon_hands_sh")
				if IsValid(hands) then
					ply:SelectWeapon("weapon_hands_sh")
				end

				if ply:Team() == 1 then
					if elites > 0 and not ply.subClass then
						elites = elites - 1
						ply.subClass = "elite"
						if not leader then
							ply.leader = true
							ply:SetNWString("PlayerRole", "Elite")
							leader = true
						end
					end

					if shotgunners > 0 and not ply.subClass then
						shotgunners = shotgunners - 1
						ply.subClass = "shotgunner"
						ply:SetNWString("PlayerRole", "Shotgunner")
					end

					if snipersC > 0 and (#playersAlive > 6) and not ply.subClass then
						snipersC = snipersC - 1
						ply.subClass = "sniper"
						local points = zb.GetMapPoints("HL2DM_SNIPERSPAWN")
						if #points > 0 then
							ply:SetPos(points[math.random(#points)].pos)
						end
					end
				else
					if medics > 0 and not ply.subClass then
						medics = medics - 1
						ply.subClass = "medic"
					end

					if grenadiers > 0 and (#playersAlive > 6) and not ply.subClass then
						grenadiers = grenadiers - 1
						ply.subClass = "grenadier"
					end

					if snipersR > 0 and (#playersAlive > 6) and not ply.subClass then
						snipersR = snipersR - 1
						ply.subClass = "sniper"
						local points = zb.GetMapPoints("HL2DM_CROSSBOWSPAWN")
						if #points > 0 then
							ply:SetPos(points[math.random(#points)].pos)
						end
					end
				end

				local inv = ply:GetNetVar("Inventory", {})
				inv["Weapons"] = inv["Weapons"] or {}
				inv["Weapons"]["hg_sling"] = true
				ply:SetNetVar("Inventory", inv)

				ply:SetPlayerClass(ply:Team() == 1 and "Combine" or "Rebel")
			end

			timer.Simple(0.1, function()
				if not IsValid(ply) then return end

				if ply:Team() == VORT_TEAM then
					self:ApplyVortBattleState(ply)
					if ply:HasWeapon("vort_swep") then
						ply:SelectWeapon("vort_swep")
					end
				end

				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
	self.ZCHL3NextRegenThink = self.ZCHL3NextRegenThink or 0
	if self.ZCHL3NextRegenThink > CurTime() then return end

	self.ZCHL3NextRegenThink = CurTime() + VORT_REGEN_INTERVAL

	local aliveVorts = {}
	for _, ply in player.Iterator() do
		if isLiveVort(ply) then
			aliveVorts[#aliveVorts + 1] = ply
		end
	end

	for _, ply in ipairs(aliveVorts) do
		if (ply.ZCHL3NextRegenAt or 0) > CurTime() then continue end

		local healthCap = ply:GetNWInt("ZC_HL3_VortHealthCap", VORT_HEALTH_CAP)
		local armorCap = ply:GetNWInt("ZC_HL3_VortArmorCap", VORT_ARMOR_CAP)
		if ply:Health() >= healthCap and ply:Armor() >= armorCap then continue end

		local supportBonus = 0
		for _, other in ipairs(aliveVorts) do
			if other == ply then continue end
			if other:GetPos():DistToSqr(ply:GetPos()) <= VORT_SUPPORT_RADIUS_SQR then
				supportBonus = 1
				break
			end
		end

		if ply:Health() < healthCap then
			ply:SetHealth(math.min(healthCap, ply:Health() + VORT_REGEN_HEALTH + supportBonus * VORT_SUPPORT_HEALTH_BONUS))
		end

		if ply:Armor() < armorCap then
			ply:SetArmor(math.min(armorCap, ply:Armor() + VORT_REGEN_ARMOR + supportBonus * VORT_SUPPORT_ARMOR_BONUS))
		end
	end
end

function MODE:EntityTakeDamage(target, dmgInfo)
	local ply = resolvePlayerEntity(target)
	if not isLiveVort(ply) then return end
	if not dmgInfo or (dmgInfo.GetDamage and dmgInfo:GetDamage() <= 0) then return end

	ply.ZCHL3NextRegenAt = CurTime() + VORT_REGEN_DELAY
end

function MODE:PlayerDeath(ply)
	if not IsValid(ply) then return end
	ply.ZCHL3NextRegenAt = nil
end

util.AddNetworkString("hl3_roundend")
function MODE:EndRound()
	local endround, winnerteam = zb:CheckWinner(self:CheckAlivePlayers())
	if not endround then
		winnerteam = 4
	end

	self:ClearPlayerRoles()
	for _, ply in player.Iterator() do
		self:ClearVortBattleState(ply)
	end

	timer.Simple(2, function()
		net.Start("hl3_roundend")
		net.WriteInt(winnerteam or 4, 3)
		net.Broadcast()
	end)
end

local MODE = MODE

local defaultSpawnClasses = {
    "info_player_deathmatch", "info_player_combine", "info_player_rebel",
    "info_player_counterterrorist", "info_player_terrorist", "info_player_axis",
    "info_player_allies", "gmod_player_start", "info_player_teamspawn",
    "ins_spawnpoint", "aoc_spawnpoint", "dys_spawn_point", "info_player_pirate",
    "info_player_viking", "info_player_knight", "diprip_start_team_blue", "diprip_start_team_red",
    "info_player_red", "info_player_blue", "info_player_coop", "info_player_human", "info_player_zombie",
    "info_player_zombiemaster", "info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"
}

local function addUniqueSpawn(target, pos, seen)
    if not isvector(pos) then return end

    local key = tostring(pos)
    if seen[key] then return end

    seen[key] = true
    target[#target + 1] = pos
end

function MODE:GetDefaultSpawnVectors()
    local spawns = {}
    local seen = {}

    for _, ent in ipairs(ents.FindByClass("info_player_start")) do
        addUniqueSpawn(spawns, ent:GetPos(), seen)
    end

    for _, className in ipairs(defaultSpawnClasses) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            addUniqueSpawn(spawns, ent:GetPos(), seen)
        end
    end

    if #spawns == 0 then
        local mappedSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("Spawnpoint") or {})
        for _, pos in ipairs(mappedSpawns) do
            addUniqueSpawn(spawns, pos, seen)
        end
    end

    return spawns
end

function MODE:CanLaunch()
    return #self:GetDefaultSpawnVectors() > 0
end

function MODE:Intermission()
    game.CleanUpMap()

    self.SpawnPoints = self:GetDefaultSpawnVectors()

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end

        ApplyAppearance(ply)
        ply:SetupTeam((ply:Team() == 1) and 1 or 0)
    end
end

function MODE:GetTeamSpawn()
    local spawnPoints = self.SpawnPoints
    if not istable(spawnPoints) or #spawnPoints == 0 then
        spawnPoints = self:GetDefaultSpawnVectors()
    end

    return spawnPoints, spawnPoints
end

function MODE:CheckAlivePlayers()
    return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
    local roundTime = self.ROUND_TIME or 2700

    if not self.SandboxRoundEndTime then
        local roundStart = zb and zb.ROUND_START or CurTime()
        self.SandboxRoundEndTime = roundStart + roundTime
    end

    if CurTime() >= self.SandboxRoundEndTime then
        return true
    end

    return
end

function MODE:RoundStart()
    local roundTime = self.ROUND_TIME or 2700
    self.SandboxRoundEndTime = CurTime() + roundTime

    if hg and hg.UpdateRoundTime then
        hg.UpdateRoundTime(roundTime, CurTime(), CurTime())
    end

    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end

        ply:SetSuppressPickupNotices(true)
        ply.noSound = true
        ply:StripWeapons()
        ply:RemoveAllAmmo()

        local hands = ply:Give("weapon_hands_sh")
        if IsValid(hands) then
            ply:SelectWeapon("weapon_hands_sh")
        end

        if ply.organism then
            ply.organism.allowholster = true
        end

        zb.GiveRole(ply, "Sandbox Player", Color(244, 197, 66))

        timer.Simple(0.1, function()
            if not IsValid(ply) then return end

            ply.noSound = false
            ply:SetSuppressPickupNotices(false)
        end)
    end
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

function MODE:RoundThink()
end

function MODE:CanSpawn()
end

function MODE:EndRound()
    self.SandboxRoundEndTime = nil
end

function MODE:PlayerDeath()
end

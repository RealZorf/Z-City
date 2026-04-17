local MODE = MODE

local TEAM_GERMAN = 0
local TEAM_AMERICAN = 1

local teamData = {
    [TEAM_GERMAN] = {
        role = "German Forces",
        color = Color(120, 105, 85),
        model = "models/player/dod_german.mdl",
        radio = function()
            return math.Round(math.Rand(100, 108), 1)
        end,
    },
    [TEAM_AMERICAN] = {
        role = "American Forces",
        color = Color(70, 120, 85),
        model = "models/player/dod_american.mdl",
        radio = function()
            return math.Round(math.Rand(88, 95), 1)
        end,
    },
}

local modelWarnings = {}

local function IsWW2Round()
    if not CurrentRound then return false end

    local mode = CurrentRound()
    return mode and mode.name == "ww2"
end

local function GetTeamInfo(ply)
    return teamData[ply:Team()] or teamData[TEAM_GERMAN]
end

local function ApplyTeamModel(ply, info)
    if not IsValid(ply) or not info or not info.model then return end

    if util.IsValidModel and not util.IsValidModel(info.model) then
        if not modelWarnings[info.model] then
            print("[WW2] Model was not reported as valid, trying anyway: " .. info.model)
            modelWarnings[info.model] = true
        end
    end

    if util.PrecacheModel then
        pcall(util.PrecacheModel, info.model)
    end

    ply:SetModel(info.model)
    ply:SetPlayerColor(Vector(1, 1, 1))
    ply:SetNetVar("Accessories", "none")
    ply:SetSubMaterial()
    ply:SetSkin(0)
    ply:SetBodyGroups("00000000000000000000")
end

local function ApplyTeamModelDelayed(ply, info)
    if not IsWW2Round() then return end

    ApplyTeamModel(ply, info)

    timer.Simple(0.25, function()
        if not IsWW2Round() then return end

        ApplyTeamModel(ply, info)
    end)

    timer.Simple(1, function()
        if not IsWW2Round() then return end

        ApplyTeamModel(ply, info)
    end)

    timer.Simple(3.25, function()
        if not IsWW2Round() then return end

        ApplyTeamModel(ply, info)
    end)
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        for _, ply in player.Iterator() do
            if not ply:Alive() then continue end

            local inv = ply:GetNetVar("Inventory") or {}
            inv["Weapons"] = inv["Weapons"] or {}
            inv["Weapons"]["hg_sling"] = true
            ply:SetNetVar("Inventory", inv)

            ply:SetSuppressPickupNotices(true)
            ply.noSound = true

            local info = GetTeamInfo(ply)
            ply:SetPlayerClass()
            ApplyTeamModelDelayed(ply, info)
            zb.GiveRole(ply, info.role, info.color)
            ply:SetNetVar("CurPluv", "pluv")

            ply:Give("weapon_melee")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_tourniquet")
            ply.organism.allowholster = true

            local Radio = ply:Give("weapon_walkie_talkie")
            Radio.Frequency = info.radio()

            ply:Give("weapon_hands_sh")
            ply:SelectWeapon("weapon_hands_sh")

            timer.Simple(0.1, function()
                if IsValid(ply) then
                    ply.noSound = false
                end
            end)

            ply:SetSuppressPickupNotices(false)
        end
    end)
end

hook.Add("PlayerSpawn", "ZB_WW2_ApplyTeamModel", function(ply)
    timer.Simple(0.25, function()
        if not IsValid(ply) or not IsWW2Round() then return end

        ApplyTeamModelDelayed(ply, GetTeamInfo(ply))
    end)
end)

local nextModelCheck = 0
hook.Add("Think", "ZB_WW2_KeepTeamModels", function()
    if nextModelCheck > CurTime() then return end
    nextModelCheck = CurTime() + 1

    if not IsWW2Round() then return end

    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end

        local info = GetTeamInfo(ply)
        if ply:GetModel() == info.model then continue end

        ApplyTeamModel(ply, info)
    end
end)

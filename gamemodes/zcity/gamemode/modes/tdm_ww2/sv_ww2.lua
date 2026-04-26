local MODE = MODE

local TEAM_GERMAN = 0
local TEAM_AMERICAN = 1

local teamData = {
    [TEAM_GERMAN] = {
        role = "German Forces",
        color = Color(120, 105, 85),

        models = {
            "models/wehrmacht_male01v1pm.mdl",
            "models/wehrmacht_male02v1pm.mdl",
            "models/wehrmacht_male03v1pm.mdl",
            "models/wehrmacht_male04v1pm.mdl",
            "models/wehrmacht_male05v1pm.mdl",
            "models/wehrmacht_male06v1pm.mdl",
            "models/wehrmacht_male07v1pm.mdl",
            "models/wehrmacht_male08v1pm.mdl",
            "models/wehrmacht_male09v1pm.mdl",
        },

        bodygroups = {
            [0] = 0, 
            [1] = 0, 
            [2] = 3, 
            [3] = 0,
            [4] = 0, 
            [5] = 0, 
            [6] = 0, 
            [7] = 0,
            [8] = 0, 
            [9] = 0, 
            [10] = 0, 
            [11] = 0,
        },

        radio = function()
            return math.Round(math.Rand(100, 108), 1)
        end,
    },

    [TEAM_AMERICAN] = {
        role = "American Forces",
        color = Color(70, 120, 85),

        models = {
            "models/normandyusmc1pm.mdl",
            "models/normandyusmc2pm.mdl",
            "models/normandyusmc3pm.mdl",
            "models/normandyusmc4pm.mdl",
            "models/normandyusmc5pm.mdl",
            "models/normandyusmc6pm.mdl",
            "models/normandyusmc7pm.mdl",
            "models/normandyusmc8pm.mdl",
            "models/normandyusmc9pm.mdl",
        },

        bodygroups = {
            [0] = 0, 
            [1] = 0, 
            [2] = 0,
            [3] = 4, 
            [4] = 0, 
            [5] = 1,
        },

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

local function PickModel(info)
    if not info or not info.models or #info.models == 0 then return nil end
    return table.Random(info.models)
end

local function ApplyBodygroups(ply, info)
    if not info or not info.bodygroups then return end

    for k, v in pairs(info.bodygroups) do
        if isnumber(k) and isnumber(v) then
            ply:SetBodygroup(k, v)
        end
    end
end

local function ApplyTeamModel(ply, info)
    if not IsValid(ply) or not info then return end

    -- assign model once per life
    if not ply.ZB_AssignedModel then
        ply.ZB_AssignedModel = PickModel(info)
    end

    local model = ply.ZB_AssignedModel
    if not model then return end

    if util.IsValidModel and not util.IsValidModel(model) then
        if not modelWarnings[model] then
            print("[WW2] Invalid model detected: " .. model)
            modelWarnings[model] = true
        end
    end

    if util.PrecacheModel then
        pcall(util.PrecacheModel, model)
    end

    ply:SetModel(model)
    ply:SetPlayerColor(Vector(1, 1, 1))
    ply:SetNetVar("Accessories", "none")
    ply:SetSubMaterial()
    ply:SetSkin(0)

    ApplyBodygroups(ply, info)
end

local function ApplyTeamModelDelayed(ply, info)
    if not IsWW2Round() then return end

    ApplyTeamModel(ply, info)

    timer.Simple(0.25, function()
        if IsValid(ply) and IsWW2Round() then
            ApplyTeamModel(ply, info)
        end
    end)

    timer.Simple(1, function()
        if IsValid(ply) and IsWW2Round() then
            ApplyTeamModel(ply, info)
        end
    end)

    timer.Simple(3.25, function()
        if IsValid(ply) and IsWW2Round() then
            ApplyTeamModel(ply, info)
        end
    end)
end

hook.Add("PlayerSpawn", "ZB_WW2_ApplyTeamModel", function(ply)
    timer.Simple(0.25, function()
        if not IsValid(ply) or not IsWW2Round() then return end
        ply.ZB_AssignedModel = nil
        ApplyTeamModelDelayed(ply, GetTeamInfo(ply))
    end)
end)

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        for _, ply in player.Iterator() do
            if not IsValid(ply) or not ply:Alive() then continue end

            ply.ZB_AssignedModel = nil

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
            if IsValid(Radio) then
                Radio.Frequency = info.radio()
            end

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
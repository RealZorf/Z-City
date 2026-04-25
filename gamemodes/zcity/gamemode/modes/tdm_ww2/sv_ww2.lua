local MODE = MODE

local TEAM_GERMAN = 0
local TEAM_AMERICAN = 1

local teamData = {
    [TEAM_GERMAN] = {
        role = "German Forces",
        color = Color(120, 105, 85),
        models = {
            -- NEW
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
        radio = function()
            return math.Round(math.Rand(100, 108), 1)
        end,
    },

    [TEAM_AMERICAN] = {
        role = "American Forces",
        color = Color(70, 120, 85),
        models = {
            -- NEW
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
        radio = function()
            return math.Round(math.Rand(88, 95), 1)
        end,
    },
}

-- 🔥 YOUR ORIGINAL BODYGROUP SYSTEM
local baseBodygroups = {
    german_infantry = {

        [0] = 0, -- wehrmacht_male01
        [1] = 0, -- hands
        [2] = 3, -- Helmet
        [3] = 0, -- Coat
        [4] = 0, -- goggles
        [5] = 0, -- shemagh
        [6] = 0, -- Grenades
        [7] = 0, -- Uniforminsignia
        [8] = 0, -- Scarf
        [9] = 0, -- Gasmask
        [10] = 0, -- Rank
        [11] = 0, -- Gear
    },

    american_infantry = {
        [0] = 0, -- soldier
        [1] = 0, -- hand
        [2] = 0, -- body
        [3] = 4, -- Helmet
        [4] = 0, -- Gear
        [5] = 1, -- Beach_Gear
    }
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

local function GetPlayerModel(ply, info)
    local list = info.models
    if not list or #list == 0 then return nil end

    local seed = util.CRC(ply:SteamID64() or tostring(ply:EntIndex()))
    local index = (tonumber(seed) % #list) + 1

    return list[index]
end

local function ApplyBodygroups(ply, model)
    local groups

    if string.find(model, "wehrmacht") then
        groups = baseBodygroups.german_infantry

    elseif string.find(model, "usmc") or string.find(model, "american") then
        groups = baseBodygroups.american_infantry
    end

    if not groups then return end

    for id, value in pairs(groups) do
        ply:SetBodygroup(id, value)
    end
end

local function ApplyTeamModel(ply, info)
    if not IsValid(ply) or not info then return end

    local model = GetPlayerModel(ply, info)
    if not model then return end

    if util.IsValidModel and not util.IsValidModel(model) then
        if not modelWarnings[model] then
            print("[WW2] Model invalid, forcing anyway: " .. model)
            modelWarnings[model] = true
        end
    end

    if util.PrecacheModel then
        pcall(util.PrecacheModel, model)
    end

    ply:SetModel(model)

    ApplyBodygroups(ply, model)

    ply:SetPlayerColor(Vector(1, 1, 1))
    ply:SetNetVar("Accessories", "none")
    ply:SetSubMaterial()
    ply:SetSkin(0)
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
        local expectedModel = GetPlayerModel(ply, info)

        if expectedModel and ply:GetModel() ~= expectedModel then
            ApplyTeamModel(ply, info)
        else
            ApplyBodygroups(ply, expectedModel)
        end
    end
end)
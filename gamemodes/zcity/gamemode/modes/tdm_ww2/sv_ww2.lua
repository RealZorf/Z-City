local MODE = MODE

local TEAM_GERMAN = 0
local TEAM_AMERICAN = 1

local teamOfficer = {
    [TEAM_GERMAN] = nil,
    [TEAM_AMERICAN] = nil,
}

local teamData = {
    [TEAM_GERMAN] = {
        role = "German Forces",
        color = Color(120, 105, 85),
        infantry = {
            "models/germans/infantry/m38_s2_01.mdl",
            "models/germans/infantry/m38_s2_02.mdl",
            "models/germans/infantry/m38_s2_03.mdl",
            "models/germans/infantry/m38_s2_04.mdl",
            "models/germans/infantry/m38_s2_05.mdl",
            "models/germans/infantry/m38_s2_06.mdl",
        },
        officer = "models/germans/officer/m38_s1_02.mdl",
        radio = function()
            return math.Round(math.Rand(100, 108), 1)
        end,
    },

    [TEAM_AMERICAN] = {
        role = "American Forces",
        color = Color(70, 120, 85),
        infantry = {
            "models/americans/infantry/m41_s1_01.mdl",
            "models/americans/infantry/m41_s1_02.mdl",
            "models/americans/infantry/m41_s1_03.mdl",
            "models/americans/infantry/m41_s1_04.mdl",
            "models/americans/infantry/m41_s1_05.mdl",
            "models/americans/infantry/m41_s1_06.mdl",
        },
        officer = "models/americans/officer/m37_s1_01.mdl",
        radio = function()
            return math.Round(math.Rand(88, 95), 1)
        end,
    },
}

local baseBodygroups = {
    german_infantry = {
        [0] = 0, -- Soldat
        [1] = 5, -- headgear
        [2] = 0, -- helmet decals
        [3] = 0, -- helmet accessory
        [4] = 0, -- helmet paints
        [5] = 0, -- facial features
        [6] = 0, -- neck award
        [7] = 0, -- german cross
        [8] = 0, -- iron cross 1st class
        [9] = 0, -- iron cross 2nd class
        [10] = 0, -- tunic
        [11] = 0, -- belt
        [12] = 0, -- trousers
        [13] = 0, -- hands
        [14] = 0, -- Collar Tabs
        [15] = 0, -- rank
        [16] = 0, -- facewear
        [17] = 0, -- entrenchingtools
        [18] = 0, -- backpack
        [19] = 0, -- Binos
        [20] = 0, -- Kit
        [21] = 0, -- mapcase
    },

    german_officer = {
        [0] = 0, -- Soldat
        [1] = 2, -- headgear
        [2] = 0, -- facial features
        [3] = 0, -- neck award
        [4] = 0, -- german cross
        [5] = 0, -- iron cross 1st class
        [6] = 0, -- iron cross 2nd class
        [7] = 0, -- tunic
        [8] = 0, -- aiguilette
        [9] = 0, -- belt
        [10] = 0, -- sidestrap
        [11] = 0, -- trousers
        [12] = 0, -- hands
        [13] = 0, -- Collar Tabs
        [14] = 0, -- sabre
        [15] = 0, -- rank
        [16] = 0, -- facewear
        [17] = 0, -- Binos
        [18] = 0, -- holster
        [19] = 0, -- mapcase
    },

    american_infantry = {
        [0] = 0, -- Soldat
        [1] = 4, -- headgear
        [2] = 0, -- helmet_decal
        [3] = 0, -- tunic
        [4] = 0, -- trousers
        [5] = 0, -- hands
        [6] = 0, -- facewear
        [7] = 0, -- flashlight
        [8] = 0, -- watch
        [9] = 0, -- kit
        [10] = 0, -- extragear
        [11] = 0, -- backpack
    },

    american_officer = {
        [0] = 0, -- Soldat
        [1] = 4, -- headgear
        [2] = 0, -- rank
        [3] = 0, -- tunic
        [4] = 0, -- trousers
        [5] = 0, -- hands
        [6] = 0, -- facewear
        [7] = 0, -- flashlight
        [8] = 0, -- watch
        [9] = 0, -- kit
        [10] = 0, -- backpack
    }
}

local modelWarnings = {}

local function IsWW2Round()
    if not CurrentRound then return false end
    local mode = CurrentRound()
    return mode and mode.name == "ww2"
end

local function AssignOfficers()
    for teamID, _ in pairs(teamData) do
        local candidates = {}

        for _, ply in player.Iterator() do
            if ply:Team() == teamID and ply:Alive() then
                table.insert(candidates, ply)
            end
        end

        teamOfficer[teamID] = (#candidates > 0) and table.Random(candidates) or nil
    end
end

local function GetTeamInfo(ply)
    return teamData[ply:Team()] or teamData[TEAM_GERMAN]
end

local function GetInfantryModel(ply, info)
    local list = info.infantry
    if not list or #list == 0 then return info.officer end

    local seed = util.CRC(ply:SteamID64() or tostring(ply:EntIndex()))
    local index = (tonumber(seed) % #list) + 1

    return list[index]
end

-- 🪖 SMART BODYGROUP APPLIER
local function ApplyBodygroups(ply, model, role)
    local groups

    if string.find(model, "germans") then
        groups = (role == "officer") and baseBodygroups.german_officer or baseBodygroups.german_infantry
    elseif string.find(model, "americans") then
        groups = (role == "officer") and baseBodygroups.american_officer or baseBodygroups.american_infantry
    end

    if not groups then return end

    for id, value in pairs(groups) do
        ply:SetBodygroup(id, value)
    end
end

local function ApplyTeamModel(ply, info)
    if not IsValid(ply) or not info then return end

    local teamID = ply:Team()
    local isOfficer = teamOfficer[teamID] == ply

    local model, role

    if isOfficer then
        model = info.officer
        role = "officer"
    else
        model = GetInfantryModel(ply, info)
        role = "infantry"
    end

    if util.IsValidModel and not util.IsValidModel(model) then
        if not modelWarnings[model] then
            print("[WW2] Invalid model but applying anyway: " .. model)
            modelWarnings[model] = true
        end
    end

    if util.PrecacheModel then
        pcall(util.PrecacheModel, model)
    end

    ply:SetModel(model)

    -- 🎯 ALWAYS APPLY CORRECT BODYGROUPS
    ApplyBodygroups(ply, model, role)

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
        AssignOfficers()

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

        local isOfficer = teamOfficer[ply:Team()] == ply
        local expectedModel = isOfficer and info.officer or GetInfantryModel(ply, info)
        local role = isOfficer and "officer" or "infantry"

        if ply:GetModel() ~= expectedModel then
            ApplyTeamModel(ply, info)
        else
            -- 🔧 keep bodygroups synced even if model is correct
            ApplyBodygroups(ply, expectedModel, role)
        end
    end
end)
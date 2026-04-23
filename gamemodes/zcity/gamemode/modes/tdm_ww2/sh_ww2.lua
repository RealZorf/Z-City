local MODE = MODE

MODE.base = "cstrike"

MODE.PrintName = "World War II Frontline"
MODE.name = "ww2"
MODE.Description = "German and American squads fight through bomb and rescue objectives with period weapons and limited field equipment."
MODE.BombSiteLabel = "TARGET"
MODE.SiteInsideText = "On objective!"
MODE.HostageZoneLabel = "EXTRACTION ZONE"
MODE.SkipSpawnAppearance = true
MODE.ThemeMusicFile = "tdm_ww2_theme.mp3"
MODE.ThemeMusicVolume = 0.60
MODE.BuyMenuTheme = {
    Background = Color(0, 18, 28, 165),
    InnerBackground = Color(3, 30, 44, 145),
    Outline = Color(137, 207, 240, 185),
    Gradient = Color(137, 207, 240, 75),
    AttachmentGradient = Color(165, 225, 245, 70),
}

MODE.TeamNames = {
    [0] = "German Forces",
    [1] = "American Forces",
    [3] = "Nobody",
}

MODE.BuyItems = {}

local TEAM_GERMAN = 0
local TEAM_AMERICAN = 1

local priority = 1
local function AddItemToBUY(ItemName, Type, ItemClass, Price, Category, Attachments, Amount, TeamBased)
    if not MODE.BuyItems[Category] then
        MODE.BuyItems[Category] = {}
        MODE.BuyItems[Category].Priority = priority
        priority = priority + 1
    end

    MODE.BuyItems[Category][ItemName] = {
        Type = Type,
        ItemClass = ItemClass,
        Price = Price,
        Category = Category,
        Attachments = Attachments or {},
        Amount = Amount,
        TeamBased = TeamBased,
    }
end

-- Pistols
AddItemToBUY("Walther P38", "Weapon", "weapon_p38", 450, "Pistols", {}, nil, TEAM_GERMAN)
AddItemToBUY("Colt M1911", "Weapon", "weapon_m1911", 400, "Pistols", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Walther PPK", "Weapon", "weapon_ppk", 350, "Pistols", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Mauser M712", "Weapon", "weapon_m712", 700, "Pistols", {}, nil, TEAM_GERMAN)

-- Sniper
AddItemToBUY("Karabiner 98k", "Weapon", "weapon_kar98", 2100, "Sniper", {"optic12"}, nil, TEAM_GERMAN)
AddItemToBUY("Gewehr 43", "Weapon", "weapon_gewehr43", 2600, "Sniper", {}, nil, TEAM_GERMAN)
AddItemToBUY("L42A1", "Weapon", "weapon_l42a1", 2500, "Sniper", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Mosin-Nagant", "Weapon", "weapon_mosin", 2100, "Sniper", {}, nil, TEAM_AMERICAN)

-- Assault rifles
AddItemToBUY("FG 42", "Weapon", "weapon_fg42", 3200, "Assault Rifles", {}, nil, TEAM_GERMAN)
AddItemToBUY("M14", "Weapon", "weapon_m14", 3200, "Assault Rifles", {}, nil, TEAM_AMERICAN)

-- Submachine guns
AddItemToBUY("MP40", "Weapon", "weapon_mp40", 1500, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("Suomi KP/-31", "Weapon", "weapon_kp31", 1700, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("MAT-49", "Weapon", "weapon_mat49", 1500, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("PPSh-41", "Weapon", "weapon_ppsh", 1600, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Voere SAM-180", "Weapon", "weapon_sam180", 1800, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Thompson", "Weapon", "weapon_thompson", 1900, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("MPL", "Weapon", "weapon_mpl", 1600, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("M3 Grease Gun", "Weapon", "weapon_m3greasegun", 1300, "Submachine Guns", {}, nil, TEAM_AMERICAN)

-- Rifles and machine guns
AddItemToBUY("Mini-14", "Weapon", "weapon_mini14", 2200, "Rifles", {}, nil, TEAM_AMERICAN)
AddItemToBUY("MG 34", "Weapon", "weapon_mg34", 4500, "MGs", {}, nil, TEAM_GERMAN)

-- Equipment
AddItemToBUY("Stahlhelm", "Armor", "ent_armor_helmet1", 350, "Equipment", {}, nil, TEAM_GERMAN)
AddItemToBUY("Field Helmet", "Armor", "ent_armor_helmet7", 350, "Equipment", {}, nil, TEAM_AMERICAN)

-- Melee
AddItemToBUY("Buck 120 General", "Weapon", "weapon_buck200knife", 300, "Melee", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Spaten", "Weapon", "weapon_hg_crovel", 300, "Melee", {}, nil, TEAM_GERMAN)

-- Medical
AddItemToBUY("Bandage", "Weapon", "weapon_bandage_sh", 200, "Medical", {})
AddItemToBUY("Morphine", "Weapon", "weapon_morphine", 1000, "Medical", {})
AddItemToBUY("Tourniquet", "Weapon", "weapon_tourniquet", 150, "Medical", {})

-- Grenades
AddItemToBUY("Type 59 Grenade", "Weapon", "weapon_hg_type59_tpik", 450, "Grenades", {}, nil, TEAM_GERMAN)
AddItemToBUY("F1 Grenade", "Weapon", "weapon_hg_f1_tpik", 450, "Grenades", {}, nil, TEAM_AMERICAN)

-- Ammo
AddItemToBUY("9x19mm (30)", "Ammo", "ent_ammo_9x19mmparabellum", 75, "Ammo", {}, 30)
AddItemToBUY("9x17mm (30)", "Ammo", "ent_ammo_9x17mm", 75, "Ammo", {}, 30)
AddItemToBUY("7.65x17mm (30)", "Ammo", "ent_ammo_7.65x17mm", 75, "Ammo", {}, 30)
AddItemToBUY("7.62x25mm (30)", "Ammo", "ent_ammo_7.62x25mm", 90, "Ammo", {}, 30)
AddItemToBUY(".45 ACP (30)", "Ammo", "ent_ammo_.45acp", 75, "Ammo", {}, 30)
AddItemToBUY(".357 Magnum (20)", "Ammo", "ent_ammo_.357magnum", 75, "Ammo", {}, 20)
AddItemToBUY(".22 Long Rifle (60)", "Ammo", "ent_ammo_.22longrifle", 50, "Ammo", {}, 60)
AddItemToBUY("5.56x45mm (30)", "Ammo", "ent_ammo_5.56x45mm", 100, "Ammo", {}, 30)
AddItemToBUY("7.62x51mm (20)", "Ammo", "ent_ammo_7.62x51mm", 150, "Ammo", {}, 20)
AddItemToBUY("7.62x54mm (20)", "Ammo", "ent_ammo_7.62x54mm", 100, "Ammo", {}, 20)
AddItemToBUY("7.92x57mm (20)", "Ammo", "ent_ammo_7.92x57mmmauser", 150, "Ammo", {}, 20)

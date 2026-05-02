local MODE = MODE

MODE.base = "dm"

MODE.name = "gravitydm"
MODE.PrintName = "Gravity Deathmatch"
MODE.Description = "A physics-driven free-for-all with a shrinking combat zone. Every player starts with hands, adrenaline, and a gravity gun. Scavenge combat armor, weaponize loose props, and be the last super soldier standing."

MODE.IntroTitle = "Homicide | Gravity Deathmatch"
MODE.IntroRoleName = "Gravity Fighter"
MODE.IntroDescription = "Turn the arena into a weapon. Hurl debris, fight over armor, and survive the collapsing zone."
MODE.IntroObjective = "Kill everyone and be the last super soldier standing."
MODE.IntroColor = Color(110, 160, 255)

MODE.FixedPlayerModel = "models/player/combine_super_soldier.mdl"

MODE.GuaranteedWeapons = {
	"weapon_hands_sh",
	"weapon_adrenaline",
	"weapon_physcannon",
}

MODE.RandomLootEntities = {
	"ent_armor_helmet2",
	"ent_armor_vest7",
}

MODE.MapPropModels = {
	"models/props_c17/oildrum001.mdl",
	"models/props_lab/filecabinet02.mdl",
	"models/props_lab/monitor02.mdl",
}

MODE.MinLootSpawns = 6
MODE.MaxLootSpawns = 10
MODE.MinPropSpawns = 10
MODE.MaxPropSpawns = 16

MODE.LootSpawnHeight = 14
MODE.PropSpawnHeight = 18
MODE.LootSpawnSeparation = 80
MODE.PropSpawnSeparation = 96
MODE.LootSpawnPlayerBuffer = 128
MODE.PropSpawnPlayerBuffer = 160

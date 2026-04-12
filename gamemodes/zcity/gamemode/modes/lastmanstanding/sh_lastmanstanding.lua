local MODE = MODE

MODE.base = "dm"

MODE.name = "lastmanstanding"
MODE.PrintName = "Last Man Standing"
MODE.Description = "Free-for-all survival with a shrinking combat zone. Everyone spawns with a Kar98, a sling, a knife, light armor and a medkit. Players gain 25% extra health and stamina. Be the final survivor."

MODE.IntroTitle = "Homicide | Last Man Standing"
MODE.IntroRoleName = "Survivor"
MODE.IntroDescription = "One life. Limited gear. The zone keeps closing in."
MODE.IntroObjective = "Eliminate everyone and be the only player left alive."
MODE.IntroColor = Color(214, 180, 92)
MODE.ThemeMusicFile = "lastmanstanding_theme.mp3"
MODE.ThemeMusicVolume = 0.35

MODE.HealthMultiplier = 1.25
MODE.StaminaMultiplier = 1.25

MODE.PrimaryWeapon = "weapon_kar98"
MODE.PrimaryTotalAmmo = 50
MODE.MeleeWeapon = "weapon_buck200knife"
MODE.MedicalItem = "weapon_medkit_sh"
MODE.InventoryWeapons = {
	"hg_sling",
}
MODE.Armor = {
	"helmet7",
	"vest1",
}
MODE.PlayerModels = {
	"models/player/dod_american.mdl",
	"models/player/dod_german.mdl",
}

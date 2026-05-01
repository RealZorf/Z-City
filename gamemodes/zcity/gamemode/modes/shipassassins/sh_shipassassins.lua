local homicideMode = zb and zb.modes and zb.modes["hmcd"]

MODE.name = "assassinsgreed"
MODE.PrintName = "Assassin's Greed"
MODE.Description = "Every player is both hunter and hunted. Eliminate your assigned targets to survive to the end."

MODE.Chance = 0.09
MODE.ROUND_TIME = 900
MODE.start_time = 1
MODE.end_time = 7

MODE.randomSpawns = true
MODE.shouldfreeze = true
MODE.PoliceAllowed = false
MODE.OverrideSpawn = true
MODE.LootSpawn = true
MODE.LootOnTime = true
MODE.LootDivTime = 500
MODE.ForBigMaps = true
MODE.GuiltDisabled = true
MODE.ContractDuration = 240
MODE.ContractGraceDuration = 30
MODE.ContractWarningThresholds = {60, 30, 10}

MODE.IntroTitle = "Assassin's Greed"
MODE.IntroRoleName = "Assassin"
MODE.IntroObjective = "Only attack your target or your hunter. Hurting anyone else gets you slain. Each contract lasts 4 minutes, and a successful contract gives you 30 seconds of grace before the next one begins. Contract kills pay $250. Press F3 to buy equipment."
MODE.IntroColor = Color(193, 118, 36)

MODE.AssassinRoleColor = Color(193, 118, 36)
MODE.TargetColor = Color(205, 72, 72)
MODE.HunterColor = Color(90, 145, 215)
MODE.KillRewardMoney = 250
MODE.StartMoney = 0

MODE.ShopItems = {
	{
		id = "pocketknife",
		name = "Pocket Knife",
		class = "weapon_pocketknife",
		price = 100,
		description = "A cheap backup blade."
	},
	{
		id = "bat",
		name = "Bat",
		class = "weapon_bat",
		price = 250,
		description = "A solid blunt weapon for close pressure."
	},
	{
		id = "makarov",
		name = "Makarov Pistol",
		class = "weapon_makarov",
		price = 500,
		description = "A compact pistol for decisive contracts."
	},
	{
		id = "sr25",
		name = "M98B",
		class = "weapon_m98b",
		price = 1000,
		description = "A powerful marksman rifle for long contracts."
	}
}

MODE.LootTable = table.Copy(homicideMode and homicideMode.LootTable or {})
MODE.LootTableStandard = table.Copy(homicideMode and homicideMode.LootTableStandard or {})

function MODE:CanLaunch()
	return true
end

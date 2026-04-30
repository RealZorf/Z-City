MODE.name = "hl3"
MODE.base = "hl2dm"

MODE.PrintName = "Half Life 2: Vortessence War"
MODE.Description = "Three-way faction battle between Combine, Rebels, and Vortigaunts."
MODE.Chance = 0.03
MODE.SkipSpawnAppearance = true
MODE.ForBigMaps = true

function MODE:CanLaunch()
    return true
end

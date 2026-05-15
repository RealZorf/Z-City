local MODE = MODE

MODE.name = "tdmselect"
MODE.PrintName = "Team Deathmatch Vote"
MODE.Description = "Players vote between team deathmatch variants before the round starts."
MODE.Chance = 0.10
MODE.start_time = 10
MODE.ROUND_TIME = 60
MODE.LootSpawn = false
MODE.GuiltDisabled = true

function MODE:CanLaunch()
	return true
end

if SERVER then
	function MODE:Intermission()
		zb.ModeVoteSelect.Start(self.name)
	end

	function MODE:GiveEquipment()
	end

	function MODE:RoundStart()
		if zb.ModeVoteSelect and zb.ModeVoteSelect.Active then
			zb.ModeVoteSelect.Resolve(zb.ModeVoteSelect.Active.id)
		end
	end

	function MODE:ShouldRoundEnd()
		return false
	end

	function MODE:EndRound()
	end
end

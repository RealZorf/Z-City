zb = zb or {}
zb.ModeVoteSelect = zb.ModeVoteSelect or {}

local SELECT = zb.ModeVoteSelect

SELECT.VoteTime = 8
SELECT.SelectorKeys = {
	"hmcdselect",
	"dmselect",
	"tdmselect",
}

SELECT.Configs = SELECT.Configs or {
	hmcdselect = {
		title = "Homicide Vote",
		fallback = "standard",
		options = {
			{key = "standard", name = "Standard", description = "Classic murderer hunt with police escalation."},
			{key = "soe", name = "SOE", description = "Stronger traitor gear and heavier response force."},
			{key = "wildwest", name = "Wild West", description = "Frontier weapons, cowboy chaos, no police backup."},
			{key = "gunfreezone", name = "Gun Free Zone", description = "Low-firearm setup focused on improvised survival."},
		},
	},
	dmselect = {
		title = "Deathmatch Vote",
		fallback = "dm",
		options = {
			{key = "dm", name = "Deathmatch", description = "Free-for-all gunfight with random loadouts."},
			{key = "lastmanstanding", name = "Last Man Standing", description = "One-life survival with fixed gear and a closing zone."},
			{key = "assassinsgreed", name = "Assassin's Greed", description = "Everyone hunts a target while being hunted."},
			{key = "sfd", name = "Superfighters", description = "Free-for-all brawl with unique HP Bar and weapons."},
		},
	},
	tdmselect = {
		title = "Team Deathmatch Vote",
		fallback = "tdm",
		options = {
			{key = "tdm", name = "Team Deathmatch", description = "Two teams buy gear and fight for the round win."},
			{key = "cstrike", name = "Counter-Strike", description = "Bomb, hostage, and economy objectives."},
			{key = "ww2", name = "World War II Frontline", description = "Period weapons with German and American squads."},
			{key = "melee_tdm", name = "Melee TDM", description = "Team combat with melee weapons and support items."},
			{key = "hl2dm", name = "Half-Life 2 Deathmatch", description = "Fast HL2-style arena weapons and movement."},
			{key = "hl3", name = "Half Life 2 Vortessence War", description = "Combine, Rebels, and Vortigaunts in a three-way war."},
		},
	},
}

local selector_lookup = {}
for _, key in ipairs(SELECT.SelectorKeys) do
	selector_lookup[key] = true
end

function SELECT.IsSelector(key)
	return selector_lookup[tostring(key or "")] == true
end

function SELECT.GetSelectorKeys()
	return SELECT.SelectorKeys
end

function SELECT.GetConfig(key)
	return SELECT.Configs[tostring(key or "")]
end

function SELECT.ToSelector(key)
	key = tostring(key or "")
	if key == "" then return nil end
	if SELECT.IsSelector(key) then return key end
	if key == "coop" then return "coop" end

	if key == "standard" or key == "soe" or key == "wildwest" or key == "gunfreezone" then
		return "hmcdselect"
	end

	if key == "dm" or key == "hl2dm" or key == "lastmanstanding" or key == "assassinsgreed" or key == "scugarena" then
		return "dmselect"
	end

	if key == "tdm" or key == "cstrike" or key == "ww2" or key == "melee_tdm" or key == "hl3" then
		return "tdmselect"
	end

	if zb and zb.GetMode then
		local main = zb:GetMode(key)
		if main == "hmcd" then return "hmcdselect" end
		if main == "dm" then return "dmselect" end
		if main == "tdm" or main == "cstrike" or main == "ww2" or main == "melee_tdm" or main == "hl3" then return "tdmselect" end
	end
end

if SERVER then
	util.AddNetworkString("ZB_ModeSelectVoteStart")
	util.AddNetworkString("ZB_ModeSelectVoteCast")
	util.AddNetworkString("ZB_ModeSelectVoteUpdate")
	util.AddNetworkString("ZB_ModeSelectVoteResult")

	local function valid_player(ply)
		return IsValid(ply) and ply:IsPlayer()
	end

	local function player_id(ply)
		if not valid_player(ply) then return "0" end
		if ply:IsBot() then return "bot:" .. ply:EntIndex() end

		local steam_id64 = ply:SteamID64()
		if isstring(steam_id64) and steam_id64 ~= "" and steam_id64 ~= "0" then
			return "steamid64:" .. steam_id64
		end

		return "steamid:" .. tostring(ply:SteamID() or ply:EntIndex())
	end

	local function can_launch_mode(key)
		if not zb or not zb.GetMode or not zb.modes then return false end

		local main = zb:GetMode(key)
		local mode = main and zb.modes[main]
		if not mode then return false end
		if mode.CanLaunch and not mode:CanLaunch() then return false end

		return true
	end

	local function get_available_options(config)
		local out = {}

		for _, option in ipairs(config.options or {}) do
			if istable(option) and isstring(option.key) and option.key ~= "" and can_launch_mode(option.key) then
				out[#out + 1] = {
					key = option.key,
					name = tostring(option.name or option.key),
					description = tostring(option.description or ""),
				}
			end
		end

		return out
	end

	local function pick_winner(active)
		local best = {}
		local best_count = -1

		for index, option in ipairs(active.options or {}) do
			local count = tonumber(active.counts[index]) or 0

			if count > best_count then
				best = {option}
				best_count = count
			elseif count == best_count then
				best[#best + 1] = option
			end
		end

		if #best == 0 then return active.fallback end
		return table.Random(best).key or active.fallback
	end

	local function send_round_info()
		if not CurrentRound then return end

		local mode = CurrentRound()
		if not mode then return end

		net.Start("RoundInfo")
			net.WriteString(mode.name or "hmcd")
			net.WriteInt(zb.ROUND_STATE or 0, 4)
		net.Broadcast()
	end

	local function sync_admin_queue()
		if not zb.GetAllAdmins or not zb.SendRoundListToClient then return end

		for _, admin in ipairs(zb.GetAllAdmins()) do
			if IsValid(admin) then
				zb.SendRoundListToClient(admin)
			end
		end
	end

	local function broadcast_vote_update(active)
		if not active then return end

		net.Start("ZB_ModeSelectVoteUpdate")
			net.WriteString(active.id or "")
			net.WriteUInt(#(active.options or {}), 4)
			for index = 1, #(active.options or {}) do
				net.WriteUInt(math.Clamp(tonumber(active.counts[index]) or 0, 0, 255), 8)
			end
		net.Broadcast()
	end

	function SELECT.Resolve(id)
		local active = SELECT.Active
		if not active or active.id ~= id then return end

		SELECT.Active = nil
		timer.Remove("ZB_ModeSelectVote_" .. id)

		local winner = pick_winner(active)
		if not can_launch_mode(winner) then
			winner = active.fallback
		end

		if not can_launch_mode(winner) then
			winner = "hmcd"
		end

		zb.CROUND = winner
		zb.CROUND_MAIN = nil
		zb.LASTCROUND = nil

		local mode = CurrentRound()
		if not mode then return end

		mode.saved = {}
		zb.START_TIME = CurTime() + math.max(tonumber(mode.start_time) or 5, 1)
		if hg and hg.UpdateRoundTime then
			hg.UpdateRoundTime(mode.ROUND_TIME, CurTime(), zb.START_TIME)
		end
		send_round_info()

		if mode.Intermission then
			mode:Intermission()
		end

		if mode.GiveEquipment then
			mode:GiveEquipment()
		end

		net.Start("ZB_ModeSelectVoteResult")
			net.WriteString(winner)
			net.WriteString(mode.PrintName or winner)
			net.WriteFloat(zb.START_TIME or (CurTime() + 3))
		net.Broadcast()

		PrintMessage(HUD_PRINTTALK, "Vote selected next mode: " .. tostring(mode.PrintName or winner))
		sync_admin_queue()
	end

	function SELECT.Start(selector_key)
		local config = SELECT.GetConfig(selector_key)
		if not config then return false end

		local options = get_available_options(config)
		if #options == 0 and config.fallback and can_launch_mode(config.fallback) then
			options[1] = {
				key = config.fallback,
				name = tostring(config.fallback),
				description = "",
			}
		end
		if #options == 0 then return false end

		local id = tostring(selector_key) .. "_" .. math.floor(CurTime() * 100)
		local duration = SELECT.VoteTime

		SELECT.Active = {
			id = id,
			selector = selector_key,
			title = config.title or "Mode Vote",
			fallback = config.fallback or options[1].key,
			options = options,
			counts = {},
			votes = {},
			ends = CurTime() + duration,
		}

		for i = 1, #options do
			SELECT.Active.counts[i] = 0
		end

		net.Start("ZB_ModeSelectVoteStart")
			net.WriteString(id)
			net.WriteString(SELECT.Active.title)
			net.WriteFloat(SELECT.Active.ends)
			net.WriteUInt(#options, 4)
			for _, option in ipairs(options) do
				net.WriteString(option.key)
				net.WriteString(option.name)
				net.WriteString(option.description or "")
			end
		net.Broadcast()
		broadcast_vote_update(SELECT.Active)

		timer.Create("ZB_ModeSelectVote_" .. id, duration, 1, function()
			SELECT.Resolve(id)
		end)

		return true
	end

	net.Receive("ZB_ModeSelectVoteCast", function(_, ply)
		if not valid_player(ply) then return end

		local id = net.ReadString()
		local index = net.ReadUInt(4)
		local active = SELECT.Active

		if not active or active.id ~= id then return end
		if CurTime() > active.ends then return end
		if index < 1 or index > #(active.options or {}) then return end

		local key = player_id(ply)
		local previous = active.votes[key]
		if previous and active.counts[previous] then
			active.counts[previous] = math.max((active.counts[previous] or 0) - 1, 0)
		end

		active.votes[key] = index
		active.counts[index] = (active.counts[index] or 0) + 1
		broadcast_vote_update(active)
	end)

	timer.Simple(0, function()
		if not zb or not zb.SetRoundList or not zb.RoundList then return end

		local queued = {}
		if isstring(zb.nextround) and zb.nextround ~= "" then
			queued[#queued + 1] = zb.nextround
		end

		for _, round in ipairs(zb.RoundList) do
			queued[#queued + 1] = round
		end

		if #queued > 0 then
			zb.SetRoundList(queued)
		end
	end)
else
	local active_vote

	local function ui(num)
		return math.Round(num * math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.85, 1.2))
	end

	local function close_vote_panel()
		if IsValid(SELECT.Panel) then
			SELECT.Panel:Remove()
		end

		SELECT.Panel = nil
		active_vote = nil
	end

	local function open_vote_panel(id, title, ends, options)
		close_vote_panel()

		active_vote = {
			id = id,
			ends = ends,
			options = options,
			counts = {},
			selected = nil,
			result = nil,
			closeAt = ends + 4,
		}

		local frame = vgui.Create("EditablePanel")
		SELECT.Panel = frame
		frame:SetSize(ScrW(), ScrH())
		frame:SetPos(0, 0)
		frame:MakePopup()
		frame:SetKeyboardInputEnabled(false)
		frame:SetMouseInputEnabled(true)
		frame:SetAlpha(255)
		frame.Think = function()
			if active_vote and active_vote.closeAt and active_vote.closeAt <= CurTime() then
				close_vote_panel()
			end
		end

		local box_w = ui(540)
		local box_h = ui(118 + #options * 62)
		local box_x = ScrW() * 0.5 - box_w * 0.5
		local box_y = ui(72)

		frame.Paint = function(_, w, h)
			local remaining = math.max(math.ceil((active_vote and active_vote.ends or 0) - CurTime()), 0)
			local result = active_vote and active_vote.result
			surface.SetDrawColor(0, 0, 0, 238)
			surface.DrawRect(0, 0, w, h)

			draw.RoundedBox(0, box_x, box_y, box_w, box_h, Color(3, 13, 9, 248))
			surface.SetDrawColor(35, 255, 110, 170)
			surface.DrawOutlinedRect(box_x, box_y, box_w, box_h, 1)
			draw.SimpleText(string.upper(title or "MODE VOTE"), "DermaLarge", box_x + ui(18), box_y + ui(14), Color(230, 245, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			if result then
				draw.SimpleText("SELECTED: " .. string.upper(result), "DermaDefaultBold", box_x + box_w - ui(18), box_y + ui(24), Color(35, 255, 110), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			else
				draw.SimpleText("VOTE ENDS IN " .. remaining .. "S", "DermaDefaultBold", box_x + box_w - ui(18), box_y + ui(24), Color(35, 255, 110), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			end

		end

		for index, option in ipairs(options) do
			local button = vgui.Create("DButton", frame)
			button:SetText("")
			button:SetPos(box_x + ui(18), box_y + ui(68) + (index - 1) * ui(62))
			button:SetSize(box_w - ui(36), ui(52))
			button.Paint = function(panel, w, h)
				local hover = panel:IsHovered() and 1 or 0
				local selected = active_vote and active_vote.selected == index
				local counts = active_vote and active_vote.counts or {}
				local total = 0
				for _, count in pairs(counts) do
					total = total + (tonumber(count) or 0)
				end

				local votes = tonumber(counts[index]) or 0
				local pct = total > 0 and math.floor((votes / total) * 100 + 0.5) or 0
				local bar_w = total > 0 and math.floor(w * (votes / total)) or 0

				draw.RoundedBox(0, 0, 0, w, h, Color(5 + hover * 12, 32 + hover * 18, 18 + hover * 8, 235))
				if bar_w > 0 then
					draw.RoundedBox(0, 0, 0, bar_w, h, Color(35, 255, 110, selected and 78 or 45))
				end

				surface.SetDrawColor(35, 255, 110, selected and 230 or (80 + hover * 90))
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				draw.SimpleText(option.name or option.key, "DermaDefaultBold", ui(14), ui(10), Color(225, 245, 232), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText(option.description or "", "DermaDefault", ui(14), ui(29), Color(150, 205, 168), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText(tostring(votes) .. " (" .. pct .. "%)", "DermaDefaultBold", w - ui(14), h * 0.5, Color(35, 255, 110), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

				if selected then
					draw.SimpleText("YOUR VOTE", "DermaDefaultBold", w - ui(118), h * 0.5, Color(255, 238, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
			end
			button.DoClick = function()
				if active_vote then
					active_vote.selected = index
				end

				net.Start("ZB_ModeSelectVoteCast")
					net.WriteString(id)
					net.WriteUInt(index, 4)
				net.SendToServer()
			end
		end
	end

	net.Receive("ZB_ModeSelectVoteStart", function()
		local id = net.ReadString()
		local title = net.ReadString()
		local ends = net.ReadFloat()
		local count = math.Clamp(net.ReadUInt(4), 0, 12)
		local options = {}

		for i = 1, count do
			options[i] = {
				key = net.ReadString(),
				name = net.ReadString(),
				description = net.ReadString(),
			}
		end

		open_vote_panel(id, title, ends, options)
	end)

	net.Receive("ZB_ModeSelectVoteUpdate", function()
		local id = net.ReadString()
		local count = math.Clamp(net.ReadUInt(4), 0, 12)
		local counts = {}

		for i = 1, count do
			counts[i] = net.ReadUInt(8)
		end

		if not active_vote or active_vote.id ~= id then return end

		active_vote.counts = counts
	end)

	net.Receive("ZB_ModeSelectVoteResult", function()
		local key = net.ReadString()
		local name = net.ReadString()
		if net.BytesLeft and net.BytesLeft() > 0 then
			net.ReadFloat()
		end

		if active_vote then
			active_vote.result = name ~= "" and name or key
			active_vote.closeAt = CurTime() + 2.5
		else
			close_vote_panel()
		end

		chat.AddText(Color(235, 245, 238), "Vote selected ", Color(35, 255, 110), name ~= "" and name or key)
	end)
end

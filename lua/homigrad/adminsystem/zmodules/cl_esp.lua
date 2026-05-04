if !hg or !hg.AdminSystem then return end

local AS = hg.AdminSystem
local ESP = {}

ESP.Enabled = false
ESP.InAdminMode = false
ESP.AllESP = false
ESP.NextToggle = 0

local ESPEye = CreateClientConVar("zb_espeye", "0", true, false, "Show admin ESP eye trace line")

local col_default = Color(255, 0, 0)
local col_gray = Color(180, 180, 180)
local col_weapon = Color(255, 200, 100)
local col_box_outline = Color(0, 0, 0, 200)

local SHOW_TARGET_OUTLINE = true
local SHOW_TARGET_BOX = false

local teamColors = {
	[0] = Color(200, 200, 200),
	[1] = Color(255, 100, 100),
	[2] = Color(100, 150, 255),
	[3] = Color(100, 255, 100),
	[4] = Color(255, 255, 100),
	[1001] = Color(150, 150, 150),
}

-- 🧠 FIX: render check now includes real state
local function CanRenderESP()
	return ESP.Enabled or ESP.AllESP
end

local function GetESPTeamColor(tm)
	local teamCol = team.GetColor(tm)
	if teamCol and (teamCol.r != 255 or teamCol.g != 255 or teamCol.b != 255) then
		return Color(teamCol.r, teamCol.g, teamCol.b, 255)
	end

	if zb and zb.Points then
		for _, pointData in pairs(zb.Points) do
			if pointData.Color and pointData.Team == tm then
				return Color(pointData.Color.r, pointData.Color.g, pointData.Color.b, 255)
			end
		end
	end

	return teamColors[tm] or col_default
end

local function GetPlayerTeamColor(target)
	if !IsValid(target) then return col_default end
	return GetESPTeamColor(target:Team())
end

local UpVector = Vector(0, 0, 80)

-- (weapon function unchanged — it’s fine)

local function ShouldShowPlayer(localPly, target)
	if !IsValid(target) or target == localPly then return false end
	if !target:Alive() then return false end
	if target:Team() == TEAM_SPECTATOR then return false end

	-- 🧠 FIX: actually respect ESP state
	if ESP.AllESP then return true end
	if ESP.Enabled then return true end

	return false
end

local function GetPlayerRenderEntity(target)
	if !IsValid(target) then return nil end

	local ragdoll = target.FakeRagdoll
	if IsValid(ragdoll) then return ragdoll end

	ragdoll = target:GetNWEntity("FakeRagdoll", NULL)
	if IsValid(ragdoll) then return ragdoll end

	return target
end

-- 🧠 FIX: safer box (no instant nil kill on offscreen corner)
local function Get2DBox(ent)
	if !IsValid(ent) then return nil end

	local mins = ent:OBBMins()
	local maxs = ent:OBBMaxs()
	local pos = ent:GetPos()
	local ang = Angle(0, ent:GetAngles().y, 0)

	local corners = {
		Vector(mins.x, mins.y, mins.z),
		Vector(mins.x, maxs.y, mins.z),
		Vector(maxs.x, maxs.y, mins.z),
		Vector(maxs.x, mins.y, mins.z),
		Vector(mins.x, mins.y, maxs.z),
		Vector(mins.x, maxs.y, maxs.z),
		Vector(maxs.x, maxs.y, maxs.z),
		Vector(maxs.x, mins.y, maxs.z)
	}

	local minX, minY = ScrW(), ScrH()
	local maxX, maxY = 0, 0
	local anyVisible = false

	for _, corner in ipairs(corners) do
		local worldPos = LocalToWorld(corner, Angle(0, 0, 0), pos, ang)
		local screen = worldPos:ToScreen()

		if screen.visible then
			anyVisible = true
			minX = math.min(minX, screen.x)
			minY = math.min(minY, screen.y)
			maxX = math.max(maxX, screen.x)
			maxY = math.max(maxY, screen.y)
		end
	end

	if !anyVisible then return nil end

	return minX, minY, maxX - minX, maxY - minY
end

function ESP:SetupNetworking()
	net.Receive("AS_Sync", function()
		ESP.Enabled = net.ReadBool()
		ESP.InAdminMode = net.ReadBool()
		ESP.AllESP = net.ReadBool()
	end)
end

function ESP:SetupHooks()
	hook.Remove("PlayerButtonDown", "AS_ESP_ToggleKey")
	hook.Remove("SetupOutlines", "AS_ESP_Outlines")
	hook.Remove("PreDrawHUD", "AS_ESP_EyeTrace")
	hook.Remove("HUDPaint", "AS_ESP_Draw")

	hook.Add("PlayerButtonDown", "AS_ESP_ToggleKey", function(ply, button)
		if ply != LocalPlayer() then return end
		if button != KEY_O then return end
		if gui.IsGameUIVisible() or vgui.GetKeyboardFocus() then return end
		if RealTime() < ESP.NextToggle then return end

		ESP.NextToggle = RealTime() + 0.3
		RunConsoleCommand("zb_admesp")
	end)

	-- 🧠 FIX: no per-player cam.Start3D spam
	hook.Add("PreDrawHUD", "AS_ESP_EyeTrace", function()
		if !ESPEye:GetBool() then return end
		if !CanRenderESP() then return end

		local localPly = LocalPlayer()

		cam.Start3D()
		for _, target in player.Iterator() do
			if !ShouldShowPlayer(localPly, target) then continue end

			local col = GetPlayerTeamColor(target)

			local eyePos = target:EyePos()
			local dir = target:EyeAngles():Forward()
			local endPos = eyePos + dir * 10000

			render.DrawLine(eyePos, endPos, col, true)
		end
		cam.End3D()
	end)

	hook.Add("HUDPaint", "AS_ESP_Draw", function()
		local ply = LocalPlayer()
		if !CanRenderESP() then return end

		local myPos = ply:GetPos()

		for _, target in player.Iterator() do
			if !ShouldShowPlayer(ply, target) then continue end

			local col = GetPlayerTeamColor(target)
			local ent = GetPlayerRenderEntity(target)
			if !IsValid(ent) then continue end

			local x, y, w, h = Get2DBox(ent)

			if SHOW_TARGET_BOX and x then
				surface.SetDrawColor(col_box_outline)
				surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2, 1)

				surface.SetDrawColor(col)
				surface.DrawOutlinedRect(x, y, w, h, 2)
			end

			local screenPos = (ent:WorldSpaceCenter() + UpVector * 0.25):ToScreen()
			if !screenPos.visible then continue end

			local sx, sy = screenPos.x, screenPos.y
			local dist = math.floor(myPos:Distance(ent:GetPos()) / 52.49)

			draw.SimpleTextOutlined(target:Nick(), "TargetIDSmall",
				sx, sy - 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

			local bottomY = y and (y + h + 5) or (sy + 50)

			draw.SimpleTextOutlined(dist .. " m.", "TargetIDSmall",
				sx, bottomY, col_gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)

			local wep = target:GetActiveWeapon()
			local weaponClass = GetWeaponClass(wep)

			draw.SimpleTextOutlined(weaponClass, "TargetIDSmall",
				sx, bottomY + 14, col_weapon, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
		end
	end)
end

function ESP:Init()
	self:SetupNetworking()
	self:SetupHooks()
end

AS:RegisterModule("esp", ESP)
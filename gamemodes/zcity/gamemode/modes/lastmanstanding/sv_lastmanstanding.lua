local MODE = MODE

local DEFAULT_HEALTH = 100
local DEFAULT_STAMINA = 60 * 3

local function SetInventoryFlag(ply, weaponKey)
	local inv = ply:GetNetVar("Inventory") or {}
	inv.Weapons = inv.Weapons or {}
	inv.Weapons[weaponKey] = true
	ply:SetNetVar("Inventory", inv)
end

local function ApplyPlayerBuffs(mode, ply)
	local healthMultiplier = mode.HealthMultiplier or 1
	local currentMaxHealth = math.max((ply:GetMaxHealth() > 0 and ply:GetMaxHealth()) or DEFAULT_HEALTH, 1)
	local boostedMaxHealth = math.max(1, math.Round(currentMaxHealth * healthMultiplier))

	ply:SetMaxHealth(boostedMaxHealth)
	ply:SetHealth(boostedMaxHealth)

	if not ply.organism or not ply.organism.stamina then return end

	local stamina = ply.organism.stamina
	local staminaBase = math.max(stamina.range or stamina.max or DEFAULT_STAMINA, 1)
	local boostedStamina = math.max(1, math.Round(staminaBase * (mode.StaminaMultiplier or 1)))

	stamina.range = boostedStamina
	stamina.max = boostedStamina
	stamina[1] = boostedStamina
end

local function ApplyPlayerModel(mode, ply, index)
	local models = mode.PlayerModels or {}
	local model = models[((index - 1) % math.max(#models, 1)) + 1]
	if not model or model == "" then return end

	if util.IsValidModel and not util.IsValidModel(model) then return end

	ply:SetModel(model)
end

function MODE:RoundStart()
	local roleName = self.IntroRoleName or "Survivor"
	local roleColor = self.IntroColor or Color(214, 180, 92)
	local modelIndex = 0

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end

		modelIndex = modelIndex + 1

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:StripWeapons()
		ply:RemoveAllAmmo()

		for _, weaponKey in ipairs(self.InventoryWeapons or {}) do
			SetInventoryFlag(ply, weaponKey)
		end

		local primary = ply:Give(self.PrimaryWeapon)
		if IsValid(primary) then
			local totalAmmo = math.max(self.PrimaryTotalAmmo or 0, 0)
			local clipSize = math.max(primary:Clip1(), primary:GetMaxClip1(), 0)
			local reserveAmmo = math.max(totalAmmo - clipSize, 0)
			ply:GiveAmmo(reserveAmmo, primary:GetPrimaryAmmoType(), true)
		end

		if self.MeleeWeapon then
			ply:Give(self.MeleeWeapon)
		end

		if self.MedicalItem then
			ply:Give(self.MedicalItem)
		end

		hg.AddArmor(ply, self.Armor or {})
		ApplyPlayerBuffs(self, ply)
		ApplyPlayerModel(self, ply, modelIndex)

		if ply.organism then
			ply.organism.recoilmul = 0.5
		end

		if self.PrimaryWeapon then
			ply:SelectWeapon(self.PrimaryWeapon)
		end

		zb.GiveRole(ply, roleName, roleColor)
		ply:SetNetVar("CurPluv", "pluvboss")

		timer.Simple(0.1, function()
			if not IsValid(ply) then return end

			ply.noSound = false
			ply:SetSuppressPickupNotices(false)
		end)
	end
end

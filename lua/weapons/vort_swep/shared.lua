if SERVER then
	AddCSLuaFile("shared.lua")

	resource.AddFile("models/weapons/v_vortbeamvm.mdl")
	resource.AddFile("materials/vgui/entities/weapon_vortbeam.vmt")
	resource.AddFile("materials/vgui/entities/swep_vortigaunt_beam.vtf")
	resource.AddFile("materials/vgui/killicons/weapon_vortbeam.vmt")
	resource.AddFile("materials/vgui/killicons/swep_vortigaunt_beam.vtf")

	SWEP.AutoSwitchTo = true
	SWEP.AutoSwitchFrom = true
	util.AddNetworkString("ZC_VortBeamHitFlash")
end

if CLIENT then
	SWEP.DrawAmmo = true
	SWEP.PrintName = "Vort Beam"
	SWEP.Instructions = ""
	SWEP.Author = "HL3"
	SWEP.DrawCrosshair = true
	SWEP.ViewModelFOV = 60

	killicon.Add("vort_swep", "VGUI/killicons/weapon_vortbeam", Color(255, 255, 255))

	net.Receive("ZC_VortBeamHitFlash", function()
		local alpha = 255
		hook.Add("HUDPaint", "RP_VortBeamHitFlash", function()
			alpha = Lerp(0.10, alpha, 0)
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawRect(0, 0, ScrW(), ScrH())

			if math.Round(alpha) == 0 then
				hook.Remove("HUDPaint", "RP_VortBeamHitFlash")
			end
		end)
	end)
end

CreateConVar("vorthands_beamdamage", 360, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE))
CreateConVar("vorthands_beamrange", 1500, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE))
CreateConVar("vorthands_beamchargetime", 1.25, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE))
CreateConVar("vorthands_healdelay", 0.9, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE))
CreateConVar("vorthands_maxarmorheal", 24, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE))
CreateConVar("vorthands_minarmorheal", 14, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE))

SWEP.Category = "Vortigaunt"
SWEP.UseHands = false
SWEP.Slot = 3
SWEP.SlotPos = 5
SWEP.Weight = 5
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/v_vortbeamvm.mdl"
SWEP.WorldModel = ""

SWEP.Range = 2 * 100 * 12
SWEP.DamageForce = 48000
SWEP.HealSound = Sound("NPC_Vortigaunt.SuitOn")
SWEP.HealLoop = Sound("NPC_Vortigaunt.StartHealLoop")
SWEP.AttackLoop = Sound("NPC_Vortigaunt.ZapPowerup")
SWEP.AttackSound = Sound("NPC_Vortigaunt.ClawBeam")
SWEP.Deny = Sound("Buttons.snd19")
SWEP.AllyHealSound = Sound("npc/vort/health_charge.wav")

SWEP.ArmorLimit = 100
SWEP.BeamDamage = 360
SWEP.BeamChargeTime = 1.25
SWEP.BeamCooldown = 0.45
SWEP.HL3BeamDamage = 425
SWEP.HL3BeamCooldown = 0.33
SWEP.HL3SplashRadius = 135
SWEP.HL3SplashDamage = 72
SWEP.AltBeamDamage = 575
SWEP.AltBeamChargeTime = 0.2
SWEP.AltBeamCooldown = 9
SWEP.AltBeamRange = 2200
SWEP.AltDamageForce = 96000
SWEP.ArmorHealDelay = 0.9
SWEP.ArmorHealMin = 14
SWEP.ArmorHealMax = 24
SWEP.AllyHealCooldown = 2.25
SWEP.AllyHealAmountMin = 16
SWEP.AllyHealAmountMax = 28
SWEP.AllyHealRange = 110

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false

local ZAP_PARTICLE = "vortigaunt_beam"
local ALT_ZAP_PARTICLE = "vortigaunt_beam_charge"
local CHARGE_PARTICLE = "vortigaunt_charge_token"
local CHARGE_PARTICLE_A = "vortigaunt_charge_token_b"
local CHARGE_PARTICLE_B = "vortigaunt_charge_token_c"
local IMPACT_EFFECT = "StunstickImpact"
local ALT_IMPACT_EFFECT = "cball_explode"

function SWEP:Initialize()
	self:SetWeaponHoldType("fist")
	self:SetHoldType("fist")

	self.Charging = false
	self.Healing = false
	self.ChargeTime = 0
	self.HealTime = 0
	self.NextBusyClear = 0
	self.ChargeAnimPlayed = false
	self.ChargeKind = nil
	self.LastOwner = nil
	self.NextAllyHealTime = 0

	if CLIENT then return end
	self:CreateSounds()
end

function SWEP:Precache()
	PrecacheParticleSystem(ZAP_PARTICLE)
	PrecacheParticleSystem("vortigaunt_beam_charge")
	PrecacheParticleSystem(CHARGE_PARTICLE_A)
	PrecacheParticleSystem(CHARGE_PARTICLE_B)
	PrecacheParticleSystem(CHARGE_PARTICLE)
	util.PrecacheModel(self.ViewModel)
end

function SWEP:CreateSounds()
	if not self.ChargeSound then
		self.ChargeSound = CreateSound(self, self.AttackLoop)
	end

	if not self.HealingSound then
		self.HealingSound = CreateSound(self, self.HealLoop)
	end
end

function SWEP:IsBusy()
	return self.Charging or self.Healing
end

function SWEP:IsVortOwner(pPlayer)
	return IsValid(pPlayer) and string.lower(pPlayer:GetModel() or "") == "models/player/vortigaunt.mdl"
end

function SWEP:GetBeamSourceData(pPlayer)
	if not IsValid(pPlayer) then return nil end

	local isVort = self:IsVortOwner(pPlayer)

	if CLIENT and pPlayer == LocalPlayer() and not isVort then
		local vm = pPlayer:GetViewModel()
		if IsValid(vm) then
			local vmAttachment = vm:LookupAttachment("muzzle")
			if vmAttachment and vmAttachment > 0 then
				local vmData = vm:GetAttachment(vmAttachment)
				if vmData and vmData.Pos then
					return vmData.Pos, vm:EntIndex(), vmAttachment
				end
			end
		end
	end

	local plyAttachment = pPlayer:LookupAttachment("anim_attachment_RH")
	if not plyAttachment or plyAttachment <= 0 then
		plyAttachment = pPlayer:LookupAttachment("anim_attachment_rh")
	end

	if plyAttachment and plyAttachment > 0 then
		local plyData = pPlayer:GetAttachment(plyAttachment)
		if plyData and plyData.Pos then
			return plyData.Pos, pPlayer:EntIndex(), plyAttachment
		end
	end

	local attachmentBone = pPlayer:LookupBone("ValveBiped.Anim_Attachment_RH")
	if attachmentBone then
		local attachmentMatrix = pPlayer:GetBoneMatrix(attachmentBone)
		if attachmentMatrix then
			local attachmentAng = attachmentMatrix:GetAngles()
			return attachmentMatrix:GetTranslation() + attachmentAng:Forward() * 2, pPlayer:EntIndex(), 0
		end
	end

	local handBone = pPlayer:LookupBone("ValveBiped.Bip01_R_Hand")
	if handBone then
		local handMatrix = pPlayer:GetBoneMatrix(handBone)
		if handMatrix then
			local handAng = handMatrix:GetAngles()
			return handMatrix:GetTranslation() + handAng:Forward() * 8 + handAng:Right() * 2, pPlayer:EntIndex(), 0
		end
	end

	return pPlayer:GetShootPos(), pPlayer:EntIndex(), 0
end

function SWEP:DispatchEffect(effectName)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local _, sourceEntIndex, sourceAttachment = self:GetBeamSourceData(owner)
	if not sourceEntIndex then return end

	if CLIENT and owner == LocalPlayer() then
		local vm = owner:GetViewModel()
		if IsValid(vm) and sourceEntIndex == vm:EntIndex() and sourceAttachment and sourceAttachment > 0 then
			ParticleEffectAttach(effectName, PATTACH_POINT_FOLLOW, vm, sourceAttachment)
			return
		end
	end

	if sourceAttachment and sourceAttachment > 0 then
		ParticleEffectAttach(effectName, PATTACH_POINT_FOLLOW, owner, sourceAttachment)
	end
end

function SWEP:PlayTracer(effectName, endPos)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local beamStart, sourceEntIndex, sourceAttachment = self:GetBeamSourceData(CLIENT and LocalPlayer() or owner)
	if not beamStart then return end

	util.ParticleTracerEx(effectName, beamStart, endPos, true, sourceEntIndex, sourceAttachment or 0)
end

function SWEP:CreateImpactSprite(scale, pos)
	if CLIENT then return end

	local sprite = ents.Create("env_sprite")
	sprite:SetPos(pos)
	sprite:SetKeyValue("model", "sprites/vortring1.vmt")
	sprite:SetKeyValue("scale", tostring(scale))
	sprite:SetKeyValue("framerate", 60)
	sprite:SetKeyValue("spawnflags", "1")
	sprite:SetKeyValue("brightness", "255")
	sprite:SetKeyValue("angles", "0 0 0")
	sprite:SetKeyValue("rendermode", "9")
	sprite:SetKeyValue("renderamt", "255")
	sprite:Spawn()
	sprite:Fire("kill", "", 0.45)
end

function SWEP:ImpactEffect(traceHit)
	local data = EffectData()
	data:SetOrigin(traceHit.HitPos)
	data:SetNormal(traceHit.HitNormal)
	data:SetScale(20)
	util.Effect(IMPACT_EFFECT, data)

	local rand = math.Rand(1, 1.5)
	self:CreateImpactSprite(rand, traceHit.HitPos)
	self:CreateImpactSprite(rand, traceHit.HitPos)

	if SERVER and IsValid(traceHit.Entity) and string.find(traceHit.Entity:GetClass(), "ragdoll") then
		traceHit.Entity:Fire("StartRagdollBoogie")
	end
end

function SWEP:AltImpactEffect(traceHit)
	self:ImpactEffect(traceHit)

	local data = EffectData()
	data:SetOrigin(traceHit.HitPos)
	data:SetNormal(traceHit.HitNormal)
	data:SetScale(1)
	util.Effect(ALT_IMPACT_EFFECT, data, true, true)

	local rand = math.Rand(1.4, 2.1)
	self:CreateImpactSprite(rand, traceHit.HitPos)
	self:CreateImpactSprite(rand, traceHit.HitPos)
end

function SWEP:GetAimTrace(range)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local rangeValue = range or GetConVar("vorthands_beamrange"):GetFloat() or self.Range
	return util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * rangeValue,
		filter = owner,
		mask = MASK_SHOT
	})
end

function SWEP:StopViewParticles(owner)
	if not IsValid(owner) then return end

	if CLIENT and owner == LocalPlayer() then
		local vm = owner:GetViewModel()
		if IsValid(vm) then
			vm:StopParticles()
		end
	end

	owner:StopParticles()
end

function SWEP:ResetState()
	local owner = self.LastOwner or self:GetOwner()

	self.Charging = false
	self.Healing = false
	self.ChargeAnimPlayed = false
	self.ChargeKind = nil
	self.ChargeTime = 0
	self.HealTime = 0
	self:SetWeaponHoldType("fist")
	self:SetHoldType("fist")

	if SERVER and self.ChargeSound then
		self.ChargeSound:Stop()
	end

	if SERVER and self.HealingSound then
		self.HealingSound:Stop()
	end

	if IsValid(owner) then
		self:StopViewParticles(owner)
	end
end

function SWEP:CancelCharge(playDeny)
	local owner = self:GetOwner()
	local isAlt = self.ChargeKind == "secondary"
	self:ResetState()

	if playDeny and SERVER and IsValid(owner) then
		owner:EmitSound(self.Deny)
	end

	local nextTime = CurTime() + 0.25
	if isAlt then
		self:SetNextSecondaryFire(nextTime)
	else
		self:SetNextPrimaryFire(nextTime)
	end
end

function SWEP:BeginCharge(isAlt)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if self:IsBusy() then return end
	if owner:WaterLevel() >= 3 then
		if SERVER then
			owner:EmitSound(self.Deny)
		end
		return
	end

	self.Charging = true
	self.ChargeAnimPlayed = false
	self.ChargeKind = isAlt and "secondary" or "primary"
	self.ChargeTime = CurTime() + ((isAlt and self.AltBeamChargeTime) or (GetConVar("vorthands_beamchargetime"):GetFloat() or self.BeamChargeTime))
	self:SetWeaponHoldType("magic")
	self:SetHoldType("magic")
	self:SendWeaponAnim(ACT_VM_RELOAD)
	self:DispatchEffect(CHARGE_PARTICLE_A)
	self:DispatchEffect(CHARGE_PARTICLE_B)
	if isAlt then
		self:DispatchEffect(CHARGE_PARTICLE)
	end

	if SERVER and self.ChargeSound then
		self.ChargeSound:PlayEx(100, isAlt and 115 or 150)
		owner:SetAnimation(PLAYER_ATTACK1)
	end

	local nextTime = self.ChargeTime + (isAlt and self.AltBeamCooldown or self:GetPrimaryCooldown())
	if isAlt then
		self:SetNextSecondaryFire(nextTime)
	else
		self:SetNextPrimaryFire(nextTime)
	end
end

function SWEP:IsHL3Mode()
	return CurrentRound and CurrentRound() and CurrentRound().name == "hl3"
end

function SWEP:GetPrimaryDamage()
	if self:IsHL3Mode() then
		return self.HL3BeamDamage
	end

	return GetConVar("vorthands_beamdamage"):GetFloat() or self.BeamDamage
end

function SWEP:GetPrimaryCooldown()
	if self:IsHL3Mode() then
		return self.HL3BeamCooldown
	end

	return self.BeamCooldown
end

function SWEP:ApplyPrimarySplash(owner, traceRes, directTarget)
	if not SERVER or not self:IsHL3Mode() then return end

	local radius = self.HL3SplashRadius
	local maxDamage = self.HL3SplashDamage
	if radius <= 0 or maxDamage <= 0 then return end

	local origin = traceRes.HitPos
	for _, target in ipairs(ents.FindInSphere(origin, radius)) do
		if target == owner or target == directTarget then continue end
		if not IsValid(target) then continue end
		if not (target:IsPlayer() or target:IsNPC() or string.find(target:GetClass() or "", "ragdoll", 1, true)) then continue end

		local targetPos = target.WorldSpaceCenter and target:WorldSpaceCenter() or target:GetPos()
		local distance = origin:Distance(targetPos)
		if distance > radius then continue end

		local los = util.TraceLine({
			start = origin + traceRes.HitNormal * 4,
			endpos = targetPos,
			filter = {owner, directTarget},
			mask = MASK_SHOT
		})

		if los.Hit and los.Entity ~= target then continue end

		local scale = 1 - math.Clamp(distance / radius, 0, 1)
		local splashDamage = math.max(8, math.Round(maxDamage * scale))
		local pushDir = (targetPos - origin)
		if pushDir:LengthSqr() <= 0 then
			pushDir = owner:GetAimVector()
		else
			pushDir:Normalize()
		end

		local splash = DamageInfo()
		splash:SetDamageType(bit.bor(DMG_SHOCK, DMG_DISSOLVE))
		splash:SetDamage(splashDamage)
		splash:SetAttacker(owner)
		splash:SetInflictor(self)
		splash:SetDamagePosition(targetPos)
		splash:SetDamageForce(pushDir * self.DamageForce * 0.45)
		target:TakeDamageInfo(splash)
	end
end

function SWEP:FireBeam()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local isAlt = self.ChargeKind == "secondary"
	local traceRes = self:GetAimTrace(isAlt and self.AltBeamRange or self.Range)
	if not traceRes then return end

	if isAlt then
		self:PlayTracer(ALT_ZAP_PARTICLE, traceRes.HitPos)
		self:PlayTracer(ZAP_PARTICLE, traceRes.HitPos)
	else
		self:PlayTracer(ZAP_PARTICLE, traceRes.HitPos)
	end

	if SERVER then
		local damage = isAlt and self.AltBeamDamage or self:GetPrimaryDamage()
		local dmg = DamageInfo()
		dmg:SetDamageType(bit.bor(DMG_SHOCK, DMG_DISSOLVE))
		dmg:SetDamage(damage)
		dmg:SetAttacker(owner)
		dmg:SetInflictor(self)
		dmg:SetDamagePosition(traceRes.HitPos)
		dmg:SetDamageForce(owner:GetAimVector() * (isAlt and self.AltDamageForce or self.DamageForce))

		if IsValid(traceRes.Entity) then
			traceRes.Entity:TakeDamageInfo(dmg)

			if traceRes.Entity:IsPlayer() then
				net.Start("ZC_VortBeamHitFlash")
				net.Send(traceRes.Entity)
			end
		end

		if not isAlt then
			self:ApplyPrimarySplash(owner, traceRes, traceRes.Entity)
		end

		owner:EmitSound(self.AttackSound, isAlt and 95 or 85, isAlt and 85 or 100)
	end

	if isAlt then
		self:AltImpactEffect(traceRes)
	else
		self:ImpactEffect(traceRes)
	end
	self:ResetState()

	local nextTime = CurTime() + (isAlt and self.AltBeamCooldown or self:GetPrimaryCooldown())
	if isAlt then
		self:SetNextSecondaryFire(nextTime)
	else
		self:SetNextPrimaryFire(nextTime)
	end
end

function SWEP:GiveArmor()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local minArmorGain = math.max(0, math.floor(GetConVar("vorthands_minarmorheal"):GetFloat() or self.ArmorHealMin))
	local maxArmorGain = math.max(minArmorGain, math.floor(GetConVar("vorthands_maxarmorheal"):GetFloat() or self.ArmorHealMax))
	local armorGain = math.random(minArmorGain, maxArmorGain)

	owner:SetArmor(math.min(owner:Armor() + armorGain, self.ArmorLimit))
end

function SWEP:BeginArmorHeal()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if self:IsBusy() or owner:Armor() >= self.ArmorLimit then return end
	if owner:WaterLevel() >= 3 then
		if SERVER then
			owner:EmitSound(self.Deny)
		end
		return
	end

	self.Healing = true
	self.HealTime = CurTime() + (GetConVar("vorthands_healdelay"):GetFloat() or self.ArmorHealDelay)
	self:SetWeaponHoldType("slam")
	self:SetHoldType("slam")
	self:SendWeaponAnim(ACT_VM_RELOAD)
	self:DispatchEffect(CHARGE_PARTICLE)

	if SERVER and self.HealingSound then
		self.HealingSound:PlayEx(100, 150)
	end

	local nextTime = self.HealTime + 0.5
	self:SetNextPrimaryFire(nextTime)
	self:SetNextSecondaryFire(nextTime)
end

function SWEP:ResolveHealTarget()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local trace = owner:GetEyeTrace()
	local target = trace.Entity
	if not IsValid(target) then return end

	if target:GetClass() == "prop_ragdoll" and IsValid(target.ixPlayer) then
		target = target.ixPlayer
	end

	if not IsValid(target) or not target:IsPlayer() then return end
	if target == owner then return end
	if trace.HitPos:Distance(owner:GetShootPos()) > self.AllyHealRange then return end

	return target, trace
end

function SWEP:DoAllyHeal()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if self:IsBusy() then return end
	if self.NextAllyHealTime > CurTime() then return end

	local target, trace = self:ResolveHealTarget()
	if not IsValid(target) then return end

	local maxHealth = target:GetMaxHealth()
	local maxArmor = target.GetMaxArmor and target:GetMaxArmor() or self.ArmorLimit

	if target:Health() >= maxHealth and target:Armor() >= maxArmor then
		owner:EmitSound(self.Deny)
		local nextTime = CurTime() + 0.25
		self:SetNextPrimaryFire(nextTime)
		self:SetNextSecondaryFire(nextTime)
		return
	end

	local healAmount = math.random(self.AllyHealAmountMin, self.AllyHealAmountMax)
	local armorAmount = math.max(4, math.floor(healAmount * 0.5))

	target:SetHealth(math.min(target:Health() + healAmount, maxHealth))
	target:SetArmor(math.min(target:Armor() + armorAmount, maxArmor))

	self:PlayTracer(ZAP_PARTICLE, trace.HitPos)
	self:DispatchEffect(CHARGE_PARTICLE)
	owner:EmitSound(self.AllyHealSound)
	target:EmitSound(self.HealSound)

	self.NextAllyHealTime = CurTime() + self.AllyHealCooldown
	local nextTime = CurTime() + 0.8
	self:SetNextPrimaryFire(nextTime)
	self:SetNextSecondaryFire(nextTime)
end

function SWEP:Holster()
	self:ResetState()
	return true
end

function SWEP:OnRemove()
	self:ResetState()
end

function SWEP:Deploy()
	self:ResetState()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetDeploySpeed(1)
	return true
end

function SWEP:Think()
	local owner = self:GetOwner()
	if IsValid(owner) then
		self.LastOwner = owner
	end

	if not IsValid(owner) then
		self:ResetState()
		return
	end

	if self.Charging then
		local chargeKey = self.ChargeKind == "secondary" and IN_ATTACK2 or IN_ATTACK
		if not owner:KeyDown(chargeKey) then
			self:CancelCharge(false)
			return
		end

		if not self.ChargeAnimPlayed and (self.ChargeTime - CurTime()) <= 0.2 then
			self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
			self:DispatchEffect(CHARGE_PARTICLE)
			self.ChargeAnimPlayed = true
		end

		if CurTime() >= self.ChargeTime then
			self:StopViewParticles(owner)
			self:FireBeam()
			return
		end
	end

	if self.Healing and CurTime() >= self.HealTime then
		if owner:Armor() >= self.ArmorLimit then
			owner:EmitSound(self.Deny)
			self:CancelCharge(false)
			return
		end

		self:StopViewParticles(owner)
		self:GiveArmor()
		owner:EmitSound(self.HealSound)
		self:ResetState()

		local nextTime = CurTime() + 0.5
		self:SetNextPrimaryFire(nextTime)
		self:SetNextSecondaryFire(nextTime)
	end
end

function SWEP:PrimaryAttack()
	self:BeginCharge(false)
end

function SWEP:SecondaryAttack()
	self:BeginCharge(true)
end

function SWEP:Reload()
	self:DoAllyHeal()
end

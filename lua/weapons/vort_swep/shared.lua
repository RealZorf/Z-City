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
SWEP.HL3BeamDamage = 440
SWEP.HL3BeamChargeTime = 0.9
SWEP.HL3BeamCooldown = 0.24
SWEP.HL3BeamRange = 2400
SWEP.HL3SplashRadius = 160
SWEP.HL3SplashDamage = 88
SWEP.HL3ArcRadius = 210
SWEP.HL3ArcDamage = 38
SWEP.HL3PrimaryLeechHealth = 6
SWEP.HL3PrimaryLeechArmor = 10
SWEP.AltBeamDamage = 575
SWEP.AltBeamChargeTime = 0.2
SWEP.AltBeamCooldown = 9
SWEP.AltBeamRange = 2200
SWEP.AltDamageForce = 96000
SWEP.HL3AltBeamDamage = 660
SWEP.HL3AltBeamChargeTime = 0.16
SWEP.HL3AltBeamCooldown = 6.75
SWEP.HL3AltBeamRange = 2600
SWEP.HL3AltSplashRadius = 190
SWEP.HL3AltSplashDamage = 125
SWEP.HL3AltLeechHealth = 12
SWEP.HL3AltLeechArmor = 18
SWEP.ArmorHealDelay = 0.9
SWEP.ArmorHealMin = 14
SWEP.ArmorHealMax = 24
SWEP.HL3ArmorHealDelay = 0.55
SWEP.HL3ArmorHealMin = 18
SWEP.HL3ArmorHealMax = 32
SWEP.HL3SelfHealMin = 8
SWEP.HL3SelfHealMax = 16
SWEP.AllyHealCooldown = 2.25
SWEP.AllyHealAmountMin = 16
SWEP.AllyHealAmountMax = 28
SWEP.AllyHealRange = 110
SWEP.HL3AllyHealCooldown = 1.5
SWEP.HL3AllyHealAmountMin = 24
SWEP.HL3AllyHealAmountMax = 36
SWEP.HL3AllyHealArmorRatio = 0.75
SWEP.HL3AllyHealRange = 150
SWEP.HL3SupportHealHealth = 10
SWEP.HL3SupportHealArmor = 14
SWEP.HL3AltSupportHealHealth = 18
SWEP.HL3AltSupportHealArmor = 24

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
local HL3_VORT_TEAM = 2

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

function SWEP:GetRoundInfo()
	if not CurrentRound then return nil, nil end

	local roundMode, roundKey = CurrentRound()
	return roundMode, roundKey
end

function SWEP:IsHL3Mode()
	local _, roundKey = self:GetRoundInfo()
	return roundKey == "hl3"
end

function SWEP:IsHL3Vort(pPlayer)
	return IsValid(pPlayer)
		and self:IsHL3Mode()
		and (pPlayer:GetNWBool("ZC_HL3_Vort", false) or pPlayer:Team() == HL3_VORT_TEAM or self:IsVortOwner(pPlayer))
end

function SWEP:ResolvePlayerEntity(target)
	if not IsValid(target) then return nil end

	local ragdollOwner = hg and hg.RagdollOwner and hg.RagdollOwner(target) or nil
	if IsValid(ragdollOwner) then
		return ragdollOwner
	end

	if target:GetClass() == "prop_ragdoll" and IsValid(target.ixPlayer) then
		return target.ixPlayer
	end

	return target:IsPlayer() and target or nil
end

function SWEP:GetHealthLimitFor(target)
	if not IsValid(target) then return 100 end

	if self:IsHL3Vort(target) then
		return target:GetNWInt("ZC_HL3_VortHealthCap", math.max(target:GetMaxHealth() or 100, 150))
	end

	return target.GetMaxHealth and target:GetMaxHealth() or 100
end

function SWEP:GetArmorLimitFor(target)
	if not IsValid(target) then return self.ArmorLimit end

	if self:IsHL3Vort(target) then
		return target:GetNWInt("ZC_HL3_VortArmorCap", self.ArmorLimit)
	end

	return target.GetMaxArmor and target:GetMaxArmor() or self.ArmorLimit
end

function SWEP:IsFriendlyHL3Target(owner, target)
	if not self:IsHL3Mode() then return false end

	local playerTarget = self:ResolvePlayerEntity(target)
	return IsValid(owner) and IsValid(playerTarget) and playerTarget ~= owner and playerTarget:Team() == owner:Team()
end

function SWEP:ShouldBlockHL3FriendlyDamage(owner, target)
	if not self:IsHL3Mode() then return false end

	local playerTarget = self:ResolvePlayerEntity(target)
	if not IsValid(owner) or not IsValid(playerTarget) or playerTarget == owner then return false end
	if playerTarget:Team() ~= owner:Team() then return false end

	return self:IsHL3Vort(owner) and self:IsHL3Vort(playerTarget)
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
	self.ChargeTime = CurTime() + (isAlt and self:GetAltChargeTime() or self:GetPrimaryChargeTime())
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

	local nextTime = self.ChargeTime + (isAlt and self:GetAltCooldown() or self:GetPrimaryCooldown())
	if isAlt then
		self:SetNextSecondaryFire(nextTime)
	else
		self:SetNextPrimaryFire(nextTime)
	end
end

function SWEP:GetPrimaryDamage()
	if self:IsHL3Mode() then
		return self.HL3BeamDamage
	end

	return GetConVar("vorthands_beamdamage"):GetFloat() or self.BeamDamage
end

function SWEP:GetPrimaryChargeTime()
	if self:IsHL3Mode() then
		return self.HL3BeamChargeTime
	end

	return GetConVar("vorthands_beamchargetime"):GetFloat() or self.BeamChargeTime
end

function SWEP:GetPrimaryCooldown()
	if self:IsHL3Mode() then
		return self.HL3BeamCooldown
	end

	return self.BeamCooldown
end

function SWEP:GetPrimaryRange()
	if self:IsHL3Mode() then
		return self.HL3BeamRange
	end

	return GetConVar("vorthands_beamrange"):GetFloat() or self.Range
end

function SWEP:GetAltDamage()
	if self:IsHL3Mode() then
		return self.HL3AltBeamDamage
	end

	return self.AltBeamDamage
end

function SWEP:GetAltChargeTime()
	if self:IsHL3Mode() then
		return self.HL3AltBeamChargeTime
	end

	return self.AltBeamChargeTime
end

function SWEP:GetAltCooldown()
	if self:IsHL3Mode() then
		return self.HL3AltBeamCooldown
	end

	return self.AltBeamCooldown
end

function SWEP:GetAltRange()
	if self:IsHL3Mode() then
		return self.HL3AltBeamRange
	end

	return self.AltBeamRange
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
		if self:ShouldBlockHL3FriendlyDamage(owner, target) then continue end
		if self:IsFriendlyHL3Target(owner, target) then continue end

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

function SWEP:ApplyAltSplash(owner, traceRes, directTarget)
	if not SERVER or not self:IsHL3Mode() then return end

	local radius = self.HL3AltSplashRadius
	local maxDamage = self.HL3AltSplashDamage
	if radius <= 0 or maxDamage <= 0 then return end

	local origin = traceRes.HitPos
	for _, target in ipairs(ents.FindInSphere(origin, radius)) do
		if target == owner or target == directTarget then continue end
		if not IsValid(target) then continue end
		if not (target:IsPlayer() or target:IsNPC() or string.find(target:GetClass() or "", "ragdoll", 1, true)) then continue end
		if self:ShouldBlockHL3FriendlyDamage(owner, target) then continue end
		if self:IsFriendlyHL3Target(owner, target) then continue end

		local targetPos = target.WorldSpaceCenter and target:WorldSpaceCenter() or target:GetPos()
		local distance = origin:Distance(targetPos)
		if distance > radius then continue end

		local los = util.TraceLine({
			start = origin + traceRes.HitNormal * 6,
			endpos = targetPos,
			filter = {owner, directTarget},
			mask = MASK_SHOT
		})

		if los.Hit and los.Entity ~= target then continue end

		local scale = 1 - math.Clamp(distance / radius, 0, 1)
		local splashDamage = math.max(12, math.Round(maxDamage * scale))
		local pushDir = targetPos - origin
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
		splash:SetDamageForce(pushDir * self.AltDamageForce * 0.4)
		target:TakeDamageInfo(splash)
	end
end

function SWEP:ApplyPrimaryArc(owner, traceRes, directTarget)
	if not SERVER or not self:IsHL3Mode() then return end

	local radius = self.HL3ArcRadius
	local damage = self.HL3ArcDamage
	if radius <= 0 or damage <= 0 then return end

	local bestTarget, bestTargetPos, bestDistSqr
	for _, target in ipairs(ents.FindInSphere(traceRes.HitPos, radius)) do
		if target == owner or target == directTarget then continue end
		if not IsValid(target) then continue end
		if not (target:IsPlayer() or target:IsNPC() or string.find(target:GetClass() or "", "ragdoll", 1, true)) then continue end
		if self:ShouldBlockHL3FriendlyDamage(owner, target) then continue end
		if self:IsFriendlyHL3Target(owner, target) then continue end

		local targetPos = target.WorldSpaceCenter and target:WorldSpaceCenter() or target:GetPos()
		local distToTarget = traceRes.HitPos:DistToSqr(targetPos)
		if bestDistSqr and distToTarget >= bestDistSqr then continue end

		local los = util.TraceLine({
			start = traceRes.HitPos + traceRes.HitNormal * 4,
			endpos = targetPos,
			filter = {owner, directTarget},
			mask = MASK_SHOT
		})

		if los.Hit and los.Entity ~= target then continue end

		bestTarget = target
		bestTargetPos = targetPos
		bestDistSqr = distToTarget
	end

	if not IsValid(bestTarget) then return end

	local arcDamage = DamageInfo()
	arcDamage:SetDamageType(bit.bor(DMG_SHOCK, DMG_DISSOLVE))
	arcDamage:SetDamage(damage)
	arcDamage:SetAttacker(owner)
	arcDamage:SetInflictor(self)
	arcDamage:SetDamagePosition(bestTargetPos)
	arcDamage:SetDamageForce((bestTargetPos - traceRes.HitPos):GetNormalized() * self.DamageForce * 0.25)
	bestTarget:TakeDamageInfo(arcDamage)

	local arcEffect = EffectData()
	arcEffect:SetStart(traceRes.HitPos)
	arcEffect:SetOrigin(bestTargetPos)
	arcEffect:SetMagnitude(1)
	util.Effect("ToolTracer", arcEffect, true, true)
end

function SWEP:ApplyBeamSiphon(owner, target, isAlt)
	if not SERVER or not IsValid(owner) or not self:IsHL3Mode() then return end
	if not IsValid(target) or self:IsFriendlyHL3Target(owner, target) then return end

	local healthCap = self:GetHealthLimitFor(owner)
	local armorCap = self:GetArmorLimitFor(owner)
	local healthGain = isAlt and self.HL3AltLeechHealth or self.HL3PrimaryLeechHealth
	local armorGain = isAlt and self.HL3AltLeechArmor or self.HL3PrimaryLeechArmor

	if healthGain > 0 then
		owner:SetHealth(math.min(healthCap, owner:Health() + healthGain))
	end

	if armorGain > 0 then
		owner:SetArmor(math.min(armorCap, owner:Armor() + armorGain))
	end
end

function SWEP:ApplyBeamSupport(owner, target, isAlt)
	if not SERVER or not self:IsHL3Mode() then return false end

	local ally = self:ResolvePlayerEntity(target)
	if not IsValid(ally) or ally == owner or ally:Team() ~= owner:Team() then return false end

	local healthCap = self:GetHealthLimitFor(ally)
	local armorCap = self:GetArmorLimitFor(ally)
	if ally:Health() >= healthCap and ally:Armor() >= armorCap then return true end

	local healthGain = isAlt and self.HL3AltSupportHealHealth or self.HL3SupportHealHealth
	local armorGain = isAlt and self.HL3AltSupportHealArmor or self.HL3SupportHealArmor

	ally:SetHealth(math.min(healthCap, ally:Health() + healthGain))
	ally:SetArmor(math.min(armorCap, ally:Armor() + armorGain))
	owner:EmitSound(self.AllyHealSound)
	ally:EmitSound(self.HealSound)
	return true
end

function SWEP:FireBeam()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local isAlt = self.ChargeKind == "secondary"
	local traceRes = self:GetAimTrace(isAlt and self:GetAltRange() or self:GetPrimaryRange())
	if not traceRes then return end

	if isAlt then
		self:PlayTracer(ALT_ZAP_PARTICLE, traceRes.HitPos)
		self:PlayTracer(ZAP_PARTICLE, traceRes.HitPos)
	else
		self:PlayTracer(ZAP_PARTICLE, traceRes.HitPos)
	end

	if SERVER then
		local friendlyTarget = self:IsFriendlyHL3Target(owner, traceRes.Entity)
		local blockFriendlyDamage = self:ShouldBlockHL3FriendlyDamage(owner, traceRes.Entity)
		if friendlyTarget then
			self:ApplyBeamSupport(owner, traceRes.Entity, isAlt)
		elseif not blockFriendlyDamage then
			local damage = isAlt and self:GetAltDamage() or self:GetPrimaryDamage()
			local dmg = DamageInfo()
			dmg:SetDamageType(bit.bor(DMG_SHOCK, DMG_DISSOLVE))
			dmg:SetDamage(damage)
			dmg:SetAttacker(owner)
			dmg:SetInflictor(self)
			dmg:SetDamagePosition(traceRes.HitPos)
			dmg:SetDamageForce(owner:GetAimVector() * (isAlt and self.AltDamageForce or self.DamageForce))

			if IsValid(traceRes.Entity) then
				traceRes.Entity:TakeDamageInfo(dmg)

				local tracePly = self:ResolvePlayerEntity(traceRes.Entity)
				if IsValid(tracePly) then
					net.Start("ZC_VortBeamHitFlash")
					net.Send(tracePly)
				end
			end

			if isAlt then
				self:ApplyAltSplash(owner, traceRes, traceRes.Entity)
			else
				self:ApplyPrimarySplash(owner, traceRes, traceRes.Entity)
				self:ApplyPrimaryArc(owner, traceRes, traceRes.Entity)
			end

			self:ApplyBeamSiphon(owner, traceRes.Entity, isAlt)
		end

		owner:EmitSound(self.AttackSound, isAlt and 95 or 85, isAlt and 85 or 100)
	end

	if isAlt then
		self:AltImpactEffect(traceRes)
	else
		self:ImpactEffect(traceRes)
	end
	self:ResetState()

	local nextTime = CurTime() + (isAlt and self:GetAltCooldown() or self:GetPrimaryCooldown())
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

	local armorLimit = self:GetArmorLimitFor(owner)
	local minArmorGain = math.max(0, math.floor(self:IsHL3Vort(owner) and self.HL3ArmorHealMin or (GetConVar("vorthands_minarmorheal"):GetFloat() or self.ArmorHealMin)))
	local maxArmorGain = math.max(minArmorGain, math.floor(self:IsHL3Vort(owner) and self.HL3ArmorHealMax or (GetConVar("vorthands_maxarmorheal"):GetFloat() or self.ArmorHealMax)))
	local armorGain = math.random(minArmorGain, maxArmorGain)

	owner:SetArmor(math.min(owner:Armor() + armorGain, armorLimit))

	if self:IsHL3Vort(owner) then
		local healthLimit = self:GetHealthLimitFor(owner)
		local healthGain = math.random(self.HL3SelfHealMin, self.HL3SelfHealMax)
		owner:SetHealth(math.min(owner:Health() + healthGain, healthLimit))
	end
end

function SWEP:BeginArmorHeal()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local armorLimit = self:GetArmorLimitFor(owner)
	local healthLimit = self:GetHealthLimitFor(owner)
	local hl3Vort = self:IsHL3Vort(owner)
	if self:IsBusy() or (owner:Armor() >= armorLimit and (not hl3Vort or owner:Health() >= healthLimit)) then return end
	if owner:WaterLevel() >= 3 then
		if SERVER then
			owner:EmitSound(self.Deny)
		end
		return
	end

	self.Healing = true
	self.HealTime = CurTime() + (hl3Vort and self.HL3ArmorHealDelay or (GetConVar("vorthands_healdelay"):GetFloat() or self.ArmorHealDelay))
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
	local target = self:ResolvePlayerEntity(trace.Entity)
	if not IsValid(target) then return end

	if target == owner then return end

	local healRange = self:IsHL3Vort(owner) and self.HL3AllyHealRange or self.AllyHealRange
	if trace.HitPos:Distance(owner:GetShootPos()) > healRange then return end
	if self:IsHL3Mode() and target:Team() ~= owner:Team() then return end

	return target, trace
end

function SWEP:DoAllyHeal()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if self:IsBusy() then return end
	if self.NextAllyHealTime > CurTime() then return end

	local target, trace = self:ResolveHealTarget()
	if not IsValid(target) then return false end

	local maxHealth = self:GetHealthLimitFor(target)
	local maxArmor = self:GetArmorLimitFor(target)

	if target:Health() >= maxHealth and target:Armor() >= maxArmor then
		owner:EmitSound(self.Deny)
		local nextTime = CurTime() + 0.25
		self:SetNextPrimaryFire(nextTime)
		self:SetNextSecondaryFire(nextTime)
		return true
	end

	local hl3Vort = self:IsHL3Vort(owner)
	local healAmount = math.random(hl3Vort and self.HL3AllyHealAmountMin or self.AllyHealAmountMin, hl3Vort and self.HL3AllyHealAmountMax or self.AllyHealAmountMax)
	local armorAmount = hl3Vort and math.max(10, math.floor(healAmount * self.HL3AllyHealArmorRatio)) or math.max(4, math.floor(healAmount * 0.5))

	target:SetHealth(math.min(target:Health() + healAmount, maxHealth))
	target:SetArmor(math.min(target:Armor() + armorAmount, maxArmor))

	self:PlayTracer(ZAP_PARTICLE, trace.HitPos)
	self:DispatchEffect(CHARGE_PARTICLE)
	owner:EmitSound(self.AllyHealSound)
	target:EmitSound(self.HealSound)

	self.NextAllyHealTime = CurTime() + (hl3Vort and self.HL3AllyHealCooldown or self.AllyHealCooldown)
	local nextTime = CurTime() + 0.8
	self:SetNextPrimaryFire(nextTime)
	self:SetNextSecondaryFire(nextTime)
	return true
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
		local armorLimit = self:GetArmorLimitFor(owner)
		local healthLimit = self:GetHealthLimitFor(owner)
		local hl3Vort = self:IsHL3Vort(owner)
		if owner:Armor() >= armorLimit and (not hl3Vort or owner:Health() >= healthLimit) then
			owner:EmitSound(self.Deny)
			self:ResetState()

			local denyTime = CurTime() + 0.25
			self:SetNextPrimaryFire(denyTime)
			self:SetNextSecondaryFire(denyTime)
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
	if self:DoAllyHeal() then return end
	if self:IsHL3Vort(self:GetOwner()) then
		self:BeginArmorHeal()
	end
end

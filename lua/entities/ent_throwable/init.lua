AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local vector_one = Vector(1, 1, 1)

local function buildThrowableBounds(ent)
	local mins, maxs = ent:GetModelBounds()
	local scale = ent.modelscale or 1

	mins = mins * scale
	maxs = maxs * scale

	local center = (mins + maxs) * 0.5
	local extents = (maxs - mins) * 0.5

	-- Keep a minimum hull thickness so thin blades and shards do not get a degenerate
	-- physics shape that spins forever or clips into the floor.
	extents.x = math.max(extents.x, 2)
	extents.y = math.max(extents.y, 2)
	extents.z = math.max(extents.z, 2)

	return center - extents, center + extents
end

function ENT:Initialize()
	self:SetModel(self.WorldModel)
	self:SetModelScale(self.modelscale or 1, 0)

	local mins, maxs = buildThrowableBounds(self)

	self:PhysicsInitBox(mins, maxs)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionBounds(mins, maxs)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetUseType(USE_TOGGLE)
	self:DrawShadow(true)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		local size = maxs - mins
		phys:SetMass(math.Clamp(size:Length() * 0.08, 3, 18))
		phys:SetDamping(0.05, 4)
		phys:Wake()
		phys:EnableMotion(true)
	end
	self.created = CurTime()

	timer.Simple(0, function()
		if not IsValid(self) then return end

		self:SetModelScale(self.modelscale or 1, 0)
	end)

	timer.Simple(0.5,function()
		if not IsValid(self) then return end
		
		self:SetOwner()
	end)
end

function ENT:Think()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end
	local speed = phys:GetVelocity():LengthSqr()
	if self.constrained then return end
	if self.AeroDrag then
		AeroDrag(self, self:GetAngles():Forward(), 10)
	end

	if speed < 220000 then
		self.lowSpeedSince = self.lowSpeedSince or CurTime()
	else
		self.lowSpeedSince = nil
	end

	local settled = self.lowSpeedSince and (self.lowSpeedSince + 0.15) < CurTime()
	local desiredCollisionGroup = settled and COLLISION_GROUP_WEAPON or COLLISION_GROUP_NONE
	if self:GetCollisionGroup() ~= desiredCollisionGroup then
		self:SetCollisionGroup(desiredCollisionGroup)
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed < 400 then return end
	if self.removed then return end
	local pos,_ = LocalToWorld(self.localshit,angle_zero,self:GetPos(),self:GetAngles())
	local tr = {}
	tr.start = pos
	tr.endpos = pos + data.OurOldVelocity:GetNormalized() * 32
	tr.filter = self
	--if util.TraceLine(tr).Entity != data.HitEntity and not self.dont_account_for_placement then return end
	
	self.Penetration = self.penetration or 1
	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(self.owner)
	dmginfo:SetInflictor(self)
	dmginfo:SetDamage((self.damage or 20) * math.Clamp((data.Speed / self.MaxSpeed), 0, 1))
	dmginfo:SetDamageForce(data.OurOldVelocity)
	dmginfo:SetDamageType(self.DamageType or DMG_SLASH)
	dmginfo:SetDamagePosition(data.HitPos)
	data.HitEntity:TakeDamageInfo(dmginfo)

	if data.HitEntity.organism then
		self:EmitSound(self.AttackHitFlesh, 65)
	end

	if (data.HitEntity.organism) and ((self.DamageType or DMG_SLASH) == DMG_SLASH) and !self.shouldntlodge then

		local pos, ang = self:GetPos(), self:GetAngles()

		local hitent = data.HitEntity

		local tr = {}
		tr.start = pos
		tr.endpos = pos + data.OurOldVelocity
		tr.filter = self
		local tr = util.TraceLine(tr)
		local bone = tr.PhysicsBone
		local mat = hitent:GetBoneMatrix(hitent:TranslatePhysBoneToBone(bone))

		local lpos, lang = WorldToLocal(tr.HitPos, ang, mat:GetTranslation(), mat:GetAngles())

		local org = hitent.organism
		org.LodgedEntities = org.LodgedEntities or {}
		org.LodgedEntities[#org.LodgedEntities + 1] = {
			PhysBoneID = bone,
			OffsetPos = lpos,
			OffsetAng = lang,
			model = self:GetModel(),
			takeent = self.wep,
		}

		local rf = RecipientFilter()
		if IsValid(org.owner) then
			rf:AddPVS(org.owner:GetPos())
			if org.owner:IsPlayer() then
				rf:AddPlayer(org.owner)
			end
		else
			rf:AddAllPlayers()
		end

		net.Start("organism_send", true)

		local tbl = {}
		tbl.LodgedEntities = org.LodgedEntities
		tbl.owner = org.owner
	
		net.WriteTable(tbl)
		net.WriteBool(true)
		net.WriteBool(false)
		net.WriteBool(false)
		net.WriteBool(true)
		net.Send(rf)

		self:Remove()
		self.removed = true
	end
end

function ENT:Use(ply)
	if self.created + 0.5 > CurTime() then return end
	if self.removed then return end
	if self.wep then
		local wep = ents.Create(self.wep)
		wep:Spawn()
		wep:SetPos(self:GetPos())
		wep:SetAngles(self:GetAngles())
		wep.poisoned2 = self.poisoned2
		self:Remove()

		if constraint.FindConstraint( self, "Weld" ) then
			local tbl = constraint.FindConstraint( self, "Weld" )
			if tbl.Ent2:IsPlayer() or tbl.Ent2:IsRagdoll() then
				local dmginfo = DamageInfo()
				dmginfo:SetAttacker(self.owner)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamage(self.returndamage or 10)
				dmginfo:SetDamagePosition(self:GetPos())
				dmginfo:SetDamageType(DMG_SLASH)
				self.PainMultiplier = 0.5
				tbl.Ent2:TakeDamageInfo(dmginfo)
				hg.organism.AddWoundManual(tbl.Ent2,self.returnblood or 10,vector_origin,angle_zero,tbl["Bone2"] or 0,CurTime())
			end
		end

		if not hook.Run("PlayerCanPickupWeapon",ply,wep) then wep.IsSpawned = true wep.init = true return end

		ply:PickupWeapon(wep)
	end
end

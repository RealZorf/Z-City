AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local shotJitter = Vector(0, 0, 10)

function ENT:InitAdd()
	self:Activate()
end

function ENT:Explode()
	if self.Exploded then return end

	self.Exploded = true
	self.DecoyActive = true
	self.DecoyEndTime = CurTime() + self.DecoyDuration
	self.DecoyNextShot = 0

	self:EmitSound("weapons/p99/slideback.wav", 70, 105, 0.7, CHAN_ITEM)
end

function ENT:AddThink()
	if not self.DecoyActive then return end

	local now = CurTime()
	if now >= (self.DecoyEndTime or 0) then
		self:Remove()
		return
	end

	if (self.DecoyNextShot or 0) > now then return end

	local pos = self:GetPos() + shotJitter
	local pitch = math.random(92, 108)

	self:EmitSound(self.DecoySound, self.DecoySoundLevel, pitch, 1, CHAN_WEAPON)

	if hg and hg.EmitAISound then
		hg.EmitAISound(pos, self.DecoyAISoundRadius, 3, 8)
	end

	self.DecoyNextShot = now + math.Rand(self.DecoyShotMinDelay, self.DecoyShotMaxDelay)
end

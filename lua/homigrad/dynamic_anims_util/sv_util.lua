--

util.AddNetworkString("DynamicAnims_SendGesture")

local PLAYER = FindMetaTable("Player")
local function resolveSequenceSafe(ent, anim)
	if not IsValid(ent) then return -1, 0 end
	if anim == nil or anim == "" then return -1, 0 end

	local seqID, seqDuration

	if isnumber(anim) then
		seqID = anim
		if seqID >= 0 and seqID < ent:GetSequenceCount() then
			seqDuration = ent:SequenceDuration(seqID)
		end
	else
		seqID, seqDuration = ent:LookupSequence(anim)
	end

	if not isnumber(seqID) or seqID < 0 or seqID >= ent:GetSequenceCount() then
		return -1, 0
	end

	seqDuration = tonumber(seqDuration) or ent:SequenceDuration(seqID) or 0

	return seqID, seqDuration
end

function PLAYER:PlayCustomAnims(anim, autoStop, speed, needForceLook, autostopAdjust, tSvCallbacks)
	local seqID, seqDuration = resolveSequenceSafe(self, anim)
	if anim ~= "" and seqID < 0 then
		self:SetNWString("hg_CustomAnim", "")
		self:SetNWFloat("hg_CustomAnimDelay", 0)
		self:SetNWFloat("hg_CustomAnimStartTime", CurTime())
		self:SetNWBool("hg_NeedAutoStop", false)
		self:SetNWFloat("hg_AutoStopAdjust", 0)
		self.CustomAnimCallbacks = nil
		return 0
	end

	self:SetNWString("hg_CustomAnim", anim)
	self:SetNWFloat("hg_CustomAnimDelay", math.max(speed or seqDuration, 0.001))
	self:SetNWFloat("hg_CustomAnimStartTime", CurTime())
	self:SetNWBool("hg_NeedAutoStop", autoStop)
	self:SetNWFloat("hg_AutoStopAdjust", autostopAdjust or 0)
	self:SetCycle(0)
	self:DoAnimationEvent(0)

	self.CustomAnimCallbacks = tSvCallbacks or nil

    if needForceLook then
        local ang = self:EyeAngles()
        ang[1] = 0
        self:SetVelocity(ang:Forward() * 15)
    end

	return seqDuration
end

hook.Add("PlayerDeath", "StopWhenDieCustomAnim", function(ply)
	ply:PlayCustomAnims("")
end)

hook.Add("CalcMainActivity", "CustomAnim_Activity", function(ply, vel)
	local str = ply:GetNWString("hg_CustomAnim", "")
	local num = ply:GetNWFloat("hg_CustomAnimDelay")
	local st = ply:GetNWFloat("hg_CustomAnimStartTime")
	local needAutoStop = ply:GetNWBool("hg_NeedAutoStop", false)
	local autostopAdjust = ply:GetNWFloat("hg_AutoStopAdjust", 0)

	if str ~= nil and str ~= "" then
		local seqID = resolveSequenceSafe(ply, str)
		if seqID < 0 or num <= 0 then
			ply:PlayCustomAnims("")
			return
		end

		ply:SetCycle((CurTime() - st) / num)
		local timing = math.Truncate(math.Round( (CurTime() - st) / num, 3),2)
		ply.OldCustomAnimCallbackTime = ply.OldCustomAnimCallbackTime or timing
		if ply.CustomAnimCallbacks and ply.CustomAnimCallbacks[ timing ] and ply.OldCustomAnimCallbackTime != timing then
			ply.CustomAnimCallbacks[ timing ]( ply )
			ply.OldCustomAnimCallbackTime = timing
		end

		if needAutoStop and st + (num - autostopAdjust) < CurTime() then
			ply:PlayCustomAnims("")
		end

		return -1, seqID
	end
end)

-- PlayAnimAsGesture
-- https://gmodwiki.com/Player:AddVCDSequenceToGestureSlot
-- https://gmodwiki.com/Entity:SetLayerBlendIn
function PLAYER:PlayCustomAnimAsGesture(anim, weight, anim_time, start_time, autokill)
	local AnimID, AnimDuration = resolveSequenceSafe(self, anim)
	anim_time = anim_time or AnimDuration

	if AnimID < 0 then
		ErrorNoHalt("[Dynamic Anim] No sequence: " .. tostring(anim) .. "\n")
		return
	end

	self:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
	self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, AnimID, start_time or 0, autokill)
	self:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, weight or 1)

	net.Start("DynamicAnims_SendGesture")
		net.WriteEntity(self)
		net.WriteInt(AnimID, 16)
		net.WriteFloat(weight or 1)
		net.WriteFloat(CurTime())
		net.WriteFloat(start_time or 0)
		net.WriteFloat(anim_time)
		net.WriteFloat(AnimDuration)
		net.WriteBool(autokill or false)
	net.SendPVS(self:GetPos())
end

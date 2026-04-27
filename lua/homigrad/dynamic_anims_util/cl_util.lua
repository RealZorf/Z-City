--

local hook = hook

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

function PLAYER:PlayCustomAnims(anim, autoStop, speed, autostopAdjust)
	local seqID, seqDuration = resolveSequenceSafe(self, anim)
	if anim ~= "" and seqID < 0 then
		self:SetNWString("hg_CustomAnim", "")
		self:SetNWFloat("hg_CustomAnimDelay", 0)
		self:SetNWFloat("hg_CustomAnimStartTime", CurTime())
		self:SetNWBool("hg_NeedAutoStop", false)
		self:SetNWFloat("hg_AutoStopAdjust", 0)
		return 0
	end

	self:SetNWString("hg_CustomAnim", anim)
	self:SetNWFloat("hg_CustomAnimDelay", math.max(speed or seqDuration, 0.001))
	self:SetNWFloat("hg_CustomAnimStartTime", CurTime())
	self:SetNWBool("hg_NeedAutoStop", autoStop)
	self:SetNWFloat("hg_AutoStopAdjust", autostopAdjust or 0)
	self:SetCycle(0)
	self:DoAnimationEvent(0)

	return seqDuration
end

hook.Add("CalcMainActivity", "SLCAnim_Activity", function(ply, vel)
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

		return -1, seqID
	end
end)

net.Receive("DynamicAnims_SendGesture", function()
	local ent = net.ReadEntity()
	local AnimID = net.ReadInt(16)
	local weight = net.ReadFloat()
	local sv_start_time = net.ReadFloat()
	local start_time = net.ReadFloat()
	local anim_time = net.ReadFloat()
	local AnimDuration = net.ReadFloat()
	local autokill = net.ReadBool()
	--print(ent, AnimID, weight, sv_start_time, start_time, anim_time, AnimDuration, autokill)
	if !IsValid(ent) then return end

	ent:PlayCustomAnimAsGesture(AnimID, weight, anim_time, sv_start_time, start_time, AnimDuration, autokill)
end)

function PLAYER:PlayCustomAnimAsGesture(AnimID, weight, anim_time, sv_start_time, start_time, AnimDuration, autokill)
	local seqID = select(1, resolveSequenceSafe(self, AnimID))
	if seqID < 0 then return end

	local ping_adjust = CurTime() - sv_start_time
	self:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
	self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, seqID,(start_time or 0) + ping_adjust, autokill)
	self:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, weight or 1)
end

if not SERVER then return end

local repairClasses = {
	["prop_static"] = true,
	["prop_dynamic"] = true,
	["prop_dynamic_override"] = true,
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
}

local ignoredModelHints = {
	"grass",
	"bush",
	"tree",
	"foliage",
	"plant",
	"weed",
	"ivy",
	"vine",
	"paper",
	"card",
	"decal",
	"sprite",
}

local forcedBlockerModelHints = {
	"chair",
	"bench",
	"couch",
	"sofa",
	"seat",
	"stool",
	"pew",
}

local function isIgnoredModel(model)
	model = string.lower(model or "")
	if model == "" then return true end

	for _, hint in ipairs(ignoredModelHints) do
		if string.find(model, hint, 1, true) then
			return true
		end
	end

	return false
end

local function needsForcedBlocker(model)
	model = string.lower(model or "")
	if model == "" then return false end

	for _, hint in ipairs(forcedBlockerModelHints) do
		if string.find(model, hint, 1, true) then
			return true
		end
	end

	return false
end

local function getEntityBounds(ent)
	if not IsValid(ent) then return nil, nil end

	if ent.GetRenderBounds then
		local mins, maxs = ent:GetRenderBounds()
		if isvector(mins) and isvector(maxs) then
			return mins, maxs
		end
	end

	if ent.OBBMins and ent.OBBMaxs then
		local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
		if isvector(mins) and isvector(maxs) then
			return mins, maxs
		end
	end

	return nil, nil
end

local function getBlockerBounds(ent)
	local mins, maxs = getEntityBounds(ent)
	if not mins or not maxs then return nil, nil end

	if not needsForcedBlocker(ent:GetModel()) then
		return mins, maxs
	end

	local size = maxs - mins
	local inset = math.Clamp(math.min(size.x, size.y) * 0.08, 2, 8)
	local top = mins.z + math.Clamp(size.z * 0.45, 18, 34)

	local blockerMins = Vector(mins.x + inset, mins.y + inset, mins.z)
	local blockerMaxs = Vector(maxs.x - inset, maxs.y - inset, math.min(maxs.z, top))

	if blockerMaxs.x <= blockerMins.x then
		blockerMins.x = mins.x
		blockerMaxs.x = maxs.x
	end

	if blockerMaxs.y <= blockerMins.y then
		blockerMins.y = mins.y
		blockerMaxs.y = maxs.y
	end

	if blockerMaxs.z <= blockerMins.z then
		blockerMins.z = mins.z
		blockerMaxs.z = mins.z + math.min(size.z, 24)
	end

	return blockerMins, blockerMaxs
end

local function hideOriginalMapProp(ent)
	if not IsValid(ent) then return end

	ent:SetNoDraw(true)
	ent:SetNotSolid(true)
	ent:SetSolid(SOLID_NONE)
	ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
	ent.hg_collision_hidden = true
end

local function restoreOriginalMapProp(ent)
	if not IsValid(ent) or not ent.hg_collision_hidden then return end

	ent:SetNoDraw(false)
	ent:SetNotSolid(false)
	ent:SetCollisionGroup(COLLISION_GROUP_NONE)
	ent.hg_collision_hidden = nil
end

local function clearFurnitureRepair(ent)
	if not IsValid(ent) then return end

	if IsValid(ent.hg_collision_blocker) then
		ent.hg_collision_blocker:Remove()
	end

	if IsValid(ent.hg_collision_proxy) then
		ent.hg_collision_proxy:Remove()
	end

	ent.hg_collision_blocker = nil
	ent.hg_collision_proxy = nil
	restoreOriginalMapProp(ent)
end

local function shouldRepairMapProp(ent)
	if not IsValid(ent) then return false end
	if not repairClasses[ent:GetClass()] then return false end
	if not ent:CreatedByMap() then return false end
	if ent:GetNoDraw() then return false end
	if IsValid(ent:GetParent()) then return false end

	if hg and hg.GetLootBoxData and hg.GetLootBoxData(ent) then
		return false
	end

	local model = ent:GetModel()
	if not util.IsValidModel(model) or not util.IsValidProp(model) then return false end
	if isIgnoredModel(model) then return false end

	local forceBlocker = needsForcedBlocker(model)
	if ent.hg_collision_repaired then
		if not forceBlocker then
			return false
		end

		if ent.hg_collision_repaired == "proxy" and IsValid(ent.hg_collision_proxy) then
			return false
		end
	end

	if ent:GetSolid() ~= SOLID_NONE and not forceBlocker then
		return false
	end

	local mins, maxs = getEntityBounds(ent)
	if not mins or not maxs then return false end
	local size = maxs - mins
	if size:LengthSqr() < (48 * 48) then return false end
	if math.max(size.x, size.y, size.z) < 32 then return false end

	return true
end

local function tryEnableFurniturePhysics(ent)
	if not IsValid(ent) then return false end

	restoreOriginalMapProp(ent)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetCollisionGroup(COLLISION_GROUP_NONE)
	ent:EnableCustomCollisions(true)

	if ent.PhysicsInitStatic then
		ent:PhysicsInitStatic(SOLID_VPHYSICS)
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			ent:SetSolid(SOLID_VPHYSICS)
			phys:EnableMotion(false)
			phys:Sleep()
			return true
		end
	end

	return false
end

local function ensureCollisionBlocker(ent)
	if not IsValid(ent) then return false end
	if IsValid(ent.hg_collision_blocker) then return true end

	local mins, maxs = getBlockerBounds(ent)
	if not mins or not maxs then return false end
	local blocker = ents.Create("base_anim")
	if not IsValid(blocker) then return false end

	blocker:SetPos(ent:GetPos())
	blocker:SetAngles(ent:GetAngles())
	blocker:SetModel(ent:GetModel())
	blocker:SetNoDraw(true)
	blocker:DrawShadow(false)
	blocker:SetMoveType(MOVETYPE_NONE)
	blocker:SetNotSolid(false)
	blocker:SetCollisionGroup(COLLISION_GROUP_NONE)
	blocker:EnableCustomCollisions(true)
	blocker:Spawn()
	blocker:Activate()
	blocker:SetSolid(SOLID_BBOX)
	blocker:SetCollisionBounds(mins, maxs)
	blocker:SetTrigger(false)
	blocker:SetName("zcity_collision_blocker")

	ent.hg_collision_blocker = blocker
	blocker.hg_collision_source = ent

	if ent.CallOnRemove then
		ent:CallOnRemove("zcity_remove_collision_blocker", function(source)
			local blockerEnt = source.hg_collision_blocker
			if IsValid(blockerEnt) then
				blockerEnt:Remove()
			end
		end)
	end

	return true
end

local function ensureFurniturePhysicsProxy(ent)
	if not IsValid(ent) then return false end
	if IsValid(ent.hg_collision_proxy) then return true end

	local model = ent:GetModel()
	if not util.IsValidProp(model) then return false end

	local proxy = ents.Create("base_anim")
	if not IsValid(proxy) then return false end

	proxy:SetModel(model)
	proxy:SetPos(ent:GetPos())
	proxy:SetAngles(ent:GetAngles())
	proxy:SetSkin(ent:GetSkin() or 0)
	proxy:SetModelScale(ent:GetModelScale(), 0)
	proxy:Spawn()
	proxy:Activate()
	proxy:SetNoDraw(false)

	local sourceColor = ent:GetColor()
	if not IsColor(sourceColor) or sourceColor.a <= 0 then
		sourceColor = color_white
	end

	proxy:SetColor(sourceColor)
	proxy:SetRenderMode(sourceColor.a < 255 and RENDERMODE_TRANSALPHA or RENDERMODE_NORMAL)

	local sourceMaterial = ent:GetMaterial()
	if isstring(sourceMaterial) and sourceMaterial ~= "" then
		proxy:SetMaterial(sourceMaterial)
	end

	if proxy.GetNumBodyGroups and ent.GetNumBodyGroups then
		for index = 0, ent:GetNumBodyGroups() - 1 do
			proxy:SetBodygroup(index, ent:GetBodygroup(index))
		end
	end

	proxy:SetMoveType(MOVETYPE_NONE)
	proxy:SetCollisionGroup(COLLISION_GROUP_NONE)
	proxy:EnableCustomCollisions(true)

	if proxy.PhysicsInitStatic then
		proxy:PhysicsInitStatic(SOLID_VPHYSICS)
	else
		proxy:PhysicsInit(SOLID_VPHYSICS)
	end

	local phys = proxy:GetPhysicsObject()
	if not IsValid(phys) then
		proxy:Remove()
		return false
	end

	proxy.zcity_collision_proxy = true
	proxy:SetSolid(SOLID_VPHYSICS)
	phys:EnableMotion(false)
	phys:Sleep()

	hideOriginalMapProp(ent)

	ent.hg_collision_proxy = proxy
	proxy.hg_collision_source = ent

	proxy:CallOnRemove("zcity_restore_collision_source", function(proxyEnt)
		local source = proxyEnt.hg_collision_source
		if IsValid(source) and source.hg_collision_proxy == proxyEnt then
			source.hg_collision_proxy = nil
			source.hg_collision_repaired = nil
			restoreOriginalMapProp(source)
		end
	end)

	if ent.CallOnRemove then
		ent:CallOnRemove("zcity_remove_collision_proxy", function(source)
			local proxyEnt = source.hg_collision_proxy
			if IsValid(proxyEnt) then
				proxyEnt:Remove()
			end
		end)
	end

	return true
end

local function tryRepairMapPropCollision(ent)
	if not shouldRepairMapProp(ent) then return false end

	local mins, maxs = getEntityBounds(ent)
	if not mins or not maxs then return false end
	local forceBlocker = needsForcedBlocker(ent:GetModel())

	if forceBlocker then
		clearFurnitureRepair(ent)

		if tryEnableFurniturePhysics(ent) then
			ent.hg_collision_repaired = "vphysics_furniture"
			return true
		end

		if ensureFurniturePhysicsProxy(ent) then
			ent.hg_collision_repaired = "proxy"
			return true
		end
	end

	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetCollisionGroup(COLLISION_GROUP_NONE)
	ent:EnableCustomCollisions(true)

	if ent:GetClass() ~= "prop_static" and not forceBlocker then
		ent:PhysicsInit(SOLID_VPHYSICS)
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			ent:SetSolid(SOLID_VPHYSICS)
			phys:EnableMotion(false)
			phys:Sleep()
			ent.hg_collision_repaired = "vphysics"
			return true
		end

		ent:SetSolid(SOLID_BBOX)
		ent:SetCollisionBounds(mins, maxs)
		if ent:GetSolid() ~= SOLID_NONE then
			ent.hg_collision_repaired = "bbox"
			return true
		end
	end

	if ensureCollisionBlocker(ent) then
		ent.hg_collision_repaired = "blocker"
		return true
	end

	return false
end

local function repairBrokenMapPropCollisions()
	local repaired = 0

	for _, ent in ipairs(ents.GetAll()) do
		if tryRepairMapPropCollision(ent) then
			repaired = repaired + 1
		end
	end

	if repaired > 0 and GetConVar("developer"):GetBool() then
		print(string.format("[zcity] repaired collision on %d map props", repaired))
	end
end

hook.Add("InitPostEntity", "zcity_repair_map_prop_collision", function()
	timer.Simple(0, repairBrokenMapPropCollisions)
end)

hook.Add("PostCleanupMap", "zcity_repair_map_prop_collision", function()
	timer.Simple(0.5, repairBrokenMapPropCollisions)
end)

hook.Add("OnEntityCreated", "zcity_repair_map_prop_collision", function(ent)
	if not IsValid(ent) then return end

	timer.Simple(0, function()
		if not IsValid(ent) then return end
		tryRepairMapPropCollision(ent)
	end)
end)

zb = zb or {}
zb.ESPPerf = zb.ESPPerf or {}

local ESPPerf = zb.ESPPerf

local esp_range_limit = ConVarExists("zb_esp_range_limit") and GetConVar("zb_esp_range_limit") or CreateClientConVar("zb_esp_range_limit", "0", true, false, "Maximum ESP range in meters (0 = unlimited)", 0, 1000)
local esp_outline_limit = ConVarExists("zb_esp_outline_limit") and GetConVar("zb_esp_outline_limit") or CreateClientConVar("zb_esp_outline_limit", "0", true, false, "Maximum number of player outlines (0 = unlimited)", 0, 40)
local esp_show_outlines = ConVarExists("zb_esp_show_outlines") and GetConVar("zb_esp_show_outlines") or CreateClientConVar("zb_esp_show_outlines", "0", true, false, "Enable or disable player outlines", 0, 1)

local METERS_TO_UNITS = 52.49

local targetCache = { frame = -1, localPly = NULL, targets = {}}

local huge = math.huge

function ESPPerf.GetMaxDistanceSqr()
    local m = esp_range_limit:GetFloat()
    if m <= 0 then return huge end
    local u = m * METERS_TO_UNITS
    return u*u
end

function ESPPerf.GetMaxOutlineCount()
    local c = esp_outline_limit:GetInt()
    if c <= 0 then return huge end
    return c
end

function ESPPerf.ShouldDrawOutlines()
    return esp_show_outlines:GetBool()
end

function ESPPerf.BuildTargets(localPly, shouldDrawFn, getEntityFn)
    local frame = FrameNumber()

    if targetCache.frame == frame and targetCache.localPly == localPly then
        return targetCache.targets
    end

    local origin = EyePos()
    local maxDist = ESPPerf.GetMaxDistanceSqr()
    local outlineLimit = ESPPerf.GetMaxOutlineCount()

    local targets = targetCache.targets

    for i=1,#targets do
        targets[i] = nil
    end

    local count = 0
    for _, ply in player.Iterator() do
        if not shouldDrawFn(localPly, ply) then
            continue
        end

        local ent = getEntityFn(ply)
        if not IsValid(ent) then continue end

        local pos = ent:GetPos()
        local dist = origin:DistToSqr(pos)
        if dist > maxDist then continue end
        count = count + 1

        local t = targets[count]

        if t then
            t.ply = ply
            t.ent = ent
            t.dist = dist
        else
            targets[count] = {
                ply=ply,
                ent=ent,
                dist=dist
            }
        end
    end

    if count > 1 then
        table.sort(targets,function(a,b)
            return a.dist < b.dist
        end)
    end

    if outlineLimit < count then
        for i=outlineLimit+1,count do
            targets[i]=nil
        end
    end

    targetCache.frame = frame
    targetCache.localPly = localPly
    return targets
end

function ESPPerf.AddGroupedOutlines(outline_Add, targets, getColorFn,groupKeyFn)
    if not ESPPerf.ShouldDrawOutlines() then return end
    local grouped = {}

    for i=1,#targets do
        local t = targets[i]
        local key = groupKeyFn and groupKeyFn(t.ply,t.ent) or getColorFn(t.ply)
        local group = grouped[key]

        if not group then
            group = { color = getColorFn(t.ply), ents = {}}
            grouped[key] = group
        end
        local ents = group.ents
        ents[#ents+1] = t.ent
    end

    for _,group in pairs(grouped) do
        outline_Add(group.ents, group.color, OUTLINE_MODE_BOTH)
    end
end
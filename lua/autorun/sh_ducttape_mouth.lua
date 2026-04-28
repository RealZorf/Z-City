if SERVER then
    AddCSLuaFile()
end

hg = hg or {}
hg.DuctTapeMouth = hg.DuctTapeMouth or {}

local MouthTape = hg.DuctTapeMouth
local NW_KEY = "HG_DuctTapeMouth"
local HEAD_BONES = {
    "ValveBiped.Bip01_Head1",
    "ValveBiped.Bip01_Neck1"
}
local DEFAULT_EYES_TO_MOUTH_OFFSET = Vector( 0.95, 0, -4.65 )
local DEFAULT_HEAD_TO_MOUTH_OFFSET = Vector( 4.85, 0, -1.85 )
local DRAW_DIST_SQR = 1200 * 1200
local MODEL_MOUTH_OFFSET_FIXES = {
    ["models/player/group01/male_06.mdl"] = Vector( 0.15, 0, 0.1 ),
    ["models/player/group03/male_06.mdl"] = Vector( 0.15, 0, 0.1 ),
    ["models/player/group03m/male_06.mdl"] = Vector( 0.15, 0, 0.1 )
}

local function getCurrentCharacter( ply )
    if not IsValid( ply ) then
        return NULL
    end

    if hg.GetCurrentCharacter then
        return hg.GetCurrentCharacter( ply ) or ply
    end

    return IsValid( ply.FakeRagdoll ) and ply.FakeRagdoll or ply
end

function MouthTape.IsTaped( ply )
    return IsValid( ply ) and ply:IsPlayer() and ply:GetNWBool( NW_KEY, false ) == true
end

function MouthTape.IsProtected( ply )
    return IsValid( ply ) and ply:IsPlayer() and string.lower( ply:GetUserGroup() or "" ) == "superadmin"
end

function MouthTape.SetTaped( ply, taped )
    if not IsValid( ply ) or not ply:IsPlayer() then
        return false
    end

    taped = taped == true

    if taped and MouthTape.IsProtected( ply ) then
        if MouthTape.IsTaped( ply ) then
            ply:SetNWBool( NW_KEY, false )
        end

        return false
    end

    if MouthTape.IsTaped( ply ) == taped then
        return taped
    end

    ply:SetNWBool( NW_KEY, taped )
    return taped
end

local function getMouthOffsetFix( ent )
    local model = string.lower( ent:GetModel() or "" )
    return MODEL_MOUTH_OFFSET_FIXES[model] or vector_origin
end

local function getAttachmentPose( ent, attachmentName, offset )
    local attachmentId = ent.LookupAttachment and ent:LookupAttachment( attachmentName ) or 0
    if not attachmentId or attachmentId <= 0 then
        return
    end

    local attachment = ent:GetAttachment( attachmentId )
    if not attachment then
        return
    end

    local pos, ang = LocalToWorld( offset, angle_zero, attachment.Pos, attachment.Ang )
    return pos + ang:Forward() * 0.12, ang:Forward(), ang
end

function MouthTape.GetPose( ent, fallbackPly )
    if not IsValid( ent ) then
        return
    end

    if ent.SetupBones then
        ent:SetupBones()
    end

    local fix = getMouthOffsetFix( ent )
    local pos, normal, ang = getAttachmentPose( ent, "mouth", fix )
    if pos then
        return pos, normal, ang
    end

    pos, normal, ang = getAttachmentPose( ent, "eyes", DEFAULT_EYES_TO_MOUTH_OFFSET + fix )
    if pos then
        return pos, normal, ang
    end

    local boneId

    if ent.LookupBone then
        for _, boneName in ipairs( HEAD_BONES ) do
            local id = ent:LookupBone( boneName )

            if id then
                boneId = id
                break
            end
        end
    end

    if boneId then
        local matrix = ent:GetBoneMatrix( boneId )

        if matrix then
            local bonePos = matrix:GetTranslation()
            local boneAng = matrix:GetAngles()
            local pos, ang = LocalToWorld( DEFAULT_HEAD_TO_MOUTH_OFFSET + fix, angle_zero, bonePos, boneAng )
            return pos, ang:Forward(), ang
        end
    end

    if IsValid( fallbackPly ) then
        local ang = fallbackPly:EyeAngles()
        local pos = fallbackPly:EyePos() + ang:Forward() * 1.05 + ang:Up() * -4.6
        return pos, ang:Forward(), ang
    end
end

function MouthTape.GetTarget( owner, dist )
    if not IsValid( owner ) or not owner:IsPlayer() or not owner.GetAimVector then
        return
    end

    local trace = hg.eyeTrace and hg.eyeTrace( owner, dist or 70 )
    if not trace or not trace.Hit or not IsValid( trace.Entity ) then
        return
    end

    local target = trace.Entity
    local ply = target:IsPlayer() and target or ( hg.RagdollOwner and hg.RagdollOwner( target ) )

    if not IsValid( ply ) or ply == owner or not ply:Alive() then
        return
    end

    if MouthTape.IsProtected( ply ) then
        return false, ply, trace
    end

    local renderEnt = getCurrentCharacter( ply )
    local mouthPos = MouthTape.GetPose( renderEnt, ply )

    if not mouthPos then
        return
    end

    if owner:EyePos():DistToSqr( mouthPos ) > 90 * 90 then
        return
    end

    if trace.HitPos:DistToSqr( mouthPos ) > 14 * 14 and trace.HitGroup ~= HITGROUP_HEAD then
        return
    end

    return ply, renderEnt, trace, mouthPos
end

function hg.IsMouthDuctTaped( ply )
    return MouthTape.IsTaped( ply )
end

function hg.CanMouthBeDuctTaped( ply )
    return not MouthTape.IsProtected( ply )
end

function hg.SetMouthDuctTaped( ply, taped )
    return MouthTape.SetTaped( ply, taped )
end

if SERVER then
    hook.Add( "PlayerSpawn", "HG.DuctTapeMouth.Reset", function( ply )
        MouthTape.SetTaped( ply, false )
    end )

    hook.Add( "PlayerDeath", "HG.DuctTapeMouth.ClearOnDeath", function( ply )
        MouthTape.SetTaped( ply, false )
    end )
end

if CLIENT then
    local TAPE_MAT = Material( "decals/mat_jack_hmcd_ducttape" )
    if TAPE_MAT:IsError() then
        TAPE_MAT = Material( "models/debug/debugwhite" )
    end

    local BACKGROUND_COLOR = Color( 55, 55, 55, 230 )
    local TAPE_COLOR = Color( 182, 182, 182, 245 )
    local HIGHLIGHT_COLOR = Color( 220, 220, 220, 180 )

    hook.Add( "PostDrawTranslucentRenderables", "HG.DuctTapeMouth.Draw", function()
        render.SetMaterial( TAPE_MAT )
        local eyePos = EyePos()

        for _, ply in ipairs( player.GetAll() ) do
            if not MouthTape.IsTaped( ply ) or not ply:Alive() then
                continue
            end

            local ent = getCurrentCharacter( ply )
            if not IsValid( ent ) or ent:GetNoDraw() then
                continue
            end

            if ent.GetPos and ent:GetPos():DistToSqr( eyePos ) > DRAW_DIST_SQR then
                continue
            end

            if ent.shouldTransmit == false or ent.NotSeen then
                continue
            end

            local pos, normal = MouthTape.GetPose( ent, ply )
            if not pos or not normal then
                continue
            end

            render.DrawQuadEasy( pos, normal, 9.2, 2.9, BACKGROUND_COLOR, 90 )
            render.DrawQuadEasy( pos + normal * 0.02, normal, 8.2, 1.9, TAPE_COLOR, 90 )
            render.DrawQuadEasy( pos + normal * 0.03, normal, 7.6, 0.18, HIGHLIGHT_COLOR, 90 )
        end
    end )
end

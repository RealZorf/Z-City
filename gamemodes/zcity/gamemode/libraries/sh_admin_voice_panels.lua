if SERVER then
    if not ConVarExists("zb_voicechat_panel_groups") then
        CreateConVar(
            "zb_voicechat_panel_groups",
            "superadmin,admin,headadmin,developer,operator",
            bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
            "Comma-separated ULX/ULib groups allowed to enable alive voice panels."
        )
    end

    return
end

local AdminShowVoiceChat = GetConVar("zb_admin_show_voicechat") or CreateClientConVar(
    "zb_admin_show_voicechat",
    "0",
    true,
    false,
    "Show voicechat panels in-round if your ULX/ULib group is allowed by the server",
    0,
    1
)

local activeVoiceTalkers = {}

local function ui(value)
    local scale = math.min(ScrW() / 1920, ScrH() / 1080)
    return math.max(1, math.floor(value * scale))
end

local function rebuildFonts()
    local signature = ScrW() .. "x" .. ScrH()
    if zb.AdminVoicePanelFontSignature == signature then return end
    zb.AdminVoicePanelFontSignature = signature

    surface.CreateFont("ZB_AdminVoicePanelTitle", {
        font = "Bahnschrift",
        size = ui(22),
        weight = 700,
        antialias = true
    })

    surface.CreateFont("ZB_AdminVoicePanelEntry", {
        font = "Bahnschrift",
        size = ui(18),
        weight = 600,
        antialias = true
    })
end

local function groupCanSeeVoicePanels(groupName)
    groupName = string.lower(string.Trim(groupName or ""))
    if groupName == "" then return false end

    local cvar = GetConVar("zb_voicechat_panel_groups")
    local allowList = string.Trim((cvar and cvar:GetString()) or "")
    if allowList == "" then return false end

    for _, rawGroup in ipairs(string.Explode(",", allowList, false)) do
        local wantedGroup = string.lower(string.Trim(rawGroup or ""))
        if wantedGroup ~= "" and wantedGroup == groupName then
            return true
        end
    end

    return false
end

local function canSeeVoicePanelsInRound(lply)
    if not IsValid(lply) then return false end
    if not AdminShowVoiceChat:GetBool() then return false end

    local userGroup = (lply.GetUserGroup and lply:GetUserGroup()) or ""
    return groupCanSeeVoicePanels(userGroup)
end

zb.CanSeeVoicePanelsInRound = canSeeVoicePanelsInRound
hg.CanSeeVoicePanelsInRound = canSeeVoicePanelsInRound

local function getVoiceName(ply)
    if not IsValid(ply) then return "Unknown" end

    local customName = ply.GetNWString and ply:GetNWString("PlayerName", "") or ""
    if customName ~= "" then return customName end

    return ply:Name()
end

hook.Add("PlayerStartVoice", "ZB_AdminVoicePanelsTrackStart", function(ply)
    if not IsValid(ply) then return end

    activeVoiceTalkers[ply] = true
end)

hook.Add("PlayerEndVoice", "ZB_AdminVoicePanelsTrackEnd", function(ply)
    activeVoiceTalkers[ply] = nil
end)

hook.Add("Think", "ZB_AdminVoicePanelsCleanup", function()
    for ply in pairs(activeVoiceTalkers) do
        if not IsValid(ply) or not ply:IsSpeaking() then
            activeVoiceTalkers[ply] = nil
        end
    end
end)

hook.Add("HUDPaint", "ZB_AdminVoicePanelsDraw", function()
    local lply = LocalPlayer()
    if not canSeeVoicePanelsInRound(lply) then return end

    rebuildFonts()

    local talkers = {}
    for ply in pairs(activeVoiceTalkers) do
        if IsValid(ply) then
            talkers[#talkers + 1] = ply
        end
    end

    if #talkers == 0 then return end

    table.sort(talkers, function(a, b)
        return getVoiceName(a) < getVoiceName(b)
    end)

    local x = ui(24)
    local y = ui(180)
    local width = ui(270)
    local headerH = ui(28)
    local rowH = ui(22)
    local padding = ui(10)
    local gap = ui(4)
    local height = headerH + padding + (#talkers * rowH) + math.max(#talkers - 1, 0) * gap + padding

    draw.RoundedBox(6, x, y, width, height, Color(12, 18, 28, 215))
    surface.SetDrawColor(86, 140, 225, 220)
    surface.DrawOutlinedRect(x, y, width, height, math.max(1, ui(2)))

    draw.SimpleTextOutlined("Voice Activity", "ZB_AdminVoicePanelTitle", x + width * 0.5, y + headerH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), Color(10, 24, 48, 240))

    local rowY = y + headerH + padding
    for _, ply in ipairs(talkers) do
        draw.SimpleTextOutlined(getVoiceName(ply), "ZB_AdminVoicePanelEntry", x + padding, rowY + rowH * 0.5, Color(230, 238, 250), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, math.max(1, ui(1)), color_black)
        rowY = rowY + rowH + gap
    end
end)

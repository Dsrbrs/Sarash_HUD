-- ============================================================
-- SARASH HUD v0.1 — Full Edition
-- ============================================================

---------------------------------------------------------------
local ss = false

local renderv = render.RenderView
local renderc = render.Clear
local rendercap = render.Capture
local vguiworldpanel = vgui.GetWorldPanel
------------------------------------------------------------------
-- ── CONFIG ──────────────────────────────────────────────────
local CFG = {
    themeColor = Color(153, 17, 17),
    fontMono = "Courier New",
    hudW = 430,
    hudH = 30,
    adminPanelW = 230,
    radarSize = 160,
    consoleW = 220,
    consoleH = 160,
    logW = 220,
    logH = 130,
    maxLogs = 40,
    maxCmdOut = 10,
    lagFPSThresh = 30,
    lagPingThresh= 250,
}

-- ── OVERALL STATE ──────────────────────────────────────────────
local STATE = {
    showFPS = true,
    showPing = true,
    showTick = true,
    showUptime = true,
    showHUD = true,
    showAdmins = true,
    showRadar = true,
    showLogs = true,
    showConsole = true,
    showKillfeed = true,
    showCombo = true,
    showSpeedometer = true,
    showHealthBar = true,
    showAmmoBar = true,
    showArmor = true,
    showWatermark = true,
    bhop = false,
    streamerMode = false,
    antiScreen = true,
    fov = 90,
    noclipSpeed = 400,
}

-- ── POSITIONS OF THE FRAMES ─────────────────────────
local FRAMES = {
    hud = { x = 0, y = 0, w = CFG.hudW, h = CFG.hudH, init=false },
    admins = { x = 0, y = 0, w = CFG.adminPanelW,h = 0, init=false },
    radar = { x = 0, y = 0, w = CFG.radarSize, h = CFG.radarSize,init=false },
    logs = { x = 0, y = 0, w = CFG.logW, h = CFG.logH, init=false },
    console = { x = 0, y = 0, w = CFG.consoleW, h = CFG.consoleH, init=false },
    speedom = { x = 0, y = 0, w = 90, h = 30, init=false },
    health = { x = 0, y = 0, w = 200, h = 14, init=false },
    ammo = { x = 0, y = 0, w = 160, h = 14, init=false },
    armor = { x = 0, y = 0, w = 180, h = 14, init=false },
}

local function InitPositions()
    local W, H = ScrW(), ScrH()
    FRAMES.hud.x = W/2 - CFG.hudW/2
    FRAMES.hud.y = H - CFG.hudH - 18
    FRAMES.admins.x = W - CFG.adminPanelW - 16
    FRAMES.admins.y = H/2 - 75
    FRAMES.radar.x = 16
    FRAMES.radar.y = 16
    FRAMES.logs.x = 16
    FRAMES.logs.y = 16 + CFG.radarSize + 6
    FRAMES.console.x = 16
    FRAMES.console.y = 16 + CFG.radarSize + 6 + CFG.logH + 6
    FRAMES.speedom.x = W/2 - 45
    FRAMES.speedom.y = H - CFG.hudH - 60
    FRAMES.health.x = 16
    FRAMES.health.y = H - 80
    FRAMES.ammo.x = W - 180
    FRAMES.ammo.y = H - 80
    FRAMES.armor.x = 16
    FRAMES.armor.y = H - 62
    for _, f in pairs(FRAMES) do f.init = true end
end

-- ── FONTS ────────────────────────────────────────────────────
local fontsOK = false
local function CreateFonts()
    surface.CreateFont("SHUD_Name", { font=CFG.fontMono, size=13, weight=700 })
    surface.CreateFont("SHUD_Value", { font=CFG.fontMono, size=11, weight=400 })
    surface.CreateFont("SHUD_Label", { font=CFG.fontMono, size=9, weight=700 })
    surface.CreateFont("SHUD_Admin", { font=CFG.fontMono, size=10, weight=600 })
    surface.CreateFont("SHUD_Console", { font=CFG.fontMono, size=10, weight=400 })
    surface.CreateFont("SHUD_Kill", { font=CFG.fontMono, size=14, weight=700 })
    surface.CreateFont("SHUD_Speedom", { font=CFG.fontMono, size=18, weight=700 })
    surface.CreateFont("SHUD_Radar", { font=CFG.fontMono, size=8, weight=400 })
    fontsOK = true
end

-- ── UTILS ────────────────────────────────────────────────────
local sessionStart = CurTime()
local function FormatTime(s)
    s = math.floor(s)
    return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), s%60)
end
local function FormatTimestamp()
    local t = math.floor(CurTime() - sessionStart)
    return string.format("%02d:%02d", math.floor(t/60), t%60)
end
local function GetGrade(ply)
    return IsValid(ply) and ply:GetUserGroup() or "user"
end
local function GradeColor(g, a)
    a = a or 255
    if g == "superadmin" then return Color(255,70,70,a)
    elseif g == "admin" then return Color(70,140,255,a)
    else return Color(160,160,160,a)
    end
end

-- ── DRAW HELPERS ─────────────────────────────────────────────
local TC = CFG.themeColor
local function SharpBox(x,y,w,h,fill,alpha)
    alpha = alpha or fill.a or 255
    surface.SetDrawColor(fill.r,fill.g,fill.b,alpha)
    surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(TC.r,TC.g,TC.b,alpha)
    surface.DrawOutlinedRect(x,y,w,h,1)
end

local function DrawHeader(x,y,w,title,alpha)
    alpha = alpha or 255
    surface.SetDrawColor(10,10,10,alpha)
    surface.DrawRect(x,y,w,18)
    surface.SetDrawColor(TC.r,TC.g,TC.b,math.floor(alpha*0.4))
    surface.DrawRect(x,y+17,w,1)
    surface.SetDrawColor(TC.r,TC.g,TC.b,alpha)
    surface.DrawRect(x+6,y+6,5,5)
    draw.SimpleText(title,"SHUD_Label",x+16,y+9,Color(60,60,60,alpha),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
end

local function DrawPipe(x,midY)
    draw.SimpleText("|","SHUD_Value",x,midY,Color(30,30,30,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

local function DrawBlock(label,value,x,w,midY,valCol)
    local cx = x+w/2
    draw.SimpleText(label,"SHUD_Label",cx,midY-7,Color(80,80,80,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText(value,"SHUD_Value",cx,midY+7,valCol,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

-- ── LOG SYSTEM ───────────────────────────────────────────────
local LOGS = {}
local LOG_ICONS = { info="›", admin="★", lag="!", join="+", leave="−", cmd="$", kill="×", warn="⚠" }
local LOG_COLORS = {
    info = Color(60,200,90),
    admin = Color(0, 229, 255),
    lag = Color(255,160,40),
    join = Color(60,200,90),
    leave = Color(200,60,60),
    cmd = Color(180,100,255),
    kill = Color(255,80,80),
    warn = Color(255, 255, 0),
}
local function PushLog(kind, msg)
    table.insert(LOGS, { kind=kind, msg=msg, t=FormatTimestamp(), born=CurTime() })
    if #LOGS > CFG.maxLogs then table.remove(LOGS, 1) end
end

-- ── CONSOLE CMD ──────────────────────────────────────────────
local cmdOutput = {}
local cmdHistory = {}
local cmdInput = ""
local cmdActive = false

local function PushCmdOut(kind, msg)
    local prefix = kind=="ok" and "✓ " or kind=="err" and "✗ " or kind=="warn" and "⚠ " or kind=="info" and " " or " "
    table.insert(cmdOutput, { kind=kind, msg=prefix..msg })
    if #cmdOutput > CFG.maxCmdOut then table.remove(cmdOutput, 1) end
end

local function ClearCmdOut() cmdOutput = {} end

-- ── COMMANDES ────────────────────────────────────────────────
local COMMANDS = {}

-- Helper for toggling on/off
local function Toggle(args, key, label)
    if args[1] == "on" then STATE[key]=true PushCmdOut("ok", label.." on") PushLog("cmd",label.." on")
    elseif args[1] == "off" then STATE[key]=false PushCmdOut("warn", label.." off") PushLog("cmd",label.." off")
    else PushCmdOut("err","Use: "..label:lower().." on|off") end
end

COMMANDS["clear"] = function() ClearCmdOut() PushCmdOut("ok","Empty console") end

COMMANDS["version"] = function()
    PushCmdOut("info","SARASH HUD v0.1")
    PushCmdOut("info","Build 20260509 — by Rayzix")
end

COMMANDS["uptime"] = function()
    PushCmdOut("info","Session: "..FormatTime(CurTime()-sessionStart))
end

COMMANDS["fps"] = function()
    local f = math.floor(1/FrameTime())
    PushCmdOut("info","current FPS: "..f)
end

COMMANDS["ping"] = function()
    local ply = LocalPlayer()
    PushCmdOut("info","Ping: "..(IsValid(ply) and ply:Ping() or "N/A").." ms")
end

COMMANDS["tickrate"] = function()
    PushCmdOut("info","Tickrate: "..math.floor(1/engine.TickInterval()).." Hz")
end

COMMANDS["map"] = function()
    PushCmdOut("info","Map: "..game.GetMap())
end

COMMANDS["server"] = function()
    PushCmdOut("info","Server: "..GetHostName())
    PushCmdOut("info","Address: "..game.GetIPAddress())
end

COMMANDS["maxplayers"] = function()
    PushCmdOut("info","MaxPlayers: "..game.MaxPlayers())
end

COMMANDS["time"] = function()
    PushCmdOut("info","Server time: "..os.date("%H:%M:%S"))
end

COMMANDS["players"] = function()
    local all = player.GetAll()
    PushCmdOut("info",#all.." connected players:")
    for _, v in ipairs(all) do
        if IsValid(v) then
            local grade = GetGrade(v)
            PushCmdOut("info"," "..v:Name().." ["..grade.."] — "..v:Ping().."ms")
        end
    end
end

COMMANDS["pos"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local p = ply:GetPos()
    PushCmdOut("info",string.format("X:%.0f Y:%.0f Z:%.0f", p.x, p.y, p.z))
end

COMMANDS["vel"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    PushCmdOut("info","Vitesse: "..math.floor(ply:GetVelocity():Length2D()).." u/s")
end

COMMANDS["health"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    PushCmdOut("info","HP: "..ply:Health().."/"..ply:GetMaxHealth())
end

COMMANDS["armor"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    PushCmdOut("info","Armor: "..ply:Armor())
end

COMMANDS["ammo"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        PushCmdOut("info","Ammo: "..wep:Clip1().." / "..ply:GetAmmoCount(wep:GetPrimaryAmmoType()))
    else PushCmdOut("warn","No active weapon") end
end

COMMANDS["weapon"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    PushCmdOut("info","Weapons: "..(IsValid(wep) and wep:GetClass() or "aucune"))
end

COMMANDS["team"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    PushCmdOut("info","Team: "..team.GetName(ply:Team()))
end

COMMANDS["Rank"] = function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    PushCmdOut("info","Rank: "..GetGrade(ply))
end

COMMANDS["dumpstate"] = function()
    for k, v in pairs(STATE) do
        PushCmdOut("info", k..": "..tostring(v))
    end
end

COMMANDS["name"] = function(args)
    if not args[1] then PushCmdOut("err","Use: name [new name]") return end
    local n = table.concat(args, " ")
    STATE.playerNameOverride = n
    PushCmdOut("OK","Name → "..n)
    PushLog("cmd","name "..n)
end

COMMANDS["streamer"] = function(args) Toggle(args,"streamerMode","Streamer mode") end
COMMANDS["bhop"] = function(args) Toggle(args,"bhop","BHop") end
COMMANDS["killfeed"] = function(args) Toggle(args,"showKillfeed","Kill feed") end
COMMANDS["speedometer"]=function(args) Toggle(args,"showSpeedometer","Speedomètre") end
COMMANDS["healthbar"] =function(args) Toggle(args,"showHealthBar","Health bar") end
COMMANDS["ammobar"] =function(args) Toggle(args,"showAmmoBar","Ammo bar") end
COMMANDS["crosshair"] =function(args) Toggle(args,"crosshair","Crosshair") end
COMMANDS["watermark"] =function(args) Toggle(args,"showWatermark","Watermark") end

COMMANDS["fov"] = function(args)
    local v = tonumber(args[1])
    if not v or v<60 or v>160 then PushCmdOut("err","FOV between 60 and 160") return end
    STATE.fov = v
    RunConsoleCommand("fov_desired", tostring(v))
    PushCmdOut("ok","FOV → "..v)
    PushLog("cmd","fov "..v)
end

COMMANDS["speed"] = function(args)
    local v = tonumber(args[1])
    if not v then PushCmdOut("err","Use: speed [value]") return end
    STATE.noclipSpeed = v
    PushCmdOut("ok","Speed → "..v)
    PushLog("cmd","speed "..v)
end

COMMANDS["sens"] = function(args)
    local v = tonumber(args[1])
    if not v then PushCmdOut("err","Use: sens [value]") return end
    STATE.sens = v
    RunConsoleCommand("sensitivity", tostring(v))
    PushCmdOut("ok","Sensitivity → "..string.format("%.2f",v))
    PushLog("cmd","sens "..v)
end

COMMANDS["crosshairsize"] = function(args)
    local v = tonumber(args[1])
    if not v then PushCmdOut("err","Use: crosshairsize [value]") return end
    STATE.crosshairSize = math.Clamp(v,2,30)
    PushCmdOut("ok","Crosshair size → "..STATE.crosshairSize)
end

COMMANDS["crosshairgap"] = function(args)
    local v = tonumber(args[1])
    if not v then PushCmdOut("err","Use: crosshairgap [value]") return end
    STATE.crosshairGap = math.Clamp(v,0,30)
    PushCmdOut("ok","Crosshair gap → "..STATE.crosshairGap)
end

COMMANDS["theme"] = function(args)
    local themes = { red=Color(153,17,17), blue=Color(17,85,153), green=Color(17,102,17), white=Color(100,100,100) }
    local c = themes[args[1]]
    if not c then PushCmdOut("err","Theme: red | blue | green | white") return end
    TC = c
    CFG.themeColor = c
    PushCmdOut("ok","Theme → "..args[1])
    PushLog("cmd","Theme "..args[1])
end

COMMANDS["killsound"] = function(args) Toggle(args,"killSound","Kill sound") end
COMMANDS["hitsound"] = function(args) Toggle(args,"hitSound","Hit sound") end

COMMANDS["hide"] = function(args)
    local map = {
        fps="showFPS", ping="showPing", tick="showTick", uptime="showUptime",
        hud="showHUD", admins="showAdmins", radar="showRadar",
        logs="showLogs", console="showConsole", killfeed="showKillfeed",
        speedometer="showSpeedometer", healthbar="showHealthBar",
        ammobar="showAmmoBar", armor="showArmor", watermark="showWatermark",
        combo="showCombo",
    }
    local key = map[args[1]]
    if not key then PushCmdOut("err","Unknown target: "..(args[1] or "?")) return end
    STATE[key] = false
    PushCmdOut("ok",(args[1]).." hide")
    PushLog("cmd","hide "..args[1])
end

COMMANDS["show"] = function(args)
    local map = {
        fps="showFPS", ping="showPing", tick="showTick", uptime="showUptime",
        hud="showHUD", admins="showAdmins", radar="showRadar",
        logs="showLogs", console="showConsole", killfeed="showKillfeed",
        speedometer="showSpeedometer", healthbar="showHealthBar",
        ammobar="showAmmoBar", armor="showArmor", watermark="showWatermark",
        combo="showCombo",
    }
    local key = map[args[1]]
    if not key then PushCmdOut("err","Unknown target: "..(args[1] or "?")) return end
    STATE[key] = true
    PushCmdOut("ok",(args[1]).." show")
    PushLog("cmd","show "..args[1])
end

-- Executing a command
local function RunCmd(raw)
    if raw == "" then return end
    table.insert(cmdHistory, 1, raw)
    cmdHistIdx = 0
    PushCmdOut("cmd","> "..raw)
    PushLog("cmd", raw)
    local parts = string.Explode(" ", raw:Trim())
    local cmd = parts[1]:lower()
    table.remove(parts, 1)
    if COMMANDS[cmd] then
        COMMANDS[cmd](parts)
    else
        PushCmdOut("err",'Unknown command: "'..cmd..'"')
    end
end

-- Input console
hook.Add("GUIMousePressed", "SarashConsoleClick", function(btn, mx, my)
    if btn == MOUSE_LEFT then
        local f = FRAMES.console
        if mx >= f.x and mx <= f.x+f.w and my >= f.y and my <= f.y+f.h then
            cmdActive = true
            gui.RequestFocus()
        else
            cmdActive = false
        end
    end
end)

hook.Add("OnScreenSizeChanged", "SarashResize", function()
    for _, f in pairs(FRAMES) do f.init = false end
end)

-- Console keyboard
hook.Add("Think", "SarashCmdInput", function()
    if not cmdActive then return end
end)

-- ── KILL NOTIFS ──────────────────────────────────────────────
local killNotifs = {}
local combo = 0
local lastKillTime = 0

local function AddKillNotif(text)
    table.insert(killNotifs, 1, { text=text, time=CurTime(), off=25 })
    combo = combo + 1
    lastKillTime = CurTime()
    PushLog("kill", text)
end

-- ── RADAR DATA ───────────────────────────────────────────────
-- The radar draws the players around the LocalPlayer
local function GetRadarPlayers()
    local ply = LocalPlayer()
    if not IsValid(ply) then return {} end
    local result = {}
    local myPos = ply:GetPos()
    local myAng = ply:EyeAngles().y
    local radarR = CFG.radarSize / 2 - 14
    local worldR = 2000-- world radius in units

    for _, v in ipairs(player.GetAll()) do
        if v ~= ply and IsValid(v) then
            local diff = v:GetPos() - myPos
            local dist = diff:Length2D()
            if dist < worldR then
                local ang = math.atan2(diff.y, diff.x)
                local relAng = ang - math.rad(myAng) + math.pi/2
                local ratio = math.min(dist / worldR, 1)
                local rx = math.sin(relAng) * ratio * radarR
                local ry = -math.cos(relAng) * ratio * radarR
                table.insert(result, {
                    rx = rx,
                    ry = ry,
                    name = STATE.streamerMode and "***" or v:Name():sub(1,8),
                    team = v:Team() == ply:Team(),
                    admin= v:IsAdmin(),
                    dist = math.floor(dist/52.49),
                })
            end
        end
    end
    return result
end

-- ── ADMIN WATCHER ────────────────────────────────────────────
local lastAdmins = {}
hook.Add("Think", "SarashAdminWatcher", function()
    local cur = {}
    for _, v in ipairs(player.GetAll()) do
        if v:IsAdmin() then
            cur[v:SteamID()] = true
            if not lastAdmins[v:SteamID()] then
                PushLog("admin", v:Name().." ["..GetGrade(v).."] online")
                PushLog("join", v:Name().." joined")
            end
        end
    end
    for id in pairs(lastAdmins) do
        if not cur[id] then PushLog("leave","An admin has left") end
    end
    lastAdmins = cur
end)

-- Lag watcher
local lagCooldown = 0
hook.Add("Think","SarashLagWatch",function()
    if CurTime() < lagCooldown then return end
    local fps = math.floor(1/FrameTime())
    local ply = LocalPlayer()
    local ping = IsValid(ply) and ply:Ping() or 0
    if fps < CFG.lagFPSThresh then
        PushLog("lag","Lag — "..fps.." FPS")
        lagCooldown = CurTime() + 5
    elseif ping > CFG.lagPingThresh then
        PushLog("lag","Spike — "..ping.." ms")
        lagCooldown = CurTime() + 5
    end
end)

-- ── HUD PAINT ────────────────────────────────────────────────
hook.Add("HUDPaint","SarashHUD", function()
    if ss then return end
    if not fontsOK then CreateFonts() end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not FRAMES.hud.init then InitPositions() end

    local fps = math.floor(1/FrameTime())
    local ping = ply:Ping()
    local uptime = CurTime() - sessionStart
    local speed = math.floor(ply:GetVelocity():Length2D())
    local hp = ply:Health()
    local maxHp = math.max(ply:GetMaxHealth(),1)
    local arm = ply:Armor()
    local wep = ply:GetActiveWeapon()
    local ammo = IsValid(wep) and wep:Clip1() or 0
    local maxAmmo = IsValid(wep) and wep:GetMaxClip1() or 1
    local tick = math.floor(1/engine.TickInterval())
    local dispName = STATE.playerNameOverride or (STATE.streamerMode and "***" or ply:Name())

    -- ── HUD BAR ─────────────────────────────────
    if STATE.showHUD then
        local f = FRAMES.hud
        SharpBox(f.x,f.y,f.w,f.h,Color(0,20,20,255))

        local nameW = 100
        local blockW = (f.w - nameW) / 4
        local midY = f.y + f.h/2

        draw.SimpleText(dispName,"SHUD_Name",f.x+nameW/2,midY,
            Color(255,210,80,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

        DrawPipe(f.x+nameW, midY)

        local blocksActive = {}
        if STATE.showFPS then table.insert(blocksActive,{label="FPS", val=tostring(fps), col=fps>=60 and Color(70,220,90) or fps>=30 and Color(220,170,50) or Color(220,60,60)}) end
        if STATE.showPing then table.insert(blocksActive,{label="PING", val=ping.."ms", col=ping<=80 and Color(70,220,90) or ping<=150 and Color(220,170,50) or Color(220,60,60)}) end
        if STATE.showTick then table.insert(blocksActive,{label="TICK", val=tostring(tick), col=Color(140,140,255)}) end
        if STATE.showUptime then table.insert(blocksActive,{label="UP", val=FormatTime(uptime), col=Color(150,150,150)}) end

        local bW = blockW
        if #blocksActive > 0 then bW = (f.w - nameW) / #blocksActive end

        for i, blk in ipairs(blocksActive) do
            DrawBlock(blk.label, blk.val, f.x+nameW+(i-1)*bW, bW, midY, blk.col)
            if i < #blocksActive then DrawPipe(f.x+nameW+i*bW, midY) end
        end
    end

    -- ── PANEL ADMINS ────────────────────────────
    if STATE.showAdmins then
        local admins = {}
        for _, v in ipairs(player.GetAll()) do
            if v:IsAdmin() then table.insert(admins, v) end
        end
        local rowH = 15
        local panelH = 24 + (#admins * rowH) + 20
        local f = FRAMES.admins
        FRAMES.admins.h = panelH

        SharpBox(f.x,f.y,CFG.adminPanelW,panelH,Color(0,0,0,255))
        DrawHeader(f.x,f.y,CFG.adminPanelW,"ADMINS")

        for i, v in ipairs(admins) do
            local ry = f.y + 22 + (i-1)*rowH
            local grade = GetGrade(v)
            local gCol = GradeColor(grade)
            local dist = math.floor(ply:GetPos():Distance(v:GetPos())/52.49)
            local dname = STATE.streamerMode and "***" or v:Name():sub(1,14)

            draw.SimpleText(dname, "SHUD_Admin",f.x+7,ry,Color(180,180,180),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
            draw.SimpleText(grade, "SHUD_Admin",f.x+CFG.adminPanelW/2,ry,gCol,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
            draw.SimpleText(dist.."m","SHUD_Admin",f.x+CFG.adminPanelW-7,ry,Color(55,55,55),TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
        end

        surface.SetDrawColor(TC.r,TC.g,TC.b,50)
        surface.DrawRect(f.x, f.y+panelH-16, CFG.adminPanelW, 1)
        draw.SimpleText(#admins.." online","SHUD_Label",f.x+7,f.y+panelH-8,Color(60,60,60),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        draw.SimpleText("SARASH","SHUD_Label",f.x+CFG.adminPanelW-7,f.y+panelH-8,Color(40,40,40),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
    end

    -- ── RADAR ───────────────────────────────────
    if STATE.showRadar then
        local f = FRAMES.radar
        local sz = CFG.radarSize
        local cx = f.x + sz/2
        local cy = f.y + sz/2
        local r = sz/2 - 12

        SharpBox(f.x,f.y,sz,sz,Color(0,0,0,255))
        DrawHeader(f.x,f.y,sz,"RADAR")

        surface.SetDrawColor(20,20,20,255)
        surface.DrawRect(f.x+1,f.y+18,sz-2,sz-19)

        for i=1,3 do
            surface.SetDrawColor(18,18,18,255)
            local ir = r*(i/3)
            surface.DrawLine(cx-ir,cy,cx+ir,cy)
            surface.DrawLine(cx,cy-ir,cx,cy+ir)
        end

        surface.SetDrawColor(25,25,25,255)
        local steps = 36
        local prev = { cx+r, cy }
        for i=1,steps do
            local a = (i/steps)*math.pi*2
            local nx,ny = cx+math.sin(a)*r, cy-math.cos(a)*r
            surface.DrawLine(prev[1],prev[2],nx,ny)
            prev = {nx,ny}
        end

        draw.SimpleText("N","SHUD_Radar",cx,f.y+20,Color(600,20,20),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
        draw.SimpleText("S","SHUD_Radar",cx,f.y+sz-5,Color(600,20,20),TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM)
        draw.SimpleText("E","SHUD_Radar",f.x+sz-5,cy,Color(600,20,20),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
        draw.SimpleText("O","SHUD_Radar",f.x+5,cy,Color(600,20,20),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

        local rplayers = GetRadarPlayers()
        for _, rp in ipairs(rplayers) do
            local px = cx + rp.rx
            local py = cy + rp.ry
            local col = rp.admin and Color(255,100,100) or (rp.team and Color(70,130,255) or Color(220,80,80))
            surface.SetDrawColor(col.r,col.g,col.b,255)
            surface.DrawRect(px-2,py-2,4,4)
            draw.SimpleText(rp.name,"SHUD_Radar",px+5,py,Color(col.r,col.g,col.b,180),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        end

        surface.SetDrawColor(255,255,255,255)
        surface.DrawRect(cx-2,cy-2,5,5)
    end

    -- ── LOG PANEL ───────────────────────────────
    if STATE.showLogs then
        local f = FRAMES.logs
        SharpBox(f.x,f.y,f.w,f.h,Color(0,20,20,255))
        DrawHeader(f.x,f.y,f.w,"SYSTEM LOGER")

        local visible = {}
        for i=#LOGS,1,-1 do
            table.insert(visible,LOGS[i])
            if #visible >= 8 then break end
        end

        for i=#visible,1,-1 do
            local log = visible[i]
            local life = CurTime()-log.born
            local alpha= life > 8 and math.max(0,255-((life-8)*40)) or 255
            local col = LOG_COLORS[log.kind] or LOG_COLORS.info
            local icon = LOG_ICONS[log.kind] or "›"
            local ln = #visible-(i-1)
            local ly = f.y + 22 + (ln-1)*13

            draw.SimpleText(log.t, "SHUD_Console",f.x+5, ly,Color(30,30,30,alpha),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
            draw.SimpleText(icon, "SHUD_Console",f.x+34,ly,Color(col.r,col.g,col.b,alpha),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
            draw.SimpleText(log.msg,"SHUD_Console",f.x+44,ly,Color(col.r,col.g,col.b,alpha),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
        end
    end

    -- ── CONSOLE ─────────────────────────────────
    if STATE.showConsole then
        local f = FRAMES.console
        SharpBox(f.x,f.y,f.w,f.h,Color(20,20,20,255))
        DrawHeader(f.x,f.y,f.w,"CONSOLE")

        local outAreaH = f.h - 40
        local maxLines = math.floor(outAreaH/12)
        local visible = {}
        for i = math.max(1,#cmdOutput-maxLines+1), #cmdOutput do
            table.insert(visible, cmdOutput[i])
        end

        for i, line in ipairs(visible) do
            local ly = f.y + 20 + (i-1)*12
            local col = line.kind=="ok" and Color(60,200,90)
                      or line.kind=="err" and Color(200,60,60)
                      or line.kind=="warn" and Color(255,160,40)
                      or line.kind=="info" and Color(70,120,200)
                      or line.kind=="cmd" and Color(160,80,255)
                      or Color(60,60,60)
            draw.SimpleText(line.msg,"SHUD_Console",f.x+5,ly,col,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
        end

        local iy = f.y+f.h-17
        surface.SetDrawColor(TC.r,TC.g,TC.b,50)
        surface.DrawRect(f.x,iy-2,f.w,1)
        draw.SimpleText("sarash>","SHUD_Console",f.x+5,iy+5,Color(TC.r,TC.g,TC.b,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

        local cursor = cmdActive and (math.floor(CurTime()*2)%2==0 and "_" or "") or ""
        draw.SimpleText(cmdInput..cursor,"SHUD_Console",f.x+52,iy+5,Color(200,200,200,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end

    -- ── SPEEDOMETER ──────────────────────────────
    if STATE.showSpeedometer then
        local f = FRAMES.speedom
        SharpBox(f.x,f.y,f.w,f.h,Color(0,0,0,220))
        local col = speed>600 and Color(255,80,80) or speed>300 and Color(255,180,40) or Color(70,220,90)
        draw.SimpleText(tostring(speed),"SHUD_Speedom",f.x+f.w/2,f.y+f.h/2,col,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        draw.SimpleText("u/s","SHUD_Label",f.x+f.w-6,f.y+f.h-4,Color(50,50,50),TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
    end

    -- ── HEALTH BAR ──────────────────────────────
    if STATE.showHealthBar then
        local f = FRAMES.health
        local ratio = math.Clamp(hp/maxHp,0,1)
        surface.SetDrawColor(0,0,0,200)
        surface.DrawRect(f.x,f.y,f.w,f.h)
        local col = ratio>0.5 and Color(60,200,80) or ratio>0.25 and Color(220,160,40) or Color(220,50,50)
        surface.SetDrawColor(col.r,col.g,col.b,220)
        surface.DrawRect(f.x+1,f.y+1,math.floor((f.w-2)*ratio),f.h-2)
        surface.SetDrawColor(TC.r,TC.g,TC.b,160)
        surface.DrawOutlinedRect(f.x,f.y,f.w,f.h,1)
        draw.SimpleText("HP "..hp,"SHUD_Label",f.x+4,f.y+f.h/2,Color(200,200,200),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end

    -- ── ARMOR BAR ───────────────────────────────
    if STATE.showArmor and arm > 0 then
        local f = FRAMES.armor
        local ratio = math.Clamp(arm/100,0,1)
        surface.SetDrawColor(0,0,0,200)
        surface.DrawRect(f.x,f.y,f.w,f.h)
        surface.SetDrawColor(80,140,255,200)
        surface.DrawRect(f.x+1,f.y+1,math.floor((f.w-2)*ratio),f.h-2)
        surface.SetDrawColor(TC.r,TC.g,TC.b,160)
        surface.DrawOutlinedRect(f.x,f.y,f.w,f.h,1)
        draw.SimpleText("ARMOR "..arm,"SHUD_Label",f.x+4,f.y+f.h/2,Color(180,180,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end

    -- ── AMMO BAR ────────────────────────────────
    if STATE.showAmmoBar and IsValid(wep) then
        local f = FRAMES.ammo
        local ratio = maxAmmo>0 and math.Clamp(ammo/maxAmmo,0,1) or 0
        surface.SetDrawColor(0,0,0,200)
        surface.DrawRect(f.x,f.y,f.w,f.h)
        local col = ratio>0.4 and Color(200,200,200) or ratio>0.15 and Color(220,160,40) or Color(220,50,50)
        surface.SetDrawColor(col.r,col.g,col.b,200)
        surface.DrawRect(f.x+1,f.y+1,math.floor((f.w-2)*ratio),f.h-2)
        surface.SetDrawColor(TC.r,TC.g,TC.b,160)
        surface.DrawOutlinedRect(f.x,f.y,f.w,f.h,1)
        draw.SimpleText(ammo.." / "..ply:GetAmmoCount(wep:GetPrimaryAmmoType()),"SHUD_Label",f.x+4,f.y+f.h/2,Color(200,200,200),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end

    -- ── CROSSHAIR ───────────────────────────────
    if STATE.crosshair then
        local scx,scy = ScrW()/2, ScrH()/2
        local s = STATE.crosshairSize
        local g = STATE.crosshairGap
        local col = STATE.crosshairColor
        surface.SetDrawColor(col.r,col.g,col.b,200)
        surface.DrawRect(scx-s-g, scy-1, s, 2)
        surface.DrawRect(scx+g, scy-1, s, 2)
        surface.DrawRect(scx-1, scy-s-g, 2, s)
        surface.DrawRect(scx-1, scy+g, 2, s)
    end

    -- ── WATERMARK ───────────────────────────────
    if STATE.showWatermark then
        draw.SimpleText("SARASH v0.1","SHUD_Label",
            ScrW()-5, ScrH()-5,
            Color(25,25,25,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end

    -- ── KILL NOTIFS ─────────────────────────────
    if STATE.showKillfeed then
        for i = #killNotifs,1,-1 do
            local kn = killNotifs[i]
            local life = CurTime()-kn.time
            if life > 4 then table.remove(killNotifs,i)
            else
                kn.off = Lerp(FrameTime()*10, kn.off, 0)
                local alpha = life>3 and math.floor(255-(life-3)*255) or 255
                local ky = FRAMES.hud.y - 20 - (i*26) - kn.off
                surface.SetDrawColor(0,0,0,alpha) surface.DrawRect(ScrW()/2-140,ky,280,22)
                surface.SetDrawColor(TC.r,TC.g,TC.b,alpha) surface.DrawOutlinedRect(ScrW()/2-140,ky,280,22,1)
                draw.SimpleText(kn.text,"SHUD_Kill",ScrW()/2,ky+11,Color(255,255,255,alpha),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
        end
    end

    -- ── COMBO ───────────────────────────────────
    if STATE.showCombo and combo>1 then
        if CurTime()-lastKillTime > 5 then combo=0 end
        local pulse = math.sin(CurTime()*6)*40+215
        local cx2 = FRAMES.hud.x-108
        local cy2 = FRAMES.hud.y
        surface.SetDrawColor(0,0,0,220) surface.DrawRect(cx2,cy2,100,30)
        surface.SetDrawColor(TC.r,TC.g,TC.b,180) surface.DrawOutlinedRect(cx2,cy2,100,30,1)
        draw.SimpleText("COMBO x"..combo,"SHUD_Kill",cx2+50,cy2+15,Color(pulse,80,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
end)

-- ── INPUT CLAVIER CONSOLE ────────────────────────────────────
hook.Add("PlayerButtonDown","SarashConsoleKey",function(_,btn)
    if btn == KEY_LSHIFT or btn == KEY_RSHIFT or btn == KEY_LCTRL then return end
end)

-- We use the GUI hook to capture the text
hook.Add("GUIKeyTyped","SarashCmdKey",function(key)
    if not cmdActive then return end
    if key == "\b" then
        cmdInput = cmdInput:sub(1,-2)
    elseif key == "\r" or key == "\n" then
        RunCmd(cmdInput)
        cmdInput = ""
    else
        cmdInput = cmdInput..key
    end
end)

-- ── KILL HOOKS ───────────────────────────────────────────────
hook.Add("PlayerDeath","SarashKill",function(victim,inflictor,attacker)
    if attacker==LocalPlayer() and victim~=LocalPlayer() then
        local wn = IsValid(inflictor) and inflictor:GetClass() or "arme"
        AddKillNotif("You killed "..victim:Name().." with "..wn)
    end
end)

hook.Add("OnNPCKilled","SarashNPCKill",function(attacker,inflictor)
    if attacker==LocalPlayer() then
        local wn = IsValid(inflictor) and inflictor:GetClass() or "weapon"
        AddKillNotif("NPC eliminated — "..wn)
    end
end)

-- ── CONCOMMANDS ──────────────────────────────────────────────
concommand.Add("sarash_toggle_admins", function() STATE.showAdmins = not STATE.showAdmins end)
concommand.Add("sarash_toggle_radar", function() STATE.showRadar = not STATE.showRadar end)
concommand.Add("sarash_toggle_hud", function() STATE.showHUD = not STATE.showHUD end)
concommand.Add("sarash_toggle_console", function() STATE.showConsole = not STATE.showConsole end)
concommand.Add("sarash_toggle_logs", function() STATE.showLogs = not STATE.showLogs end)

-- ── ANTI-SCREENSHOT ──────────────────────────────────────────
API.Callbacks.Add("Hook::OnScreengrabDetected", "block_render", function()
	if ss then return end
	ss = true

	renderc( 0, 0, 0, 255, true, true )
	renderv( {
		origin = LocalPlayer():EyePos(),
		angles = LocalPlayer():EyeAngles(),
		x = 0,
		y = 0,
		w = ScrW(),
		h = ScrH(),
		dopostprocess = true,
		drawhud = true,
		drawmonitors = true,
		drawviewmodel = true
	} )

	local vguishits = vguiworldpanel()

	if IsValid( vguishits ) then
		vguishits:SetPaintedManually( true )
	end

	timer.Simple( 0.1, function()
		vguiworldpanel():SetPaintedManually( false )
		ss = false
	end)
end)

render.Capture = function(data)
	screengrab()
	local cap = rendercap( data )
	return cap
end

PushLog("info","SARASH HUD v1.0")
PushLog("info","MADE WITH BENZOY")

hook.Add("OnPlayerChat", "SarashChatCmd", function(ply, text)
    if ply ~= LocalPlayer() then return end

    if text:sub(1, 3) == "/s " or text:sub(1, 3) == "!s " then
        local cmd = text:sub(4)
        RunCmd(cmd)
        return true
    end
end)

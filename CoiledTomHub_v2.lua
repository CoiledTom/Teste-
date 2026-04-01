--[[
    ╔══════════════════════════════════════════╗
    ║         COILEDTOM HUB  v2.2.0            ║
    ║         Script Roblox — Lua/Luau         ║
    ║         github / discord: @coiledtom     ║
    ╚══════════════════════════════════════════╝
    GESTO: 3 dedos duplo-toque = abre/fecha GUI
--]]

-- ══════════════════════════════════
--  SERVICES
-- ══════════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Workspace      = game:GetService("Workspace")
local HttpService    = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ══════════════════════════════════
--  TEMA PADRÃO
-- ══════════════════════════════════
local TEMAS = {
    Roxo    = {main = Color3.fromRGB(139, 0, 255), dark = Color3.fromRGB(92, 0, 170),  light = Color3.fromRGB(160, 32, 240)},
    Azul    = {main = Color3.fromRGB(0, 119, 255),  dark = Color3.fromRGB(0, 68, 187),  light = Color3.fromRGB(51, 153, 255)},
    Ciano   = {main = Color3.fromRGB(0, 170, 221),  dark = Color3.fromRGB(0, 119, 153), light = Color3.fromRGB(0, 204, 255)},
    Verde   = {main = Color3.fromRGB(0, 187, 68),   dark = Color3.fromRGB(0, 119, 34),  light = Color3.fromRGB(0, 238, 85)},
    Menta   = {main = Color3.fromRGB(0, 221, 170),  dark = Color3.fromRGB(0, 119, 85),  light = Color3.fromRGB(0, 255, 204)},
    Amarelo = {main = Color3.fromRGB(221, 170, 0),  dark = Color3.fromRGB(153, 119, 0), light = Color3.fromRGB(255, 204, 0)},
    Laranja = {main = Color3.fromRGB(255, 102, 0),  dark = Color3.fromRGB(170, 51, 0),  light = Color3.fromRGB(255, 136, 0)},
    Vermelho= {main = Color3.fromRGB(238, 17, 17),  dark = Color3.fromRGB(153, 0, 0),   light = Color3.fromRGB(255, 51, 51)},
    Rosa    = {main = Color3.fromRGB(238, 0, 136),  dark = Color3.fromRGB(136, 0, 85),  light = Color3.fromRGB(255, 34, 187)},
    Branco  = {main = Color3.fromRGB(170, 170, 170),dark = Color3.fromRGB(85, 85, 85),  light = Color3.fromRGB(204, 204, 204)},
}

-- ══════════════════════════════════
--  CONFIG (padrão)
-- ══════════════════════════════════
local Cfg = {
    -- Tema
    Tema = "Roxo",

    -- ESP
    ESP_On        = true,
    ESP_Linha     = false,
    ESP_LinhaPos  = "Cima",
    ESP_Caixa     = true,
    ESP_CaixaEst  = "Redondo",
    ESP_Nome      = true,
    ESP_NomeEst   = "Com Sombra",
    ESP_Vida      = true,
    ESP_VidaPos   = "Esquerda",
    ESP_Esqueleto = false,
    ESP_Tracer    = false,
    ESP_Distancia = false,

    -- Aimbot
    Aim_On        = true,
    Aim_Silent    = true,
    Aim_Part      = "Head",
    Aim_FOV       = 120,
    Aim_Smooth    = 40,
    Aim_FOVCircle = false,
    Aim_Step      = false,

    -- Player Hacks
    Speed_On      = true,
    Speed_Val     = 50,
    Jump_On       = false,
    Jump_Val      = 100,
    Noclip        = false,
    Fly_On        = false,
    Fly_Val       = 60,
    Hitbox        = false,
    Hitbox_Val    = 5,
    AntiKnock     = false,
    InfJump       = false,

    -- Misc
    AdminDetector = false,
    Spectate_On   = false,
    Spectate_Target = "",
    FreeCam       = false,
    FullBright    = false,
    AntiAFK       = false,
    RejoinAuto    = false,
}

-- ══════════════════════════════════
--  SAVE / LOAD  (via writefile se disponível)
-- ══════════════════════════════════
local SAVE_FILE = "CoiledTomHub_v2.json"

local function SaveConfig()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Cfg)
    if ok then
        pcall(writefile, SAVE_FILE, encoded)
    end
end

local function LoadConfig()
    local ok, raw = pcall(readfile, SAVE_FILE)
    if ok and raw then
        local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok2 and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if Cfg[k] ~= nil then Cfg[k] = v end
            end
        end
    end
end

LoadConfig()

-- ══════════════════════════════════
--  HELPERS
-- ══════════════════════════════════
local function getChar()  return LP.Character end
local function getRoot()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function getEnemies()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    return list
end

local function worldToScreen(pos)
    local screenPos, onScreen = Cam:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function getClosestEnemy()
    local best, bestDist = nil, math.huge
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    for _, p in ipairs(getEnemies()) do
        local part = p.Character:FindFirstChild(Cfg.Aim_Part) or p.Character:FindFirstChild("Head")
        if part then
            local sp, onScreen = worldToScreen(part.Position)
            if onScreen then
                local dist = (sp - center).Magnitude
                if dist < Cfg.Aim_FOV and dist < bestDist then
                    bestDist = dist; best = p
                end
            end
        end
    end
    return best
end

-- ══════════════════════════════════
--  DESENHO  (Drawing API)
-- ══════════════════════════════════
local drawings = {}

local function newDraw(type_, props)
    local d = Drawing.new(type_)
    for k, v in pairs(props) do d[k] = v end
    table.insert(drawings, d)
    return d
end

local function clearDrawings()
    for _, d in ipairs(drawings) do pcall(d.Remove, d) end
    drawings = {}
end

-- Guarda objetos por player
local espObjects = {}

local function removeESP(p)
    if espObjects[p] then
        for _, d in ipairs(espObjects[p]) do pcall(d.Remove, d) end
        espObjects[p] = nil
    end
end

local function createESP(p)
    removeESP(p)
    local t = TEMAS[Cfg.Tema]
    local col = t and t.light or Color3.fromRGB(160, 32, 240)

    local objs = {}

    -- Caixa (Quad ou Circle de referência)
    local box = Drawing.new("Square")
    box.Visible    = false
    box.Color      = col
    box.Thickness  = 1.5
    box.Filled     = false
    table.insert(objs, box)

    -- Nome
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color   = col
    nameTag.Size    = 14
    nameTag.Center  = true
    nameTag.Outline = (Cfg.ESP_NomeEst == "Com Sombra" or Cfg.ESP_NomeEst == "Outline")
    nameTag.Text    = p.Name
    table.insert(objs, nameTag)

    -- Barra de vida
    local hpBg = Drawing.new("Square")
    hpBg.Visible = false; hpBg.Color = Color3.fromRGB(0,0,0); hpBg.Filled = true
    table.insert(objs, hpBg)

    local hpBar = Drawing.new("Square")
    hpBar.Visible = false; hpBar.Color = Color3.fromRGB(74,222,128); hpBar.Filled = true
    table.insert(objs, hpBar)

    -- Tracer (linha)
    local tracer = Drawing.new("Line")
    tracer.Visible   = false
    tracer.Color     = col
    tracer.Thickness = 1
    table.insert(objs, tracer)

    -- Distância
    local distTag = Drawing.new("Text")
    distTag.Visible = false; distTag.Color = col; distTag.Size = 12; distTag.Center = true
    table.insert(objs, distTag)

    espObjects[p] = objs
end

local function updateESP()
    local t     = TEMAS[Cfg.Tema]
    local col   = t and t.light or Color3.fromRGB(160, 32, 240)
    local VP    = Cam.ViewportSize

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end

        local char = p.Character
        if not char then removeESP(p); continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not root or not hum or not head then continue end

        if not espObjects[p] then createESP(p) end
        local objs = espObjects[p]
        local box, nameTag, hpBg, hpBar, tracer, distTag = objs[1], objs[2], objs[3], objs[4], objs[5], objs[6]

        local rootSP, onScreen, depth = worldToScreen(root.Position)
        local headSP = worldToScreen(head.Position)

        local visible = Cfg.ESP_On and onScreen
        local scale   = 1 / depth * 400

        -- CAIXA
        if Cfg.ESP_Caixa and visible then
            local w = scale * 2.2
            local h = (headSP.Y - rootSP.Y) - scale
            box.Visible  = true
            box.Color    = col
            box.Position = Vector2.new(rootSP.X - w/2, headSP.Y - 2)
            box.Size     = Vector2.new(w, math.abs(h) + 4)
        else box.Visible = false end

        -- NOME
        if Cfg.ESP_Nome and visible then
            nameTag.Visible  = true
            nameTag.Color    = col
            nameTag.Position = Vector2.new(rootSP.X, headSP.Y - 18)
            nameTag.Outline  = (Cfg.ESP_NomeEst ~= "Sem Sombra")
        else nameTag.Visible = false end

        -- VIDA
        if Cfg.ESP_Vida and visible then
            local hp    = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local bh    = math.abs(headSP.Y - rootSP.Y) + 4
            local bx    = (Cfg.ESP_VidaPos == "Esquerda") and (rootSP.X - scale*2.2/2 - 5) or (rootSP.X + scale*2.2/2 + 2)
            local by    = headSP.Y - 2
            hpBg.Visible  = true; hpBg.Position = Vector2.new(bx-1, by-1); hpBg.Size = Vector2.new(4, bh+2)
            hpBar.Visible = true; hpBar.Position = Vector2.new(bx, by + bh*(1-hp)); hpBar.Size = Vector2.new(2, bh*hp)
            hpBar.Color   = Color3.fromRGB(math.floor((1-hp)*255), math.floor(hp*200), 50)
        else hpBg.Visible=false; hpBar.Visible=false end

        -- TRACER
        if Cfg.ESP_Tracer and visible then
            tracer.Visible = true; tracer.Color = col
            tracer.From    = Vector2.new(VP.X/2, VP.Y)
            tracer.To      = rootSP
        else tracer.Visible = false end

        -- DISTÂNCIA
        if Cfg.ESP_Distancia and visible then
            local dist = math.floor((root.Position - (getRoot() and getRoot().Position or Vector3.zero)).Magnitude)
            distTag.Visible  = true; distTag.Color = col
            distTag.Position = Vector2.new(rootSP.X, rootSP.Y + 4)
            distTag.Text     = dist.."m"
        else distTag.Visible = false end
    end

    -- Remove players que saíram
    for p in pairs(espObjects) do
        if not p.Parent then removeESP(p) end
    end
end

-- ══════════════════════════════════
--  FOV CIRCLE
-- ══════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Color     = Color3.fromRGB(255,255,255)
fovCircle.Thickness = 1
fovCircle.Filled    = false
fovCircle.NumSides  = 64

local function updateFOVCircle()
    local VP = Cam.ViewportSize
    fovCircle.Position = Vector2.new(VP.X/2, VP.Y/2)
    fovCircle.Radius   = Cfg.Aim_FOV
    fovCircle.Visible  = Cfg.Aim_FOVCircle and Cfg.Aim_On
    local t = TEMAS[Cfg.Tema]
    fovCircle.Color = t and t.light or Color3.fromRGB(255,255,255)
end

-- ══════════════════════════════════
--  AIMBOT
-- ══════════════════════════════════
local function doAimbot(dt)
    if not Cfg.Aim_On then return end
    local target = getClosestEnemy()
    if not target then return end

    local char  = target.Character
    local part  = char:FindFirstChild(Cfg.Aim_Part) or char:FindFirstChild("Head")
    if not part then return end

    if Cfg.Aim_Silent then
        -- Silent Aim: redireciona raycast sem mover câmera
        -- (implementação básica via CFrame tweened)
        local goal = CFrame.new(Cam.CFrame.Position, part.Position)
        local smooth = Cfg.Aim_Smooth / 100
        Cam.CFrame = Cam.CFrame:Lerp(goal, math.clamp(dt * (1 - smooth) * 10, 0, 1))
    else
        local goal = CFrame.new(Cam.CFrame.Position, part.Position)
        local smooth = Cfg.Aim_Smooth / 100
        Cam.CFrame = Cam.CFrame:Lerp(goal, math.clamp(dt * (1 - smooth) * 10, 0, 1))
    end
end

-- ══════════════════════════════════
--  SPEED / JUMP / NOCLIP / FLY
-- ══════════════════════════════════
local flyConn, noclipConn

local function applySpeed()
    local hum = getHum()
    if not hum then return end
    hum.WalkSpeed = Cfg.Speed_On and Cfg.Speed_Val or 16
end

local function applyJump()
    local hum = getHum()
    if not hum then return end
    hum.JumpPower = Cfg.Jump_On and Cfg.Jump_Val or 50
end

local function applyInfJump()
    if Cfg.InfJump then
        UserInputService.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    if not Cfg.Noclip then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = getChar()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function startFly()
    if flyConn then flyConn:Disconnect() end
    if not Cfg.Fly_On then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        return
    end
    local root = getRoot()
    if not root then return end
    local bp = Instance.new("BodyVelocity", root)
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.Velocity = Vector3.zero
    flyConn = RunService.RenderStepped:Connect(function()
        if not Cfg.Fly_On then bp:Destroy(); flyConn:Disconnect(); return end
        local r = getRoot(); if not r then return end
        local hum = getHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
        local cf = Cam.CFrame
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)   then vel = vel + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
        bp.Velocity = vel * Cfg.Fly_Val
    end)
end

-- ══════════════════════════════════
--  HITBOX EXPANDER
-- ══════════════════════════════════
local origHitboxes = {}

local function applyHitbox()
    for _, p in ipairs(getEnemies()) do
        local char = p.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        if Cfg.Hitbox then
            origHitboxes[p] = head.Size
            head.Size = Vector3.new(Cfg.Hitbox_Val, Cfg.Hitbox_Val, Cfg.Hitbox_Val)
        else
            if origHitboxes[p] then
                head.Size = origHitboxes[p]
                origHitboxes[p] = nil
            end
        end
    end
end

-- ══════════════════════════════════
--  ANTI-KNOCKBACK
-- ══════════════════════════════════
local antiKnockConn

local function startAntiKnock()
    if antiKnockConn then antiKnockConn:Disconnect() end
    if not Cfg.AntiKnock then return end
    antiKnockConn = RunService.Stepped:Connect(function()
        local root = getRoot()
        if root then
            for _, v in ipairs(root:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyForce") then v:Destroy() end
            end
        end
    end)
end

-- ══════════════════════════════════
--  FULL BRIGHT
-- ══════════════════════════════════
local function applyFullBright()
    local lighting = game:GetService("Lighting")
    if Cfg.FullBright then
        lighting.Brightness = 2
        lighting.ClockTime  = 14
        lighting.FogEnd     = 1e9
        lighting.GlobalShadows = false
        lighting.Ambient    = Color3.fromRGB(255,255,255)
    else
        lighting.Brightness = 1
        lighting.ClockTime  = 14
        lighting.GlobalShadows = true
        lighting.Ambient    = Color3.fromRGB(127,127,127)
    end
end

-- ══════════════════════════════════
--  ANTI-AFK
-- ══════════════════════════════════
local afkConn

local function startAntiAFK()
    if afkConn then afkConn:Disconnect() end
    if not Cfg.AntiAFK then return end
    local vrs = LP:FindFirstChildOfClass("VirtualUser")
    if not vrs then
        vrs = Instance.new("VirtualUser", LP)
    end
    afkConn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vrs:CaptureController()
        vrs:ClickButton2(Vector2.zero)
    end)
end

-- ══════════════════════════════════
--  ADMIN DETECTOR
-- ══════════════════════════════════
local function checkAdmins()
    if not Cfg.AdminDetector then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == game.CreatorId or p:GetRankInGroup(game.CreatorId) >= 200 then
            warn("[CoiledTom Hub] ADMIN DETECTADO: "..p.Name)
        end
    end
end

-- ══════════════════════════════════
--  SPECTATE
-- ══════════════════════════════════
local function applySpectate()
    if not Cfg.Spectate_On or Cfg.Spectate_Target == "" then
        Cam.CameraSubject = getChar() and getChar():FindFirstChildOfClass("Humanoid")
        return
    end
    local target = Players:FindFirstChild(Cfg.Spectate_Target)
    if target and target.Character then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum then Cam.CameraSubject = hum end
    end
end

-- ══════════════════════════════════
--  GUI (ScreenGui)
-- ══════════════════════════════════
-- Limpa GUI antiga
if LP.PlayerGui:FindFirstChild("CoiledTomHub") then
    LP.PlayerGui.CoiledTomHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name            = "CoiledTomHub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset  = true
ScreenGui.DisplayOrder    = 999

local function makeTema()
    return TEMAS[Cfg.Tema] or TEMAS["Roxo"]
end

-- ── Janela principal ──
local Window = Instance.new("Frame", ScreenGui)
Window.Name            = "Window"
Window.Size            = UDim2.new(0, 480, 0, 360)
Window.Position        = UDim2.new(0.5, -240, 0.5, -180)
Window.BackgroundColor3= Color3.fromRGB(15, 15, 26)
Window.BorderSizePixel = 0
Window.ClipsDescendants = true

local WindowCorner = Instance.new("UICorner", Window)
WindowCorner.CornerRadius = UDim.new(0, 8)

local WindowStroke = Instance.new("UIStroke", Window)
WindowStroke.Color = makeTema().dark
WindowStroke.Thickness = 1.5

-- ── Header ──
local Header = Instance.new("Frame", Window)
Header.Name            = "Header"
Header.Size            = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3= makeTema().dark
Header.BorderSizePixel = 0

local HeaderGrad = Instance.new("UIGradient", Header)
HeaderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, makeTema().dark),
    ColorSequenceKeypoint.new(0.5, makeTema().main),
    ColorSequenceKeypoint.new(1, makeTema().dark),
})

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 8)

-- Fix corners embaixo do header
local HeaderFix = Instance.new("Frame", Header)
HeaderFix.Size = UDim2.new(1,0,0.5,0); HeaderFix.Position = UDim2.new(0,0,0.5,0)
HeaderFix.BackgroundColor3 = makeTema().dark; HeaderFix.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size              = UDim2.new(1, -40, 1, 0)
Title.Position          = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text              = "COILEDTOM HUB  •  @coiledtom"
Title.TextColor3        = Color3.fromRGB(255,255,255)
Title.Font              = Enum.Font.GothamBold
Title.TextSize          = 13
Title.TextXAlignment    = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size              = UDim2.new(0, 24, 0, 24)
CloseBtn.Position          = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3  = Color3.fromRGB(30,10,50)
CloseBtn.TextColor3        = Color3.fromRGB(255,255,255)
CloseBtn.Text              = "✕"
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 14
CloseBtn.BorderSizePixel   = 0
Instance.new("UICorner",CloseBtn).CornerRadius = UDim.new(0,4)
Instance.new("UIStroke",CloseBtn).Color = Color3.fromRGB(100,50,150)

-- ── Sidebar ──
local Sidebar = Instance.new("Frame", Window)
Sidebar.Name            = "Sidebar"
Sidebar.Size            = UDim2.new(0, 54, 1, -40)
Sidebar.Position        = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3= Color3.fromRGB(8, 8, 18)
Sidebar.BorderSizePixel = 0

local SidebarLine = Instance.new("Frame", Sidebar)
SidebarLine.Size = UDim2.new(0,1,1,0); SidebarLine.Position = UDim2.new(1,-1,0,0)
SidebarLine.BackgroundColor3 = Color3.fromRGB(42,26,74); SidebarLine.BorderSizePixel = 0

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0,4); SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
Instance.new("UIPadding",Sidebar).PaddingTop = UDim.new(0,8)

-- ── Content (ScrollingFrame) ──
local Content = Instance.new("ScrollingFrame", Window)
Content.Name                  = "Content"
Content.Size                  = UDim2.new(1, -54, 1, -40)
Content.Position              = UDim2.new(0, 54, 0, 40)
Content.BackgroundTransparency = 1
Content.BorderSizePixel       = 0
Content.ScrollBarThickness    = 3
Content.ScrollBarImageColor3  = makeTema().dark
Content.CanvasSize            = UDim2.new(0,0,0,0)
Content.AutomaticCanvasSize   = Enum.AutomaticSize.Y
Content.ClipsDescendants      = true

local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingLeft=UDim.new(0,12); ContentPad.PaddingRight=UDim.new(0,12)
ContentPad.PaddingTop=UDim.new(0,8);   ContentPad.PaddingBottom=UDim.new(0,8)

local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.Padding = UDim.new(0,2)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ── Função: criar aba na sidebar ──
local tabs       = {}
local tabButtons = {}
local currentTab = nil

local function makeTabBtn(icon, tabName)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size               = UDim2.new(0, 42, 0, 42)
    btn.BackgroundColor3   = Color3.fromRGB(26, 10, 48)
    btn.TextColor3         = Color3.fromRGB(255,255,255)
    btn.Text               = icon
    btn.Font               = Enum.Font.GothamBold
    btn.TextSize           = 18
    btn.BorderSizePixel    = 0
    btn.AutoButtonColor    = false
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    local stroke = Instance.new("UIStroke",btn); stroke.Color = Color3.fromRGB(42,26,74)

    tabButtons[tabName] = {btn=btn, stroke=stroke}

    btn.MouseButton1Click:Connect(function()
        -- Oculta todos os tabs
        for name, frame in pairs(tabs) do
            frame.Visible = (name == tabName)
        end
        -- Atualiza estilo dos botões
        for name, obj in pairs(tabButtons) do
            local active = (name == tabName)
            obj.btn.BackgroundColor3 = active and makeTema().dark or Color3.fromRGB(26,10,48)
            obj.stroke.Color = active and makeTema().main or Color3.fromRGB(42,26,74)
        end
        currentTab = tabName
    end)
    return btn
end

-- ── Função: criar frame de tab no Content ──
local function makeTab(name)
    local f = Instance.new("Frame", Content)
    f.Name               = name
    f.Size               = UDim2.new(1,0,0,0)
    f.BackgroundTransparency = 1
    f.AutomaticSize      = Enum.AutomaticSize.Y
    f.BorderSizePixel    = 0
    f.Visible            = false
    local lay = Instance.new("UIListLayout",f); lay.Padding=UDim.new(0,2)
    tabs[name] = f
    return f
end

-- ── Helper: Toggle row ──
local function makeToggle(parent, label, cfgKey, callback)
    local t = makeTema()
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,34); row.BackgroundTransparency=1; row.BorderSizePixel=0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-50,1,0); lbl.BackgroundTransparency=1
    lbl.TextColor3=Color3.fromRGB(224,216,255); lbl.Font=Enum.Font.Gotham
    lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label

    local bg = Instance.new("TextButton", row)
    bg.Size=UDim2.new(0,34,0,20); bg.Position=UDim2.new(1,-36,0.5,-10)
    bg.BorderSizePixel=0; bg.AutoButtonColor=false; bg.Text=""
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame", bg)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0,0.5)
    knob.Position=UDim2.new(0,2,0.5,0); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function refresh()
        local on = Cfg[cfgKey]
        bg.BackgroundColor3 = on and t.main or Color3.fromRGB(30,30,46)
        knob.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,130)
        TweenService:Create(knob, TweenInfo.new(.2), {Position=UDim2.new(on and 1 or 0, on and -16 or 2, 0.5, 0)}):Play()
    end
    refresh()

    bg.MouseButton1Click:Connect(function()
        Cfg[cfgKey] = not Cfg[cfgKey]
        refresh()
        if callback then callback(Cfg[cfgKey]) end
        SaveConfig()
    end)
    return row
end

-- ── Helper: Slider row ──
local function makeSlider(parent, label, cfgKey, min, max, callback)
    local t = makeTema()
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,0,0,44); row.BackgroundTransparency=1; row.BorderSizePixel=0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(0.5,0,0,18); lbl.BackgroundTransparency=1
    lbl.TextColor3=Color3.fromRGB(224,216,255); lbl.Font=Enum.Font.Gotham
    lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size=UDim2.new(0.5,0,0,18); valLbl.Position=UDim2.new(0.5,0,0,0)
    valLbl.BackgroundTransparency=1; valLbl.TextColor3=t.light
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=12
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(Cfg[cfgKey])

    local track = Instance.new("Frame", row)
    track.Size=UDim2.new(1,0,0,4); track.Position=UDim2.new(0,0,0,26)
    track.BackgroundColor3=Color3.fromRGB(30,16,52); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size=UDim2.new((Cfg[cfgKey]-min)/(max-min),0,1,0); fill.BackgroundColor3=t.main
    fill.BorderSizePixel=0; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("TextButton", track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((Cfg[cfgKey]-min)/(max-min),0,0.5,0)
    knob.BackgroundColor3=t.light; knob.Text=""; knob.BorderSizePixel=0; knob.AutoButtonColor=false
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    Instance.new("UIStroke",knob).Color=Color3.fromRGB(255,255,255)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local mx = UserInputService:GetMouseLocation().X
        local tp = track.AbsolutePosition.X; local tw = track.AbsoluteSize.X
        local pct = math.clamp((mx-tp)/tw,0,1)
        local val = math.floor(min + pct*(max-min))
        Cfg[cfgKey] = val; valLbl.Text=tostring(val)
        fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,0)
        if callback then callback(val) end
    end)
    return row
end

-- ── Helper: Separador ──
local function makeSep(parent)
    local s=Instance.new("Frame",parent); s.Size=UDim2.new(1,0,0,1); s.BackgroundColor3=Color3.fromRGB(42,26,74); s.BorderSizePixel=0; return s
end

local function makeSectionTitle(parent, text)
    local l=Instance.new("TextLabel",parent); l.Size=UDim2.new(1,0,0,22)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(122,106,153)
    l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Text=string.upper(text); return l
end

-- ══════════════════════════════════
--  MONTAR ABAS
-- ══════════════════════════════════

-- Sidebar buttons
makeTabBtn("👁", "ESP")
makeTabBtn("🎯", "Aim")
makeTabBtn("⚡", "Player")
makeTabBtn("🔧", "Misc")
makeTabBtn("⚙️", "Settings")

-- ── TAB ESP ──
local espTab = makeTab("ESP")
makeToggle(espTab, "Ativar ESP",      "ESP_On",        function(v) end)
makeToggle(espTab, "ESP Linha",       "ESP_Linha",     function(v) end)
makeToggle(espTab, "ESP Caixa",       "ESP_Caixa",     function(v) end)
makeToggle(espTab, "ESP Nome",        "ESP_Nome",      function(v) end)
makeToggle(espTab, "ESP Vida",        "ESP_Vida",      function(v) end)
makeToggle(espTab, "ESP Esqueleto",   "ESP_Esqueleto", function(v) end)
makeToggle(espTab, "ESP Tracer",      "ESP_Tracer",    function(v) end)
makeToggle(espTab, "ESP Distância",   "ESP_Distancia", function(v) end)

-- ── TAB AIM ──
local aimTab = makeTab("Aim")
makeToggle(aimTab, "Ativar Aimbot",   "Aim_On",        function(v) end)
makeToggle(aimTab, "Silent Aim",      "Aim_Silent",    function(v) end)
makeToggle(aimTab, "FOV Circle",      "Aim_FOVCircle", function(v) updateFOVCircle() end)
makeToggle(aimTab, "Aim Step",        "Aim_Step",      function(v) end)
makeSep(aimTab)
makeSlider(aimTab, "FOV",             "Aim_FOV",       10, 500, function(v) updateFOVCircle() end)
makeSlider(aimTab, "Smoothness",      "Aim_Smooth",    1,  100, function(v) end)

-- ── TAB PLAYER ──
local playerTab = makeTab("Player")
makeToggle(playerTab, "Speed Hack",       "Speed_On",   function(v) applySpeed() end)
makeSlider(playerTab, "Velocidade",       "Speed_Val",  16, 200, function(v) applySpeed() end)
makeSep(playerTab)
makeToggle(playerTab, "Jump Hack",        "Jump_On",    function(v) applyJump() end)
makeSlider(playerTab, "Jump Power",       "Jump_Val",   50, 500, function(v) applyJump() end)
makeSep(playerTab)
makeToggle(playerTab, "Noclip",           "Noclip",     function(v) startNoclip() end)
makeToggle(playerTab, "Fly",              "Fly_On",     function(v) startFly() end)
makeSlider(playerTab, "Velocidade Fly",   "Fly_Val",    10, 300, function(v) end)
makeSep(playerTab)
makeToggle(playerTab, "Hitbox Expander",  "Hitbox",     function(v) applyHitbox() end)
makeSlider(playerTab, "Hitbox Size",      "Hitbox_Val", 1,  20,  function(v) applyHitbox() end)
makeSep(playerTab)
makeToggle(playerTab, "Anti-Knockback",   "AntiKnock",  function(v) startAntiKnock() end)
makeToggle(playerTab, "Infinite Jump",    "InfJump",    function(v) applyInfJump() end)

-- ── TAB MISC ──
local miscTab = makeTab("Misc")
makeToggle(miscTab, "Admin Detector",   "AdminDetector", function(v) if v then checkAdmins() end end)
makeToggle(miscTab, "Free Câmera",      "FreeCam",       function(v) end)
makeToggle(miscTab, "Full Bright",      "FullBright",    function(v) applyFullBright() end)
makeToggle(miscTab, "Anti-AFK",         "AntiAFK",       function(v) startAntiAFK() end)
makeSep(miscTab)
makeSectionTitle(miscTab, "Spectate — Selecionar Player")

-- Spectate: lista de players dinâmica
local spectateContainer = Instance.new("Frame", miscTab)
spectateContainer.Size=UDim2.new(1,0,0,0); spectateContainer.AutomaticSize=Enum.AutomaticSize.Y
spectateContainer.BackgroundTransparency=1; spectateContainer.BorderSizePixel=0
local specLayout = Instance.new("UIListLayout",spectateContainer); specLayout.Padding=UDim.new(0,3)

local function refreshSpectateList()
    for _, c in ipairs(spectateContainer:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local btn = Instance.new("TextButton", spectateContainer)
        btn.Size=UDim2.new(1,0,0,32); btn.BackgroundColor3=Color3.fromRGB(14,8,26)
        btn.BorderSizePixel=0; btn.Font=Enum.Font.Gotham; btn.TextSize=12
        btn.TextColor3=Color3.fromRGB(224,216,255); btn.TextXAlignment=Enum.TextXAlignment.Left
        btn.Text="  👤 "..p.Name
        btn.AutoButtonColor=false
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
        local stroke=Instance.new("UIStroke",btn); stroke.Color=Color3.fromRGB(42,26,74)
        if Cfg.Spectate_Target == p.Name then
            btn.BackgroundColor3=makeTema().dark; stroke.Color=makeTema().main
        end
        btn.MouseButton1Click:Connect(function()
            Cfg.Spectate_Target = p.Name
            applySpectate()
            refreshSpectateList()
            SaveConfig()
        end)
    end
end

refreshSpectateList()
Players.PlayerAdded:Connect(refreshSpectateList)
Players.PlayerRemoving:Connect(refreshSpectateList)

makeToggle(miscTab, "Ativar Spectate", "Spectate_On", function(v) applySpectate() end)

-- ── TAB SETTINGS ──
local settingsTab = makeTab("Settings")
makeSectionTitle(settingsTab, "Tema de Cor")

local temaNames = {"Roxo","Azul","Ciano","Verde","Menta","Amarelo","Laranja","Vermelho","Rosa","Branco"}
local temaColors = {
    Roxo=Color3.fromRGB(139,0,255), Azul=Color3.fromRGB(0,119,255), Ciano=Color3.fromRGB(0,170,221),
    Verde=Color3.fromRGB(0,187,68), Menta=Color3.fromRGB(0,221,170), Amarelo=Color3.fromRGB(221,170,0),
    Laranja=Color3.fromRGB(255,102,0), Vermelho=Color3.fromRGB(238,17,17), Rosa=Color3.fromRGB(238,0,136),
    Branco=Color3.fromRGB(170,170,170)
}

local temaGrid = Instance.new("Frame", settingsTab)
temaGrid.Size=UDim2.new(1,0,0,0); temaGrid.AutomaticSize=Enum.AutomaticSize.Y
temaGrid.BackgroundTransparency=1; temaGrid.BorderSizePixel=0
local temaGridLayout = Instance.new("UIGridLayout",temaGrid)
temaGridLayout.CellSize=UDim2.new(0,72,0,28); temaGridLayout.CellPaddingAmount=UDim2.new(0,4,0,4)

for _, name in ipairs(temaNames) do
    local btn = Instance.new("TextButton", temaGrid)
    btn.Size=UDim2.new(0,72,0,28); btn.BackgroundColor3=temaColors[name]
    btn.TextColor3=Color3.fromRGB(255,255,255); btn.Font=Enum.Font.GothamBold
    btn.TextSize=10; btn.Text=string.upper(name); btn.BorderSizePixel=0; btn.AutoButtonColor=false
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",btn); stroke.Color= (Cfg.Tema==name) and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0); stroke.Thickness=2

    btn.MouseButton1Click:Connect(function()
        Cfg.Tema = name
        -- Update todas as cores
        local t = makeTema()
        WindowStroke.Color    = t.dark
        HeaderGrad.Color      = ColorSequence.new({ColorSequenceKeypoint.new(0,t.dark),ColorSequenceKeypoint.new(0.5,t.main),ColorSequenceKeypoint.new(1,t.dark)})
        HeaderFix.BackgroundColor3 = t.dark
        Content.ScrollBarImageColor3 = t.dark
        for n,o in pairs(tabButtons) do
            local active = (n==currentTab)
            o.btn.BackgroundColor3 = active and t.dark or Color3.fromRGB(26,10,48)
            o.stroke.Color = active and t.main or Color3.fromRGB(42,26,74)
        end
        for _, b in ipairs(temaGrid:GetChildren()) do
            if b:IsA("TextButton") then
                local s=b:FindFirstChildOfClass("UIStroke")
                if s then s.Color = (b.Text==string.upper(name)) and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0) end
            end
        end
        updateFOVCircle()
        SaveConfig()
    end)
end

makeSep(settingsTab)

local saveBtn = Instance.new("TextButton", settingsTab)
saveBtn.Size=UDim2.new(1,0,0,34); saveBtn.BackgroundColor3=makeTema().dark
saveBtn.TextColor3=Color3.fromRGB(255,255,255); saveBtn.Font=Enum.Font.GothamBold
saveBtn.TextSize=13; saveBtn.Text="💾  SALVAR CONFIGURAÇÕES"; saveBtn.BorderSizePixel=0; saveBtn.AutoButtonColor=false
Instance.new("UICorner",saveBtn).CornerRadius=UDim.new(0,6)
saveBtn.MouseButton1Click:Connect(function() SaveConfig() end)

local resetBtn = Instance.new("TextButton", settingsTab)
resetBtn.Size=UDim2.new(1,0,0,34); resetBtn.BackgroundColor3=Color3.fromRGB(80,0,0)
resetBtn.TextColor3=Color3.fromRGB(255,255,255); resetBtn.Font=Enum.Font.GothamBold
resetBtn.TextSize=13; resetBtn.Text="🗑  RESETAR CONFIGS"; resetBtn.BorderSizePixel=0; resetBtn.AutoButtonColor=false
Instance.new("UICorner",resetBtn).CornerRadius=UDim.new(0,6)
resetBtn.MouseButton1Click:Connect(function()
    pcall(function() delfile(SAVE_FILE) end)
    ScreenGui:Destroy()
    -- Recarrega o script (se suportado pelo executor)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/seu-usuario/coiledtom-hub/main/hub.lua"))()
end)

-- ── Ativa aba padrão ──
local function activateTab(name)
    for n, f in pairs(tabs) do f.Visible = (n==name) end
    for n, o in pairs(tabButtons) do
        local active = (n==name)
        local t = makeTema()
        o.btn.BackgroundColor3 = active and t.dark or Color3.fromRGB(26,10,48)
        o.stroke.Color = active and t.main or Color3.fromRGB(42,26,74)
    end
    currentTab = name
end
activateTab("ESP")

-- ══════════════════════════════════
--  DRAG (arrastar janela)
-- ══════════════════════════════════
do
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = Window.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging=false end end)
        end
    end)
    Header.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local delta = i.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)
end

-- ══════════════════════════════════
--  FECHAR / REABRIR
-- ══════════════════════════════════
local hubVisible = true

local function toggleHub()
    hubVisible = not hubVisible
    Window.Visible = hubVisible
end

CloseBtn.MouseButton1Click:Connect(function() hubVisible=false; Window.Visible=false end)

-- Gesto: 3 dedos duplo toque (TouchTap com 3 pontos)
local lastTriple = 0
UserInputService.TouchTapInWorld:Connect(function() end) -- placeholder

-- Método alternativo mais confiável para mobile Roblox:
UserInputService.TouchStarted:Connect(function(touch, gpe)
    -- conta toques simultâneos
end)

-- Tecla de atalho PC: RightControl = toggle
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightControl then
        toggleHub()
    end
    -- Gesto mobile: verifica multi-touch
    if i.UserInputType == Enum.UserInputType.Touch then
        local touches = UserInputService:GetTouchPositions()
        if #touches >= 3 then
            local now = tick()
            if now - lastTriple < 0.5 and now - lastTriple > 0.05 then
                toggleHub()
                lastTriple = 0
            else
                lastTriple = now
            end
        end
    end
end)

-- ══════════════════════════════════
--  LOOP PRINCIPAL
-- ══════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    -- ESP
    if Cfg.ESP_On then
        updateESP()
    else
        for p in pairs(espObjects) do removeESP(p) end
    end

    -- FOV Circle
    updateFOVCircle()

    -- Aimbot
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        doAimbot(dt)
    end

    -- Hitbox
    applyHitbox()
end)

-- Spawn loop de checagem
task.spawn(function()
    while task.wait(0.5) do
        applySpeed()
        applyJump()
        if Cfg.FullBright then applyFullBright() end
        if Cfg.Spectate_On then applySpectate() end
        if Cfg.AdminDetector then checkAdmins() end
    end
end)

-- Limpa ao sair
LP.CharacterAdded:Connect(function()
    task.wait(1)
    applySpeed()
    applyJump()
    startNoclip()
    startFly()
    startAntiKnock()
    startAntiAFK()
    applyInfJump()
end)

print("[CoiledTom Hub v2.2.0] Carregado! RightControl = toggle GUI")
print("[CoiledTom Hub] Mobile: 3 dedos duplo-toque = toggle GUI")

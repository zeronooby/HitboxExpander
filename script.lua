-- Zeron HUB | Invisible Torso Hitbox (R6+R15) + Silent Aim
-- Delta / Fluxus / Solara / Wave
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Zeron HUB - Anti Detect",
    LoadingTitle = "Inicializando...",
    LoadingSubtitle = "2026",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZeronAntiDetect",
        FileName = "Settings"
    },
    KeySystem = false
})
-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
-- CONFIG
getgenv().Config = {
    Hitbox = {
        Enabled = false,
        Size = 14,
        TeamCheck = true,
        ShowBox = true -- caixa vermelha (debug) apenas para hitbox atirável (não team)
    },
    Aimbot = {
        Enabled = false,
        FOV = 120,
        ShowFOV = false,
        Part = "Auto", -- Auto = R6/R15
        TeamCheck = true,
        VisibleCheck = true,
        HitChance = 82,
        Prediction = true,
        PredAmount = 0.135,
        Jitter = 0.8
    }
}
-- ======================
-- R6 / R15 TORSO
-- ======================
local function getTorso(character)
    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("LowerTorso")
        or character:FindFirstChild("Torso")
end
-- ======================
-- INVISIBLE HITBOX
-- ======================
local function createHitbox(char)
    local torso = getTorso(char)
    if not torso then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then return end
    local isTeammate = (plr.Team == LocalPlayer.Team)
    local hb = char:FindFirstChild("SilentHitbox")
    local sizeJitter = Config.Hitbox.Size + math.random(-1, 1) -- anti-detect: randomize size levemente
    if hb then
        hb.Size = Vector3.new(sizeJitter, sizeJitter, sizeJitter)
        return
    end
    hb = Instance.new("Part")
    hb.Name = "SilentHitbox"
    hb.Size = Vector3.new(sizeJitter, sizeJitter, sizeJitter)
    hb.CFrame = torso.CFrame
    hb.Anchored = false
    hb.Massless = true
    hb.Transparency = 1
    hb.LocalTransparencyModifier = 1
    hb.CanCollide = false
    hb.CanTouch = false
    hb.CanQuery = true -- tiros / faca acertam
    hb.Parent = char
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hb
    weld.Part1 = torso
    weld.Parent = hb
    if Config.Hitbox.ShowBox and not isTeammate then -- apenas visível para hitbox atirável (não team)
        local box = Instance.new("SelectionBox")
        box.Adornee = hb
        box.Color3 = Color3.fromRGB(255,0,0)
        box.LineThickness = 0.05
        box.SurfaceTransparency = 1
        box.Parent = hb
    end
end
local function removeHitbox(char)
    local hb = char:FindFirstChild("SilentHitbox")
    if hb then hb:Destroy() end
end
-- ======================
-- HITBOX LOOP
-- ======================
task.spawn(function()
    while true do
        task.wait(0.3 + math.random() * 0.15) -- anti-detect: randomize timing para evitar padrões
        for _, plr in Players:GetPlayers() do
            if not plr.Character or plr == LocalPlayer then continue end
            if Config.Hitbox.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            if Config.Hitbox.Enabled then
                createHitbox(plr.Character)
            else
                removeHitbox(plr.Character)
            end
        end
    end
end)
-- ======================
-- FOV CIRCLE
-- ======================
local FOVCircle = Drawing.new("Circle")
FOVCircle.NumSides = 64
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(220,50,50)
FOVCircle.Transparency = 0.9
FOVCircle.Visible = false
-- ======================
-- SILENT AIM
-- ======================
local silentPos = nil
local function worldToScreen(pos)
    local v, onscreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onscreen
end
local function isVisible(part)
    if not Config.Aimbot.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, part.Position - origin, params)
    return result and result.Instance:IsDescendantOf(part.Parent)
end
local function getClosest()
    local mouse = UIS:GetMouseLocation()
    local best, dist = nil, Config.Aimbot.FOV
    for _, plr in Players:GetPlayers() do
        if plr == LocalPlayer or not plr.Character then continue end
        if Config.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        local part = getTorso(plr.Character)
        if not part or not isVisible(part) then continue end
        local screenPos, onscreen = worldToScreen(part.Position)
        if not onscreen then continue end
        local mag = (screenPos - mouse).Magnitude
        if mag < dist then
            dist = mag
            best = part
        end
    end
    return best
end
RunService.Heartbeat:Connect(function()
    silentPos = nil
    if not Config.Aimbot.Enabled then
        FOVCircle.Visible = false
        return
    end
    local target = getClosest()
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Visible = Config.Aimbot.ShowFOV
    if target then
        local predJitter = Config.Aimbot.PredAmount + math.random(-0.015, 0.015) -- anti-detect: randomize prediction levemente
        local pos = target.Position
        if Config.Aimbot.Prediction then
            pos += target.Velocity * predJitter
        end
        local j = Config.Aimbot.Jitter
        pos = pos + Vector3.new(math.random(-j, j), math.random(-j, j), math.random(-j, j)) -- anti-detect: jitter para humanizar
        silentPos = pos
    end
end)
-- ======================
-- RAYCAST HOOK
-- ======================
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt,false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if Config.Aimbot.Enabled
    and silentPos
    and math.random(1,100) <= (Config.Aimbot.HitChance + math.random(-5, 5)) -- anti-detect: randomize hitchance levemente
    and self == workspace
    and method == "Raycast" then
        local dir = (silentPos - args[1]).Unit * 2000
        local jitterDir = Vector3.new(math.random(-0.01, 0.01), math.random(-0.01, 0.01), math.random(-0.01, 0.01)) -- anti-detect: pequeno jitter na direção
        args[2] = dir + jitterDir
    end
    return old(self, unpack(args))
end)
setreadonly(mt,true)
-- ======================
-- GUI
-- ======================
local HBTab = Window:CreateTab("Hitbox", 4483362458)
HBTab:CreateToggle({
    Name = "Ativar Hitbox Invisível",
    CurrentValue = false,
    Callback = function(v) Config.Hitbox.Enabled = v end
})
HBTab:CreateSlider({
    Name = "Tamanho",
    Range = {8, 24},
    Increment = 1,
    CurrentValue = 14,
    Callback = function(v) Config.Hitbox.Size = v end
})
HBTab:CreateToggle({
    Name = "Team Check (Skip Team)",
    CurrentValue = true,
    Callback = function(v) Config.Hitbox.TeamCheck = v end
})
HBTab:CreateToggle({
    Name = "Mostrar Caixa Vermelha (Apenas Inimigos)",
    CurrentValue = true,
    Callback = function(v) Config.Hitbox.ShowBox = v end
})
local ATab = Window:CreateTab("Aimbot", 4483362458)
ATab:CreateToggle({
    Name = "Ativar Silent Aim",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.Enabled = v end
})
ATab:CreateSlider({
    Name = "FOV",
    Range = {50, 300},
    Increment = 10,
    CurrentValue = 120,
    Callback = function(v) Config.Aimbot.FOV = v end
})
ATab:CreateToggle({
    Name = "Mostrar FOV",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.ShowFOV = v end
})
ATab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.TeamCheck = v end
})
ATab:CreateToggle({
    Name = "Visible Check",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.VisibleCheck = v end
})
ATab:CreateSlider({
    Name = "Hit Chance (%)",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 82,
    Callback = function(v) Config.Aimbot.HitChance = v end
})
ATab:CreateToggle({
    Name = "Prediction",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.Prediction = v end
})
ATab:CreateSlider({
    Name = "Pred Amount",
    Range = {0.1, 0.2},
    Increment = 0.005,
    CurrentValue = 0.135,
    Callback = function(v) Config.Aimbot.PredAmount = v end
})
ATab:CreateSlider({
    Name = "Jitter",
    Range = {0, 2},
    Increment = 0.1,
    CurrentValue = 0.8,
    Callback = function(v) Config.Aimbot.Jitter = v end
})
Rayfield:Notify({
    Title = "Zeron HUB",
    Content = "Hitbox invisível + Silent Aim carregado com anti-detect.",
    Duration = 5
})
print("Zeron HUB | Invisible Hitbox + Silent Aim")```

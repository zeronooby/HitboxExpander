-- Rafael Hub | Hitbox + Silent Aim | Anti-Detect Lite 2026
-- Delta/Solara/Fluxus/Wave compatível
-- Use com alt account sempre!

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Zeron HUB - Anti-Detect Mode",
    LoadingTitle = "Carregando com cuidado...",
    LoadingSubtitle = "by Grok | 2026",
    ConfigurationSaving = {Enabled = true, FolderName = "RafaelAntiDetect", FileName = "settings"},
    KeySystem = false
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações
getgenv().Config = {
    Hitbox = {
        Enabled = false,
        Size = 10,
        Trans = 0.75,
        TeamCheck = true,
        Color = Color3.fromRGB(200, 0, 150)
    },
    Aimbot = {
        Enabled = false,
        FOV = 120,
        FOVShow = false,
        Part = "Head",
        TeamCheck = true,
        VisibleCheck = true,
        HitChance = 82,
        Prediction = true,
        PredAmount = 0.135,
        Jitter = 0.8
    }
}

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 60
fovCircle.Radius = Config.Aimbot.FOV
fovCircle.Color = Color3.fromRGB(220, 50, 50)
fovCircle.Transparency = 0.9
fovCircle.Visible = false

local closest = nil

-- Funções úteis
local function worldToScreen(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function isVisible(targetPart)
    if not Config.Aimbot.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = (targetPart.Position - origin).Unit * 999
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character or {}}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, dir, params)
    return result and result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosest()
    local mouse = UserInputService:GetMouseLocation()
    local best, dist = nil, Config.Aimbot.FOV
    for _, plr in Players:GetPlayers() do
        if plr == LocalPlayer or not plr.Character then continue end
        if Config.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character
        local targetPart = char:FindFirstChild(Config.Aimbot.Part) or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end
        if not isVisible(targetPart) then continue end
        local screenPos, onScreen = worldToScreen(targetPart.Position)
        if not onScreen then continue end
        local mag = (screenPos - mouse).Magnitude
        if mag < dist then
            dist = mag
            best = targetPart
        end
    end
    return best
end

-- ========================
-- HITBOX EXPANDER
-- ========================
spawn(function()
    while true do
        if not Config.Hitbox.Enabled then
            task.wait(1.2 + math.random(0, 8)/10)
            continue
        end

        for _, plr in Players:GetPlayers() do
            if plr == LocalPlayer or not plr.Character then continue end
            if Config.Hitbox.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            
            pcall(function()
                for _, part in plr.Character:GetChildren() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if not part:GetAttribute("OGSize") then
                            part:SetAttribute("OGSize", part.Size)
                            part:SetAttribute("OGTrans", part.Transparency)
                        end
                        local randomFactor = 0.95 + math.random(-5,5)/100
                        part.Size = Vector3.new(Config.Hitbox.Size, Config.Hitbox.Size, Config.Hitbox.Size) * randomFactor
                        part.Transparency = Config.Hitbox.Trans
                        part.Color = Config.Hitbox.Color
                        part.CanCollide = false
                    end
                end
            end)
        end
        
        task.wait(0.18 + math.random(1,9)/100)
    end
end)

local function revertHitbox()
    for _, plr in Players:GetPlayers() do
        pcall(function()
            for _, part in plr.Character:GetChildren() do
                if part:IsA("BasePart") and part:GetAttribute("OGSize") then
                    part.Size = part:GetAttribute("OGSize")
                    part.Transparency = part:GetAttribute("OGTrans")
                    part.CanCollide = true
                end
            end
        end)
    end
end

-- ========================
-- AIMBOT (Silent Aim)
-- ========================
RunService.Heartbeat:Connect(function()
    closest = nil
    if not Config.Aimbot.Enabled then
        fovCircle.Visible = false
        return
    end

    closest = getClosest()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = Config.Aimbot.FOV
    fovCircle.Visible = Config.Aimbot.FOVShow

    if closest then
        local predPos = closest.Position
        if Config.Aimbot.Prediction and closest.Velocity then
            predPos += closest.Velocity * Config.Aimbot.PredAmount
        end
        -- Adiciona jitter
        predPos += Vector3.new(
            math.random(-Config.Aimbot.Jitter*10, Config.Aimbot.Jitter*10)/10,
            math.random(-Config.Aimbot.Jitter*5, Config.Aimbot.Jitter*5)/10,
            math.random(-Config.Aimbot.Jitter*5, Config.Aimbot.Jitter*5)/10
        )
    end
end)

-- Hook namecall (usado pelo Aimbot)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Config.Aimbot.Enabled and closest and math.random(1,100) <= Config.Aimbot.HitChance then
        if (method == "Raycast" or method == "FindPartOnRayWithIgnoreList" or method:find("Ray")) and self == workspace then
            local origin = args[1]
            local pred = closest.Position
            if Config.Aimbot.Prediction then
                pred += closest.Velocity * Config.Aimbot.PredAmount
            end
            if method == "Raycast" then
                args[2] = (pred - origin).Unit * 2000
            else
                args[1] = Ray.new(origin, (pred - origin).Unit * 2000)
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- ========================
-- INTERFACE (GUI)
-- ========================

-- Tab Hitbox
local HBTab = Window:CreateTab("Hitbox Expander", 4483362458)
HBTab:CreateToggle({
    Name = "Ativar Hitbox",
    CurrentValue = false,
    Callback = function(v)
        Config.Hitbox.Enabled = v
        if not v then revertHitbox() end
    end
})
HBTab:CreateSlider({
    Name = "Tamanho (recom: 8-18)",
    Range = {6, 22},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v) Config.Hitbox.Size = v end
})
HBTab:CreateSlider({
    Name = "Transparência",
    Range = {0.4, 0.9},
    Increment = 0.05,
    CurrentValue = 0.75,
    Callback = function(v) Config.Hitbox.Trans = v end
})
HBTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.Hitbox.TeamCheck = v end
})

-- Tab Aimbot
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
AimbotTab:CreateToggle({
    Name = "Ativar Aimbot",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.Enabled = v end
})
AimbotTab:CreateSlider({
    Name = "FOV",
    Range = {60, 250},
    Increment = 5,
    CurrentValue = 120,
    Callback = function(v) Config.Aimbot.FOV = v end
})
AimbotTab:CreateToggle({
    Name = "Mostrar FOV Circle",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.FOVShow = v end
})
AimbotTab:CreateDropdown({
    Name = "Parte Alvo",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Callback = function(opt) Config.Aimbot.Part = opt end
})
AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.TeamCheck = v end
})
AimbotTab:CreateToggle({
    Name = "Visible Check (Wall)",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.VisibleCheck = v end
})
AimbotTab:CreateSlider({
    Name = "Hit Chance %",
    Range = {60, 100},
    Increment = 1,
    CurrentValue = 82,
    Callback = function(v) Config.Aimbot.HitChance = v end
})
AimbotTab:CreateToggle({
    Name = "Predição",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.Prediction = v end
})
AimbotTab:CreateSlider({
    Name = "Força da Predição",
    Range = {0.08, 0.22},
    Increment = 0.005,
    CurrentValue = 0.135,
    Callback = function(v) Config.Aimbot.PredAmount = v end
})
AimbotTab:CreateSlider({
    Name = "Jitter (humanizar)",
    Range = {0.3, 1.5},
    Increment = 0.1,
    CurrentValue = 0.8,
    Callback = function(v) Config.Aimbot.Jitter = v end
})

Rayfield:Notify({
    Title = "Zeron Hub Anti-Detect",
    Content = "Carregado! Use com cuidado e alt account.",
    Duration = 6
})

print("Zeron Hub carregado | Hitbox + Aimbot separado")

-- Zeron HUB | Invisible Torso Hitbox (R6+R15) + Silent Aim

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Zeron HUB - Anti Detect",
    LoadingTitle = "Inicializando...",
    LoadingSubtitle = "ZeroNoob",
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
        ShowBox = true
    },
    Aimbot = {
        Enabled = false,
        FOV = 120,
        ShowFOV = false,
        TeamCheck = true,
        VisibleCheck = true,
        HitChance = 82,
        Prediction = true,
        PredAmount = 0.135,
        Jitter = 0.8
    }
}

local Config = getgenv().Config

-- R6 / R15
local function getTorso(char)
    return char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("LowerTorso")
        or char:FindFirstChild("Torso")
end

-- HITBOX
local function createHitbox(char)
    local torso = getTorso(char)
    if not torso then return end

    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then return end
    if Config.Hitbox.TeamCheck and plr.Team == LocalPlayer.Team then return end

    local hb = char:FindFirstChild("SilentHitbox")
    local size = Config.Hitbox.Size + math.random(-1,1)

    if hb then
        hb.Size = Vector3.new(size,size,size)
        return
    end

    hb = Instance.new("Part")
    hb.Name = "SilentHitbox"
    hb.Size = Vector3.new(size,size,size)
    hb.CFrame = torso.CFrame
    hb.Transparency = 1
    hb.CanCollide = false
    hb.CanTouch = false
    hb.CanQuery = true
    hb.Massless = true
    hb.Parent = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hb
    weld.Part1 = torso
    weld.Parent = hb

    if Config.Hitbox.ShowBox then
        local box = Instance.new("SelectionBox")
        box.Adornee = hb
        box.Color3 = Color3.fromRGB(255,0,0)
        box.LineThickness = 0.05
        box.Parent = hb
    end
end

local function removeHitbox(char)
    local hb = char:FindFirstChild("SilentHitbox")
    if hb then hb:Destroy() end
end

-- LOOP HITBOX
task.spawn(function()
    while true do
        task.wait(0.35 + math.random()*0.15)
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if Config.Hitbox.Enabled then
                    createHitbox(plr.Character)
                else
                    removeHitbox(plr.Character)
                end
            end
        end
    end
end)

-- VISIBILITY CHECK (FIXED)
local function isVisible(part)
    if not Config.Aimbot.VisibleCheck then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(
        Camera.CFrame.Position,
        part.Position - Camera.CFrame.Position,
        params
    )

    return (not result) or result.Instance:IsDescendantOf(part.Parent)
end

-- SILENT AIM CORE
local silentPos

RunService.Heartbeat:Connect(function()
    silentPos = nil
    if not Config.Aimbot.Enabled then return end

    local mouse = UIS:GetMouseLocation()
    local closest, dist = nil, Config.Aimbot.FOV

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if Config.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            local part = getTorso(plr.Character)
            if part and isVisible(part) then
                local pos, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local mag = (Vector2.new(pos.X,pos.Y) - mouse).Magnitude
                    if mag < dist then
                        dist = mag
                        closest = part
                    end
                end
            end
        end
    end

    if closest then
        local p = closest.Position
        if Config.Aimbot.Prediction then
            p += closest.Velocity * (Config.Aimbot.PredAmount + math.random(-15,15)/1000)
        end
        local j = Config.Aimbot.Jitter
        silentPos = p + Vector3.new(
            math.random(-j,j),
            math.random(-j,j),
            math.random(-j,j)
        )
    end
end)

-- RAYCAST HOOK (SAFE)
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt,false)

mt.__namecall = newcclosure(function(self,...)
    local args = {...}
    if Config.Aimbot.Enabled
    and silentPos
    and self == workspace
    and getnamecallmethod() == "Raycast"
    and typeof(args[1]) == "Vector3"
    and typeof(args[2]) == "Vector3"
    and math.random(1,100) <= Config.Aimbot.HitChance then
        args[2] = (silentPos - args[1]).Unit * 2000
        return old(self, unpack(args))
    end
    return old(self,...)
end)

setreadonly(mt,true)

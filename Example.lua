--[[
    xtvo Hub - Fling Script Implementation
    Powered by xtvo Lib 🍵
    
    Ported from fling_improved.lua
]]

--------------------------------------------------------------------------------
-- LIBRARY LOADER
--------------------------------------------------------------------------------
local RepoURL = "https://raw.githubusercontent.com/xtvoo/uilib/main/xtvoLib.lua"
local Library
pcall(function()
    -- Dev Mode: Load from local file if available
    if isfile and isfile("matcha_ui/xtvoLib.lua") then
        Library = loadstring(readfile("matcha_ui/xtvoLib.lua"))()
    else
        Library = loadstring(game:HttpGet(RepoURL))()
    end
end)
if not Library then Library = loadstring(game:HttpGet(RepoURL))() end

--------------------------------------------------------------------------------
-- SERVICES & VARIABLES
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local OWNER = Players.LocalPlayer
local Mouse = OWNER:GetMouse()

-- State
local UnanchoredPart = nil
local TargetMode = "Target" -- Target, Nearest, Key, Constant
local TARGET = nil
local Active = false
local AutoPrediction = false
local AutoClaim = false
local RotationEnabled = false

-- Settings
local Config = {
    Prediction = 0.8,
    Distance = 50,
    Offsets = {X = 8, Y = 8, Z = 8},
    Rotation = {X = 0, Y = 0, Z = 0}
}
local Force = Vector3.new(-10000, -10000, -10000)
local OriginalVelocity = {} -- Placeholder for more advanced pred if needed
local hbConnection = nil
local SelectionMode = false
local SelectionHighlight = nil

--------------------------------------------------------------------------------
-- CORE FUNCTIONS
--------------------------------------------------------------------------------
local function Notify(msg)
    game.StarterGui:SetCore("SendNotification", {Title = "xtvo Hub"; Text = msg; Duration = 3})
end

local function ClaimNetworkOwnership()
    if UnanchoredPart then
        pcall(function() UnanchoredPart:SetNetworkOwner(OWNER) end)
    end
end

local function ClaimSeat(seatPart)
    if not seatPart then return end
    if not (seatPart:IsA("Seat") or seatPart:IsA("VehicleSeat")) then
        Notify("⚠️ Not a Seat!")
        return
    end

    Notify("🪑 Claiming Seat...")
    local char = OWNER.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if root and hum then
        local originalCF = root.CFrame
        local seatCF = seatPart.CFrame
        
        root.CFrame = seatCF + Vector3.new(0, 2, 0)
        seatPart:Sit(hum)
        task.wait(0.2)
        pcall(function() seatPart:SetNetworkOwner(OWNER) end)
        task.wait(0.1)
        hum.Sit = false
        task.wait(0.1)
        root.CFrame = originalCF
        Notify("✅ Seat Claimed!")
    end
end

local function GetNearestPlayer()
    local Nearest = nil
    local MinDist = Config.Distance
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= OWNER and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (OWNER.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if dist < MinDist then
                MinDist = dist
                Nearest = v
            end
        end
    end
    return Nearest
end

local function SpawnPart()
    if UnanchoredPart and UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
        UnanchoredPart.BodyPosition.Position = OWNER.Character.HumanoidRootPart.Position + 
            Vector3.new(Config.Offsets.X, Config.Offsets.Y, Config.Offsets.Z)
        UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
    end
end

local function StopFling()
    Active = false
    if hbConnection then hbConnection:Disconnect() hbConnection = nil end
    if UnanchoredPart then
        for _, c in pairs(UnanchoredPart:GetChildren()) do
            if c:IsA("BodyPosition") or c:IsA("BodyThrust") or c:IsA("BodyGyro") then c:Destroy() end
        end
        UnanchoredPart.Velocity = Vector3.zero
        UnanchoredPart.RotVelocity = Vector3.zero
        UnanchoredPart.CanCollide = true
        UnanchoredPart.Transparency = 0 -- Reset visibility
    end
end

local function SetFlingPart(part)
    StopFling() -- Reset previous
    UnanchoredPart = part
    part.Transparency = 0.5
    ClaimNetworkOwnership()
    
    if AutoClaim and (part:IsA("Seat") or part:IsA("VehicleSeat")) then
        ClaimSeat(part)
    end
    Notify("✅ Selected: " .. part.Name)
end

-- SELECTION LOGIC
Mouse.Button1Down:Connect(function()
    if SelectionMode and Mouse.Target then
        local target = Mouse.Target
        if not target.Anchored and not target:IsDescendantOf(OWNER.Character) then
            SetFlingPart(target)
            SelectionMode = false 
            Notify("Selection Mode OFF")
            if SelectionHighlight then SelectionHighlight:Destroy() SelectionHighlight = nil end
        else
            Notify("❌ Invalid Part (Anchored/Yours)")
        end
    end
end)

--------------------------------------------------------------------------------
-- UI CONSTRUCTION
--------------------------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "xtvo Hub | Fling",
    TabWidth = 140
})

local MainTab = Window:AddTab("Main")
local SettingsTab = Window:AddTab("Settings")

-- MAIN TAB
MainTab:AddToggle({
    Text = "Selection Mode",
    Default = false,
    Callback = function(v)
        SelectionMode = v
        if v then
            Notify("Click a part to select it!")
            SelectionHighlight = Instance.new("Highlight", game.CoreGui) -- Temp highlight container
        else
            if SelectionHighlight then SelectionHighlight:Destroy() end
        end
    end
})

MainTab:AddDropdown({
    Text = "Target Mode",
    Options = {"Target", "Nearest", "Key", "Constant"},
    Default = "Target",
    Callback = function(v)
        TargetMode = v
    end
})

MainTab:AddToggle({
    Text = "Start Fling",
    Default = false,
    Callback = function(v)
        Active = v
        if not v then 
            StopFling() 
            return 
        end
        
        if not UnanchoredPart then
            Notify("❌ No Part Selected!")
            return
        end
        
        -- START LOOP
        hbConnection = RunService.Heartbeat:Connect(function()
            if not UnanchoredPart or not UnanchoredPart.Parent then StopFling() return end
            
            -- Setup Physics
            UnanchoredPart.CanCollide = false
            UnanchoredPart.CanTouch = false
            pcall(function() 
                sethiddenproperty(OWNER, "SimulationRadius", math.huge) 
                UnanchoredPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end)
            ClaimNetworkOwnership()
            
            -- Anti-Void
            if UnanchoredPart.Position.Y < Workspace.FallenPartsDestroyHeight + 20 then
                 UnanchoredPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame
                 UnanchoredPart.Velocity = Vector3.zero
                 UnanchoredPart.RotVelocity = Vector3.zero
            end
            
            -- Body Objects
            if not UnanchoredPart:FindFirstChild("BodyPosition") then
                local bp = Instance.new("BodyPosition", UnanchoredPart)
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.P = 10000
                bp.D = 175
            end
            if not UnanchoredPart:FindFirstChild("BodyThrust") then Instance.new("BodyThrust", UnanchoredPart) end
            
            -- Rotation
            if RotationEnabled then
                 if not UnanchoredPart:FindFirstChild("BodyGyro") then
                     local bg = Instance.new("BodyGyro", UnanchoredPart)
                     bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                 end
                 UnanchoredPart.BodyGyro.CFrame = CFrame.Angles(
                     math.rad(Config.Rotation.X), math.rad(Config.Rotation.Y), math.rad(Config.Rotation.Z)
                 )
            end
            
            UnanchoredPart.Velocity = Vector3.new(0, -87, 0) -- Fling Velocity
            
            -- Mode Logic
            local activePred = Config.Prediction
            if AutoPrediction then
                local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
                activePred = ping + 0.15
            end
            
            if TargetMode == "Target" then
                -- Simplified: Assume user wants to fling whoever they clicked or typed (add target selector later if needed)
                -- For now, falling back to Nearest in Target mode if explicit target logic isn't fully ported (as it relied on chat commands often)
                -- Let's swap to Nearest logic for robustness unless explicit target is set
                local T = GetNearestPlayer()
                if T then
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = T.Character.HumanoidRootPart.Position + (T.Character.HumanoidRootPart.Velocity * activePred)
                     UnanchoredPart.BodyThrust.Location = T.Character.HumanoidRootPart.Position
                else
                    SpawnPart()
                end
            elseif TargetMode == "Nearest" then
                local T = GetNearestPlayer()
                if T then
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = T.Character.HumanoidRootPart.Position + (T.Character.HumanoidRootPart.Velocity * activePred)
                     UnanchoredPart.BodyThrust.Location = T.Character.HumanoidRootPart.Position
                else
                    SpawnPart()
                end
            elseif TargetMode == "Key" then
                 UnanchoredPart.BodyThrust.Force = Force
                 UnanchoredPart.BodyPosition.Position = Mouse.Hit.p
                 UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
            else -- Constant
                SpawnPart()
            end
        end)
    end
})


MainTab:AddButton({
    Text = "Claim Seat (Force)",
    Callback = function()
        if UnanchoredPart then ClaimSeat(UnanchoredPart) end
    end
})

-- SETTINGS TAB
SettingsTab:AddToggle({
    Text = "Auto Prediction",
    Default = false,
    Callback = function(v) AutoPrediction = v end
})

SettingsTab:AddSlider({
    Text = "Prediction (Ms)",
    Min = 0, Max = 200, Default = 80,
    Callback = function(v) Config.Prediction = v/100 end
})

SettingsTab:AddSlider({
    Text = "Distance Check",
    Min = 10, Max = 500, Default = 50,
    Callback = function(v) Config.Distance = v end
})

SettingsTab:AddToggle({
    Text = "Auto Claim Seats",
    Default = false,
    Callback = function(v) AutoClaim = v end
})

SettingsTab:AddToggle({
    Text = "Enable Rotation",
    Default = false,
    Callback = function(v) RotationEnabled = v end
})

SettingsTab:AddSlider({
    Text = "Rot X",
    Min = 0, Max = 360, Default = 0,
    Callback = function(v) Config.Rotation.X = v end
})
SettingsTab:AddSlider({
    Text = "Rot Y",
    Min = 0, Max = 360, Default = 0,
    Callback = function(v) Config.Rotation.Y = v end
})
SettingsTab:AddSlider({
    Text = "Rot Z",
    Min = 0, Max = 360, Default = 0,
    Callback = function(v) Config.Rotation.Z = v end
})

Notify("xtvo Hub Loaded!")

--[[
    xtvo Hub - Fling Script Implementation
    Powered by xtvo Lib 🍵
    
    Ported from fling_improved.lua (OG Logic Restored)
]]

--------------------------------------------------------------------------------
-- LIBRARY LOADER
--------------------------------------------------------------------------------
local RepoURL = "https://raw.githubusercontent.com/xtvoo/uilib/main/xtvoLib.lua"
local Library
pcall(function()
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
local Activated = false -- The "Attack" state
local AutoPrediction = false
local RotationEnabled = false

-- Settings
local Config = {
    Prediction = 0.8,
    Distance = 50,
    Offsets = {X = 8, Y = 8, Z = 8},
    Rotation = {X = 0, Y = 0, Z = 0},
    AttackKey = Enum.KeyCode.E
}
local Force = Vector3.new(-10000, -10000, -10000)
local OriginalVelocity = {}
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

-- Find player by string (partial match)
local function GetPlayer(str)
    for _, v in pairs(Players:GetPlayers()) do
        if v.Name:lower():sub(1, #str) == str:lower() or v.DisplayName:lower():sub(1, #str) == str:lower() then
            if v ~= OWNER then return v end
        end
    end
    return nil
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
        UnanchoredPart.Transparency = 0
    end
end

local function SetFlingPart(part)
    StopFling()
    UnanchoredPart = part
    part.Transparency = 0.5
    ClaimNetworkOwnership()
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
        end
    end
end)

-- INPUT LOGIC (Attack Key)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Config.AttackKey and Active then
        Activated = true
        task.wait(0.3) -- Short pulse like OG
        Activated = false
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
            SelectionHighlight = Instance.new("Highlight", game.CoreGui)
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
        Notify("Mode: " .. v)
    end
})

-- Target TextBox (New! To replace chat commands)
local TargetInput = MainTab:AddButton({
    Text = "Set Target (Click to Type)",
    Callback = function()
         -- Simple emulation of a textbox using a prompt since library doesn't have TextBox yet
         -- In a real scenario, we'd add input. For now, we'll suggest using chat commands or
         -- implementation a basic capture. 
         -- actually wait, let's just make a chat command listener since users requested "OG Version"
         Notify("Type :smite [user] in chat to set target!")
    end
})

-- Chat Listener for OG Compatibility
OWNER.Chatted:Connect(function(msg)
    local args = msg:split(" ")
    if args[1] == ":smite" and args[2] then
        local found = GetPlayer(args[2])
        if found then
            TARGET = found
            Notify("🎯 Target Set: " .. found.Name)
            if Active and TargetMode == "Target" then
                Activated = true -- Instant fire on command
                task.wait(1)
                Activated = false
            end
        else
            Notify("❌ Player not found")
        end
    end
end)


MainTab:AddToggle({
    Text = "Start Fling Loop",
    Default = false,
    Callback = function(v)
        Active = v
        if not v then 
            StopFling() 
            return 
        end
        
        if not UnanchoredPart then
            Notify("❌ No Part Selected!")
            Active = false
            return
        end
        
        -- START HEARTBEAT
        hbConnection = RunService.Heartbeat:Connect(function()
            if not UnanchoredPart or not UnanchoredPart.Parent then StopFling() return end
            
            -- Physics Setup
            UnanchoredPart.CanCollide = false
            UnanchoredPart.CanTouch = false
            pcall(function() 
                sethiddenproperty(OWNER, "SimulationRadius", math.huge) 
                UnanchoredPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end)
            ClaimNetworkOwnership()
            
            -- Safety
            if UnanchoredPart.Position.Y < Workspace.FallenPartsDestroyHeight + 20 then
                 UnanchoredPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame
                 UnanchoredPart.Velocity = Vector3.zero
                 UnanchoredPart.RotVelocity = Vector3.zero
            end
            
            -- Body Movers
            if not UnanchoredPart:FindFirstChild("BodyPosition") then
                local bp = Instance.new("BodyPosition", UnanchoredPart)
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.P = 10000
                bp.D = 175
            end
            if not UnanchoredPart:FindFirstChild("BodyThrust") then Instance.new("BodyThrust", UnanchoredPart) end
            
            if RotationEnabled then
                 if not UnanchoredPart:FindFirstChild("BodyGyro") then
                     local bg = Instance.new("BodyGyro", UnanchoredPart)
                     bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                 end
                 UnanchoredPart.BodyGyro.CFrame = CFrame.Angles(
                     math.rad(Config.Rotation.X), math.rad(Config.Rotation.Y), math.rad(Config.Rotation.Z)
                 )
            end
            
            UnanchoredPart.Velocity = Vector3.new(0, -87, 0)
            
            -- LOGIC RESTORATION
            local activePred = Config.Prediction
            if AutoPrediction then
                local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
                activePred = ping + 0.15
            end
            
            if TargetMode == "Target" then
                if Activated and TARGET and TARGET.Character and TARGET.Character:FindFirstChild("HumanoidRootPart") then
                    -- ATTACK!
                    UnanchoredPart.BodyThrust.Force = Force
                    UnanchoredPart.BodyPosition.Position = TARGET.Character.HumanoidRootPart.Position + (TARGET.Character.HumanoidRootPart.Velocity * activePred)
                    UnanchoredPart.BodyThrust.Location = TARGET.Character.HumanoidRootPart.Position
                else
                    -- PASSIVE
                    SpawnPart()
                end
                
            elseif TargetMode == "Nearest" then
                -- OG logic: Nearest mode always attacks if it finds someone
                TARGET = GetNearestPlayer()
                if TARGET then
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = TARGET.Character.HumanoidRootPart.Position + (TARGET.Character.HumanoidRootPart.Velocity * activePred)
                     UnanchoredPart.BodyThrust.Location = TARGET.Character.HumanoidRootPart.Position
                else
                    SpawnPart()
                end
                
            elseif TargetMode == "Key" then
                if Activated then
                     -- ATTACK MOUSE
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = Mouse.Hit.p
                     UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
                else
                    SpawnPart()
                end
                
            else -- Constant
                SpawnPart()
            end
        end)
    end
})

MainTab:AddKeybind({
    Text = "Attack Key (E)",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        Config.AttackKey = key
    end
})

-- SETTINGS TAB
SettingsTab:AddToggle({ Text = "Auto Prediction", Default = false, Callback = function(v) AutoPrediction = v end })
SettingsTab:AddSlider({ Text = "Prediction (Ms)", Min = 0, Max = 200, Default = 80, Callback = function(v) Config.Prediction = v/100 end })
SettingsTab:AddSlider({ Text = "Distance Check", Min = 10, Max = 500, Default = 50, Callback = function(v) Config.Distance = v end })
SettingsTab:AddToggle({ Text = "Enable Rotation", Default = false, Callback = function(v) RotationEnabled = v end })
SettingsTab:AddSlider({ Text = "Rot X", Min = 0, Max = 360, Default = 0, Callback = function(v) Config.Rotation.X = v end })
SettingsTab:AddSlider({ Text = "Rot Y", Min = 0, Max = 360, Default = 0, Callback = function(v) Config.Rotation.Y = v end })
SettingsTab:AddSlider({ Text = "Rot Z", Min = 0, Max = 360, Default = 0, Callback = function(v) Config.Rotation.Z = v end })
SettingsTab:AddKeybind({
    Text = "Toggle Menu Key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        Library:SetToggleKey(key)
    end
})

SettingsTab:AddButton({
    Text = "Unload Script",
    Callback = function()
        StopFling() -- Ensure loop stops
        Library:Unload()
        Notify("xtvo Hub Unloaded!")
    end
})

Notify("xtvo Hub (OG Logic) Loaded!")

--[[
    xtvo Hub - Game Loader 🍵
    Auto-loads scripts based on the game you're playing.
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
        Library = loadstring(game:HttpGet(RepoURL .. "?t=" .. tostring(os.time())))()
    end
end)
if not Library then 
    Library = loadstring(game:HttpGet(RepoURL .. "?t=" .. tostring(os.time())))() 
end

function Library:Notify(msg)
    game.StarterGui:SetCore("SendNotification", {Title = "xtvo Hub"; Text = msg; Duration = 3})
end

--------------------------------------------------------------------------------
-- MODULES
--------------------------------------------------------------------------------

-- 1. FLING MODULE ("So Crying RN" / Strongest Battlegrounds)
local function LoadFlingHub()
    Library:Notify("Loading Fling Hub...")
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local Stats = game:GetService("Stats")
    local OWNER = Players.LocalPlayer
    local Mouse = OWNER:GetMouse()

    -- State
    local UnanchoredPart = nil
    local TargetMode = "Target" 
    local TARGET = nil
    local Active = false
    local Activated = false
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
    local hbConnection = nil
    local SelectionMode = false
    local SelectionHighlight = nil
    
    -- ... [Helper Functions same as before, condensed for loader] ...
    local function ClaimNetworkOwnership()
        if UnanchoredPart then pcall(function() UnanchoredPart:SetNetworkOwner(OWNER) end) end
    end
    
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
                if dist < MinDist then MinDist = dist Nearest = v end
            end
        end
        return Nearest
    end
    
    local function SpawnPart()
         if UnanchoredPart and UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
            UnanchoredPart.BodyPosition.Position = OWNER.Character.HumanoidRootPart.Position + Vector3.new(Config.Offsets.X, Config.Offsets.Y, Config.Offsets.Z)
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
            UnanchoredPart.Transparency = 0
            UnanchoredPart.CanCollide = true
        end
    end

    local function SetFlingPart(part)
        StopFling()
        UnanchoredPart = part
        part.Transparency = 0.5
        ClaimNetworkOwnership()
        Library:Notify("✅ Selected: " .. part.Name)
    end
    
    -- UI
    local Window = Library:CreateWindow({Title = "xtvo Hub | Fling", TabWidth = 140})
    local MainTab = Window:AddTab("Main")
    local SettingsTab = Window:AddTab("Settings")

    -- Main Features
    MainTab:AddToggle({Text = "Selection Mode", Default = false, Callback = function(v)
        SelectionMode = v
        if v then Library:Notify("Click PART to select!") else if SelectionHighlight then SelectionHighlight:Destroy() end end
    end})
    
    MainTab:AddDropdown({Text = "Target Mode", Options = {"Target", "Nearest", "Key", "Constant"}, Default = "Target", Callback = function(v) TargetMode = v end})
    
    MainTab:AddToggle({Text = "Start Fling Loop", Default = false, Callback = function(v)
        Active = v
        if not v then StopFling() return end
        if not UnanchoredPart then Library:Notify("❌ Select a Part First!") Active = false return end
        
        hbConnection = RunService.Heartbeat:Connect(function()
            if not UnanchoredPart or not UnanchoredPart.Parent then StopFling() return end
            UnanchoredPart.CanCollide = false
            UnanchoredPart.CanTouch = false
            pcall(function() sethiddenproperty(OWNER, "SimulationRadius", math.huge) UnanchoredPart.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0) end)
            ClaimNetworkOwnership()
            
            if UnanchoredPart.Position.Y < Workspace.FallenPartsDestroyHeight + 20 then
                 UnanchoredPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame
                 UnanchoredPart.Velocity = Vector3.zero
            end
            
            if not UnanchoredPart:FindFirstChild("BodyPosition") then 
                local bp = Instance.new("BodyPosition", UnanchoredPart) 
                bp.MaxForce = Vector3.new(math.huge,math.huge,math.huge) bp.P=10000 bp.D=175 
            end
            if not UnanchoredPart:FindFirstChild("BodyThrust") then Instance.new("BodyThrust", UnanchoredPart) end
            
            if RotationEnabled then
                 if not UnanchoredPart:FindFirstChild("BodyGyro") then local bg = Instance.new("BodyGyro", UnanchoredPart) bg.MaxTorque = Vector3.new(math.huge,math.huge,math.huge) end
                 UnanchoredPart.BodyGyro.CFrame = CFrame.Angles(math.rad(Config.Rotation.X), math.rad(Config.Rotation.Y), math.rad(Config.Rotation.Z))
            end
            UnanchoredPart.Velocity = Vector3.new(0, -87, 0)

            local activePred = Config.Prediction
            if AutoPrediction then activePred = (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) + 0.15 end

            -- LOGIC
            if TargetMode == "Target" then
                if Activated and TARGET and TARGET.Character then
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = TARGET.Character.HumanoidRootPart.Position + (TARGET.Character.HumanoidRootPart.Velocity * activePred)
                     UnanchoredPart.BodyThrust.Location = TARGET.Character.HumanoidRootPart.Position
                else SpawnPart() end
            elseif TargetMode == "Nearest" then
                TARGET = GetNearestPlayer()
                if TARGET then
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = TARGET.Character.HumanoidRootPart.Position + (TARGET.Character.HumanoidRootPart.Velocity * activePred)
                     UnanchoredPart.BodyThrust.Location = TARGET.Character.HumanoidRootPart.Position
                else SpawnPart() end
            elseif TargetMode == "Key" then
                if Activated then
                     UnanchoredPart.BodyThrust.Force = Force
                     UnanchoredPart.BodyPosition.Position = Mouse.Hit.p
                     UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
                else SpawnPart() end
            else SpawnPart() end
        end)
    end})
    
    -- Inputs
    Mouse.Button1Down:Connect(function()
        if SelectionMode and Mouse.Target and not Mouse.Target.Anchored and not Mouse.Target:IsDescendantOf(OWNER.Character) then
            SetFlingPart(Mouse.Target) SelectionMode = false Library:Notify("Selection Mode OFF")
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Config.AttackKey and Active then Activated = true task.wait(0.3) Activated = false end
    end)
    
    OWNER.Chatted:Connect(function(msg)
        local args = msg:split(" ")
        if args[1] == ":smite" and args[2] then
             local found = GetPlayer(args[2])
             if found then TARGET = found Library:Notify("🎯 Target: " .. found.Name) end
        end
    end)

    -- Universal Settings
    SettingsTab:AddKeybind({Text = "Toggle Menu Key", Default = Enum.KeyCode.RightControl, Callback = function(k) Library:SetToggleKey(k) end})
    SettingsTab:AddButton({Text = "Unload Script", Callback = function() StopFling() Library:Unload() end})
end

-- 2. UNIVERSAL MODULE
local function LoadUniversal()
    Library:Notify("Loading Universal Hub...")
    local Window = Library:CreateWindow({Title = "xtvo Hub | Universal"})
    local Main = Window:AddTab("Main")
    
    Main:AddButton({Text = "Click Me", Callback = function() print("Hello Universal!") end})
    
    local Settings = Window:AddTab("Settings")
    Settings:AddKeybind({Text = "Toggle Menu Key", Default = Enum.KeyCode.RightControl, Callback = function(k) Library:SetToggleKey(k) end})
    Settings:AddButton({Text = "Unload Script", Callback = function() Library:Unload() end})
end

--------------------------------------------------------------------------------
-- GAME DETECTOR
--------------------------------------------------------------------------------
local Games = {
    [10449761463] = LoadFlingHub, -- Strongest Battlegrounds ("So Crying RN")
    [0] = LoadFlingHub -- Debug Mode/Testing Place (Can change to Universal later)
}

local PlaceID = game.PlaceId
local GameID = game.GameId

if Games[PlaceID] then
    Games[PlaceID]()
elseif Games[GameID] then
    Games[GameID]()
else
    LoadUniversal()
end

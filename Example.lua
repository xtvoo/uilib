--[[
    xtvo Lib - Showcase / Example Script
]]

local RepoURL = "https://raw.githubusercontent.com/xtvoo/uilib/main/xtvoLib.lua"

local Library
local success, result = pcall(function() 
    -- Try Loading Local File First (Dev Mode)
    return loadstring(readfile("matcha_ui/xtvoLib.lua"))() 
end)

if success and result then
    Library = result
    print("🍵 Loaded xtvoLib from Local File (Dev Mode)")
else
    -- Fallback to GitHub (Public-Release Mode)
    Library = loadstring(game:HttpGet(RepoURL))()
    print("🍵 Loaded xtvoLib from GitHub")
end 

-- 1. Create Window
local Window = Library:CreateWindow({
    Title = "xtvo Hub"
})

-- 2. Create Tabs
local MainTab = Window:AddTab("Main")
local VisualsTab = Window:AddTab("Visuals")
local SettingsTab = Window:AddTab("Settings")

-- 3. Add Components to Main Tab
MainTab:AddToggle({
    Text = "Auto Farm (Level)",
    Default = false,
    Callback = function(state)
        print("Auto Farm set to:", state)
    end
})

MainTab:AddToggle({
    Text = "Auto Skills",
    Default = true,
    Callback = function(state)
        print("Auto Skills set to:", state)
    end
})

MainTab:AddSlider({
    Text = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(val)
        if game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
        end
    end
})

MainTab:AddButton({
    Text = "Kill All Mobs",
    Callback = function()
        print("Killing all mobs...")
    end
})

-- 4. Add Components to Visuals Tab
VisualsTab:AddToggle({
    Text = "ESP Enabled",
    Default = false,
    Callback = function(v) print("ESP:", v) end
})

-- 5. Demonstrate Theme Customization & New Components
SettingsTab:AddDropdown({
    Text = "Select Theme",
    Options = {"Matcha Dark", "Midnight Blue", "Solarized"},
    Default = "Matcha Dark",
    Callback = function(opt)
        print("Theme selected:", opt)
    end
})

SettingsTab:AddColorPicker({
    Text = "Accent Color",
    Default = Color3.fromRGB(148, 216, 45),
    Callback = function(col)
        print("Color changed:", col)
    end
})

SettingsTab:AddKeybind({
    Text = "Toggle UI Key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        print("Keybind set to:", key)
    end
})

SettingsTab:AddButton({
    Text = "Load 'Midnight' Theme",
    Callback = function()
        Library:SetTheme({
            Main = Color3.fromRGB(15, 15, 20),
            Accent = Color3.fromRGB(100, 100, 255) -- Blue accent
        })
    end
})

print("Matcha UI Loaded Successfully!")

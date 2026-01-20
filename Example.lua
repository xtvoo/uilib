--[[
    xtvo Lib - Template Script
    Use this as a base for your hubs.
]]

local RepoURL = "https://raw.githubusercontent.com/xtvoo/uilib/main/xtvoLib.lua"

local Library
pcall(function()
    -- Attempt to load local file for dev, fallback to web
    if isfile and isfile("matcha_ui/xtvoLib.lua") then
        Library = loadstring(readfile("matcha_ui/xtvoLib.lua"))()
    else
        Library = loadstring(game:HttpGet(RepoURL))()
    end
end)

if not Library then
    -- Super safe fallback
    Library = loadstring(game:HttpGet(RepoURL))()
end

-- Create Window
local Window = Library:CreateWindow({
    Title = "xtvo Hub"
})

-- Create Tab
local Main = Window:AddTab("Main")

-- Add Components Below
Main:AddToggle({
    Text = "Example Toggle",
    Callback = function(v)
        print(v)
    end
})

--[[
    xtvo Lib 🍵
    "Organic Modernism" for Roblox
    
    Author: xtvoo
    License: MIT
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

--------------------------------------------------------------------------------
-- LIBRARY STATE
--------------------------------------------------------------------------------
local Library = {
    Version = "1.0.0",
    Open = true,
    Accent = Color3.fromRGB(148, 216, 45), -- Matcha Green
    Blacklist = {},
    Tabs = {},
    Flags = {},
    Signal = nil -- Custom signal handling
}

-- Safe Parent (handles different exploits/executors)
local Viewport = (function()
    local success, result = pcall(function() return CoreGui end)
    if success and result then return result end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end)()

--------------------------------------------------------------------------------
-- THEME SYSTEM
--------------------------------------------------------------------------------
local Theme = {
    Main = Color3.fromRGB(26, 27, 30),      -- #1A1B1E (Deep Charcoal)
    Secondary = Color3.fromRGB(37, 38, 43), -- #25262B (Soft Gunmetal)
    Stroke = Color3.fromRGB(44, 46, 51),    -- #2C2E33 (Subtle Border)
    Divider = Color3.fromRGB(50, 50, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(165, 165, 165),
    Accent = Color3.fromRGB(148, 216, 45)   -- #94D82D (Matcha)
}

-- Utility: Create or Update Styles
function Library:SetTheme(newTheme)
    for k, v in pairs(newTheme) do
        Theme[k] = v
    end
end

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------
local function Create(class, props)
    local instance = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            instance[k] = v
        end
    end
    if props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

local function Tween(instance, info, props)
    local tween = TweenService:Create(instance, TweenInfo.new(unpack(info)), props)
    tween:Play()
    return tween
end

-- Rounding Helper
local function Round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

-- Stroke Helper
local function Stroke(instance, thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness
    stroke.Color = color or Theme.Stroke
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- Draggable Helper
local function MakeDraggable(topbarObject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local newPos = UDim2.new(
            StartPosition.X.Scale, 
            StartPosition.X.Offset + Delta.X, 
            StartPosition.Y.Scale, 
            StartPosition.Y.Offset + Delta.Y
        )
        Tween(object, {0.1, Enum.EasingStyle.Sine}, {Position = newPos})
    end

    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

--------------------------------------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "Matcha UI"
    
    local ScreenGui = Create("ScreenGui", {
        Name = "MatchaLib",
        ResetOnSpawn = false,
        Parent = Viewport,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- Protect GUI (Optional Synapse/Scriptware protection)
    if gethui then ScreenGui.Parent = gethui() end
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end

    local Main = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 550, 0, 350),
        Position = UDim2.new(0.5, -275, 0.5, -175),
        BackgroundColor3 = Theme.Main,
        Parent = ScreenGui
    })
    Round(Main, 8)
    Stroke(Main, 1, Theme.Stroke)
    
    -- Topbar (Draggable Area)
    local Topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1,
        Parent = Main
    })
    MakeDraggable(Topbar, Main)
    
    -- Title
    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Text = TitleText,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent = Topbar
    })
    
    -- Accent Line
    local AccentLine = Create("Frame", {
        Name = "AccentLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = Main
    })
    
    -- Tab Container (Sidebar)
    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 140, 1, -41),
        Position = UDim2.new(0, 0, 0, 41),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.5, -- Subtle difference
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        Parent = Main
    })
    
    -- Page Container
    local PageContainer = Create("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1, -150, 1, -51),
        Position = UDim2.new(0, 145, 0, 46),
        BackgroundTransparency = 1,
        Parent = Main
    })
    
    local TabListLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabContainer
    })
    
    local TabPadding = Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        Parent = TabContainer
    })
    
    -- WINDOW OBJECT
    local Window = {
        Tabs = {}
    }

    function Window:AddTab(name)
        -- Tab Button
        local TabButton = Create("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, -10, 0, 32),
            BackgroundColor3 = Theme.Main,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            Parent = TabContainer
        })
        Round(TabButton, 6)
        
        -- Page Frame
        local Page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false, -- Hidden by default
            Parent = PageContainer
        })
        
        local PageLayout = Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Page
        })
        
        local function Activate()
            -- visual reset
            for _, t in pairs(TabContainer:GetChildren()) do
                if t:IsA("TextButton") then
                    Tween(t, {0.2, Enum.EasingStyle.Quad}, {BackgroundTransparency = 1, TextColor3 = Theme.TextDim})
                end
            end
            for _, p in pairs(PageContainer:GetChildren()) do
                p.Visible = false
            end
            
            -- activate this
            Page.Visible = true
            Tween(TabButton, {0.2, Enum.EasingStyle.Quad}, {BackgroundTransparency = 0, TextColor3 = Theme.Accent})
        end
        
        TabButton.MouseButton1Click:Connect(Activate)
        
        -- First tab auto-select
        if #Window.Tabs == 0 then
            Activate()
        end
        
        table.insert(Window.Tabs, name)
        
        -- TAB OBJECT
        local TabObj = {}
        
        function TabObj:AddToggle(config)
            local Text = config.Text or "Toggle"
            local Default = config.Default or false
            local Callback = config.Callback or function() end
            
            local ToggleFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Secondary,
                Parent = Page
            })
            Round(ToggleFrame, 6)
            Stroke(ToggleFrame, 1, Theme.Stroke)
            
            local Label = Create("TextLabel", {
                Text = Text,
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ToggleFrame
            })
            
            local Switch = Create("TextButton", {
                Text = "",
                Size = UDim2.new(0, 42, 0, 22),
                Position = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = Default and Theme.Accent or Color3.fromRGB(50,50,50),
                Parent = ToggleFrame
            })
            Round(Switch, 12)
            
            local Knob = Create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = Default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = Color3.new(1,1,1),
                Parent = Switch
            })
            Round(Knob, 9)
            
            local Toggled = Default
            
            Switch.MouseButton1Click:Connect(function()
                Toggled = not Toggled
                Callback(Toggled)
                
                -- Animate
                if Toggled then
                    Tween(Switch, {0.2, Enum.EasingStyle.Quad}, {BackgroundColor3 = Theme.Accent})
                    Tween(Knob, {0.2, Enum.EasingStyle.Quad}, {Position = UDim2.new(1, -20, 0.5, -9)})
                else
                    Tween(Switch, {0.2, Enum.EasingStyle.Quad}, {BackgroundColor3 = Color3.fromRGB(50,50,50)})
                    Tween(Knob, {0.2, Enum.EasingStyle.Quad}, {Position = UDim2.new(0, 2, 0.5, -9)})
                end
            end)
        end
        
        function TabObj:AddButton(config)
            local Text = config.Text or "Button"
            local Callback = config.Callback or function() end
            
            local ButtonBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.Secondary,
                Text = Text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Parent = Page
            })
            Round(ButtonBtn, 6)
            Stroke(ButtonBtn, 1, Theme.Stroke)
            
            ButtonBtn.MouseButton1Click:Connect(function()
                Callback()
                Tween(ButtonBtn, {0.1}, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.new(0,0,0)})
                task.wait(0.1)
                Tween(ButtonBtn, {0.2}, {BackgroundColor3 = Theme.Secondary, TextColor3 = Theme.Text})
            end)
        end
        
        function TabObj:AddSlider(config)
            local Text = config.Text or "Slider"
            local Min = config.Min or 0
            local Max = config.Max or 100
            local Default = config.Default or Min
            local Callback = config.Callback or function() end

            local SliderFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.Secondary,
                Parent = Page
            })
            Round(SliderFrame, 6)
            Stroke(SliderFrame, 1, Theme.Stroke)

            local Label = Create("TextLabel", {
                Text = Text,
                Size = UDim2.new(1, 0, 0, 25),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SliderFrame
            })
            
            local ValueLabel = Create("TextLabel", {
                Text = tostring(Default),
                Size = UDim2.new(0, 50, 0, 25),
                Position = UDim2.new(1, -62, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = SliderFrame
            })

            local Track = Create("TextButton", {
                Text = "",
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = Color3.fromRGB(40,40,40),
                AutoButtonColor = false,
                Parent = SliderFrame
            })
            Round(Track, 3)

            local Fill = Create("Frame", {
                Size = UDim2.new((Default - Min)/(Max - Min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                Parent = Track
            })
            Round(Fill, 3)

            local Dragging = false
            
            local function Update(input)
                local SizeX = Track.AbsoluteSize.X
                local PosX = Track.AbsolutePosition.X
                local MouseX = input.Position.X
                local Percent = math.clamp((MouseX - PosX) / SizeX, 0, 1)
                
                local Value = math.floor(Min + ((Max - Min) * Percent))
                ValueLabel.Text = tostring(Value)
                Fill.Size = UDim2.new(Percent, 0, 1, 0)
                Callback(Value)
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
        end
        
        function TabObj:AddDropdown(config)
            local Text = config.Text or "Dropdown"
            local Options = config.Options or {}
            local Default = config.Default or Options[1]
            local Callback = config.Callback or function() end
            
            local Dropdown = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36), -- Initial size
                BackgroundColor3 = Theme.Secondary,
                ClipsDescendants = true,
                Parent = Page
            })
            Round(Dropdown, 6)
            Stroke(Dropdown, 1, Theme.Stroke)
            
            local Label = Create("TextLabel", {
                Text = Text,
                Size = UDim2.new(1, -20, 0, 36),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Dropdown
            })
            
            local ValueText = Create("TextLabel", {
                Text = tostring(Default),
                Size = UDim2.new(1, -30, 0, 36),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Dropdown
            })
            
            local Arrow = Create("ImageLabel", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -22, 0, 11),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6034818372", -- Arrow Down
                ImageColor3 = Theme.TextDim,
                Parent = Dropdown
            })

            local OptionContainer = Create("ScrollingFrame", {
                Size = UDim2.new(1, -4, 0, 0), -- Starts Height 0
                Position = UDim2.new(0, 2, 0, 38), -- Below Label
                BackgroundTransparency = 1,
                ScrollBarThickness = 2,
                Parent = Dropdown
            })
            
            local ListLayout = Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = OptionContainer
            })

            local Open = false
            local DropdownBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
                Parent = Dropdown
            })
            
            local currentItems = {}
            
            local function RefreshOptions()
                for _, v in pairs(OptionContainer:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                
                for _, opt in pairs(Options) do
                    local Item = Create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = Theme.Main,
                        Text = opt,
                        TextColor3 = (opt == Default and Theme.Accent or Theme.TextDim),
                        TextSize = 13,
                        Font = Enum.Font.GothamMedium,
                        Parent = OptionContainer
                    })
                    Round(Item, 4)
                    
                    Item.MouseButton1Click:Connect(function()
                        Default = opt
                        ValueText.Text = opt
                        Callback(opt)
                        -- Close
                        Open = false
                        Tween(Dropdown, {0.2, Enum.EasingStyle.Quad}, {Size = UDim2.new(1, 0, 0, 36)})
                        Tween(Arrow, {0.2}, {Rotation = 0})
                        RefreshOptions() -- Refresh to update colors
                    end)
                end
                
                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
            end
            
            DropdownBtn.MouseButton1Click:Connect(function()
                Open = not Open
                if Open then
                    RefreshOptions()
                    local count = #Options
                    local contentHeight = math.min(count * 30 + 5, 150)
                    Tween(Dropdown, {0.2, Enum.EasingStyle.Quad}, {Size = UDim2.new(1, 0, 0, 36 + contentHeight)})
                    Tween(OptionContainer, {0.2}, {Size = UDim2.new(1, -4, 0, contentHeight)})
                    Tween(Arrow, {0.2}, {Rotation = 180})
                else
                    Tween(Dropdown, {0.2, Enum.EasingStyle.Quad}, {Size = UDim2.new(1, 0, 0, 36)})
                    Tween(OptionContainer, {0.2}, {Size = UDim2.new(1, -4, 0, 0)})
                    Tween(Arrow, {0.2}, {Rotation = 0})
                end
            end)
            
            RefreshOptions()
        end
        
        function TabObj:AddColorPicker(config)
            local Text = config.Text or "Color Picker"
            local Default = config.Default or Color3.fromRGB(255, 255, 255)
            local Callback = config.Callback or function() end
            
            local PickerFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Secondary,
                Parent = Page
            })
            Round(PickerFrame, 6)
            Stroke(PickerFrame, 1, Theme.Stroke)
            
            local Label = Create("TextLabel", {
                Text = Text,
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = PickerFrame
            })
            
            local Preview = Create("TextButton", {
                Text = "",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -52, 0.5, -10),
                BackgroundColor3 = Default,
                Parent = PickerFrame
            })
            Round(Preview, 4)
            Stroke(Preview, 1, Theme.Stroke)
            
            -- Simplified Color Picker Logic (Basic Implementation)
            -- Ideally this would open a sub-window, but for now it's a mock until user asks for full HSV
            Preview.MouseButton1Click:Connect(function()
                -- Placeholder logic for opening palette
                -- In v2 we can add a full RGB draggable window
                Utility:Notify("Color Picker functionality coming in v1.1") 
            end)
        end
        
        function TabObj:AddKeybind(config)
            local Text = config.Text or "Keybind"
            local Default = config.Default or Enum.KeyCode.RightControl
            local Callback = config.Callback or function() end
            
            local KeyFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Secondary,
                Parent = Page
            })
            Round(KeyFrame, 6)
            Stroke(KeyFrame, 1, Theme.Stroke)
            
            local Label = Create("TextLabel", {
                Text = Text,
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = KeyFrame
            })
            
            local BindBtn = Create("TextButton", {
                Text = "[" .. Default.Name .. "]",
                Size = UDim2.new(0, 80, 0, 24),
                Position = UDim2.new(1, -92, 0.5, -12),
                BackgroundColor3 = Theme.Main,
                TextColor3 = Theme.TextDim,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = KeyFrame
            })
            Round(BindBtn, 4)
            
            local Binding = false
            
            BindBtn.MouseButton1Click:Connect(function()
                Binding = true
                BindBtn.Text = "[...]"
                BindBtn.TextColor3 = Theme.Accent
            end)
            
            UserInputService.InputBegan:Connect(function(input)
                if Binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    Default = input.KeyCode
                    BindBtn.Text = "[" .. Default.Name .. "]"
                    BindBtn.TextColor3 = Theme.TextDim
                    Binding = false
                    Callback(Default)
                elseif input.KeyCode == Default and not Binding then
                    Callback(Default) -- Trigger bind
                end
            end)
        end
        
        return TabObj
    end
    
    return Window
end

return Library

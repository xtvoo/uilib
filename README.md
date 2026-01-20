# xtvo Lib 🍵

A premium, modern, and "organic" UI library for Roblox script execution environments. Designed with a focus on aesthetics, smooth interactions, and ease of implementation.

## Features
*   **Organic Modernism Design:** Sleek dark theme with energetic Matcha Green accents.
*   **Smooth Animations:** TweenService integration for all interactions.
*   **Feature Rich:** Toggles, Sliders, Dropdowns, Color Pickers, and Keybinds.
*   **Theming Engine:** Full JSON-based custom theme support.

## Usage

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xtvoo/uilib/main/xtvoLib.lua"))()

local Window = Library:CreateWindow({
    Title = "My Script Hub",
    TabWidth = 120
})

local Tab = Window:AddTab("Main")

Tab:AddToggle({
    Text = "Auto Farm",
    Default = false,
    Callback = function(v)
        print("Auto Farm:", v)
    end
})
```

## License
MIT License. See [LICENSE](LICENSE) for details.

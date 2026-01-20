# xtvo Lib - API Documentation 📚

A complete reference for the **xtvo Lib** user interface library.

## Getting Started

Load the library at the top of your script:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xtvoo/uilib/main/xtvoLib.lua"))()
```

## 1. Window Management

### `Library:CreateWindow(config)`
Creates the main UI window.

*   **Parameters:** `config` (Table)
*   **Returns:** `WindowHelper` object

**Config Props:**
*   `Title` (string): Text shown in top bar.
*   `TabWidth` (number, optional): Width of sidebar (Default: 140).

```lua
local Window = Library:CreateWindow({
    Title = "My Script Hub"
})
```

---

## 2. Tab Management

### `Window:AddTab(name)`
Adds a new tab to the sidebar.

*   **Parameters:** `name` (string)
*   **Returns:** `TabHelper` object

```lua
local MainTab = Window:AddTab("Main")
local SettingsTab = Window:AddTab("Settings")
```

---

## 3. Components

### A. Toggle
A boolean switch.

```lua
Tab:AddToggle({
    Text = "Auto Farm",
    Default = false, -- or true
    Callback = function(Value)
        print("Toggle is now:", Value)
    end
})
```

### B. Button
A clickable action trigger.

```lua
Tab:AddButton({
    Text = "Kill All",
    Callback = function()
        print("Clicked!")
    end
})
```

### C. Slider
A draggable range selector.

```lua
Tab:AddSlider({
    Text = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(Value)
        print("Speed:", Value)
    end
})
```

### D. Dropdown
A selectable list of options.

```lua
Tab:AddDropdown({
    Text = "Target Mode",
    Options = {"Head", "Torso", "Random"},
    Default = "Head",
    Callback = function(Option)
        print("Selected:", Option)
    end
})
```

### E. Color Picker
(Basic Implementation) A simplified color selection trigger.

```lua
Tab:AddColorPicker({
    Text = "Esp Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        -- Returns Color3
    end
})
```

### F. Keybind
A key binding recorder.

```lua
Tab:AddKeybind({
    Text = "Toggle Menu",
    Default = Enum.KeyCode.RightControl,
    Callback = function(Key)
        print("Bound to:", Key)
    end
})
```

---

## 4. Theming

### `Library:SetTheme(themeConfig)`
Updates the UI colors dynamically.

**Available Keys:**
*   `Main`: Background color
*   `Secondary`: Element background
*   `Accent`: Highlight color
*   `Text`: Main text color
*   `Stroke`: Border color

```lua
-- Midnight Theme Example
Library:SetTheme({
    Main = Color3.fromRGB(20, 20, 35),
    Secondary = Color3.fromRGB(30, 30, 50),
    Accent = Color3.fromRGB(100, 100, 255)
})
```

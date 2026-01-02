local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "You Are An idiot",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "100%",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ArsenalSmoothFull"
    },
    KeySystem = false
})

local MovementTab = Window:CreateTab("プレイヤー", "move")
local CombatTab   = Window:CreateTab("戦闘", "swords")
local AntiTab     = Window:CreateTab("アンチ", "shield")
local TrollTab    = Window:CreateTab("荒らし", "skull")
local ESPTab      = Window:CreateTab("ESP", "eye")
local TeleportTab = Window:CreateTab("テレポート", "map-pin")
local DiscordTab  = Window:CreateTab("情報", "info")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Settings
local MovementSettings = {
    Enabled = false,            
    WalkspeedEnabled = false,   
    WalkspeedValue = 50,      
    JumpPowerEnabled = true,
    JumpPowerValue = 300,
    NoclipEnabled = false,
    Connections = {}
}

-- Utils
local function GetCharacterParts(character)
    local char = character or LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum, hrp
end

-- WalkSpeed
local ACCEL = 50
local currentSpeed = 0

local function EnableSpeed()
    local hum, hrp = GetCharacterParts()
    if not hum or not hrp then return end

    hum.WalkSpeed = 16  -- WalkSpeedは低めにセット（キック回避のため）

    if MovementSettings.Connections.Speed then
        MovementSettings.Connections.Speed:Disconnect()
    end

    MovementSettings.Connections.Speed = RunService.Heartbeat:Connect(function()
        if not MovementSettings.Enabled then return end

        if hum.MoveDirection.Magnitude == 0 then
            currentSpeed = math.max(0, currentSpeed - ACCEL * 2)
        else
            currentSpeed = math.clamp(currentSpeed + ACCEL, 0, MovementSettings.WalkspeedValue)
        end

        hrp.Velocity = hum.MoveDirection * currentSpeed + Vector3.new(0, hrp.Velocity.Y, 0)
    end)
end

local function DisableSpeed()
    if MovementSettings.Connections.Speed then
        MovementSettings.Connections.Speed:Disconnect()
        MovementSettings.Connections.Speed = nil
    end

    local hum, _ = GetCharacterParts()
    if hum then
        hum.WalkSpeed = 16 
    end
    currentSpeed = 0
end

-- Jump Power
local function OnStateChanged(oldState, newState)
    if not MovementSettings.JumpPowerEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if newState == Enum.HumanoidStateType.Jumping then
        hum.JumpPower = math.clamp(MovementSettings.JumpPowerValue, 0, 1000)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, hrp.Velocity.Y + MovementSettings.JumpPowerValue * 0.5, hrp.Velocity.Z)
        end
    elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Freefall then
        hum.JumpPower = 50
    end
end

local function SetupCharacter(character)
    local hum = character:WaitForChild("Humanoid")
    hum.StateChanged:Connect(OnStateChanged)
end

-- Noclip
local function ToggleNoclip(state)
    MovementSettings.NoclipEnabled = state

    if MovementSettings.Connections.Noclip then
        MovementSettings.Connections.Noclip:Disconnect()
        MovementSettings.Connections.Noclip = nil
    end

    if state then
        MovementSettings.Connections.Noclip =
            RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- CharacterAdded
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.3)

    SetupCharacter(character)

    local hum, _ = GetCharacterParts(character)
    if hum then
        if MovementSettings.JumpPowerEnabled then
            hum.JumpPower = math.clamp(MovementSettings.JumpPowerValue, 0, 300)
        else
            hum.JumpPower = 50
        end
    end

    if MovementSettings.Enabled then
        EnableSpeed()
    else
        DisableSpeed()
    end

    if MovementSettings.NoclipEnabled then
        ToggleNoclip(true)
    else
        ToggleNoclip(false)
    end
end)

if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)

    if MovementSettings.Enabled then
        EnableSpeed()
    end

    if MovementSettings.NoclipEnabled then
        ToggleNoclip(true)
    end
end


-- Movement Button
MovementTab:CreateSection("プレイヤー")

local MovementMessage = "スピードハック起動するとキックされるのを無くしました"

MovementTab:CreateLabel(MovementMessage)

MovementTab:CreateToggle({
    Name = "スピードハック",
    CurrentValue = false,
    Callback = function(v)
        MovementSettings.Enabled = v
        if v then
            EnableSpeed()
        else
            DisableSpeed()
        end
    end
})

MovementTab:CreateSlider({
    Name = "スピード速さ",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = MovementSettings.WalkspeedValue,
    Callback = function(v)
        MovementSettings.WalkspeedValue = v
        if MovementSettings.Enabled then
            EnableSpeed()
        end
    end
})

MovementTab:CreateToggle({
    Name = "ジャンプ力",
    CurrentValue = MovementSettings.JumpPowerEnabled,
    Callback = function(state)
        MovementSettings.JumpPowerEnabled = state
    end
})

MovementTab:CreateSlider({
    Name = "ジャンプ力",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = MovementSettings.JumpPowerValue,
    Callback = function(value)
        MovementSettings.JumpPowerValue = value
    end
})

MovementTab:CreateToggle({
    Name = "ノークリップ",
    CurrentValue = MovementSettings.NoclipEnabled,
    Callback = function(state)
        ToggleNoclip(state)
    end
})
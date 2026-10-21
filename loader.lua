
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local OLD_SCRIPT_URL = "https://raw.githubusercontent.com/FluxusScripts/jjs-universal/refs/heads/main/LangOld.lua"
local NEW_SCRIPT_URL = "https://raw.githubusercontent.com/FluxusScripts/jjs-universal/refs/heads/main/LangNew.lua"

local player = Players.LocalPlayer

local function getGuiParent()
    if typeof(gethui) == "function" then
        local success, result = pcall(gethui)
        if success and result then
            return result
        end
    end

    return player:WaitForChild("PlayerGui")
end

local parent = getGuiParent()

local previous = parent:FindFirstChild("ScriptLoader")
if previous then
    previous:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptLoader"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = parent

local background = Color3.fromRGB(29, 27, 32)
local surface = Color3.fromRGB(43, 40, 47)
local accent = Color3.fromRGB(0, 100, 92)
local textColor = Color3.fromRGB(245, 239, 247)
local muted = Color3.fromRGB(190, 184, 196)

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(300, 218)
window.Position = UDim2.new(0.5, -150, 0.5, -109)
window.BackgroundColor3 = background
window.BorderSizePixel = 0
window.Parent = gui

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 18)
windowCorner.Parent = window

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(75, 70, 80)
outline.Thickness = 1
outline.Parent = window

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -60, 0, 36)
header.Position = UDim2.fromOffset(16, 10)
header.BackgroundTransparency = 1
header.Text = "Выбор скрипта"
header.TextColor3 = textColor
header.Font = Enum.Font.GothamBold
header.TextSize = 18
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.Position = UDim2.new(1, -42, 0, 8)
closeButton.BackgroundColor3 = surface
closeButton.Text = "×"
closeButton.TextColor3 = textColor
closeButton.Font = Enum.Font.GothamMedium
closeButton.TextSize = 23
closeButton.AutoButtonColor = false
closeButton.Parent = window

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -32, 0, 20)
subtitle.Position = UDim2.fromOffset(16, 45)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Выбери нужную версию"
subtitle.TextColor3 = muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = window

local function makeButton(name, y, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -32, 0, 48)
    button.Position = UDim2.fromOffset(16, y)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = textColor
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 15
    button.AutoButtonColor = false
    button.Parent = window

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.08)}
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {BackgroundColor3 = color}
        ):Play()
    end)

    return button
end

local newButton = makeButton(
    "Новый скрипт",
    76,
    accent
)

local oldButton = makeButton(
    "Старый скрипт",
    132,
    surface
)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 18)
status.Position = UDim2.fromOffset(16, 188)
status.BackgroundTransparency = 1
status.Text = "Готов к запуску"
status.TextColor3 = muted
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Center
status.Parent = window

local function loadScript(url, label)
    if url == "" then
        status.Text = "Сначала добавь ссылку"
        return
    end

    if not url:match("^https://") then
        status.Text = "Нужна HTTPS-ссылка"
        return
    end

    status.Text = "Загрузка: " .. label

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or type(response) ~= "string" or response == "" then
        status.Text = "Не удалось загрузить"
        return
    end

    local compileSuccess, compiled = pcall(function()
        return loadstring(response)
    end)

    if not compileSuccess or type(compiled) ~= "function" then
        status.Text = "Ошибка в коде скрипта"
        return
    end

    window.Visible = false

    local runSuccess, runError = pcall(compiled)

    if not runSuccess then
        warn("[ScriptLoader] Ошибка запуска:", runError)
        status.Text = "Ошибка запуска скрипта"
        window.Visible = true
        return
    end

    gui:Destroy()
end

newButton.MouseButton1Click:Connect(function()
    loadScript(NEW_SCRIPT_URL, "новый")
end)

oldButton.MouseButton1Click:Connect(function()
    loadScript(OLD_SCRIPT_URL, "старый")
end)

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local dragging = false
local dragInput
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart

        window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

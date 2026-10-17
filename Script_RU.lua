local STRINGS = {
	title = "Overload",
	subtitle = "Управление",
	banner = "Платформа под вами",
	autoTitle = "Авто Overload",
	autoSub = "Повторяется само",
	platformTitle = "Платформа",
	platformSub = "Огромный пол под картой",
	divergentTitle = "Повтор Divergent",
	divergentSub = "Скастуй раз, затем +1 удар",
	materialSection = "Материал платформы",
	colorSection = "Цвет платформы",
	open = "Открыть",
	close = "Закрыть",
}

local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")

local PLATFORM_POSITION = Vector3.new(-11, -105, 52)
local PLATFORM_SIZE = Vector3.new(2048, 4, 2048)
local OFFLOAD_TIMEOUT = 1
local DRAG_THRESHOLD = 4
local REPEAT_DELAY = 0.30
local REPEAT_LOCKOUT = 2
local CACHE_REFRESH = 0.5

local DIVERGENT_ANIMATIONS = {
	["rbxassetid://100962226150441"] = true,
	["rbxassetid://95852624447551"] = true,
	["rbxassetid://74145636023952"] = true,
	["rbxassetid://123171106092050"] = true,
}

local MATERIALS = {
	"SmoothPlastic", "Plastic", "Neon", "Grass", "Ice", "Marble", "Granite",
	"Wood", "Concrete", "Metal", "Glass", "ForceField", "Sand", "Brick",
}

local PLATFORM_COLORS = {
	Color3.fromRGB(120, 120, 120), Color3.fromRGB(208, 188, 255), Color3.fromRGB(129, 201, 149),
	Color3.fromRGB(242, 184, 181), Color3.fromRGB(250, 214, 140), Color3.fromRGB(153, 205, 255),
	Color3.fromRGB(20, 18, 24),
}

local SURFACE = Color3.fromRGB(20, 18, 24)
local SURFACE_CONTAINER = Color3.fromRGB(29, 27, 32)
local SURFACE_HIGHEST = Color3.fromRGB(54, 52, 59)
local PRIMARY = Color3.fromRGB(208, 188, 255)
local ON_PRIMARY = Color3.fromRGB(56, 30, 114)
local PRIMARY_CONTAINER = Color3.fromRGB(79, 55, 139)
local ON_PRIMARY_CONTAINER = Color3.fromRGB(234, 221, 255)
local SECONDARY_CONTAINER = Color3.fromRGB(74, 68, 88)
local ON_SECONDARY_CONTAINER = Color3.fromRGB(232, 222, 248)
local ON_SURFACE = Color3.fromRGB(230, 224, 233)
local ON_SURFACE_VARIANT = Color3.fromRGB(202, 196, 208)
local OUTLINE = Color3.fromRGB(147, 143, 153)
local SNACKBAR = Color3.fromRGB(50, 47, 53)
local ON_SNACKBAR = Color3.fromRGB(245, 239, 247)

local localPlayer = playersService.LocalPlayer

local servicesFolder = replicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services")
local rightActivated = servicesFolder:WaitForChild("MechamaruService"):WaitForChild("RE"):WaitForChild("RightActivated")
local ultraEvents = servicesFolder:WaitForChild("UltraCannonService"):WaitForChild("RE")
local ultraActivated = ultraEvents:WaitForChild("Activated")
local ultraDeactivated = ultraEvents:WaitForChild("Deactivated")
local divergentRemotes = servicesFolder:WaitForChild("DivergentFistService"):WaitForChild("RE")

if shared.divergentRepeat then
	shared.divergentRepeat.enabled = false
	shared.divergentRepeat.gui:Destroy()
end

if shared.autoUltimate then
	local old = shared.autoUltimate
	old.enabled = false
	old.divergent = false

	if old.disarm then
		old.disarm()
	end

	old.gui:Destroy()
	old.platform:Destroy()

	for _, connection in ipairs(old.connections or {}) do
		connection:Disconnect()
	end
end

local state = {
	enabled = false,
	divergent = false,
	capturing = false,
	divergentRemote = nil,
	divergentArgs = nil,
	ignoreUntil = 0,
	connections = {},
}
shared.autoUltimate = state

local platform = Instance.new("Part")
platform.Name = "OverloadPlatform"
platform.Anchored = true
platform.CastShadow = false
platform.CanTouch = false
platform.Size = PLATFORM_SIZE
platform.Position = PLATFORM_POSITION
platform.Material = Enum.Material.SmoothPlastic
platform.Color = PLATFORM_COLORS[1]
platform.Parent = workspace

state.platform = platform

local oldNamecall

local function disarm()
	if not state.capturing then
		return
	end

	state.capturing = false
	hookmetamethod(game, "__namecall", oldNamecall)
end

local function arm()
	if state.capturing or state.divergentArgs then
		return
	end

	state.capturing = true
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if state.capturing and getnamecallmethod() == "FireServer" and typeof(self) == "Instance"
			and self.Parent == divergentRemotes and not checkcaller() then
			state.divergentRemote = self
			state.divergentArgs = table.pack(...)
			state.capturing = false

			task.defer(function()
				hookmetamethod(game, "__namecall", oldNamecall)
			end)
		end

		return oldNamecall(self, ...)
	end))
end

state.disarm = disarm

local function onAnimationPlayed(track)
	if not state.divergent or not state.divergentArgs or os.clock() < state.ignoreUntil then
		return
	end

	if not DIVERGENT_ANIMATIONS[track.Animation.AnimationId] then
		return
	end

	state.ignoreUntil = os.clock() + REPEAT_LOCKOUT

	local remote, args = state.divergentRemote, state.divergentArgs

	task.delay(REPEAT_DELAY, function()
		if state.divergent then
			pcall(remote.FireServer, remote, table.unpack(args, 1, args.n))
		end
	end)
end

local function watchCharacter(character)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local animator = humanoid and humanoid:WaitForChild("Animator", 10)

		if animator then
			table.insert(state.connections, animator.AnimationPlayed:Connect(onAnimationPlayed))
		end
	end)
end

if localPlayer.Character then
	watchCharacter(localPlayer.Character)
end

table.insert(state.connections, localPlayer.CharacterAdded:Connect(watchCharacter))

local function create(className, properties, parent)
	local object = Instance.new(className)

	for key, value in pairs(properties) do
		object[key] = value
	end

	object.Parent = parent
	return object
end

local function round(object, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius) }, object)
end

local function tween(object, goal, duration)
	tweenService:Create(object, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local screenGui = create("ScreenGui", { Name = "OverloadMenu", ResetOnSpawn = false }, gethui())
state.gui = screenGui

local banner = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.fromOffset(0, 40),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = SNACKBAR,
}, screenGui)
round(banner, 8)
create("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, banner)
create("TextLabel", {
	Size = UDim2.fromOffset(0, 40),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Text = STRINGS.banner,
	TextColor3 = ON_SNACKBAR,
	Font = Enum.Font.GothamMedium,
	TextSize = 14,
}, banner)

local menu = create("Frame", {
	Size = UDim2.fromOffset(340, 540),
	Position = UDim2.new(0, 100, 0.5, -270),
	BackgroundColor3 = SURFACE_CONTAINER,
	Active = true,
	Draggable = true,
	Visible = false,
}, screenGui)
round(menu, 28)
create("UIStroke", { Color = SURFACE_HIGHEST, Thickness = 1 }, menu)

create("TextLabel", {
	Size = UDim2.new(1, -80, 0, 28),
	Position = UDim2.fromOffset(24, 18),
	BackgroundTransparency = 1,
	Text = STRINGS.title,
	TextColor3 = ON_SURFACE,
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
}, menu)

create("TextLabel", {
	Size = UDim2.new(1, -80, 0, 18),
	Position = UDim2.fromOffset(24, 46),
	BackgroundTransparency = 1,
	Text = STRINGS.subtitle,
	TextColor3 = ON_SURFACE_VARIANT,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
}, menu)

local closeButton = create("TextButton", {
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.new(1, -52, 0, 16),
	BackgroundTransparency = 1,
	Text = "×",
	TextColor3 = ON_SURFACE_VARIANT,
	Font = Enum.Font.GothamMedium,
	TextSize = 26,
}, menu)
round(closeButton, 20)

local content = create("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -80),
	Position = UDim2.fromOffset(0, 76),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = OUTLINE,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, menu)
create("UIPadding", {
	PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
	PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16),
}, content)
create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, content)

local function createSwitchRow(order, title, supporting, callback)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundColor3 = SURFACE,
		LayoutOrder = order,
	}, content)
	round(row, 16)

	create("TextLabel", {
		Size = UDim2.new(1, -96, 0, 22),
		Position = UDim2.fromOffset(18, 16),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = ON_SURFACE,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	create("TextLabel", {
		Size = UDim2.new(1, -96, 0, 18),
		Position = UDim2.fromOffset(18, 38),
		BackgroundTransparency = 1,
		Text = supporting,
		TextColor3 = ON_SURFACE_VARIANT,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	local track = create("TextButton", {
		Size = UDim2.fromOffset(52, 32),
		Position = UDim2.new(1, -68, 0.5, -16),
		BackgroundColor3 = SURFACE_HIGHEST,
		Text = "",
		AutoButtonColor = false,
	}, row)
	round(track, 16)
	local stroke = create("UIStroke", { Color = OUTLINE, Thickness = 2 }, track)

	local knob = create("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = OUTLINE,
	}, track)
	round(knob, 12)

	local value = false

	local function render(animate)
		local duration = animate and 0.2 or 0
		tween(track, { BackgroundColor3 = value and PRIMARY or SURFACE_HIGHEST }, duration)
		tween(knob, {
			Size = value and UDim2.fromOffset(24, 24) or UDim2.fromOffset(16, 16),
			Position = value and UDim2.fromOffset(24, 4) or UDim2.fromOffset(8, 8),
			BackgroundColor3 = value and ON_PRIMARY or OUTLINE,
		}, duration)
		stroke.Transparency = value and 1 or 0
	end

	track.MouseButton1Click:Connect(function()
		value = not value
		render(true)
		callback(value)
	end)

	render(false)
	return function(newValue)
		value = newValue
		render(false)
		callback(value)
	end
end

createSwitchRow(1, STRINGS.autoTitle, STRINGS.autoSub, function(value)
	state.enabled = value
end)

local setPlatform = createSwitchRow(2, STRINGS.platformTitle, STRINGS.platformSub, function(value)
	platform.Parent = value and workspace or nil
	banner.Visible = value
end)

createSwitchRow(3, STRINGS.divergentTitle, STRINGS.divergentSub, function(value)
	state.divergent = value

	if value then
		arm()
	else
		disarm()
	end
end)

setPlatform(true)

local function createSection(order, text)
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = PRIMARY,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
	}, content)
end

createSection(4, "  " .. STRINGS.materialSection)

local chipsFrame = create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	LayoutOrder = 5,
}, content)
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Wraps = true,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, chipsFrame)

local chips = {}

local function selectMaterial(name)
	platform.Material = Enum.Material[name]

	for chipName, chip in pairs(chips) do
		local selected = chipName == name
		chip.button.Text = selected and ("✓ " .. chipName) or chipName
		chip.button.BackgroundColor3 = selected and SECONDARY_CONTAINER or SURFACE_CONTAINER
		chip.button.TextColor3 = selected and ON_SECONDARY_CONTAINER or ON_SURFACE_VARIANT
		chip.stroke.Transparency = selected and 1 or 0
	end
end

for index, name in ipairs(MATERIALS) do
	local button = create("TextButton", {
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = SURFACE_CONTAINER,
		Text = name,
		TextColor3 = ON_SURFACE_VARIANT,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		AutoButtonColor = false,
		LayoutOrder = index,
	}, chipsFrame)
	round(button, 9)
	create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, button)
	local stroke = create("UIStroke", { Color = OUTLINE, Thickness = 1 }, button)

	chips[name] = { button = button, stroke = stroke }
	button.MouseButton1Click:Connect(function()
		selectMaterial(name)
	end)
end

selectMaterial("SmoothPlastic")

createSection(6, "  " .. STRINGS.colorSection)

local colorRow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundTransparency = 1,
	LayoutOrder = 7,
}, content)
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 10),
	VerticalAlignment = Enum.VerticalAlignment.Center,
}, colorRow)
create("UIPadding", { PaddingLeft = UDim.new(0, 4) }, colorRow)

local swatches = {}

local function selectColor(color)
	platform.Color = color

	for swatchColor, stroke in pairs(swatches) do
		local selected = swatchColor == color
		stroke.Color = selected and PRIMARY or OUTLINE
		stroke.Thickness = selected and 3 or 1
		stroke.Transparency = selected and 0 or 0.5
	end
end

for _, color in ipairs(PLATFORM_COLORS) do
	local swatch = create("TextButton", {
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = color,
		Text = "",
		AutoButtonColor = false,
	}, colorRow)
	round(swatch, 17)
	swatches[color] = create("UIStroke", { Color = OUTLINE, Thickness = 1 }, swatch)

	swatch.MouseButton1Click:Connect(function()
		selectColor(color)
	end)
end

selectColor(PLATFORM_COLORS[1])

local openButton = create("TextButton", {
	Size = UDim2.fromOffset(112, 48),
	Position = UDim2.new(0, 20, 0.5, -24),
	BackgroundColor3 = PRIMARY_CONTAINER,
	Text = STRINGS.open,
	TextColor3 = ON_PRIMARY_CONTAINER,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
}, screenGui)
round(openButton, 16)
create("UIStroke", { Color = PRIMARY, Thickness = 1, Transparency = 0.6 }, openButton)

local function setMenuVisible(visible)
	menu.Visible = visible
	openButton.Text = visible and STRINGS.close or STRINGS.open
end

closeButton.MouseButton1Click:Connect(function()
	setMenuVisible(false)
end)

local dragging, dragged, dragStart, startPosition = false, false, nil, nil

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

openButton.InputBegan:Connect(function(input)
	if not isPointer(input) then
		return
	end

	dragging, dragged = true, false
	dragStart = input.Position
	startPosition = openButton.Position
end)

table.insert(state.connections, userInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	local isMove = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
	if not isMove then
		return
	end

	local delta = input.Position - dragStart
	if delta.Magnitude > DRAG_THRESHOLD then
		dragged = true
	end

	if dragged then
		openButton.Position = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
	end
end))

table.insert(state.connections, userInputService.InputEnded:Connect(function(input)
	if not dragging or not isPointer(input) then
		return
	end

	dragging = false

	if not dragged then
		setMenuVisible(not menu.Visible)
	end
end))

local specialWatchers = {}
local lastRefresh = 0

local function isOverlayActive(object)
	if object.Parent == nil then
		return false
	end

	if object:IsA("TextLabel") then
		return object.Visible and object.Text:match("%d") ~= nil
	end

	return object:IsA("GuiObject") and object.Visible and object.AbsoluteSize.X > 1 and object.AbsoluteSize.Y > 1
end

local function refreshSpecialWatchers()
	table.clear(specialWatchers)
	lastRefresh = os.clock()

	local main = localPlayer.PlayerGui:FindFirstChild("Main")
	local special = main and main.Controls.Ultimate:FindFirstChild("Special")

	if not special then
		return false
	end

	for _, object in ipairs(special:GetDescendants()) do
		if object:IsA("TextLabel") or object.Name == "Cooldown" then
			table.insert(specialWatchers, object)
		end
	end

	return true
end

local function isSpecialOnCooldown()
	if os.clock() - lastRefresh > CACHE_REFRESH and not refreshSpecialWatchers() then
		return true
	end

	for _, object in ipairs(specialWatchers) do
		if isOverlayActive(object) then
			return true
		end
	end

	return false
end

local function isCannonOnCooldown()
	local main = localPlayer.PlayerGui:FindFirstChild("Main")
	local button = main and main.Controls.Moveset:FindFirstChild("Ultra Cannon")
	local cooldown = button and button:FindFirstChild("Cooldown")

	if not cooldown then
		return true
	end

	return isOverlayActive(cooldown)
end

local function isSpecialActive()
	local characters = workspace:FindFirstChild("Characters")
	local character = characters and characters:FindFirstChild(localPlayer.Name)
	local info = character and character:FindFirstChild("Info")

	return info ~= nil and info:FindFirstChild("Offload") ~= nil
end

local function getCannonTool()
	local character = localPlayer.Character
	local moveset = character and character:FindFirstChild("Moveset")

	if not moveset then
		return nil
	end

	return moveset:FindFirstChild("Ultra Cannon") or moveset:GetChildren()[2]
end

task.spawn(function()
	while screenGui.Parent do
		if not state.enabled then
			task.wait(0.25)
			continue
		end

		task.wait(0.1)

		if isSpecialOnCooldown() then
			continue
		end

		rightActivated:FireServer()

		local pressedAt = os.clock()
		while state.enabled and not isSpecialActive() and os.clock() - pressedAt < OFFLOAD_TIMEOUT do
			task.wait(0.05)
		end

		local cannonTool = getCannonTool()
		if isSpecialActive() and cannonTool and not isCannonOnCooldown() then
			ultraActivated:FireServer(cannonTool)
			ultraDeactivated:FireServer(cannonTool, false)
		end

		local startedAt = os.clock()
		while state.enabled and not isSpecialOnCooldown() and os.clock() - startedAt < 1 do
			task.wait(0.05)
		end
	end
end)


local tweenService = game:GetService("TweenService")

local BASE_URL = "https://raw.githubusercontent.com/FluxusScripts/jjs-universal/main/"

local LANGUAGES = {
	{
		code = "en",
		name = "English",
		hint = "Load the English version",
		file = "NewScript_EN",
		loading = "Loading..."
	},
	{
		code = "ru",
		name = "Русский",
		hint = "Загрузить русскую версию",
		file = "NewScript_RU",
		loading = "Загрузка..."
	},
}

local SURFACE = Color3.fromRGB(20, 18, 24)
local SURFACE_CONTAINER = Color3.fromRGB(29, 27, 32)
local SURFACE_HIGHEST = Color3.fromRGB(54, 52, 59)

local PRIMARY = Color3.fromRGB(128, 218, 210)
local ON_PRIMARY = Color3.fromRGB(0, 55, 50)
local PRIMARY_CONTAINER = Color3.fromRGB(0, 80, 74)
local ON_PRIMARY_CONTAINER = Color3.fromRGB(178, 242, 235)

local SECONDARY_CONTAINER = Color3.fromRGB(51, 77, 74)
local ON_SECONDARY_CONTAINER = Color3.fromRGB(204, 232, 228)

local ON_SURFACE = Color3.fromRGB(230, 224, 233)
local ON_SURFACE_VARIANT = Color3.fromRGB(202, 196, 208)
local OUTLINE = Color3.fromRGB(147, 143, 153)

local ERROR_COLOR = Color3.fromRGB(242, 184, 181)
local HOVER_COLOR = Color3.fromRGB(0, 100, 92)
local BUTTON_SECONDARY = Color3.fromRGB(38, 42, 42)

if shared.overloadLoader then
	pcall(function()
		shared.overloadLoader:Destroy()
	end)
end

local function create(className, properties, parent)
	local object = Instance.new(className)

	for key, value in pairs(properties) do
		object[key] = value
	end

	object.Parent = parent
	return object
end

local function round(object, radius)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius)
	}, object)
end

local function tween(object, goal, duration)
	tweenService:Create(
		object,
		TweenInfo.new(
			duration or 0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		goal
	):Play()
end

local screenGui = create("ScreenGui", {
	Name = "OverloadLoader",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, gethui())

shared.overloadLoader = screenGui

local card = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(320, 290),
	BackgroundColor3 = SURFACE_CONTAINER,
	Active = true,
	Draggable = true,
}, screenGui)

round(card, 28)

create("UIStroke", {
	Color = SURFACE_HIGHEST,
	Thickness = 1,
	Transparency = 0,
}, card)

create("TextLabel", {
	Size = UDim2.new(1, -48, 0, 28),
	Position = UDim2.fromOffset(24, 22),
	BackgroundTransparency = 1,
	Text = "Overload",
	TextColor3 = PRIMARY,
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
}, card)

create("TextLabel", {
	Size = UDim2.new(1, -48, 0, 18),
	Position = UDim2.fromOffset(24, 52),
	BackgroundTransparency = 1,
	Text = "Choose language / Выберите язык",
	TextColor3 = ON_SURFACE_VARIANT,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
}, card)

local status = create("TextLabel", {
	Size = UDim2.new(1, -48, 0, 36),
	Position = UDim2.new(0, 24, 1, -48),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = ON_SURFACE_VARIANT,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
}, card)

local busy = false

local function setStatus(message, color)
	status.Text = message
	status.TextColor3 = color or ON_SURFACE_VARIANT
end

local function fetch(url)
	if typeof(request) ~= "function" then
		return nil, "HTTP request is not supported by this executor"
	end

	local ok, response = pcall(request, {
		Url = url,
		Method = "GET"
	})

	if not ok then
		return nil, tostring(response)
	end

	if not response.Success then
		return nil, "HTTP " .. tostring(response.StatusCode)
	end

	return response.Body
end

local function loadLanguage(language)
	if busy then
		return
	end

	busy = true
	setStatus(language.loading)

	task.spawn(function()
		local body, fetchError = fetch(BASE_URL .. language.file)

		if not body then
			busy = false
			setStatus(tostring(fetchError), ERROR_COLOR)
			return
		end

		local compiler = loadstring

		if typeof(compiler) ~= "function" then
			busy = false
			setStatus("loadstring is not supported", ERROR_COLOR)
			return
		end

		local chunk, compileError = compiler(body)

		if not chunk then
			busy = false
			setStatus(tostring(compileError), ERROR_COLOR)
			return
		end

		local success, runtimeError = pcall(chunk)

		if not success then
			busy = false
			setStatus(tostring(runtimeError), ERROR_COLOR)
			return
		end

		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end

		shared.overloadLoader = nil
	end)
end

for index, language in ipairs(LANGUAGES) do
	local initialColor = index == 1
		and PRIMARY_CONTAINER
		or BUTTON_SECONDARY

	local button = create("TextButton", {
		Size = UDim2.new(1, -48, 0, 64),
		Position = UDim2.fromOffset(24, 84 + (index - 1) * 76),
		BackgroundColor3 = initialColor,
		Text = "",
		AutoButtonColor = false,
	}, card)

	round(button, 16)

	local stroke = create("UIStroke", {
		Color = index == 1 and PRIMARY or OUTLINE,
		Thickness = 1,
		Transparency = index == 1 and 0.3 or 0.55,
	}, button)

	create("TextLabel", {
		Size = UDim2.new(1, -32, 0, 24),
		Position = UDim2.fromOffset(18, 12),
		BackgroundTransparency = 1,
		Text = language.name,
		TextColor3 = index == 1
			and ON_PRIMARY_CONTAINER
			or ON_SURFACE,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, button)

	create("TextLabel", {
		Size = UDim2.new(1, -32, 0, 18),
		Position = UDim2.fromOffset(18, 36),
		BackgroundTransparency = 1,
		Text = language.hint,
		TextColor3 = ON_SURFACE_VARIANT,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, button)

	button.MouseEnter:Connect(function()
		tween(button, {
			BackgroundColor3 = HOVER_COLOR
		})

		tween(stroke, {
			Color = PRIMARY,
			Transparency = 0
		})
	end)

	button.MouseLeave:Connect(function()
		tween(button, {
			BackgroundColor3 = initialColor
		})

		tween(stroke, {
			Color = index == 1 and PRIMARY or OUTLINE,
			Transparency = index == 1 and 0.3 or 0.55
		})
	end)

	button.MouseButton1Click:Connect(function()
		loadLanguage(language)
	end)
end


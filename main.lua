--[[
    Roblox Voice Chat Music Bot v4.0
    Created by: borthdayzz (boggle.cc)
]]
pcall(function() loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))("proj_5e6721981d59", "1.0.0", false) end)

if not game:GetService("GuiService") then
	print("Error: Not running in Roblox environment")
	return
end

local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local TextChatService   = game:GetService("TextChatService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local CONFIG = {
	whitelist     = {"omgyesssw"},
	pythonServer  = "http://10.0.2.2:5000",
	chatRateLimit = 5,
	toggleKey     = Enum.KeyCode.RightShift,
}

local function saveWhitelist()
	if writefile then
		pcall(function()
			writefile("MusicBot_Whitelist.json", HttpService:JSONEncode(CONFIG.whitelist))
		end)
	end
end

local function loadWhitelist()
	if isfile and readfile and isfile("MusicBot_Whitelist.json") then
		pcall(function()
			local content = readfile("MusicBot_Whitelist.json")
			local data = HttpService:JSONDecode(content)
			if type(data) == "table" then
				CONFIG.whitelist = data
			end
		end)
	end
end
loadWhitelist()

local ENDPOINTS = {
	health       = "/health",
	spotifyFetch = "/spotify/fetch",
	youtubeFetch = "/youtube/fetch",
	appleFetch   = "/apple/fetch",
	play         = "/play",
	pause        = "/pause",
	resume       = "/resume",
	stop         = "/stop",
	status       = "/status",
	search       = "/search",
	seek         = "/seek",
}

local C = {
	bg           = Color3.fromRGB(8, 9, 20),
	surface      = Color3.fromRGB(16, 18, 36),
	surfaceHigh  = Color3.fromRGB(255, 255, 253),
	surfacePop   = Color3.fromRGB(254, 255, 255),
	surfaceHover = Color3.fromRGB(253, 255, 255),
	border       = Color3.fromRGB(255, 255, 255),
	borderSub    = Color3.fromRGB(255, 255, 252),
	textPrimary  = Color3.fromRGB(248, 249, 255),
	textSec      = Color3.fromRGB(202, 207, 226),
	textMuted    = Color3.fromRGB(140, 148, 176),
	spotify      = Color3.fromRGB(30, 215, 96),
	youtube      = Color3.fromRGB(255, 62, 62),
	apple        = Color3.fromRGB(250, 45, 72),
	cyan         = Color3.fromRGB(0, 210, 255),
	discord      = Color3.fromRGB(88, 101, 242),
	warn         = Color3.fromRGB(255, 195, 45),
	error        = Color3.fromRGB(245, 75, 75),
	success      = Color3.fromRGB(30, 215, 96),
	white        = Color3.fromRGB(255, 255, 255),
	black        = Color3.fromRGB(0, 0, 0),
}

local THEME = {
	palettes = {
	Midnight = {
		bg = Color3.fromRGB(8, 9, 20), surface = Color3.fromRGB(16, 18, 36),
		surfaceHigh = Color3.fromRGB(255, 255, 253), surfacePop = Color3.fromRGB(254, 255, 255),
		surfaceHover = Color3.fromRGB(253, 255, 255), border = Color3.fromRGB(255, 255, 255),
		borderSub = Color3.fromRGB(255, 255, 252), textPrimary = Color3.fromRGB(248, 249, 255),
		textSec = Color3.fromRGB(202, 207, 226), textMuted = Color3.fromRGB(140, 148, 176),
		accent = Color3.fromRGB(30, 215, 96),
	},
	Ocean = {
		bg = Color3.fromRGB(5, 12, 27), surface = Color3.fromRGB(11, 25, 46),
		surfaceHigh = Color3.fromRGB(79, 121, 157), surfacePop = Color3.fromRGB(92, 145, 183),
		surfaceHover = Color3.fromRGB(111, 168, 204), border = Color3.fromRGB(142, 201, 231),
		borderSub = Color3.fromRGB(110, 174, 210), textPrimary = Color3.fromRGB(239, 249, 255),
		textSec = Color3.fromRGB(182, 213, 234), textMuted = Color3.fromRGB(125, 165, 193),
		accent = Color3.fromRGB(54, 190, 255),
	},
	Sunset = {
		bg = Color3.fromRGB(26, 10, 22), surface = Color3.fromRGB(43, 17, 34),
		surfaceHigh = Color3.fromRGB(164, 91, 113), surfacePop = Color3.fromRGB(187, 104, 121),
		surfaceHover = Color3.fromRGB(211, 123, 129), border = Color3.fromRGB(243, 174, 169),
		borderSub = Color3.fromRGB(220, 143, 146), textPrimary = Color3.fromRGB(255, 244, 240),
		textSec = Color3.fromRGB(235, 199, 199), textMuted = Color3.fromRGB(190, 143, 155),
		accent = Color3.fromRGB(255, 130, 91),
	},
	Light = {
		bg = Color3.fromRGB(226, 233, 245), surface = Color3.fromRGB(246, 249, 255),
		surfaceHigh = Color3.fromRGB(195, 208, 228), surfacePop = Color3.fromRGB(180, 197, 221),
		surfaceHover = Color3.fromRGB(163, 184, 213), border = Color3.fromRGB(255, 255, 255),
		borderSub = Color3.fromRGB(167, 183, 207), textPrimary = Color3.fromRGB(25, 35, 54),
		textSec = Color3.fromRGB(60, 75, 101), textMuted = Color3.fromRGB(99, 115, 142),
		accent = Color3.fromRGB(28, 145, 91),
	},
	},
	keys = {
	"bg", "surface", "surfaceHigh", "surfacePop", "surfaceHover",
	"border", "borderSub", "textPrimary", "textSec", "textMuted",
	},
	file = "MusicBot_Settings.json",
	current = "Midnight",
	properties = {},
	strokes = {},
	buttons = {},
	names = {"Midnight", "Ocean", "Sunset", "Light"},
	backendControls = {},
	backendStatusInitialized = false,
}
if isfile and readfile and isfile(THEME.file) then
	pcall(function()
		local saved = HttpService:JSONDecode(readfile(THEME.file))
		if type(saved) == "table" and THEME.palettes[saved.theme] then
			THEME.current = saved.theme
		end
		if type(saved) == "table" and type(saved.pythonServer) == "string"
			and saved.pythonServer:match("^https?://[^/%s]+/?$") then
			CONFIG.pythonServer = saved.pythonServer:gsub("/+$", "")
		end
	end)
end
for key, value in pairs(THEME.palettes[THEME.current]) do
	if key ~= "accent" then C[key] = value end
end

local currentAccent = C.spotify

local RADIUS = {
	window = UDim.new(0, 22),
	card   = UDim.new(0, 14),
	btn    = UDim.new(0, 12),
	pill   = UDim.new(0, 999),
	input  = UDim.new(0, 14),
}

THEME.getToken = function(color, property)
	local keys
	if property == "BackgroundColor3" then
		keys = {"bg", "surface", "surfaceHigh", "surfacePop", "surfaceHover"}
	elseif property == "TextColor3" then
		keys = {"textPrimary", "textSec", "textMuted"}
	elseif property == "PlaceholderColor3" or property == "ImageColor3" then
		keys = {"textMuted"}
	end
	if keys then
		for _, key in ipairs(keys) do
			if color == C[key] then return key end
		end
		return nil
	end
	for _, key in ipairs(THEME.keys) do
		if color == C[key] then return key end
	end
	return nil
end

THEME.color = function(key)
	return THEME.palettes[THEME.current][key]
end

THEME.savePreference = function()
	if writefile then
		pcall(function()
			writefile(THEME.file, HttpService:JSONEncode({
				theme = THEME.current,
				pythonServer = CONFIG.pythonServer,
			}))
		end)
	end
end

THEME.apply = function(name)
	local palette = THEME.palettes[name]
	if not palette then return end
	THEME.current = name
	for _, key in ipairs(THEME.keys) do C[key] = palette[key] end
	for instance, properties in pairs(THEME.properties) do
		if instance.Parent then
			for property, token in pairs(properties) do
				local value = palette[token]
				if THEME.tweenColors then
					THEME.tweenColors(instance, {[property] = value})
				else
					instance[property] = value
				end
			end
		end
	end
	for instance, token in pairs(THEME.strokes) do
		if instance.Parent then
			if THEME.tweenColors then
				THEME.tweenColors(instance, {Color = palette[token]})
			else
				instance.Color = palette[token]
			end
		end
	end
	if THEME.refreshServiceModeTabs then THEME.refreshServiceModeTabs(true) end
	if THEME.refreshPageTabs then THEME.refreshPageTabs() end
	if THEME.refreshWhitelistLabel then THEME.refreshWhitelistLabel() end
	THEME.savePreference()
	if THEME.refreshSelection then THEME.refreshSelection() end
end

local function make(class, props, parent)
	local inst = Instance.new(class)
	props = props or {}
	local bg = props.BackgroundColor3
	if bg and props.BackgroundTransparency == nil then
		if bg == C.surface then props.BackgroundTransparency = 0.28
		elseif bg == C.bg then props.BackgroundTransparency = 0.45
		elseif bg == C.surfaceHigh then props.BackgroundTransparency = 0.90
		elseif bg == C.surfacePop then props.BackgroundTransparency = 0.84
		elseif bg == C.surfaceHover then props.BackgroundTransparency = 0.78 end
	end
	for k, v in pairs(props) do inst[k] = v end
	for _, property in ipairs({"BackgroundColor3", "TextColor3", "PlaceholderColor3"}) do
		local value = props[property]
		local token = value and THEME.getToken(value, property)
		local statefulText = property == "TextColor3"
			and (props.Name == "StatusLabel" or props.Name == "StatusPillText")
		if token and not statefulText then
			THEME.properties[inst] = THEME.properties[inst] or {}
			THEME.properties[inst][property] = token
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(r, parent)
	return make("UICorner", {CornerRadius = r}, parent)
end

local function stroke(color, thick, trans, parent)
	local themeToken
	if color == C.border or color == C.borderSub then
		themeToken = color == C.border and "border" or "borderSub"
		trans = 0.72 + (trans or 0) * 0.25
	end
	local result = make("UIStroke", {Color = color, Thickness = thick or 1, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent)
	if themeToken then THEME.strokes[result] = themeToken end
	return result
end

local function gradient(c0, c1, rot, parent)
	return make("UIGradient", {
		Color    = ColorSequence.new{ColorSequenceKeypoint.new(0, c0), ColorSequenceKeypoint.new(1, c1)},
		Rotation = rot or 90,
	}, parent)
end

local function tween(inst, props, t, style, dir)
	if not inst or not inst.Parent then return nil end
	local info = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local tw = TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

THEME.tweenColors = function(inst, props)
	tween(inst, props, 0.22)
end

local function hover(btn, normal, over, textNormal, textOver)
	local base = btn.BackgroundTransparency
	local danger = (over.R - over.B) > 0.3
	local overAlpha = math.max(0, base - (danger and 0.45 or 0.1))
	local normalToken = THEME.getToken(normal, "BackgroundColor3")
	local overToken = THEME.getToken(over, "BackgroundColor3")
	local textNormalToken = THEME.getToken(textNormal, "TextColor3")
	local textOverToken = THEME.getToken(textOver, "TextColor3")
	btn.MouseEnter:Connect(function()
		local p = {BackgroundTransparency = overAlpha}
		if danger then p.BackgroundColor3 = overToken and THEME.color(overToken) or over end
		if textOver then p.TextColor3 = textOverToken and THEME.color(textOverToken) or textOver end
		tween(btn, p, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		local p = {BackgroundTransparency = base}
		if danger then p.BackgroundColor3 = normalToken and THEME.color(normalToken) or normal end
		if textNormal then p.TextColor3 = textNormalToken and THEME.color(textNormalToken) or textNormal end
		tween(btn, p, 0.12)
	end)
end

local accentOrbs = {}

local function orbRings(parent, cx, cy, diameter, color, ringAlpha)
	local rings = {}
	for i = 1, 5 do
		local d = diameter * (1 - (i - 1) * 0.17)
		local ring = make("Frame", {
			Name = "Orb",
			Size = UDim2.new(0, d, 0, d),
			Position = UDim2.new(0, cx - d / 2, 0, cy - d / 2),
			BackgroundColor3 = color,
			BackgroundTransparency = ringAlpha or 0.95,
			BorderSizePixel = 0,
		}, parent)
		corner(UDim.new(0, 999), ring)
		table.insert(rings, ring)
	end
	return rings
end

local function sheen(parent, radius)
	local f = make("Frame", {
		Name = "Sheen", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0, BorderSizePixel = 0,
	}, parent)
	corner(UDim.new(0, radius), f)
	make("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.4, 0.94),
			NumberSequenceKeypoint.new(1, 1),
		},
	}, f)
	return f
end

local function glassEdge(parent, thickness)
	local s = make("UIStroke", {
		Color = Color3.new(1, 1, 1), Thickness = thickness or 1.3, Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	make("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 0.25),
		},
	}, s)
	return s
end

local function glassDecor(parent, radius, orbs)
	for _, o in ipairs(orbs) do
		local rings = orbRings(parent, o.x, o.y, o.d, o.color, o.a)
		if o.accent then
			for _, r in ipairs(rings) do table.insert(accentOrbs, r) end
		end
	end
	sheen(parent, radius)
	glassEdge(parent, 1.3)
end

local function fadeEnds(f)
	make("UIGradient", {
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		},
	}, f)
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function getGuiContainer()
	local ok, res = pcall(function()
		if gethui then return gethui() end
		if game:GetService("CoreGui") then return game:GetService("CoreGui") end
		return player and player:FindFirstChild("PlayerGui")
	end)
	if ok and res then return res end
	return player and player:WaitForChild("PlayerGui")
end

local parentGui = getGuiContainer()
if parentGui and parentGui:FindFirstChild("SpotifyMusicBot") then
	pcall(function() parentGui.SpotifyMusicBot:Destroy() end)
end

local screenGui = make("ScreenGui", {
	Name           = "SpotifyMusicBot",
	ResetOnSpawn   = false,
	DisplayOrder   = 15,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parentGui)

local currentSongData   = nil
local pythonRunning     = false
local songQueue         = {}
local isPlaying         = false
local isPaused          = false
local playbackMonitor   = nil
local serviceMode       = "spotify"
local playbackElapsed   = 0
local isMiniMode        = false
local isGuiVisible      = true

local setStatus
local updateAlbumArt
local updateQueueUI
local playNextInQueue
local startPlaybackMonitor
local playSong
local pauseSong
local stopSong
local skipSong
local searchAndPlaySong
local callPythonBackend
local isPythonServerRunning
local syncQueuePosition
local toggleMiniPlayer

local WIN_W, WIN_H = 620, 420
local QUEUE_W = 290

local shadowFrame = make("Frame", {
	Name                   = "ShadowFrame",
	Size                   = UDim2.new(0, WIN_W + 16, 0, WIN_H + 16),
	Position               = UDim2.new(0.5, -(WIN_W + 16) / 2, 0.5, -(WIN_H + 16) / 2),
	BackgroundColor3       = C.black,
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
}, screenGui)
corner(UDim.new(0, 24), shadowFrame)
local winScale = make("UIScale", {Scale = 1}, shadowFrame)

local mainFrame = make("Frame", {
	Name             = "MainFrame",
	Size             = UDim2.new(0, WIN_W, 0, WIN_H),
	Position         = UDim2.new(0, 8, 0, 8),
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
}, shadowFrame)
corner(RADIUS.window, mainFrame)
glassDecor(mainFrame, 22, {
	{x = 125, y = 115, d = 230, color = C.spotify, accent = true, a = 0.94},
	{x = 490, y = 270, d = 200, color = Color3.fromRGB(130, 90, 255), a = 0.95},
	{x = 370, y = 90,  d = 150, color = Color3.fromRGB(255, 90, 180), a = 0.97},
})

local topAccent = make("Frame", {
	Name             = "TopAccent",
	Size = UDim2.new(1, -90, 0, 2), Position = UDim2.new(0, 45, 0, 1),
	BackgroundColor3 = C.spotify,
	BorderSizePixel  = 0,
	ZIndex           = 10,
}, mainFrame)
corner(UDim.new(0, 3), topAccent)
fadeEnds(topAccent)

local header = make("Frame", {
	Name             = "Header",
	Size             = UDim2.new(1, 0, 0, 46),
	Position         = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = C.bg, BackgroundTransparency = 1,
	BorderSizePixel  = 0,
}, mainFrame)

make("Frame", {
	Size             = UDim2.new(1, 0, 0, 1),
	Position         = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = C.borderSub,
	BorderSizePixel  = 0,
}, header)

local trafficControls = make("Frame", {
	Size                   = UDim2.new(0, 60, 0, 20),
	Position               = UDim2.new(0, 16, 0.5, -10),
	BackgroundTransparency = 1,
}, header)
make("UIListLayout", {
	FillDirection       = Enum.FillDirection.Horizontal,
	VerticalAlignment   = Enum.VerticalAlignment.Center,
	Padding             = UDim.new(0, 8),
}, trafficControls)

local function trafficDot(name, color, iconText, iconColor, iconSize)
	local b = make("TextButton", {
		Name = name, Size = UDim2.new(0, 13, 0, 13), BackgroundColor3 = color,
		Text = "", BorderSizePixel = 0, AutoButtonColor = false,
	}, trafficControls)
	corner(RADIUS.pill, b)
	local ic = make("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = iconText,
		TextColor3 = iconColor, Font = Enum.Font.GothamBold, TextSize = iconSize, Visible = false,
	}, b)
	return b, ic
end

local btnClose, closeIcon = trafficDot("BtnClose", Color3.fromRGB(255, 95, 88), "✕", Color3.fromRGB(100, 10, 10), 8)
local btnMini, miniIcon   = trafficDot("BtnMini", Color3.fromRGB(255, 189, 46), "−", Color3.fromRGB(120, 70, 0), 10)
local btnQueueTraffic, queueIcon = trafficDot("BtnQueueTraffic", Color3.fromRGB(39, 201, 63), "≡", Color3.fromRGB(10, 80, 20), 9)

trafficControls.MouseEnter:Connect(function()
	closeIcon.Visible, miniIcon.Visible, queueIcon.Visible = true, true, true
end)
trafficControls.MouseLeave:Connect(function()
	closeIcon.Visible, miniIcon.Visible, queueIcon.Visible = false, false, false
end)

local titleContainer = make("Frame", {
	Size                   = UDim2.new(0, 260, 0, 34),
	Position               = UDim2.new(0, 92, 0.5, -17),
	BackgroundTransparency = 1,
}, header)

local headerTitle = make("TextLabel", {
	Name = "HeaderTitle", Size = UDim2.new(1, 0, 0, 19), BackgroundTransparency = 1,
	Text = "VC Player", TextColor3 = C.textPrimary, Font = Enum.Font.GothamBold,
	TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, titleContainer)

local headerSub = make("TextLabel", {
	Name = "HeaderSub", Size = UDim2.new(1, 0, 0, 13), Position = UDim2.new(0, 0, 0, 19),
	BackgroundTransparency = 1, Text = "v4.0  ·  spotify", TextColor3 = C.textMuted,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, titleContainer)

local function headerIconButton(name, text, xOff)
	local b = make("TextButton", {
		Name = name, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, xOff, 0.5, -15),
		BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec, Text = text,
		Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false,
	}, header)
	corner(RADIUS.btn, b)
	stroke(C.borderSub, 1, 0.3, b)
	hover(b, C.surfaceHigh, C.surfacePop, C.textSec, C.white)
	return b
end
local creditsButton  = headerIconButton("CreditsButton", "ℹ", -80)
local headerQueueBtn = headerIconButton("HeaderQueueBtn", "≡", -44)

local body = make("Frame", {
	Name                   = "Body",
	Size                   = UDim2.new(1, -32, 0, 276),
	Position               = UDim2.new(0, 16, 0, 58),
	BackgroundTransparency = 1,
}, mainFrame)

local leftCol = make("Frame", {
	Name = "LeftCol", Size = UDim2.new(0, 190, 1, 0), BackgroundTransparency = 1,
}, body)

local artGlow = make("Frame", {
	Name = "ArtGlow", Size = UDim2.new(0, 206, 0, 206), Position = UDim2.new(0, -8, 0, -8),
	BackgroundColor3 = C.spotify, BackgroundTransparency = 0.9, BorderSizePixel = 0,
}, leftCol)
corner(UDim.new(0, 24), artGlow)

local artContainer = make("Frame", {
	Name = "ArtContainer", Size = UDim2.new(0, 190, 0, 190), BackgroundColor3 = C.surfacePop,
	BorderSizePixel = 0, ClipsDescendants = true,
}, leftCol)
corner(UDim.new(0, 16), artContainer)
stroke(C.border, 1, 0.5, artContainer)

local albumArt = make("ImageLabel", {
	Name = "AlbumArt", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.surfacePop,
	BorderSizePixel = 0, Image = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png",
	ScaleType = Enum.ScaleType.Crop, ImageColor3 = C.textMuted,
}, artContainer)
local albumArtGradient = gradient(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 155, 190), 135, albumArt)

local sourceBadge = make("Frame", {
	Name = "SourceBadge", Size = UDim2.new(0, 64, 0, 20), Position = UDim2.new(0, 10, 1, -30),
	BackgroundColor3 = C.spotify, BorderSizePixel = 0, ZIndex = 3,
}, artContainer)
corner(RADIUS.pill, sourceBadge)
local sourceBadgeText = make("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "SPOTIFY",
	TextColor3 = C.black, Font = Enum.Font.GothamBold, TextSize = 9, ZIndex = 4,
}, sourceBadge)

local visualizer = make("Frame", {
	Name = "Visualizer", Size = UDim2.new(0, 190, 0, 62), Position = UDim2.new(0, 0, 0, 212),
	BackgroundTransparency = 1,
}, leftCol)
local EQ_COUNT = 24
local eqBars, eqHeights = {}, {}
for i = 1, EQ_COUNT do
	local bar = make("Frame", {
		Name = "Bar_" .. i, Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(0, (i - 1) * 8, 1, -4),
		BackgroundColor3 = C.spotify, BackgroundTransparency = 0.6, BorderSizePixel = 0,
	}, visualizer)
	corner(RADIUS.pill, bar)
	eqBars[i], eqHeights[i] = bar, 4
end

local rightCol = make("Frame", {
	Name = "RightCol", Size = UDim2.new(1, -206, 1, 0), Position = UDim2.new(0, 206, 0, 0),
	BackgroundTransparency = 1,
}, body)

local modeTabs = make("Frame", {
	Name = "ModeTabs", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0,
}, rightCol)
corner(RADIUS.pill, modeTabs)
stroke(C.borderSub, 1, 0.3, modeTabs)

local function makeTab(name, label, color, index)
	local tab = make("TextButton", {
		Name = "Tab_" .. name, Size = UDim2.new(0, 93, 0, 26),
		Position = UDim2.new(0, 2 + (index - 1) * 95, 0, 3),
		BackgroundColor3 = color,
		BackgroundTransparency = (serviceMode == name) and 0 or 1,
		TextColor3 = (serviceMode == name) and ((name == "spotify") and C.black or C.white) or C.textMuted,
		Text = label, Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false,
	}, modeTabs)
	corner(RADIUS.pill, tab)
	return tab
end
local tabSpotify = makeTab("spotify", "Spotify", C.spotify, 1)
local tabYouTube = makeTab("youtube", "YouTube", C.youtube, 2)
local tabApple   = makeTab("apple",   "Apple",   C.apple,   3)
local tabAuto    = makeTab("auto",    "Auto",    C.cyan,    4)

THEME.refreshServiceModeTabs = function(animate)
	local tabs = {
		spotify = {btn = tabSpotify, color = C.spotify},
		youtube = {btn = tabYouTube, color = C.youtube},
		apple = {btn = tabApple, color = C.apple},
		auto = {btn = tabAuto, color = C.cyan},
	}
	for mode, tab in pairs(tabs) do
		local selected = mode == serviceMode
		local props = selected and {
			BackgroundColor3 = tab.color, BackgroundTransparency = 0,
			TextColor3 = (mode == "spotify" or mode == "auto") and C.black or C.white,
		} or {BackgroundTransparency = 1, TextColor3 = C.textMuted}
		if animate then
			tween(tab.btn, props, 0.15)
		else
			for property, value in pairs(props) do tab.btn[property] = value end
		end
	end
end

local songTitle = make("TextLabel", {
	Name = "SongTitle", Size = UDim2.new(1, -86, 0, 28), Position = UDim2.new(0, 0, 0, 46),
	BackgroundTransparency = 1, Text = "Nothing playing", TextColor3 = C.textPrimary,
	Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, rightCol)

local songArtist = make("TextLabel", {
	Name = "SongArtist", Size = UDim2.new(1, -86, 0, 18), Position = UDim2.new(0, 0, 0, 75),
	BackgroundTransparency = 1, Text = "Paste a link or search below to play", TextColor3 = C.textSec,
	Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, rightCol)

local statusPill = make("Frame", {
	Name = "StatusPill", Size = UDim2.new(0, 76, 0, 20), Position = UDim2.new(1, -76, 0, 50),
	BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0,
}, rightCol)
corner(RADIUS.pill, statusPill)
local statusPillStroke = stroke(C.borderSub, 1, 0.2, statusPill)
local statusPillText = make("TextLabel", {
	Name = "StatusPillText",
	Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "IDLE",
	TextColor3 = C.textMuted, Font = Enum.Font.GothamBold, TextSize = 9,
}, statusPill)

local progTrack = make("Frame", {
	Name = "ProgressTrack", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 103),
	BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
}, rightCol)
local progTrackVisual = make("Frame", {
	Name = "ProgressTrackVisual", Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3),
	BackgroundColor3 = C.surfacePop, BorderSizePixel = 0,
}, progTrack)
corner(RADIUS.pill, progTrackVisual)
local progFill = make("Frame", {
	Name = "ProgressFill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.spotify, BorderSizePixel = 0,
}, progTrackVisual)
corner(RADIUS.pill, progFill)
local progKnob = make("Frame", {
	Name = "Knob", Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6),
	BackgroundColor3 = C.white, BorderSizePixel = 0,
}, progFill)
corner(RADIUS.pill, progKnob)

local timeElapsedLabel = make("TextLabel", {
	Name = "TimeElapsed", Size = UDim2.new(0, 60, 0, 14), Position = UDim2.new(0, 0, 0, 122),
	BackgroundTransparency = 1, Text = "00:00", TextColor3 = C.textMuted,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, rightCol)
local timeTotalLabel = make("TextLabel", {
	Name = "TimeTotal", Size = UDim2.new(0, 60, 0, 14), Position = UDim2.new(1, -60, 0, 122),
	BackgroundTransparency = 1, Text = "--:--", TextColor3 = C.textMuted,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right,
}, rightCol)

local ctrlRow = make("Frame", {
	Name = "ControlsRow", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.new(0, 0, 0, 144),
	BackgroundTransparency = 1,
}, rightCol)

local transport = make("Frame", {
	Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
}, ctrlRow)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 14),
}, transport)

local function roundButton(name, text, size, bg, fg, textSize)
	local b = make("TextButton", {
		Name = name, Size = UDim2.new(0, size, 0, size), BackgroundColor3 = bg, TextColor3 = fg,
		Text = text, Font = Enum.Font.GothamBold, TextSize = textSize, BorderSizePixel = 0, AutoButtonColor = false,
	}, transport)
	corner(RADIUS.pill, b)
	return b
end

local stopButton = roundButton("StopButton", "⏹", 40, C.surfaceHigh, C.textSec, 15)
stroke(C.borderSub, 1, 0.2, stopButton)
hover(stopButton, C.surfaceHigh, C.surfacePop, C.textSec, C.white)

local playHeroButton = roundButton("PlayHeroButton", "▶", 56, currentAccent, C.black, 22)
playHeroButton.MouseEnter:Connect(function() tween(playHeroButton, {Size = UDim2.new(0, 60, 0, 60)}, 0.12) end)
playHeroButton.MouseLeave:Connect(function() tween(playHeroButton, {Size = UDim2.new(0, 56, 0, 56)}, 0.12) end)

local skipButton = roundButton("SkipButton", "⏭", 40, C.surfaceHigh, C.textSec, 15)
stroke(C.borderSub, 1, 0.2, skipButton)
hover(skipButton, C.surfaceHigh, C.surfacePop, C.textSec, C.white)

local queueToggleBtn = make("TextButton", {
	Name = "QueueToggleBtn", Size = UDim2.new(0, 92, 0, 34), Position = UDim2.new(1, -92, 0.5, -17),
	BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec, Text = "≡  Queue (0)",
	Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false,
}, ctrlRow)
corner(RADIUS.btn, queueToggleBtn)
stroke(C.borderSub, 1, 0.2, queueToggleBtn)
hover(queueToggleBtn, C.surfaceHigh, C.surfacePop, C.textSec, C.white)

local inputRow = make("Frame", {
	Name = "InputRow", Size = UDim2.new(1, 0, 0, 42), Position = UDim2.new(0, 0, 0, 220),
	BackgroundTransparency = 1,
}, rightCol)

local inputContainer = make("Frame", {
	Name = "InputContainer", Size = UDim2.new(1, -92, 1, 0), BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0,
}, inputRow)
corner(RADIUS.input, inputContainer)
local inputStroke = stroke(C.borderSub, 1, 0.2, inputContainer)

make("TextLabel", {
	Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1,
	Text = "🔍", TextColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 12,
}, inputContainer)

local inputBox = make("TextBox", {
	Name = "InputBox", Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 36, 0, 0),
	BackgroundTransparency = 1, TextColor3 = C.textPrimary, PlaceholderColor3 = C.textMuted,
	Text = "", PlaceholderText = "Paste a link or type a song title...", TextSize = 12,
	Font = Enum.Font.Gotham, BorderSizePixel = 0, ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, inputContainer)

local btnClearInput = make("TextButton", {
	Name = "BtnClearInput", Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -28, 0.5, -10),
	BackgroundColor3 = C.surfacePop, TextColor3 = C.textSec, Text = "✕", Font = Enum.Font.GothamBold,
	TextSize = 9, BorderSizePixel = 0, Visible = false,
}, inputContainer)
corner(RADIUS.pill, btnClearInput)

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	btnClearInput.Visible = (#inputBox.Text > 0)
end)
btnClearInput.MouseButton1Click:Connect(function()
	inputBox.Text = ""
	btnClearInput.Visible = false
	inputBox:CaptureFocus()
end)
inputBox.Focused:Connect(function()
	tween(inputContainer, {BackgroundTransparency = 0.78}, 0.15)
	tween(inputStroke, {Color = currentAccent, Transparency = 0}, 0.15)
end)
inputBox.FocusLost:Connect(function()
	tween(inputContainer, {BackgroundTransparency = 0.9}, 0.15)
	tween(inputStroke, {Color = C.white, Transparency = 0.8}, 0.15)
end)

local loadButton = make("TextButton", {
	Name = "LoadButton", Size = UDim2.new(0, 84, 1, 0), Position = UDim2.new(1, -84, 0, 0),
	BackgroundColor3 = currentAccent, TextColor3 = C.black, Text = "Load",
	Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0, AutoButtonColor = false,
}, inputRow)
corner(RADIUS.input, loadButton)
loadButton.MouseEnter:Connect(function() tween(loadButton, {BackgroundTransparency = 0.15}, 0.12) end)
loadButton.MouseLeave:Connect(function() tween(loadButton, {BackgroundTransparency = 0}, 0.12) end)

local mainNotice = make("Frame", {
	Name = "UsageNotice", Size = UDim2.new(1, -32, 0, 34), Position = UDim2.new(0, 16, 0, 338),
	BackgroundColor3 = C.warn, BackgroundTransparency = 0.88, BorderSizePixel = 0,
}, mainFrame)
corner(RADIUS.btn, mainNotice)
stroke(C.warn, 1, 0.5, mainNotice)
make("TextLabel", {
	Size = UDim2.new(1, -20, 1, -4), Position = UDim2.new(0, 10, 0, 2),
	BackgroundTransparency = 1,
	Text = "⚠  Mobile is not supported. Inappropriate music in voice chat may violate Roblox rules and could get you banned.",
	TextColor3 = C.warn, Font = Enum.Font.GothamBold, TextSize = 10,
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
}, mainNotice)

local statusBar = make("Frame", {
	Name = "StatusBar", Size = UDim2.new(1, -32, 0, 26), Position = UDim2.new(0, 16, 1, -40),
	BackgroundColor3 = C.bg, BorderSizePixel = 0,
}, mainFrame)
corner(RADIUS.btn, statusBar)
stroke(C.borderSub, 1, 0.3, statusBar)

local statusDot = make("Frame", {
	Name = "StatusDot", Size = UDim2.new(0, 7, 0, 7), Position = UDim2.new(0, 12, 0.5, -3.5),
	BackgroundColor3 = C.warn, BorderSizePixel = 0,
}, statusBar)
corner(RADIUS.pill, statusDot)

local statusLabel = make("TextLabel", {
	Name = "StatusLabel", Size = UDim2.new(1, -170, 1, 0), Position = UDim2.new(0, 28, 0, 0),
	BackgroundTransparency = 1, Text = "Connecting to server...", TextColor3 = C.textSec,
	Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, statusBar)

make("TextLabel", {
	Name = "KeybindTip", Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(1, -150, 0, 0),
	BackgroundTransparency = 1, Text = "[R-Shift] Hide / Show", TextColor3 = C.textMuted,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right,
}, statusBar)

local queueFrame = make("Frame", {
	Name = "QueueFrame", Size = UDim2.new(0, QUEUE_W, 0, WIN_H),
	Position = UDim2.new(0.5, -(WIN_W + 16) / 2 + WIN_W + 22, 0.5, -(WIN_H + 16) / 2 + 8),
	BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false,
}, screenGui)
corner(RADIUS.window, queueFrame)
glassDecor(queueFrame, 22, {
	{x = 150, y = 100, d = 190, color = C.spotify, accent = true, a = 0.94},
	{x = 150, y = 290, d = 170, color = Color3.fromRGB(130, 90, 255), a = 0.95},
})

local qAccent = make("Frame", {
	Size = UDim2.new(1, -90, 0, 2), Position = UDim2.new(0, 45, 0, 1), BackgroundColor3 = C.spotify, BorderSizePixel = 0, ZIndex = 10,
}, queueFrame)
corner(UDim.new(0, 3), qAccent)
fadeEnds(qAccent)

local qHdr = make("Frame", {
	Name = "QueueHeader", Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = C.bg, BackgroundTransparency = 1, BorderSizePixel = 0,
}, queueFrame)

make("Frame", {
	Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = C.borderSub, BorderSizePixel = 0,
}, qHdr)

make("TextLabel", {
	Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1,
	Text = "Up Next", TextColor3 = C.textPrimary, Font = Enum.Font.GothamBold, TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, qHdr)

local btnClearQueue = make("TextButton", {
	Name = "BtnClearQueue", Size = UDim2.new(0, 64, 0, 26), Position = UDim2.new(1, -80, 0.5, -13),
	BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec, Text = "Clear",
	Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0, AutoButtonColor = false,
}, qHdr)
corner(RADIUS.btn, btnClearQueue)
stroke(C.borderSub, 1, 0.3, btnClearQueue)
hover(btnClearQueue, C.surfaceHigh, Color3.fromRGB(190, 50, 50), C.textSec, C.white)

local queueList = make("ScrollingFrame", {
	Name = "QueueList", Size = UDim2.new(1, -16, 1, -62), Position = UDim2.new(0, 8, 0, 56),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.border, CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, queueFrame)
make("UIListLayout", {
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, queueList)

local emptyQueueLabel = make("TextLabel", {
	Name = "EmptyQueueLabel", Size = UDim2.new(1, -20, 0, 100), Position = UDim2.new(0, 10, 0, 130),
	BackgroundTransparency = 1, Text = "🎶\nQueue is empty\nPaste links or search songs to add!",
	TextColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, Visible = true,
}, queueFrame)

local miniFrame = make("Frame", {
	Name = "MiniPlayer", Size = UDim2.new(0, 360, 0, 58), Position = UDim2.new(1, -380, 1, -78),
	BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false,
}, screenGui)
corner(UDim.new(0, 16), miniFrame)
glassDecor(miniFrame, 16, {})

local miniArt = make("ImageLabel", {
	Name = "MiniArt", Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 9, 0, 8),
	BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0,
	Image = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png",
	ScaleType = Enum.ScaleType.Crop, ImageColor3 = C.textMuted,
}, miniFrame)
corner(UDim.new(0, 8), miniArt)

local miniTitle = make("TextLabel", {
	Name = "MiniTitle", Size = UDim2.new(1, -184, 0, 18), Position = UDim2.new(0, 58, 0, 9),
	BackgroundTransparency = 1, Text = "Nothing playing", TextColor3 = C.textPrimary,
	Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, miniFrame)

local miniArtist = make("TextLabel", {
	Name = "MiniArtist", Size = UDim2.new(1, -184, 0, 14), Position = UDim2.new(0, 58, 0, 28),
	BackgroundTransparency = 1, Text = "Idle", TextColor3 = C.textSec,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, miniFrame)

local miniPlayBtn = make("TextButton", {
	Name = "MiniPlayBtn", Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, -112, 0, 9),
	BackgroundColor3 = C.spotify, TextColor3 = C.black, Text = "▶", Font = Enum.Font.GothamBold,
	TextSize = 12, BorderSizePixel = 0, AutoButtonColor = false,
}, miniFrame)
corner(RADIUS.pill, miniPlayBtn)

local miniSkipBtn = make("TextButton", {
	Name = "MiniSkipBtn", Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -74, 0, 11),
	BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec, Text = "⏭", Font = Enum.Font.GothamBold,
	TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false,
}, miniFrame)
corner(RADIUS.pill, miniSkipBtn)
hover(miniSkipBtn, C.surfaceHigh, C.surfacePop, C.textSec, C.white)

local miniExpandBtn = make("TextButton", {
	Name = "MiniExpandBtn", Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -40, 0, 11),
	BackgroundColor3 = C.surfacePop, TextColor3 = C.white, Text = "⛶", Font = Enum.Font.GothamBold,
	TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false,
}, miniFrame)
corner(RADIUS.pill, miniExpandBtn)
hover(miniExpandBtn, C.surfacePop, C.surfaceHover, C.white, C.white)

local miniTrack = make("Frame", {
	Size = UDim2.new(1, -24, 0, 3), Position = UDim2.new(0, 12, 1, -7),
	BackgroundColor3 = C.surfacePop, BorderSizePixel = 0,
}, miniFrame)
corner(RADIUS.pill, miniTrack)
local miniFill = make("Frame", {
	Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.spotify, BorderSizePixel = 0,
}, miniTrack)
corner(RADIUS.pill, miniFill)

local restoreBadge = make("TextButton", {
	Name = "RestoreBadge", Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(0.5, -60, 0, 10),
	BackgroundColor3 = C.surface, TextColor3 = C.textSec, Text = "🎵  Open Player",
	Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false, Visible = false,
}, screenGui)
corner(RADIUS.pill, restoreBadge)
stroke(C.border, 1, 0.4, restoreBadge)
hover(restoreBadge, C.surface, C.surfacePop, C.textSec, C.white)

local modalBackdrop = make("TextButton", {
	Name = "ModalBackdrop", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.black,
	BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 90,
	Text = "", AutoButtonColor = false,
}, screenGui)

local creditsModal = make("Frame", {
	Name = "CreditsModal", Size = UDim2.new(0.92, 0, 0, 320), Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false, ZIndex = 100,
}, screenGui)
creditsModal.AnchorPoint = Vector2.new(0.5, 0.5)
make("UISizeConstraint", {MaxSize = Vector2.new(520, 720)}, creditsModal)
THEME.modalScale = make("UIScale", {Scale = 1}, creditsModal)
corner(RADIUS.window, creditsModal)
glassDecor(creditsModal, 22, {
	{x = 90,  y = 80,  d = 140, color = C.spotify, accent = true, a = 0.94},
	{x = 340, y = 300, d = 150, color = Color3.fromRGB(130, 90, 255), a = 0.95},
})

local cmAccent = make("Frame", {
	Size = UDim2.new(1, -90, 0, 2), Position = UDim2.new(0, 45, 0, 1), BackgroundColor3 = currentAccent, BorderSizePixel = 0, ZIndex = 110,
}, creditsModal)
corner(UDim.new(0, 3), cmAccent)
fadeEnds(cmAccent)

local cmHdr = make("Frame", {
	Size = UDim2.new(1, 0, 0, 52), Position = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = C.bg, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 101,
}, creditsModal)

make("TextLabel", {
	Size = UDim2.new(1, -68, 0, 23), Position = UDim2.new(0, 18, 0, 5), BackgroundTransparency = 1,
	Text = "About & Settings", TextColor3 = C.textPrimary, Font = Enum.Font.GothamBold, TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102,
}, cmHdr)
make("TextLabel", {
	Size = UDim2.new(1, -68, 0, 15), Position = UDim2.new(0, 18, 0, 28), BackgroundTransparency = 1,
	Text = "Personalize your player and manage access", TextColor3 = C.textMuted,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102,
}, cmHdr)

local closeCreditsBtn = make("TextButton", {
	Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -40, 0.5, -13),
	BackgroundColor3 = C.surfacePop, TextColor3 = C.textSec, Text = "✕",
	Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, ZIndex = 102, AutoButtonColor = false,
}, cmHdr)
corner(RADIUS.pill, closeCreditsBtn)
stroke(C.borderSub, 1, 0.25, closeCreditsBtn)
hover(closeCreditsBtn, C.surfacePop, Color3.fromRGB(220, 60, 60), C.textSec, C.white)

THEME.pageTabs = {}
THEME.pages = {}
THEME.pageLayouts = {}
THEME.pageVisuals = {}
THEME.pagePositions = {}
THEME.activePage = "About"
THEME.pageSequence = 0
THEME.modalSequence = 0

THEME.updateModalSize = function(animate)
	local layout = THEME.pageLayouts[THEME.activePage]
	if not layout then return end
	local viewportHeight = 720
	local camera = workspace.CurrentCamera
	if camera and camera.ViewportSize.Y > 0 then
		viewportHeight = camera.ViewportSize.Y
	elseif screenGui.AbsoluteSize.Y > 0 then
		viewportHeight = screenGui.AbsoluteSize.Y
	end
	local maxHeight = math.max(220, math.floor(viewportHeight * 0.84))
	local contentHeight = layout.AbsoluteContentSize.Y + 120
	local modalHeight = math.clamp(contentHeight, 220, maxHeight)
	local targetSize = UDim2.new(0.92, 0, 0, modalHeight)
	if animate and creditsModal.Visible then
		tween(creditsModal, {Size = targetSize}, 0.2, Enum.EasingStyle.Quart)
	else
		creditsModal.Size = targetSize
	end
end

THEME.tabBar = make("Frame", {
	Name = "SettingsTabs", Size = UDim2.new(1, -32, 0, 34), Position = UDim2.new(0, 16, 0, 62),
	BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0, ZIndex = 102,
}, creditsModal)
corner(RADIUS.pill, THEME.tabBar)
stroke(C.borderSub, 1, 0.3, THEME.tabBar)

for index, pageName in ipairs({"About", "Settings"}) do
	local capturedPage = pageName
	THEME.pages[pageName] = make("ScrollingFrame", {
		Name = pageName .. "Page", Size = UDim2.new(1, -32, 1, -112),
		Position = UDim2.new(0, 16, 0, 104), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = currentAccent,
		CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, Visible = pageName == THEME.activePage,
		ZIndex = 101,
	}, creditsModal)
	THEME.pagePositions[pageName] = THEME.pages[pageName].Position
	THEME.pageLayouts[pageName] = make("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, THEME.pages[pageName])
	THEME.pageLayouts[pageName]:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		THEME.pages[capturedPage].CanvasSize = UDim2.new(0, 0, 0, THEME.pageLayouts[capturedPage].AbsoluteContentSize.Y + 8)
		if capturedPage == THEME.activePage then THEME.updateModalSize(true) end
	end)

	local pageTab = make("TextButton", {
		Name = "Tab" .. pageName, Size = UDim2.new(0.5, -4, 1, -4),
		Position = UDim2.new((index - 1) * 0.5, 2, 0, 2),
		BackgroundColor3 = pageName == THEME.activePage and currentAccent or C.surfaceHigh,
		BackgroundTransparency = pageName == THEME.activePage and 0 or 1,
		Text = pageName, TextColor3 = pageName == THEME.activePage and C.white or C.textMuted,
		Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 103,
	}, THEME.tabBar)
	corner(RADIUS.pill, pageTab)
	THEME.pageTabs[pageName] = pageTab
	pageTab.MouseButton1Click:Connect(function()
		THEME.switchPage(capturedPage)
	end)
end

THEME.refreshPageTabs = function()
	for _, pageName in ipairs({"About", "Settings"}) do
		local selected = pageName == THEME.activePage
		tween(THEME.pageTabs[pageName], {
			BackgroundColor3 = selected and currentAccent or C.surfaceHigh,
			BackgroundTransparency = selected and 0 or 1,
			TextColor3 = selected
			and ((currentAccent == C.spotify or currentAccent == C.cyan) and C.black or C.white)
			or C.textMuted,
		}, 0.18)
	end
end
THEME.refreshPageTabs()

THEME.capturePageVisuals = function(pageName)
	local page = THEME.pages[pageName]
	local visuals = THEME.pageVisuals[pageName]
	if visuals then return visuals end

	visuals = {}
	THEME.pageVisuals[pageName] = visuals
	for _, instance in ipairs(page:GetDescendants()) do
		local targets = {}
		if instance:IsA("GuiObject") then
			targets.BackgroundTransparency = instance.BackgroundTransparency
			if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
				targets.TextTransparency = instance.TextTransparency
				targets.TextStrokeTransparency = instance.TextStrokeTransparency
			elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
				targets.ImageTransparency = instance.ImageTransparency
			end
		elseif instance:IsA("UIStroke") then
			targets.Transparency = instance.Transparency
		end
		if next(targets) then visuals[instance] = targets end
	end
	visuals[page] = {ScrollBarImageTransparency = page.ScrollBarImageTransparency}
	return visuals
end

THEME.switchPage = function(pageName)
	if not THEME.pages[pageName] or pageName == THEME.activePage then return end
	THEME.pageSequence = THEME.pageSequence + 1
	local sequence = THEME.pageSequence
	THEME.activePage = pageName
	THEME.refreshPageTabs()
	THEME.updateModalSize(true)

	local targetPage = THEME.pages[pageName]
	targetPage.Visible = true
	THEME.capturePageVisuals(pageName)
	local targetPosition = THEME.pagePositions[pageName]
	targetPage.Position = UDim2.new(
		targetPosition.X.Scale, targetPosition.X.Offset,
		targetPosition.Y.Scale, targetPosition.Y.Offset + 8
	)

	for name, page in pairs(THEME.pages) do
		local visuals = THEME.capturePageVisuals(name)
		local entering = name == pageName
		if not entering and page.Visible then
			page.Position = UDim2.new(
				THEME.pagePositions[name].X.Scale, THEME.pagePositions[name].X.Offset,
				THEME.pagePositions[name].Y.Scale, THEME.pagePositions[name].Y.Offset - 4
			)
		end

		for instance, properties in pairs(visuals) do
			if instance.Parent then
				local goals = {}
				for property, target in pairs(properties) do
					if entering then
						instance[property] = 1
						goals[property] = target
					else
						goals[property] = 1
					end
				end
				tween(instance, goals, 0.18)
			end
		end
		if not entering and page.Visible then
			tween(page, {Position = UDim2.new(
				THEME.pagePositions[name].X.Scale, THEME.pagePositions[name].X.Offset,
				THEME.pagePositions[name].Y.Scale, THEME.pagePositions[name].Y.Offset - 4
			)}, 0.18)
		elseif entering then
			tween(page, {Position = targetPosition}, 0.22, Enum.EasingStyle.Quart)
		end
	end

	task.delay(0.24, function()
		if sequence ~= THEME.pageSequence then return end
		for name, page in pairs(THEME.pages) do
			if name ~= pageName then
				page.Visible = false
				page.Position = THEME.pagePositions[name]
				for instance, properties in pairs(THEME.pageVisuals[name]) do
					if instance.Parent then
						for property, value in pairs(properties) do instance[property] = value end
					end
				end
			else
				page.Position = THEME.pagePositions[name]
			end
		end
	end)
end

local function cmCard(parent, h, lo, bgColor)
	local f = make("Frame", {
		Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = bgColor or C.surfaceHigh,
		BorderSizePixel = 0, LayoutOrder = lo, ZIndex = 102,
	}, parent)
	corner(RADIUS.card, f)
	stroke(C.borderSub, 1, 0.3, f)
	return f
end

local function cmLabel(parent, props)
	props.BackgroundTransparency = 1
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.ZIndex = 103
	return make("TextLabel", props, parent)
end

THEME.card = cmCard(THEME.pages.Settings, 86, 1)
cmLabel(THEME.card, {
	Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 14, 0, 8),
	Text = "APPEARANCE", TextColor3 = C.textMuted, Font = Enum.Font.GothamBold, TextSize = 9,
})
THEME.currentLabel = cmLabel(THEME.card, {
	Size = UDim2.new(0, 100, 0, 16), Position = UDim2.new(1, -114, 0, 8),
	Text = THEME.current .. " theme", TextColor3 = C.textSec, Font = Enum.Font.Gotham, TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Right,
})
for index, themeName in ipairs(THEME.names) do
	local capturedTheme = themeName
	local themeButton = make("TextButton", {
		Name = "Theme_" .. themeName, Size = UDim2.new(0.25, -7, 0, 42),
		Position = UDim2.new((index - 1) * 0.25, 2, 0, 34),
		BackgroundColor3 = C.surfacePop, TextColor3 = C.textSec, Text = "",
		Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0,
		AutoButtonColor = false, ZIndex = 103,
	}, THEME.card)
	corner(RADIUS.btn, themeButton)
	local themeOutline = stroke(C.borderSub, 1, 0.25, themeButton)
	local preview = make("Frame", {
		Size = UDim2.new(0, 30, 0, 4), Position = UDim2.new(0, 8, 0, 7),
		BackgroundColor3 = THEME.palettes[capturedTheme].accent, BorderSizePixel = 0, ZIndex = 104,
	}, themeButton)
	corner(RADIUS.pill, preview)
	local nameLabel = make("TextLabel", {
		Size = UDim2.new(1, -10, 0, 14), Position = UDim2.new(0, 5, 0, 19),
		BackgroundTransparency = 1, Text = capturedTheme, TextColor3 = C.textSec,
		Font = Enum.Font.GothamBold, TextSize = 9, TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 104,
	}, themeButton)
	THEME.buttons[capturedTheme] = {button = themeButton, outline = themeOutline, label = nameLabel}
	themeButton.MouseButton1Click:Connect(function()
		THEME.apply(capturedTheme)
		setStatus("Theme changed: " .. capturedTheme, C.success)
	end)
end

THEME.refreshSelection = function()
	THEME.currentLabel.Text = THEME.current .. " theme"
	for themeName, controls in pairs(THEME.buttons) do
		local selected = themeName == THEME.current
		tween(controls.outline, {
			Color = selected and currentAccent or C.borderSub,
			Thickness = selected and 2 or 1,
		}, 0.18)
		tween(controls.label, {
			TextColor3 = selected and C.textPrimary or C.textSec,
		}, 0.18)
	end
end
local c1 = cmCard(THEME.pages.About, 54, 1)
cmLabel(c1, {
	Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 14, 0, 8),
	Text = "🎵  Roblox VC Music Player v4.0", TextColor3 = currentAccent, Font = Enum.Font.GothamBold, TextSize = 14,
})
cmLabel(c1, {
	Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 14, 0, 29),
	Text = "Created by borthdayzz  ·  boggle.cc", TextColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 10,
})

local c2 = cmCard(THEME.pages.About, 76, 2)
cmLabel(c2, {
	Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 14, 0, 9),
	Text = "CHAT COMMANDS  (whitelisted users only)", TextColor3 = C.textMuted, Font = Enum.Font.GothamBold, TextSize = 9,
})
cmLabel(c2, {
	Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 14, 0, 28),
	Text = "!play <song name / link>  ·  search or stream\n!pause  ·  !resume  ·  !stop  ·  !skip",
	TextColor3 = C.textSec, Font = Enum.Font.Gotham, TextSize = 11, TextYAlignment = Enum.TextYAlignment.Top,
})

local c3 = cmCard(THEME.pages.About, 60, 3, C.discord)
c3.BackgroundTransparency = 0.8
cmLabel(c3, {
	Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 14, 0, 8),
	Text = "COMMUNITY & SUPPORT", TextColor3 = Color3.fromRGB(150, 165, 255), Font = Enum.Font.GothamBold, TextSize = 9,
})
cmLabel(c3, {
	Size = UDim2.new(1, -100, 0, 24), Position = UDim2.new(0, 14, 0, 26),
	Text = "discord.gg/NCEfg4rKPC", TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 12,
})
local copyDiscordBtn = make("TextButton", {
	Size = UDim2.new(0, 68, 0, 24), Position = UDim2.new(1, -80, 0.5, -12),
	BackgroundColor3 = C.discord, TextColor3 = C.white, Text = "Copy",
	Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0, ZIndex = 103, AutoButtonColor = false,
}, c3)
corner(RADIUS.btn, copyDiscordBtn)
copyDiscordBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard("https://discord.gg/NCEfg4rKPC")
		copyDiscordBtn.Text = "Copied!"
		task.delay(1.5, function() copyDiscordBtn.Text = "Copy" end)
	end
end)

local serverCard = cmCard(THEME.pages.Settings, 96, 2)
cmLabel(serverCard, {
	Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 14, 0, 8),
	Text = "PYTHON SERVER", TextColor3 = C.textMuted, Font = Enum.Font.GothamBold, TextSize = 9,
})
local serverAddressBox = make("TextBox", {
	Size = UDim2.new(1, -186, 0, 28), Position = UDim2.new(0, 14, 0, 34),
	BackgroundColor3 = C.surfacePop, TextColor3 = C.textPrimary,
	PlaceholderColor3 = C.textMuted, PlaceholderText = "http://localhost:5000",
	Text = CONFIG.pythonServer, Font = Enum.Font.Gotham, TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	BorderSizePixel = 0, ZIndex = 103,
}, serverCard)
corner(RADIUS.btn, serverAddressBox)
stroke(C.borderSub, 1, 0.3, serverAddressBox)

local saveServerBtn = make("TextButton", {
	Size = UDim2.new(0, 76, 0, 28), Position = UDim2.new(1, -158, 0, 34),
	BackgroundColor3 = currentAccent, TextColor3 = C.black, Text = "Save",
	Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0,
	AutoButtonColor = false, ZIndex = 103,
}, serverCard)
corner(RADIUS.btn, saveServerBtn)

local testServerBtn = make("TextButton", {
	Size = UDim2.new(0, 72, 0, 28), Position = UDim2.new(1, -76, 0, 34),
	BackgroundColor3 = C.surfacePop, TextColor3 = C.textSec, Text = "Test",
	Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0,
	AutoButtonColor = false, ZIndex = 103,
}, serverCard)
corner(RADIUS.btn, testServerBtn)
stroke(C.borderSub, 1, 0.3, testServerBtn)

local serverTestLabel = cmLabel(serverCard, {
	Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 0, 70),
	Text = "Set the address where spotify_server.py is running.",
	TextColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 9,
	TextTruncate = Enum.TextTruncate.AtEnd,
})

local function normalizeServerAddress(value)
	local address = tostring(value or ""):match("^%s*(.-)%s*$") or ""
	if not address:match("^https?://[^/%s]+/?$") then return nil end
	return address:gsub("/+$", "")
end

local function testServerAddress(address)
	local ok, response = pcall(function()
		return game:HttpGet(address .. ENDPOINTS.health)
	end)
	if not ok or not response then return false end
	local decodedOk, data = pcall(function() return HttpService:JSONDecode(response) end)
	return decodedOk and type(data) == "table" and data.status == "ok"
end

saveServerBtn.MouseButton1Click:Connect(function()
	local address = normalizeServerAddress(serverAddressBox.Text)
	if not address then
		serverTestLabel.Text = "Enter a valid http:// or https:// address."
		serverTestLabel.TextColor3 = C.error
		return
	end
	CONFIG.pythonServer = address
	serverAddressBox.Text = address
	THEME.savePreference()
	local available = testServerAddress(address)
	if THEME.setBackendAvailable then THEME.setBackendAvailable(available) end
	serverTestLabel.Text = available and "Saved · server is online." or "Saved · server is offline."
	serverTestLabel.TextColor3 = available and C.success or C.warn
	setStatus(available and "Python server connected" or "Python server address saved; server offline", available and C.success or C.warn)
end)

testServerBtn.MouseButton1Click:Connect(function()
	local address = normalizeServerAddress(serverAddressBox.Text)
	if not address then
		serverTestLabel.Text = "Enter a valid http:// or https:// address."
		serverTestLabel.TextColor3 = C.error
		return
	end
	testServerBtn.Interactable = false
	serverTestLabel.Text = "Testing connection..."
	serverTestLabel.TextColor3 = C.textMuted
	task.spawn(function()
		local available = testServerAddress(address)
		testServerBtn.Interactable = true
		serverTestLabel.Text = available and "Connection successful." or "Could not reach /health at this address."
		serverTestLabel.TextColor3 = available and C.success or C.error
	end)
end)

local c4 = cmCard(THEME.pages.Settings, 210, 3)
cmLabel(c4, {
	Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 14, 0, 8),
	Text = "WHITELIST MANAGER", TextColor3 = C.spotify, Font = Enum.Font.GothamBold, TextSize = 9,
})
cmLabel(c4, {
	Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 14, 0, 22),
	Text = "You are always whitelisted. Remove others below.",
	TextColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 9,
})

local wlInputContainer = make("Frame", {
	Size = UDim2.new(1, -100, 0, 28), Position = UDim2.new(0, 14, 0, 40),
	BackgroundColor3 = C.surfacePop, BorderSizePixel = 0, ZIndex = 103,
}, c4)
corner(RADIUS.btn, wlInputContainer)
stroke(C.borderSub, 1, 0.3, wlInputContainer)

local wlInputBox = make("TextBox", {
	Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
	PlaceholderText = "Username or UserId...", Text = "", TextColor3 = C.textPrimary,
	PlaceholderColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 10, BorderSizePixel = 0,
	ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 104,
}, wlInputContainer)

local btnAddWL = make("TextButton", {
	Size = UDim2.new(0, 68, 0, 28), Position = UDim2.new(1, -82, 0, 40),
	BackgroundColor3 = C.spotify, TextColor3 = C.black, Text = "+ Add",
	Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0, ZIndex = 103, AutoButtonColor = false,
}, c4)
corner(RADIUS.btn, btnAddWL)

local wlList = make("ScrollingFrame", {
	Name = "WhitelistEntries", Size = UDim2.new(1, -28, 0, 118),
	Position = UDim2.new(0, 14, 0, 78), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.border,
	CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 103,
}, c4)
make("UIListLayout", {
	Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
}, wlList)

local function refreshWhitelistLabel()
	for _, child in ipairs(wlList:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end
	if #CONFIG.whitelist == 0 then
		make("TextLabel", {
			Size = UDim2.new(1, -8, 0, 24), BackgroundTransparency = 1,
			Text = "No additional users are whitelisted.",
			TextColor3 = C.textMuted, Font = Enum.Font.Gotham, TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
		}, wlList)
	else
		for index, entry in ipairs(CONFIG.whitelist) do
			local capturedEntry = tostring(entry)
			local row = make("Frame", {
				Name = "Whitelist_" .. index, Size = UDim2.new(1, -6, 0, 26),
				BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0, LayoutOrder = index,
			}, wlList)
			corner(RADIUS.btn, row)
			make("TextLabel", {
				Size = UDim2.new(1, -42, 1, 0), Position = UDim2.new(0, 8, 0, 0),
				BackgroundTransparency = 1, Text = capturedEntry,
				TextColor3 = C.textSec, Font = Enum.Font.Gotham, TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)
			local removeButton = make("TextButton", {
				Size = UDim2.new(0, 24, 0, 22), Position = UDim2.new(1, -28, 0.5, -11),
				BackgroundColor3 = C.surfacePop, TextColor3 = C.error, Text = "×",
				Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0,
				AutoButtonColor = false,
			}, row)
			corner(RADIUS.pill, removeButton)
			removeButton.MouseButton1Click:Connect(function()
				for entryIndex, value in ipairs(CONFIG.whitelist) do
					if tostring(value):lower() == capturedEntry:lower() then
						table.remove(CONFIG.whitelist, entryIndex)
						break
					end
				end
				saveWhitelist()
				refreshWhitelistLabel()
				setStatus("Whitelist entry removed", C.warn)
			end)
		end
	end
end
THEME.refreshWhitelistLabel = refreshWhitelistLabel
refreshWhitelistLabel()
THEME.updateModalSize(false)

THEME.bindViewport = function()
	if THEME.viewportConnection then
		THEME.viewportConnection:Disconnect()
		THEME.viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		THEME.viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			THEME.updateModalSize(true)
		end)
	end
end
THEME.bindViewport()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(THEME.bindViewport)

btnAddWL.MouseButton1Click:Connect(function()
	local newName = wlInputBox.Text:match("^%s*(.-)%s*$") or ""
	if newName ~= "" then
		local already = false
		for _, v in ipairs(CONFIG.whitelist) do
			if tostring(v):lower() == newName:lower() then already = true; break end
		end
		if not already then
			table.insert(CONFIG.whitelist, newName)
			saveWhitelist()
			refreshWhitelistLabel()
			wlInputBox.Text = ""
			setStatus("Whitelisted: " .. newName, C.success)
		else
			setStatus(newName .. " is already whitelisted", C.warn)
		end
	end
end)

local function toggleCredits(visible)
	THEME.modalSequence = THEME.modalSequence + 1
	local sequence = THEME.modalSequence
	if visible then
		refreshWhitelistLabel()
		THEME.updateModalSize(false)
		modalBackdrop.Visible = true
		creditsModal.Visible = true
		modalBackdrop.BackgroundTransparency = 1
		THEME.modalScale.Scale = 0.94
		tween(THEME.modalScale, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
	else
		if not creditsModal.Visible then return end
		tween(THEME.modalScale, {Scale = 0.96}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.17, function()
			if sequence ~= THEME.modalSequence then return end
			creditsModal.Visible = false
			modalBackdrop.Visible = false
			THEME.modalScale.Scale = 1
		end)
	end
end

closeCreditsBtn.MouseButton1Click:Connect(function() toggleCredits(false) end)
modalBackdrop.MouseButton1Click:Connect(function() toggleCredits(false) end)
creditsButton.MouseButton1Click:Connect(function() toggleCredits(not creditsModal.Visible) end)

local function enableDragging(dragHandle, targetFrame, onDragCallback)
	local isDragging, dragStart, startPos = false, nil, nil

	dragHandle.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			dragStart  = input.Position
			startPos   = targetFrame.Position
		end
	end)
	dragHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			targetFrame.Position = newPos
			if onDragCallback then onDragCallback(newPos) end
		end
	end)
end

function syncQueuePosition(mainPos)
	mainPos = mainPos or shadowFrame.Position
	queueFrame.Position = UDim2.new(mainPos.X.Scale, mainPos.X.Offset + WIN_W + 22, mainPos.Y.Scale, mainPos.Y.Offset + 8)
end

enableDragging(header, shadowFrame, syncQueuePosition)
enableDragging(miniFrame, miniFrame)

local function getDuration()
	if currentSongData then
		local d = tonumber(currentSongData.duration or currentSongData.duration_seconds or currentSongData.length)
		if d and d > 0 then
			if d > 10000 then d = d / 1000 end
			return d
		end
	end
	return nil
end

local eqTick = 0
local isScrubbing = false
local scrubInputType = nil
local scrubOriginalPosition = 0
RunService.RenderStepped:Connect(function(dt)
	local active = isPlaying and not isPaused
	if active then eqTick = eqTick + dt end

	for i, bar in ipairs(eqBars) do
		local target = 4
		if active then
			local v = (math.sin(eqTick * 7 + i * 0.9) * 0.5 + 0.5) * 0.55 + (math.sin(eqTick * 11 - i * 1.7) * 0.5 + 0.5) * 0.45
			target = 4 + v * 54
		end
		eqHeights[i] = eqHeights[i] + (target - eqHeights[i]) * math.min(1, dt * 12)
		local h = math.max(4, math.floor(eqHeights[i]))
		bar.Size = UDim2.new(0, 4, 0, h)
		bar.Position = UDim2.new(0, (i - 1) * 8, 1, -h)
		bar.BackgroundTransparency = active and math.clamp(0.55 - (h / 60) * 0.5, 0, 0.6) or 0.65
	end

	if active and not isScrubbing then
		playbackElapsed = playbackElapsed + dt
		timeElapsedLabel.Text = formatTime(playbackElapsed)

		local dur = getDuration()
		local frac = dur and math.clamp(playbackElapsed / dur, 0, 1) or 0
		progFill.Size = UDim2.new(frac, 0, 1, 0)
		miniFill.Size = UDim2.new(frac, 0, 1, 0)
	end
end)

local function applyAccent(accentColor)
	currentAccent = accentColor
	topAccent.BackgroundColor3     = accentColor
	qAccent.BackgroundColor3       = accentColor
	cmAccent.BackgroundColor3      = accentColor
	progFill.BackgroundColor3      = accentColor
	miniFill.BackgroundColor3      = accentColor
	miniPlayBtn.BackgroundColor3   = accentColor
	playHeroButton.BackgroundColor3= accentColor
	loadButton.BackgroundColor3    = accentColor
	saveServerBtn.BackgroundColor3 = accentColor
	artGlow.BackgroundColor3       = accentColor
	sourceBadge.BackgroundColor3   = accentColor
	for _, bar in ipairs(eqBars) do bar.BackgroundColor3 = accentColor end
	for _, r in ipairs(accentOrbs) do tween(r, {BackgroundColor3 = accentColor}, 0.35) end

	local darkText = (accentColor == C.spotify or accentColor == C.cyan)
	local fg = darkText and C.black or C.white
	playHeroButton.TextColor3 = fg
	loadButton.TextColor3     = fg
	miniPlayBtn.TextColor3    = fg
	sourceBadgeText.TextColor3= fg
	if THEME.refreshSelection then THEME.refreshSelection() end
	if THEME.refreshPageTabs then THEME.refreshPageTabs() end
end

local function switchServiceMode(mode)
	serviceMode = mode

	local tabs = {
		spotify = {btn = tabSpotify, col = C.spotify, label = "SPOTIFY"},
		youtube = {btn = tabYouTube, col = C.youtube, label = "YOUTUBE"},
		apple   = {btn = tabApple,   col = C.apple,   label = "APPLE"},
		auto    = {btn = tabAuto,    col = C.cyan,    label = "AUTO"},
	}

	THEME.refreshServiceModeTabs(true)

	applyAccent(tabs[mode] and tabs[mode].col or C.spotify)
	sourceBadgeText.Text = tabs[mode] and tabs[mode].label or "SPOTIFY"

	if mode == "spotify" then
		inputBox.PlaceholderText = "Paste a Spotify link or song name..."
		headerSub.Text = "v4.0  ·  spotify"
	elseif mode == "youtube" then
		inputBox.PlaceholderText = "Paste a YouTube link or song name..."
		headerSub.Text = "v4.0  ·  youtube"
	elseif mode == "apple" then
		inputBox.PlaceholderText = "Paste an Apple Music link or song name..."
		headerSub.Text = "v4.0  ·  apple music"
	else
		inputBox.PlaceholderText = "Auto-detect any link, or type a song name..."
		headerSub.Text = "v4.0  ·  auto-detect"
	end

	setStatus("Switched mode: " .. mode:upper(), C.success)
end

tabSpotify.TextColor3 = C.black

tabSpotify.MouseButton1Click:Connect(function() switchServiceMode("spotify") end)
tabYouTube.MouseButton1Click:Connect(function() switchServiceMode("youtube") end)
tabApple.MouseButton1Click:Connect(function() switchServiceMode("apple") end)
tabAuto.MouseButton1Click:Connect(function() switchServiceMode("auto") end)

function setStatus(text, color)
	color = color or C.success
	statusLabel.Text           = text
	statusLabel.TextColor3     = color
	statusDot.BackgroundColor3 = color
end

local function popIn()
	winScale.Scale = 0.94
	tween(winScale, {Scale = 1}, 0.25, Enum.EasingStyle.Back)
end

function toggleMiniPlayer(forceMini)
	if forceMini ~= nil then isMiniMode = forceMini else isMiniMode = not isMiniMode end

	if isMiniMode then
		shadowFrame.Visible = false
		queueFrame.Visible  = false
		miniFrame.Visible   = true
	else
		miniFrame.Visible   = false
		shadowFrame.Visible = true
		syncQueuePosition()
		popIn()
	end
end

local function setGuiVisible(visible)
	isGuiVisible = visible
	if not visible then
		shadowFrame.Visible   = false
		queueFrame.Visible    = false
		miniFrame.Visible     = false
		toggleCredits(false)
		restoreBadge.Visible  = true
	else
		restoreBadge.Visible = false
		if isMiniMode then
			miniFrame.Visible = true
		else
			shadowFrame.Visible = true
			syncQueuePosition()
			popIn()
		end
	end
end

btnClose.MouseButton1Click:Connect(function()
	setGuiVisible(false)
	setStatus("Player hidden. Press [Right-Shift] or click top badge to restore.", C.warn)
end)
btnMini.MouseButton1Click:Connect(function() toggleMiniPlayer(true) end)
miniExpandBtn.MouseButton1Click:Connect(function() toggleMiniPlayer(false) end)
restoreBadge.MouseButton1Click:Connect(function() setGuiVisible(true) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CONFIG.toggleKey then
		setGuiVisible(not isGuiVisible)
	end
end)

local function downloadAndCacheAlbumArt(imageUrl, trackId)
	if not (isfolder and makefolder and writefile and getcustomasset and isfile and readfile) then
		return nil
	end
	if not imageUrl or imageUrl == "" then return nil end

	if not isfolder("AlbumArt") then
		pcall(makefolder, "AlbumArt")
	end

	local cleanUrl = imageUrl:match("^([^?]+)") or imageUrl
	local ext = cleanUrl:match("%.%w+$") or ".png"
	local filePath = "AlbumArt/" .. tostring(trackId or "default") .. ext

	if isfile(filePath) then
		local ok, content = pcall(readfile, filePath)
		if ok and content and #content > 100 then
			return getcustomasset(filePath)
		end
	end

	local success, response
	if httpRequest and not imageUrl:find("localhost") and not imageUrl:find("127.0.0.1") and not imageUrl:find("192.168%.") then
		success, response = pcall(function()
			local res = httpRequest({
				Url = imageUrl, Method = "GET",
				Headers = {["Content-Type"] = "application/octet-stream"},
			})
			return res and (res.Body or res.body)
		end)
	end

	if not success or not response or #response < 100 then
		success, response = pcall(function() return game:HttpGet(imageUrl) end)
	end
	if not success or not response or #response < 100 then return nil end

	pcall(function() writefile(filePath, response) end)

	if isfile(filePath) then
		local ok, content = pcall(readfile, filePath)
		if ok and content and #content > 100 then
			return getcustomasset(filePath)
		end
	end
	return nil
end

function updateAlbumArt(imagePath, imageUrl, trackId)
	local fallbackIcon = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png"

	local function setArtAsset(asset)
		albumArt.Image = asset
		albumArt.ImageColor3 = Color3.new(1, 1, 1)
		albumArtGradient.Enabled = false
		miniArt.Image = asset
		miniArt.ImageColor3 = Color3.new(1, 1, 1)
	end

	local function setFallback()
		albumArt.Image = fallbackIcon
		albumArt.ImageColor3 = C.textMuted
		albumArtGradient.Enabled = true
		miniArt.Image = fallbackIcon
		miniArt.ImageColor3 = C.textMuted
	end

	if imagePath and imagePath ~= "" and isfile and isfile(imagePath) then
		local ok, asset = pcall(getcustomasset, imagePath)
		if ok and asset then setArtAsset(asset); return end
	end

	if imageUrl and imageUrl ~= "" then
		local cached = downloadAndCacheAlbumArt(imageUrl, trackId)
		if cached then setArtAsset(cached); return end
	end

	setFallback()
end

local function setNowPlaying(sd)
	currentSongData = sd
	playbackElapsed = 0
	timeElapsedLabel.Text = "00:00"
	progFill.Size = UDim2.new(0, 0, 1, 0)
	miniFill.Size = UDim2.new(0, 0, 1, 0)
	songTitle.Text  = sd.title or "Unknown"
	songArtist.Text = sd.artist or "—"
	miniTitle.Text  = sd.title or "Unknown"
	miniArtist.Text = sd.artist or "—"
	local d = getDuration()
	timeTotalLabel.Text = d and formatTime(d) or "--:--"
	updateAlbumArt(sd.image_path or "", sd.image or "", sd.track_id)
end

local function setIdleUI()
	songTitle.Text  = "Nothing playing"
	songArtist.Text = "Paste a link or search below to play"
	miniTitle.Text  = "Nothing playing"
	miniArtist.Text = "Idle"
	timeElapsedLabel.Text = "00:00"
	timeTotalLabel.Text   = "--:--"
	progFill.Size = UDim2.new(0, 0, 1, 0)
	miniFill.Size = UDim2.new(0, 0, 1, 0)
	updateAlbumArt("", "", nil)
end

local function setTransportUI(state)
	local playIcon = (state == "playing") and "⏸" or "▶"
	playHeroButton.Text = playIcon
	miniPlayBtn.Text    = playIcon

	local label, col = "IDLE", C.textMuted
	if state == "playing" then label, col = "PLAYING", C.success
	elseif state == "paused" then label, col = "PAUSED", C.warn
	elseif state == "error" then label, col = "ERROR", C.error end
	statusPillText.Text = label
	statusPillText.TextColor3 = col
	statusPillStroke.Color = (state == "idle") and C.white or col
	statusPillStroke.Transparency = (state == "idle") and 0.8 or 0.4
end

local function launchSong(s)
	setNowPlaying(s)
	setStatus("Playing: " .. (s.title or "Song"), C.success)
	local playUrl = CONFIG.pythonServer .. ENDPOINTS.play .. "?path=" .. HttpService:UrlEncode(s.path)
	local duration = tonumber(s.duration)
	if duration and duration > 0 then
		playUrl = playUrl .. "&duration=" .. HttpService:UrlEncode(tostring(duration))
	end
	local ok = pcall(function()
		return game:HttpGet(playUrl)
	end)
	if ok then
		isPlaying = true
		isPaused  = false
		playbackElapsed = 0
		setTransportUI("playing")
		startPlaybackMonitor()
	else
		isPlaying = false
		setTransportUI("error")
		setStatus("Failed to play song", C.error)
	end
	return ok
end

local function moveSongInQueue(index, offset)
	local newIndex = index + offset
	if newIndex < 1 or newIndex > #songQueue then return end
	local song = table.remove(songQueue, index)
	table.insert(songQueue, newIndex, song)
	updateQueueUI()
end

function updateQueueUI()
	for _, c in ipairs(queueList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	emptyQueueLabel.Visible = (#songQueue == 0)
	queueToggleBtn.Text     = string.format("≡  Queue (%d)", #songQueue)

	for i, song in ipairs(songQueue) do
		local queueIndex = i
		local item = make("Frame", {
			Name = "QueueItem_" .. i, Size = UDim2.new(1, -4, 0, 54),
			BackgroundColor3 = C.surfaceHigh, BorderSizePixel = 0, LayoutOrder = i,
		}, queueList)
		corner(RADIUS.card, item)
		stroke(C.borderSub, 1, 0.3, item)

		local idxBadge = make("TextLabel", {
			Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 10, 0.5, -12),
			BackgroundColor3 = C.surfacePop, TextColor3 = C.textMuted, Text = tostring(i),
			Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0,
		}, item)
		corner(RADIUS.pill, idxBadge)

		make("TextLabel", {
			Size = UDim2.new(1, -160, 0, 18), Position = UDim2.new(0, 42, 0, 9),
			BackgroundTransparency = 1, Text = song.title or "Unknown", TextColor3 = C.textPrimary,
			Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, item)

		make("TextLabel", {
			Size = UDim2.new(1, -160, 0, 14), Position = UDim2.new(0, 42, 0, 28),
			BackgroundTransparency = 1, Text = song.artist or "Unknown", TextColor3 = C.textMuted,
			Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, item)

		local pb = make("TextButton", {
			Name = "PlayBtn", Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -62, 0.5, -13),
			BackgroundColor3 = currentAccent, TextColor3 = C.black, Text = "▶",
			Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0, AutoButtonColor = false,
		}, item)
		corner(RADIUS.pill, pb)
		THEME.registerBackendControl(pb)
		if currentAccent == C.youtube or currentAccent == C.apple then pb.TextColor3 = C.white end

		local upButton = make("TextButton", {
			Name = "MoveUpBtn", Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(1, -116, 0.5, -11),
			BackgroundColor3 = C.surfacePop, TextColor3 = C.textSec, Text = "↑",
			Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0,
			AutoButtonColor = false, Interactable = i > 1,
		}, item)
		corner(RADIUS.pill, upButton)
		upButton.TextTransparency = i > 1 and 0 or 0.65
		upButton.MouseButton1Click:Connect(function() moveSongInQueue(queueIndex, -1) end)

		local downButton = make("TextButton", {
			Name = "MoveDownBtn", Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(1, -90, 0.5, -11),
			BackgroundColor3 = C.surfacePop, TextColor3 = C.textSec, Text = "↓",
			Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0,
			AutoButtonColor = false, Interactable = i < #songQueue,
		}, item)
		corner(RADIUS.pill, downButton)
		downButton.TextTransparency = i < #songQueue and 0 or 0.65
		downButton.MouseButton1Click:Connect(function() moveSongInQueue(queueIndex, 1) end)

		pb.MouseButton1Click:Connect(function()
			if not THEME.requireBackend() then return end
			local s = songQueue[queueIndex]
			if not s then return end
			table.remove(songQueue, queueIndex)
			updateQueueUI()
			launchSong(s)
		end)

		local rb = make("TextButton", {
			Name = "RemoveBtn", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -32, 0.5, -12),
			BackgroundColor3 = C.surfacePop, TextColor3 = C.textMuted, Text = "✕",
			Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, AutoButtonColor = false,
		}, item)
		corner(RADIUS.pill, rb)
		THEME.registerBackendControl(rb)
		hover(rb, C.surfacePop, Color3.fromRGB(190, 50, 50), C.textMuted, C.white)
		rb.MouseButton1Click:Connect(function()
			if not THEME.requireBackend() then return end
			table.remove(songQueue, queueIndex)
			updateQueueUI()
			setStatus("Removed track from queue", C.warn)
		end)
	end
end

local function addToQueue(songData)
	table.insert(songQueue, songData)
	updateQueueUI()
end

btnClearQueue.MouseButton1Click:Connect(function()
	if not THEME.requireBackend() then return end
	songQueue = {}
	updateQueueUI()
	setStatus("Queue cleared", C.warn)
end)

local function toggleQueueDrawer()
	queueFrame.Visible = not queueFrame.Visible
	if queueFrame.Visible then syncQueuePosition() end
end

queueToggleBtn.MouseButton1Click:Connect(toggleQueueDrawer)
headerQueueBtn.MouseButton1Click:Connect(toggleQueueDrawer)
btnQueueTraffic.MouseButton1Click:Connect(toggleQueueDrawer)

function isPythonServerRunning()
	return testServerAddress(CONFIG.pythonServer)
end

THEME.setBackendAvailable = function(available)
	pythonRunning = available
	for index = #THEME.backendControls, 1, -1 do
		local control = THEME.backendControls[index]
		if control.instance.Parent then
			control.instance.Interactable = available
			control.instance.BackgroundTransparency = available
				and control.backgroundTransparency
				or math.max(control.backgroundTransparency, 0.4)
			if control.textTransparency ~= nil then
				control.instance.TextTransparency = available
					and control.textTransparency
					or math.max(control.textTransparency, 0.45)
			end
		else
			table.remove(THEME.backendControls, index)
		end
	end
end

THEME.registerBackendControl = function(instance)
	local textTransparency
	if instance:IsA("TextBox") or instance:IsA("TextButton") then
		textTransparency = instance.TextTransparency
	end
	table.insert(THEME.backendControls, {
		instance = instance,
		backgroundTransparency = instance.BackgroundTransparency,
		textTransparency = textTransparency,
	})
	instance.Interactable = pythonRunning
	if not pythonRunning then
		instance.BackgroundTransparency = math.max(instance.BackgroundTransparency, 0.4)
		if instance:IsA("TextBox") or instance:IsA("TextButton") then
			instance.TextTransparency = math.max(instance.TextTransparency, 0.45)
		end
	end
end

THEME.requireBackend = function()
	local available = isPythonServerRunning()
	THEME.setBackendAvailable(available)
	if not available then
		setStatus("Python offline  ·  Run: python spotify_server.py", C.error)
	end
	return available
end

for _, control in ipairs({
	playHeroButton, stopButton, skipButton, miniPlayBtn, miniSkipBtn, progTrack,
	loadButton, inputBox, btnClearQueue,
}) do
	THEME.registerBackendControl(control)
end

function playNextInQueue()
	if not THEME.requireBackend() then return end
	if #songQueue > 0 then
		local nextSong = table.remove(songQueue, 1)
		updateQueueUI()
		launchSong(nextSong)
	else
		isPlaying = false
		isPaused  = false
		playbackElapsed = 0
		setTransportUI("idle")
		setIdleUI()
		setStatus("Queue finished", C.success)
	end
end

function startPlaybackMonitor()
	if playbackMonitor then return end
	playbackMonitor = task.spawn(function()
		while isPlaying or isPaused do
			local ok, res = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.status) end)
			local sd
			local decoded = ok and res and pcall(function() sd = HttpService:JSONDecode(res) end)
			local st = decoded and type(sd) == "table" and sd.status or nil
			if st then
				local serverPosition = tonumber(sd.position)
				if serverPosition and not isScrubbing then playbackElapsed = serverPosition end
				local serverDuration = tonumber(sd.duration)
				if serverDuration and serverDuration > 0 and currentSongData then
					currentSongData.duration = serverDuration
					timeTotalLabel.Text = formatTime(serverDuration)
				end
				if serverPosition and not isScrubbing then
					timeElapsedLabel.Text = formatTime(serverPosition)
					local duration = getDuration()
					if duration then
						local fraction = math.clamp(serverPosition / duration, 0, 1)
						progFill.Size = UDim2.new(fraction, 0, 1, 0)
						miniFill.Size = UDim2.new(fraction, 0, 1, 0)
					end
				end
			end
			if st == "finished" then
				isPlaying = false
				isPaused  = false
				if #songQueue > 0 then
					task.wait(0.5)
					playbackMonitor = nil
					playNextInQueue()
					return
				else
					setTransportUI("idle")
					setIdleUI()
					setStatus("Finished playing", C.success)
				end
				break
			elseif st == "stopped" then
				isPlaying = false
				isPaused  = false
				setTransportUI("idle")
				setIdleUI()
				break
			end
			task.wait(1)
		end
		playbackMonitor = nil
	end)
end

local lastChatSentAt = 0
local function safeSendChat(msg)
	local now = tick()
	if now - lastChatSentAt < CONFIG.chatRateLimit then return end
	lastChatSentAt = now
	pcall(function()
		local sent = false
		if TextChatService then
			local tc = TextChatService:FindFirstChild("TextChannels")
			if tc then
				local ch = tc:FindFirstChild("RBXGeneral") or tc:FindFirstChildOfClass("TextChannel") or tc:GetChildren()[1]
				if ch and ch:IsA("TextChannel") then
					ch:SendAsync(msg)
					sent = true
				end
			end
		end
		if not sent then
			local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
			if ev and ev:FindFirstChild("SayMessageRequest") then
				ev.SayMessageRequest:FireServer(msg, "All")
				sent = true
			end
		end
		if not sent and player and player.Chat then
			pcall(function() player:Chat(msg) end)
		end
	end)
end

local function isPlayerWhitelisted(speaker, speakerPlayer)
	if not speaker and not speakerPlayer then return false end
	local sName = tostring(speaker or ""):lower():match("^%s*(.-)%s*$")

	if player then
		if speakerPlayer and speakerPlayer == player then return true end
		if sName == player.Name:lower() or sName == player.DisplayName:lower() then return true end
		if tonumber(speaker) and tonumber(speaker) == player.UserId then return true end
	end

	if not speakerPlayer and sName ~= "" then
		speakerPlayer = Players:FindFirstChild(sName)
		if not speakerPlayer and tonumber(speaker) then
			speakerPlayer = Players:GetPlayerByUserId(tonumber(speaker))
		end
		if not speakerPlayer then
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Name:lower() == sName or p.DisplayName:lower() == sName then
					speakerPlayer = p
					break
				end
			end
		end
	end

	if speakerPlayer and player and speakerPlayer == player then return true end

	for _, n in ipairs(CONFIG.whitelist) do
		local entry = tostring(n):lower():match("^%s*(.-)%s*$")
		if entry ~= "" then
			if sName == entry then return true end
			if speakerPlayer then
				if speakerPlayer.Name:lower() == entry then return true end
				if speakerPlayer.DisplayName:lower() == entry then return true end
				if tostring(speakerPlayer.UserId) == entry then return true end
			end
		end
	end
	return false
end

function playSong()
	if not THEME.requireBackend() then return end
	if not currentSongData then
		setStatus("No song loaded", C.error)
		return
	end
	if isPaused then
		isPaused  = false
		isPlaying = true
		setTransportUI("playing")
		setStatus("Resumed: " .. (currentSongData.title or ""), C.success)

		local ok = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.resume) end)
		if not ok then
			setStatus("Failed to resume", C.error)
			isPaused  = true
			isPlaying = false
			setTransportUI("paused")
		else
			startPlaybackMonitor()
		end
		return
	end

	isPlaying = true
	isPaused  = false
	playbackElapsed = 0
	setTransportUI("playing")
	setStatus("Playing: " .. (currentSongData.title or ""), C.success)

	local playUrl = CONFIG.pythonServer .. ENDPOINTS.play .. "?path=" .. HttpService:UrlEncode(currentSongData.path)
	local duration = tonumber(currentSongData.duration)
	if duration and duration > 0 then
		playUrl = playUrl .. "&duration=" .. HttpService:UrlEncode(tostring(duration))
	end
	local ok = pcall(function()
		return game:HttpGet(playUrl)
	end)
	if not ok then
		setStatus("Failed to play", C.error)
		isPlaying = false
		setTransportUI("error")
	else
		startPlaybackMonitor()
	end
end

function pauseSong()
	if not isPlaying or isPaused then return end
	if not THEME.requireBackend() then return end
	isPaused  = true
	isPlaying = false
	setTransportUI("paused")
	setStatus("Paused: " .. (currentSongData and currentSongData.title or ""), C.warn)

	local ok, response = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.pause) end)
	if not ok then
		setStatus("Failed to pause", C.error)
		isPaused  = false
		isPlaying = true
		setTransportUI("playing")
	else
		local decoded, data = pcall(function() return HttpService:JSONDecode(response) end)
		local pausedPosition = decoded and type(data) == "table" and tonumber(data.offset) or nil
		if pausedPosition then
			playbackElapsed = pausedPosition
			timeElapsedLabel.Text = formatTime(playbackElapsed)
			local duration = getDuration()
			if duration then
				local fraction = math.clamp(playbackElapsed / duration, 0, 1)
				progFill.Size = UDim2.new(fraction, 0, 1, 0)
				miniFill.Size = UDim2.new(fraction, 0, 1, 0)
			end
		end
	end
end

local function updateSeekPreview(screenX)
	local duration = getDuration()
	local width = progTrack.AbsoluteSize.X
	if not duration or width <= 0 then return end
	local fraction = math.clamp((screenX - progTrack.AbsolutePosition.X) / width, 0, 1)
	playbackElapsed = duration * fraction
	timeElapsedLabel.Text = formatTime(playbackElapsed)
	progFill.Size = UDim2.new(fraction, 0, 1, 0)
	miniFill.Size = UDim2.new(fraction, 0, 1, 0)
end

local function seekPlayback(position)
	if not (isPlaying or isPaused) then return end
	if not currentSongData or not getDuration() then
		setStatus("Seeking needs a known track duration", C.warn)
		return
	end
	if not THEME.requireBackend() then return end

	local requestedPosition = math.max(0, position)
	local ok, response = pcall(function()
		return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.seek .. "?position=" .. HttpService:UrlEncode(tostring(requestedPosition)))
	end)
	local data
	local decoded = ok and response and pcall(function()
		data = HttpService:JSONDecode(response)
	end)
	if not decoded or type(data) ~= "table" or data.status ~= "ok" then
		playbackElapsed = scrubOriginalPosition
		timeElapsedLabel.Text = formatTime(playbackElapsed)
		local duration = getDuration()
		if duration then
			local fraction = math.clamp(playbackElapsed / duration, 0, 1)
			progFill.Size = UDim2.new(fraction, 0, 1, 0)
			miniFill.Size = UDim2.new(fraction, 0, 1, 0)
		end
		setStatus((type(data) == "table" and data.error) or "Failed to seek", C.error)
		return
	end

	playbackElapsed = tonumber(data.position) or requestedPosition
	timeElapsedLabel.Text = formatTime(playbackElapsed)
	local duration = getDuration()
	if duration then
		local fraction = math.clamp(playbackElapsed / duration, 0, 1)
		progFill.Size = UDim2.new(fraction, 0, 1, 0)
		miniFill.Size = UDim2.new(fraction, 0, 1, 0)
	end
	setStatus("Seeked to " .. formatTime(playbackElapsed), C.success)
end

progTrack.InputBegan:Connect(function(input)
	local inputType = input.UserInputType
	if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then return end
	if not (isPlaying or isPaused) then return end
	if not currentSongData or not getDuration() then return end
	isScrubbing = true
	scrubInputType = inputType
	scrubOriginalPosition = playbackElapsed
	updateSeekPreview(input.Position.X)
end)

UserInputService.InputChanged:Connect(function(input)
	if not isScrubbing then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		updateSeekPreview(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not isScrubbing or input.UserInputType ~= scrubInputType then return end
	isScrubbing = false
	seekPlayback(playbackElapsed)
end)

function stopSong()
	if not THEME.requireBackend() then return end
	pcall(function() game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.stop) end)
	isScrubbing = false
	isPlaying       = false
	isPaused        = false
	playbackElapsed = 0
	currentSongData = nil
	setTransportUI("idle")
	setIdleUI()
	setStatus("Stopped playback", C.success)
end

function skipSong()
	if not THEME.requireBackend() then return end
	pcall(function() game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.stop) end)
	task.wait(0.2)
	if #songQueue > 0 then
		setStatus("Skipping to next...", C.success)
		playNextInQueue()
		pcall(function() safeSendChat("⏭ Skipped to next song.") end)
	else
		stopSong()
		pcall(function() safeSendChat("⏭ Skipped: queue empty.") end)
	end
end

function searchAndPlaySong(query)
	if not THEME.requireBackend() then return end
	setStatus("Searching: " .. query, C.warn)
	loadButton.Text = "Searching..."

	local ok, result = pcall(function()
		return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.search .. "?query=" .. HttpService:UrlEncode(query))
	end)
	loadButton.Text = "Load"

	if not ok or not result then
		setStatus("Search failed - check Python server", C.error)
		return
	end

	local sd
	local dok = pcall(function() sd = HttpService:JSONDecode(result) end)
	if not dok or not sd or sd.error then
		setStatus("Song not found", C.error)
		pcall(function() safeSendChat("Song not found!") end)
		return
	end

	if isPlaying then
		addToQueue(sd)
		setStatus("Added '" .. (sd.title or "Song") .. "' to queue (#" .. #songQueue .. ")", C.success)
		pcall(function() safeSendChat("Added " .. (sd.title or "Song") .. " to the queue.") end)
	else
		setNowPlaying(sd)
		setStatus("Found: " .. (sd.title or "Song") .. " — playing...", C.success)
		pcall(function() safeSendChat("Found the song! Playing Now...") end)
		task.wait(0.3)
		playSong()
	end
end

function callPythonBackend(rawInput)
	local text = tostring(rawInput or ""):match("^%s*(.-)%s*$") or ""
	if text == "" then
		setStatus("Please enter a link or song name", C.warn)
		return false
	end
	local isUrl = text:find("^https?://") or text:find("spotify%.com") or text:find("youtube%.com") or text:find("youtu%.be") or text:find("music%.apple%.com")

	if not isUrl then
		searchAndPlaySong(text)
		return true
	end
	if not THEME.requireBackend() then return false end

	local detectedMode = serviceMode
	if text:find("spotify%.com") then
		detectedMode = "spotify"
	elseif text:find("youtube%.com") or text:find("youtu%.be") then
		detectedMode = "youtube"
	elseif text:find("music%.apple%.com") then
		detectedMode = "apple"
	end

	if serviceMode == "auto" or detectedMode ~= serviceMode then
		switchServiceMode(detectedMode)
	end

	setStatus("Fetching audio from " .. detectedMode:upper() .. "...", C.warn)
	loadButton.Text = "Fetching..."

	local ep = ENDPOINTS.spotifyFetch .. "?link=" .. HttpService:UrlEncode(text)
	if detectedMode == "youtube" then
		ep = ENDPOINTS.youtubeFetch .. "?link=" .. HttpService:UrlEncode(text)
	elseif detectedMode == "apple" then
		ep = ENDPOINTS.appleFetch .. "?link=" .. HttpService:UrlEncode(text)
	end

	local ok, result = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ep) end)
	loadButton.Text = "Load"

	if ok and result then
		local sd
		local dok = pcall(function() sd = HttpService:JSONDecode(result) end)
		if dok and sd and not sd.error then
			if isPlaying then
				addToQueue(sd)
				setStatus((sd.title or "Song") .. " added to queue (#" .. #songQueue .. ")", C.success)
				pcall(function() safeSendChat("Added " .. (sd.title or "Song") .. " to the queue.") end)
			else
				setNowPlaying(sd)
				setTransportUI("idle")
				setStatus("Loaded: " .. (sd.title or "Song") .. " — press Play", C.success)
			end
			return true
		else
			local errMsg = (dok and sd and sd.error) or "Failed to load song from server"
			setStatus(tostring(errMsg), C.error)
			return false
		end
	else
		setStatus("Python server not responding", C.error)
		return false
	end
end

loadButton.MouseButton1Click:Connect(function() callPythonBackend(inputBox.Text) end)
inputBox.FocusLost:Connect(function(enter)
	if enter then callPythonBackend(inputBox.Text) end
end)

local function togglePlayPause()
	if isPlaying and not isPaused then pauseSong() else playSong() end
end
playHeroButton.MouseButton1Click:Connect(togglePlayPause)
miniPlayBtn.MouseButton1Click:Connect(togglePlayPause)

stopButton.MouseButton1Click:Connect(stopSong)
skipButton.MouseButton1Click:Connect(skipSong)
miniSkipBtn.MouseButton1Click:Connect(skipSong)

local processedMsgCache = {}

local function handleChatCommand(speaker, message, speakerPlayer)
	message = (message or ""):match("^%s*(.-)%s*$") or ""
	local lower = message:lower()

	local function notWL()
		local displayName = speakerPlayer and speakerPlayer.Name or speaker or "Unknown"
		setStatus("Blocked non-whitelisted command from " .. displayName, C.warn)
		pcall(function() safeSendChat("You are not whitelisted to use music commands!") end)
	end

	if lower:sub(1, 6) == "!play " or lower == "!play" then
		if not isPlayerWhitelisted(speaker, speakerPlayer) then notWL(); return end
		local query = (message:sub(7) or ""):match("^%s*(.-)%s*$") or ""
		if query ~= "" then
			pcall(function() safeSendChat("Finding " .. query .. "...") end)
			if query:find("^https?://") then
				callPythonBackend(query)
			else
				searchAndPlaySong(query)
			end
		else
			setStatus("Usage: !play [song name / link]", C.error)
			pcall(function() safeSendChat("Usage: !play [song name / link]") end)
		end
	elseif lower == "!stop" then
		if not isPlayerWhitelisted(speaker, speakerPlayer) then notWL(); return end
		stopSong()
		pcall(function() safeSendChat("⏹ Stopped playback.") end)
	elseif lower == "!pause" then
		if not isPlayerWhitelisted(speaker, speakerPlayer) then notWL(); return end
		pauseSong()
		pcall(function() safeSendChat("⏸ Paused playback.") end)
	elseif lower == "!resume" then
		if not isPlayerWhitelisted(speaker, speakerPlayer) then notWL(); return end
		if not isPaused then
			setStatus("Nothing is paused", C.error)
			pcall(function() safeSendChat("Nothing is paused.") end)
			return
		end
		playSong()
		pcall(function() safeSendChat("▶ Resumed playback.") end)
	elseif lower == "!skip" then
		if not isPlayerWhitelisted(speaker, speakerPlayer) then notWL(); return end
		skipSong()
	end
end

local function processIncomingChatMessage(speakerName, messageText, playerObj)
	messageText = tostring(messageText or ""):match("^%s*(.-)%s*$") or ""
	if messageText == "" then return end
	if messageText:sub(1, 1) ~= "!" then return end

	local dedupeKey = tostring(speakerName) .. ":" .. messageText .. ":" .. tostring(math.floor(tick() * 3))
	if processedMsgCache[dedupeKey] then return end
	processedMsgCache[dedupeKey] = true
	task.delay(1.5, function() processedMsgCache[dedupeKey] = nil end)

	handleChatCommand(speakerName, messageText, playerObj)
end

pcall(function()
	if TextChatService then
		TextChatService.MessageReceived:Connect(function(textMsg)
			if not textMsg then return end
			local senderObj = nil
			if textMsg.TextSource then
				senderObj = Players:GetPlayerByUserId(textMsg.TextSource.UserId)
			end
			local sName = senderObj and senderObj.Name or (textMsg.TextSource and tostring(textMsg.TextSource.UserId)) or ""
			processIncomingChatMessage(sName, textMsg.Text, senderObj)
		end)
	end
end)

pcall(function()
	if TextChatService then
		local function hookChannel(ch)
			if ch:IsA("TextChannel") then
				ch.MessageReceived:Connect(function(textMsg)
					if not textMsg then return end
					local senderObj = nil
					if textMsg.TextSource then
						senderObj = Players:GetPlayerByUserId(textMsg.TextSource.UserId)
					end
					local sName = senderObj and senderObj.Name or (textMsg.TextSource and tostring(textMsg.TextSource.UserId)) or ""
					processIncomingChatMessage(sName, textMsg.Text, senderObj)
				end)
			end
		end

		local tc = TextChatService:FindFirstChild("TextChannels")
		if tc then
			for _, ch in ipairs(tc:GetChildren()) do hookChannel(ch) end
			tc.ChildAdded:Connect(hookChannel)
		end
	end
end)

pcall(function()
	if TextChatService then
		local oldCallback = TextChatService.OnIncomingMessage
		TextChatService.OnIncomingMessage = function(textMsg)
			if textMsg and textMsg.Text and textMsg.TextSource then
				task.spawn(function()
					local senderObj = Players:GetPlayerByUserId(textMsg.TextSource.UserId)
					local sName = senderObj and senderObj.Name or tostring(textMsg.TextSource.UserId)
					processIncomingChatMessage(sName, textMsg.Text, senderObj)
				end)
			end
			if oldCallback then
				return oldCallback(textMsg)
			end
		end
	end
end)

local function hookPlayerChat(p)
	p.Chatted:Connect(function(msg)
		processIncomingChatMessage(p.Name, msg, p)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	pcall(hookPlayerChat, p)
end
Players.PlayerAdded:Connect(function(p)
	pcall(hookPlayerChat, p)
end)

pcall(function()
	local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
	if chatEvents then
		local onMsg = chatEvents:FindFirstChild("OnMessageDoneFiltering")
		if onMsg and onMsg:IsA("RemoteEvent") then
			onMsg.OnClientEvent:Connect(function(data)
				if data and type(data) == "table" then
					local sName = data.FromSpeaker or ""
					local mText = data.Message or ""
					if sName ~= "" and mText ~= "" then
						local senderObj = Players:FindFirstChild(sName)
						processIncomingChatMessage(sName, mText, senderObj)
					end
				end
			end)
		end
	end
end)

applyAccent(C.spotify)
setTransportUI("idle")
updateQueueUI()
popIn()

task.spawn(function()
	while true do
		local available = isPythonServerRunning()
		local stateChanged = available ~= pythonRunning or not THEME.backendStatusInitialized
		THEME.setBackendAvailable(available)
		if stateChanged then
			if available then
				setStatus("Ready  ·  Python server connected", C.success)
			else
				setStatus("Python offline  ·  Run: python spotify_server.py", C.error)
			end
		end
		THEME.backendStatusInitialized = true
		task.wait(3)
	end
end)

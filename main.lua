--[[
    🎵 Roblox Voice Chat Music Bot v3.5
    Created by: borthdayzz (boggle.cc)
]]

if not game:GetService("GuiService") then
	print("Error: Not running in Roblox environment")
	return
end

local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local CONFIG = {
	whitelist     = {"omgyesssw"},
	pythonServer  = "http://localhost:5000",
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
}

-- ─────────────────────────────────────────────
--  THEME & STYLING
-- ─────────────────────────────────────────────
local C = {
	bg          = Color3.fromRGB(12, 13, 17),
	surface     = Color3.fromRGB(18, 20, 26),
	surfaceHigh = Color3.fromRGB(24, 27, 36),
	surfacePop  = Color3.fromRGB(33, 37, 50),
	surfaceHover= Color3.fromRGB(42, 47, 64),
	border      = Color3.fromRGB(52, 58, 76),
	borderSub   = Color3.fromRGB(38, 42, 56),
	textPrimary = Color3.fromRGB(245, 246, 250),
	textSec     = Color3.fromRGB(162, 168, 185),
	textMuted   = Color3.fromRGB(105, 112, 132),
	spotify     = Color3.fromRGB(30, 215, 96),
	spotifyDim  = Color3.fromRGB(20, 160, 70),
	youtube     = Color3.fromRGB(255, 62, 62),
	apple       = Color3.fromRGB(250, 45, 72),
	cyan        = Color3.fromRGB(0, 210, 255),
	discord     = Color3.fromRGB(88, 101, 242),
	warn        = Color3.fromRGB(255, 195, 45),
	error       = Color3.fromRGB(245, 75, 75),
	success     = Color3.fromRGB(30, 215, 96),
	white       = Color3.fromRGB(255, 255, 255),
	black       = Color3.fromRGB(0, 0, 0),
}

local currentAccent = C.spotify

local RADIUS = {
	window = UDim.new(0, 16),
	card   = UDim.new(0, 12),
	btn    = UDim.new(0, 8),
	pill   = UDim.new(0, 999),
	input  = UDim.new(0, 8),
}

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────
local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(r, parent)
	return make("UICorner", {CornerRadius = r}, parent)
end

local function stroke(color, thick, trans, parent)
	return make("UIStroke", {Color=color, Thickness=thick or 1, Transparency=trans or 0, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, parent)
end

local function gradient(c0, c1, rot, parent)
	return make("UIGradient", {
		Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,c0), ColorSequenceKeypoint.new(1,c1)},
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

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", mins, secs)
end

-- ScreenGui Parent Container Safe Resolution
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
	Name         = "SpotifyMusicBot",
	ResetOnSpawn = false,
	DisplayOrder = 15,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parentGui)

-- ─────────────────────────────────────────────
--  STATE VARIABLES
-- ─────────────────────────────────────────────
local currentSongData   = nil
local pythonRunning     = false
local songQueue         = {}
local isPlaying         = false
local isPaused          = false
local playbackMonitor   = nil
local serviceMode       = "spotify" -- "spotify" | "youtube" | "apple" | "auto"
local playbackElapsed   = 0
local playbackStartTime = 0
local isMiniMode        = false
local isGuiVisible      = true

-- Forward declarations of functions
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

-- ─────────────────────────────────────────────
--  MAIN WINDOW (560 x 380)
-- ─────────────────────────────────────────────
local WIN_W, WIN_H = 560, 380
local QUEUE_W = 280

local shadowFrame = make("Frame", {
	Name             = "ShadowFrame",
	Size             = UDim2.new(0, WIN_W + 16, 0, WIN_H + 16),
	Position         = UDim2.new(0.5, -(WIN_W + 16)/2, 0.5, -(WIN_H + 16)/2),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.65,
	BorderSizePixel  = 0,
}, screenGui)
corner(UDim.new(0, 20), shadowFrame)

local mainFrame = make("Frame", {
	Name             = "MainFrame",
	Size             = UDim2.new(0, WIN_W, 0, WIN_H),
	Position         = UDim2.new(0, 8, 0, 8),
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
	ClipsDescendants = false,
}, shadowFrame)
corner(RADIUS.window, mainFrame)
local mainStroke = stroke(C.border, 1.2, 0.45, mainFrame)
gradient(Color3.fromRGB(25, 28, 38), Color3.fromRGB(15, 17, 23), 135, mainFrame)

local topAccent = make("Frame", {
	Name             = "TopAccent",
	Size             = UDim2.new(1, 0, 0, 3),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = C.spotify,
	BorderSizePixel  = 0,
	ZIndex           = 10,
}, mainFrame)
corner(UDim.new(0, 3), topAccent)
local topAccentGrad = gradient(C.spotify, Color3.fromRGB(20, 160, 70), 0, topAccent)

-- ─────────────────────────────────────────────
--  HEADER
-- ─────────────────────────────────────────────
local header = make("Frame", {
	Name             = "Header",
	Size             = UDim2.new(1, 0, 0, 52),
	Position         = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, mainFrame)
corner(UDim.new(0, 14), header)
make("Frame", {
	Size             = UDim2.new(1, 0, 0.5, 0),
	Position         = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, header)
stroke(C.borderSub, 1, 0.6, header)

local trafficControls = make("Frame", {
	Size             = UDim2.new(0, 68, 0, 20),
	Position         = UDim2.new(0, 14, 0.5, -10),
	BackgroundTransparency = 1,
}, header)
local trafficLayout = make("UIListLayout", {
	FillDirection    = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment   = Enum.VerticalAlignment.Center,
	Padding          = UDim.new(0, 8),
}, trafficControls)

local btnClose = make("TextButton", {
	Name             = "BtnClose",
	Size             = UDim2.new(0, 13, 0, 13),
	BackgroundColor3 = Color3.fromRGB(255, 95, 88),
	Text             = "",
	BorderSizePixel  = 0,
	AutoButtonColor  = false,
}, trafficControls)
corner(RADIUS.pill, btnClose)
local closeIcon = make("TextLabel", {
	Size             = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text             = "✕",
	TextColor3       = Color3.fromRGB(100, 10, 10),
	Font             = Enum.Font.GothamBold,
	TextSize         = 8,
	Visible          = false,
}, btnClose)

local btnMini = make("TextButton", {
	Name             = "BtnMini",
	Size             = UDim2.new(0, 13, 0, 13),
	BackgroundColor3 = Color3.fromRGB(255, 189, 46),
	Text             = "",
	BorderSizePixel  = 0,
	AutoButtonColor  = false,
}, trafficControls)
corner(RADIUS.pill, btnMini)
local miniIcon = make("TextLabel", {
	Size             = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text             = "−",
	TextColor3       = Color3.fromRGB(120, 70, 0),
	Font             = Enum.Font.GothamBold,
	TextSize         = 10,
	Visible          = false,
}, btnMini)

local btnQueueTraffic = make("TextButton", {
	Name             = "BtnQueueTraffic",
	Size             = UDim2.new(0, 13, 0, 13),
	BackgroundColor3 = Color3.fromRGB(39, 201, 63),
	Text             = "",
	BorderSizePixel  = 0,
	AutoButtonColor  = false,
}, trafficControls)
corner(RADIUS.pill, btnQueueTraffic)
local queueIcon = make("TextLabel", {
	Size             = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text             = "≡",
	TextColor3       = Color3.fromRGB(10, 80, 20),
	Font             = Enum.Font.GothamBold,
	TextSize         = 9,
	Visible          = false,
}, btnQueueTraffic)

trafficControls.MouseEnter:Connect(function()
	closeIcon.Visible = true
	miniIcon.Visible = true
	queueIcon.Visible = true
end)
trafficControls.MouseLeave:Connect(function()
	closeIcon.Visible = false
	miniIcon.Visible = false
	queueIcon.Visible = false
end)

local titleContainer = make("Frame", {
	Size             = UDim2.new(0, 175, 0, 36),
	Position         = UDim2.new(0, 88, 0.5, -18),
	BackgroundTransparency = 1,
}, header)

local headerTitle = make("TextLabel", {
	Name             = "HeaderTitle",
	Size             = UDim2.new(1, 0, 0, 20),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	Text             = "Roblox VC Player",
	TextColor3       = C.textPrimary,
	Font             = Enum.Font.GothamBold,
	TextSize         = 14,
	TextXAlignment   = Enum.TextXAlignment.Left,
}, titleContainer)

local headerSub = make("TextLabel", {
	Name             = "HeaderSub",
	Size             = UDim2.new(1, 0, 0, 14),
	Position         = UDim2.new(0, 0, 0, 20),
	BackgroundTransparency = 1,
	Text             = "v3.5  ·  spotify passthrough",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Left,
}, titleContainer)

local modeTabs = make("Frame", {
	Name             = "ModeTabs",
	Size             = UDim2.new(0, 240, 0, 28),
	Position         = UDim2.new(1, -78 - 240, 0.5, -14),
	BackgroundColor3 = C.surfaceHigh,
	BorderSizePixel  = 0,
}, header)
corner(RADIUS.pill, modeTabs)
stroke(C.borderSub, 1, 0.3, modeTabs)

local tabLayout = make("UIListLayout", {
	FillDirection    = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment   = Enum.VerticalAlignment.Center,
	Padding          = UDim.new(0, 2),
}, modeTabs)

local function makeTab(name, label, color)
	local tab = make("TextButton", {
		Name             = "Tab_" .. name,
		Size             = UDim2.new(0, 56, 1, -4),
		BackgroundColor3 = (serviceMode == name) and color or Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = (serviceMode == name) and 0 or 1,
		TextColor3       = (serviceMode == name) and ((name == "spotify") and C.black or C.white) or C.textMuted,
		Text             = label,
		Font             = Enum.Font.GothamBold,
		TextSize         = 10,
		BorderSizePixel  = 0,
		AutoButtonColor  = false,
	}, modeTabs)
	corner(RADIUS.pill, tab)
	return tab
end

local tabSpotify = makeTab("spotify", "Spotify", C.spotify)
local tabYouTube = makeTab("youtube", "YouTube", C.youtube)
local tabApple   = makeTab("apple",   "Apple",   C.apple)
local tabAuto    = makeTab("auto",    "Auto",    C.cyan)

local creditsButton = make("TextButton", {
	Name             = "CreditsButton",
	Size             = UDim2.new(0, 28, 0, 28),
	Position         = UDim2.new(1, -66, 0.5, -14),
	BackgroundColor3 = C.surfaceHigh,
	TextColor3       = C.textSec,
	Text             = "ℹ",
	Font             = Enum.Font.GothamBold,
	TextSize         = 13,
	BorderSizePixel  = 0,
}, header)
corner(RADIUS.btn, creditsButton)
stroke(C.borderSub, 1, 0.4, creditsButton)
creditsButton.MouseEnter:Connect(function()
	tween(creditsButton, {BackgroundColor3 = C.surfacePop, TextColor3 = C.white}, 0.12)
end)
creditsButton.MouseLeave:Connect(function()
	tween(creditsButton, {BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec}, 0.12)
end)

local headerQueueBtn = make("TextButton", {
	Name             = "HeaderQueueBtn",
	Size             = UDim2.new(0, 28, 0, 28),
	Position         = UDim2.new(1, -34, 0.5, -14),
	BackgroundColor3 = C.surfaceHigh,
	TextColor3       = C.textSec,
	Text             = "≡",
	Font             = Enum.Font.GothamBold,
	TextSize         = 14,
	BorderSizePixel  = 0,
}, header)
corner(RADIUS.btn, headerQueueBtn)
stroke(C.borderSub, 1, 0.4, headerQueueBtn)
headerQueueBtn.MouseEnter:Connect(function()
	tween(headerQueueBtn, {BackgroundColor3 = C.surfacePop, TextColor3 = C.white}, 0.12)
end)
headerQueueBtn.MouseLeave:Connect(function()
	tween(headerQueueBtn, {BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec}, 0.12)
end)

-- ─────────────────────────────────────────────
--  BODY CONTAINER
-- ─────────────────────────────────────────────
local body = make("Frame", {
	Name                   = "Body",
	Size                   = UDim2.new(1, -28, 1, -64),
	Position               = UDim2.new(0, 14, 0, 58),
	BackgroundTransparency = 1,
}, mainFrame)

-- ── NOW PLAYING CARD ──────────────────────────
local npCard = make("Frame", {
	Name             = "NowPlayingCard",
	Size             = UDim2.new(1, 0, 0, 114),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = C.surfaceHigh,
	BorderSizePixel  = 0,
}, body)
corner(RADIUS.card, npCard)
stroke(C.borderSub, 1, 0.35, npCard)
gradient(Color3.fromRGB(28, 32, 44), Color3.fromRGB(20, 22, 30), 135, npCard)

local artContainer = make("Frame", {
	Name             = "ArtContainer",
	Size             = UDim2.new(0, 92, 0, 92),
	Position         = UDim2.new(0, 11, 0.5, -46),
	BackgroundColor3 = C.surfacePop,
	BorderSizePixel  = 0,
}, npCard)
corner(UDim.new(0, 10), artContainer)
stroke(C.border, 1, 0.5, artContainer)

local albumArt = make("ImageLabel", {
	Name             = "AlbumArt",
	Size             = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = C.surfacePop,
	BorderSizePixel  = 0,
	Image            = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png",
	ScaleType        = Enum.ScaleType.Crop,
	ImageColor3      = C.textMuted,
}, artContainer)
corner(UDim.new(0, 10), albumArt)
local albumArtGradient = gradient(Color3.fromRGB(48, 52, 68), Color3.fromRGB(24, 26, 34), 135, albumArt)

local visualizer = make("Frame", {
	Name                   = "Visualizer",
	Size                   = UDim2.new(0, 26, 0, 18),
	Position               = UDim2.new(1, -38, 0, 12),
	BackgroundTransparency = 1,
}, npCard)
local eqBars = {}
for i = 1, 5 do
	local bar = make("Frame", {
		Name             = "Bar_" .. i,
		Size             = UDim2.new(0, 3, 0, 4),
		Position         = UDim2.new(0, (i - 1) * 5, 1, -4),
		BackgroundColor3 = C.spotify,
		BorderSizePixel  = 0,
	}, visualizer)
	corner(RADIUS.pill, bar)
	table.insert(eqBars, bar)
end

local statusPill = make("Frame", {
	Name             = "StatusPill",
	Size             = UDim2.new(0, 72, 0, 18),
	Position         = UDim2.new(0, 116, 0, 12),
	BackgroundColor3 = C.surfacePop,
	BorderSizePixel  = 0,
}, npCard)
corner(RADIUS.pill, statusPill)
stroke(C.borderSub, 1, 0.4, statusPill)

local statusPillText = make("TextLabel", {
	Size             = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text             = "IDLE",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.GothamBold,
	TextSize         = 9,
	TextXAlignment   = Enum.TextXAlignment.Center,
}, statusPill)

local songTitle = make("TextLabel", {
	Name             = "SongTitle",
	Size             = UDim2.new(1, -165, 0, 24),
	Position         = UDim2.new(0, 116, 0, 34),
	BackgroundTransparency = 1,
	Text             = "No song loaded",
	TextColor3       = C.textPrimary,
	Font             = Enum.Font.GothamBold,
	TextSize         = 15,
	TextXAlignment   = Enum.TextXAlignment.Left,
	TextTruncate     = Enum.TextTruncate.AtEnd,
}, npCard)

local songArtist = make("TextLabel", {
	Name             = "SongArtist",
	Size             = UDim2.new(1, -165, 0, 18),
	Position         = UDim2.new(0, 116, 0, 58),
	BackgroundTransparency = 1,
	Text             = "Paste a link or search below to play",
	TextColor3       = C.textSec,
	Font             = Enum.Font.Gotham,
	TextSize         = 11,
	TextXAlignment   = Enum.TextXAlignment.Left,
	TextTruncate     = Enum.TextTruncate.AtEnd,
}, npCard)

local timeElapsedLabel = make("TextLabel", {
	Name             = "TimeElapsed",
	Size             = UDim2.new(0, 50, 0, 14),
	Position         = UDim2.new(0, 116, 0, 80),
	BackgroundTransparency = 1,
	Text             = "00:00",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Left,
}, npCard)

local timeTotalLabel = make("TextLabel", {
	Name             = "TimeTotal",
	Size             = UDim2.new(0, 50, 0, 14),
	Position         = UDim2.new(1, -64, 0, 80),
	BackgroundTransparency = 1,
	Text             = "--:--",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Right,
}, npCard)

local progTrack = make("Frame", {
	Name             = "ProgressTrack",
	Size             = UDim2.new(1, -130, 0, 4),
	Position         = UDim2.new(0, 116, 0, 97),
	BackgroundColor3 = C.surfacePop,
	BorderSizePixel  = 0,
}, npCard)
corner(RADIUS.pill, progTrack)

local progFill = make("Frame", {
	Name             = "ProgressFill",
	Size             = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = C.spotify,
	BorderSizePixel  = 0,
}, progTrack)
corner(RADIUS.pill, progFill)

-- ── UNIFIED INPUT / SEARCH ROW ────────────────
local inputRow = make("Frame", {
	Name                   = "InputRow",
	Size                   = UDim2.new(1, 0, 0, 38),
	Position               = UDim2.new(0, 0, 0, 124),
	BackgroundTransparency = 1,
}, body)

local inputContainer = make("Frame", {
	Name             = "InputContainer",
	Size             = UDim2.new(1, -100, 1, 0),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = C.surfaceHigh,
	BorderSizePixel  = 0,
}, inputRow)
corner(RADIUS.input, inputContainer)
local inputStroke = stroke(C.borderSub, 1, 0.4, inputContainer)

local inputIcon = make("TextLabel", {
	Size             = UDim2.new(0, 28, 1, 0),
	Position         = UDim2.new(0, 6, 0, 0),
	BackgroundTransparency = 1,
	Text             = "🔍",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 11,
	TextXAlignment   = Enum.TextXAlignment.Center,
}, inputContainer)

local inputBox = make("TextBox", {
	Name             = "InputBox",
	Size             = UDim2.new(1, -64, 1, 0),
	Position         = UDim2.new(0, 34, 0, 0),
	BackgroundTransparency = 1,
	TextColor3       = C.textPrimary,
	PlaceholderColor3= C.textMuted,
	Text             = "",
	PlaceholderText  = "Paste link (Spotify, YouTube, Apple) or type song title...",
	TextSize         = 11,
	Font             = Enum.Font.Gotham,
	BorderSizePixel  = 0,
	ClearTextOnFocus = false,
	TextXAlignment   = Enum.TextXAlignment.Left,
}, inputContainer)

local btnClearInput = make("TextButton", {
	Name             = "BtnClearInput",
	Size             = UDim2.new(0, 20, 0, 20),
	Position         = UDim2.new(1, -26, 0.5, -10),
	BackgroundColor3 = C.surfacePop,
	TextColor3       = C.textSec,
	Text             = "✕",
	Font             = Enum.Font.GothamBold,
	TextSize         = 9,
	BorderSizePixel  = 0,
	Visible          = false,
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
	tween(inputContainer, {BackgroundColor3 = C.surfacePop}, 0.15)
	tween(inputStroke, {Color = currentAccent, Transparency = 0.2}, 0.15)
end)
inputBox.FocusLost:Connect(function()
	tween(inputContainer, {BackgroundColor3 = C.surfaceHigh}, 0.15)
	tween(inputStroke, {Color = C.borderSub, Transparency = 0.4}, 0.15)
end)

local loadButton = make("TextButton", {
	Name             = "LoadButton",
	Size             = UDim2.new(0, 92, 1, 0),
	Position         = UDim2.new(1, -92, 0, 0),
	BackgroundColor3 = currentAccent,
	TextColor3       = C.black,
	Text             = "Load",
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	BorderSizePixel  = 0,
}, inputRow)
corner(RADIUS.input, loadButton)

loadButton.MouseEnter:Connect(function()
	tween(loadButton, {BackgroundTransparency = 0.15}, 0.12)
end)
loadButton.MouseLeave:Connect(function()
	tween(loadButton, {BackgroundTransparency = 0}, 0.12)
end)

-- ── PLAYBACK CONTROLS ROW ─────────────────────
local ctrlRow = make("Frame", {
	Name                   = "ControlsRow",
	Size                   = UDim2.new(1, 0, 0, 44),
	Position               = UDim2.new(0, 0, 0, 172),
	BackgroundTransparency = 1,
}, body)

local ctrlLayout = make("UIListLayout", {
	FillDirection          = Enum.FillDirection.Horizontal,
	HorizontalAlignment    = Enum.HorizontalAlignment.Center,
	VerticalAlignment      = Enum.VerticalAlignment.Center,
	Padding                = UDim.new(0, 10),
}, ctrlRow)

local function makeButton(name, text, w, bg, fg, fontSize)
	local b = make("TextButton", {
		Name             = name,
		Size             = UDim2.new(0, w, 0, 38),
		BackgroundColor3 = bg,
		TextColor3       = fg or C.textPrimary,
		Text             = text,
		Font             = Enum.Font.GothamBold,
		TextSize         = fontSize or 12,
		BorderSizePixel  = 0,
		AutoButtonColor  = false,
	}, ctrlRow)
	corner(RADIUS.btn, b)
	stroke(C.borderSub, 1, 0.4, b)

	b.MouseEnter:Connect(function()
		tween(b, {BackgroundTransparency = 0.2}, 0.1)
	end)
	b.MouseLeave:Connect(function()
		tween(b, {BackgroundTransparency = 0}, 0.1)
	end)
	return b
end

local stopButton = makeButton("StopButton", "⏹  Stop", 76, C.surfaceHigh, C.textSec)

local playHeroButton = make("TextButton", {
	Name             = "PlayHeroButton",
	Size             = UDim2.new(0, 140, 0, 42),
	BackgroundColor3 = currentAccent,
	TextColor3       = C.black,
	Text             = "▶  Play",
	Font             = Enum.Font.GothamBold,
	TextSize         = 13,
	BorderSizePixel  = 0,
	AutoButtonColor  = false,
}, ctrlRow)
corner(RADIUS.btn, playHeroButton)
playHeroButton.MouseEnter:Connect(function()
	tween(playHeroButton, {BackgroundTransparency = 0.15}, 0.1)
end)
playHeroButton.MouseLeave:Connect(function()
	tween(playHeroButton, {BackgroundTransparency = 0}, 0.1)
end)

local skipButton = makeButton("SkipButton", "⏭  Skip", 76, C.surfaceHigh, C.textSec)

local queueToggleBtn = make("TextButton", {
	Name             = "QueueToggleBtn",
	Size             = UDim2.new(0, 110, 0, 38),
	BackgroundColor3 = C.surfaceHigh,
	TextColor3       = C.textSec,
	Text             = "≡  Queue (0)",
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	BorderSizePixel  = 0,
	AutoButtonColor  = false,
}, ctrlRow)
corner(RADIUS.btn, queueToggleBtn)
stroke(C.borderSub, 1, 0.4, queueToggleBtn)

queueToggleBtn.MouseEnter:Connect(function()
	tween(queueToggleBtn, {BackgroundColor3 = C.surfacePop, TextColor3 = C.white}, 0.1)
end)
queueToggleBtn.MouseLeave:Connect(function()
	tween(queueToggleBtn, {BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec}, 0.1)
end)

-- ── STATUS BAR ────────────────────────────────
local statusBar = make("Frame", {
	Name             = "StatusBar",
	Size             = UDim2.new(1, 0, 0, 30),
	Position         = UDim2.new(0, 0, 0, 226),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, body)
corner(RADIUS.card, statusBar)
stroke(C.borderSub, 1, 0.45, statusBar)

local statusDot = make("Frame", {
	Name             = "StatusDot",
	Size             = UDim2.new(0, 8, 0, 8),
	Position         = UDim2.new(0, 12, 0.5, -4),
	BackgroundColor3 = C.success,
	BorderSizePixel  = 0,
}, statusBar)
corner(RADIUS.pill, statusDot)

local statusLabel = make("TextLabel", {
	Name                   = "StatusLabel",
	Size                   = UDim2.new(1, -180, 1, 0),
	Position               = UDim2.new(0, 28, 0, 0),
	BackgroundTransparency = 1,
	Text                   = "Connecting to server...",
	TextColor3             = C.textSec,
	Font                   = Enum.Font.Gotham,
	TextSize               = 11,
	TextXAlignment         = Enum.TextXAlignment.Left,
	TextTruncate           = Enum.TextTruncate.AtEnd,
}, statusBar)

local keybindTip = make("TextLabel", {
	Name                   = "KeybindTip",
	Size                   = UDim2.new(0, 140, 1, 0),
	Position               = UDim2.new(1, -148, 0, 0),
	BackgroundTransparency = 1,
	Text                   = "[R-Shift] Hide/Show",
	TextColor3             = C.textMuted,
	Font                   = Enum.Font.Gotham,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Right,
}, statusBar)

-- ─────────────────────────────────────────────
--  DOCKED QUEUE DRAWER (280 x 380)
-- ─────────────────────────────────────────────
local queueFrame = make("Frame", {
	Name             = "QueueFrame",
	Size             = UDim2.new(0, QUEUE_W, 0, WIN_H),
	Position         = UDim2.new(0, shadowFrame.Position.X.Offset + WIN_W + 22, 0, shadowFrame.Position.Y.Offset + 8),
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
	Visible          = false,
}, screenGui)
corner(RADIUS.window, queueFrame)
stroke(C.border, 1.2, 0.45, queueFrame)
gradient(Color3.fromRGB(24, 27, 36), Color3.fromRGB(16, 18, 24), 135, queueFrame)

local qAccent = make("Frame", {
	Size             = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = C.spotify,
	BorderSizePixel  = 0,
}, queueFrame)
corner(UDim.new(0, 3), qAccent)

local qHdr = make("Frame", {
	Name             = "QueueHeader",
	Size             = UDim2.new(1, 0, 0, 48),
	Position         = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, queueFrame)
corner(UDim.new(0, 14), qHdr)
make("Frame", {
	Size             = UDim2.new(1, 0, 0.5, 0),
	Position         = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, qHdr)

local qTitle = make("TextLabel", {
	Size             = UDim2.new(0, 120, 1, 0),
	Position         = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency = 1,
	Text             = "Play Queue",
	TextColor3       = C.textPrimary,
	Font             = Enum.Font.GothamBold,
	TextSize         = 14,
	TextXAlignment   = Enum.TextXAlignment.Left,
}, qHdr)

local btnClearQueue = make("TextButton", {
	Name             = "BtnClearQueue",
	Size             = UDim2.new(0, 64, 0, 24),
	Position         = UDim2.new(1, -78, 0.5, -12),
	BackgroundColor3 = C.surfaceHigh,
	TextColor3       = C.textSec,
	Text             = "Clear",
	Font             = Enum.Font.GothamBold,
	TextSize         = 10,
	BorderSizePixel  = 0,
}, qHdr)
corner(RADIUS.btn, btnClearQueue)
stroke(C.borderSub, 1, 0.3, btnClearQueue)
btnClearQueue.MouseEnter:Connect(function()
	tween(btnClearQueue, {BackgroundColor3 = Color3.fromRGB(190, 50, 50), TextColor3 = C.white}, 0.1)
end)
btnClearQueue.MouseLeave:Connect(function()
	tween(btnClearQueue, {BackgroundColor3 = C.surfaceHigh, TextColor3 = C.textSec}, 0.1)
end)

local queueList = make("ScrollingFrame", {
	Name                   = "QueueList",
	Size                   = UDim2.new(1, -16, 1, -60),
	Position               = UDim2.new(0, 8, 0, 54),
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	ScrollBarThickness     = 4,
	ScrollBarImageColor3   = C.border,
	CanvasSize             = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize    = Enum.AutomaticSize.Y,
}, queueFrame)

local queueLayout = make("UIListLayout", {
	Padding                = UDim.new(0, 6),
	SortOrder              = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment    = Enum.HorizontalAlignment.Center,
}, queueList)

local emptyQueueLabel = make("TextLabel", {
	Name                   = "EmptyQueueLabel",
	Size                   = UDim2.new(1, -20, 0, 100),
	Position               = UDim2.new(0, 10, 0, 40),
	BackgroundTransparency = 1,
	Text                   = "Queue is empty\nPaste links or search songs to add!",
	TextColor3             = C.textMuted,
	Font                   = Enum.Font.Gotham,
	TextSize               = 11,
	TextWrapped            = true,
	Visible                = true,
}, queueFrame)

-- ─────────────────────────────────────────────
--  MINI-PLAYER (340 x 52)
-- ─────────────────────────────────────────────
local miniFrame = make("Frame", {
	Name             = "MiniPlayer",
	Size             = UDim2.new(0, 340, 0, 52),
	Position         = UDim2.new(1, -360, 1, -72),
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
	Visible          = false,
}, screenGui)
corner(UDim.new(0, 14), miniFrame)
stroke(C.border, 1.2, 0.45, miniFrame)
gradient(Color3.fromRGB(24, 27, 36), Color3.fromRGB(15, 17, 23), 135, miniFrame)

local miniAccent = make("Frame", {
	Size             = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = C.spotify,
	BorderSizePixel  = 0,
}, miniFrame)
corner(UDim.new(0, 2), miniAccent)

local miniArt = make("ImageLabel", {
	Name             = "MiniArt",
	Size             = UDim2.new(0, 38, 0, 38),
	Position         = UDim2.new(0, 8, 0.5, -19),
	BackgroundColor3 = C.surfaceHigh,
	BorderSizePixel  = 0,
	Image            = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png",
	ScaleType        = Enum.ScaleType.Crop,
	ImageColor3      = C.textMuted,
}, miniFrame)
corner(UDim.new(0, 6), miniArt)

local miniTitle = make("TextLabel", {
	Name             = "MiniTitle",
	Size             = UDim2.new(1, -170, 0, 18),
	Position         = UDim2.new(0, 54, 0, 8),
	BackgroundTransparency = 1,
	Text             = "No song loaded",
	TextColor3       = C.textPrimary,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	TextXAlignment   = Enum.TextXAlignment.Left,
	TextTruncate     = Enum.TextTruncate.AtEnd,
}, miniFrame)

local miniArtist = make("TextLabel", {
	Name             = "MiniArtist",
	Size             = UDim2.new(1, -170, 0, 14),
	Position         = UDim2.new(0, 54, 0, 28),
	BackgroundTransparency = 1,
	Text             = "Idle",
	TextColor3       = C.textSec,
	Font             = Enum.Font.Gotham,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Left,
	TextTruncate     = Enum.TextTruncate.AtEnd,
}, miniFrame)

local miniPlayBtn = make("TextButton", {
	Name             = "MiniPlayBtn",
	Size             = UDim2.new(0, 30, 0, 30),
	Position         = UDim2.new(1, -98, 0.5, -15),
	BackgroundColor3 = C.spotify,
	TextColor3       = C.black,
	Text             = "▶",
	Font             = Enum.Font.GothamBold,
	TextSize         = 11,
	BorderSizePixel  = 0,
}, miniFrame)
corner(RADIUS.pill, miniPlayBtn)

local miniSkipBtn = make("TextButton", {
	Name             = "MiniSkipBtn",
	Size             = UDim2.new(0, 28, 0, 28),
	Position         = UDim2.new(1, -62, 0.5, -14),
	BackgroundColor3 = C.surfaceHigh,
	TextColor3       = C.textSec,
	Text             = "⏭",
	Font             = Enum.Font.GothamBold,
	TextSize         = 10,
	BorderSizePixel  = 0,
}, miniFrame)
corner(RADIUS.btn, miniSkipBtn)

local miniExpandBtn = make("TextButton", {
	Name             = "MiniExpandBtn",
	Size             = UDim2.new(0, 26, 0, 26),
	Position         = UDim2.new(1, -30, 0.5, -13),
	BackgroundColor3 = C.surfacePop,
	TextColor3       = C.white,
	Text             = "⛶",
	Font             = Enum.Font.GothamBold,
	TextSize         = 11,
	BorderSizePixel  = 0,
}, miniFrame)
corner(RADIUS.btn, miniExpandBtn)

-- ─────────────────────────────────────────────
--  RESTORE BADGE (When completely hidden)
-- ─────────────────────────────────────────────
local restoreBadge = make("TextButton", {
	Name             = "RestoreBadge",
	Size             = UDim2.new(0, 110, 0, 28),
	Position         = UDim2.new(0.5, -55, 0, 10),
	BackgroundColor3 = C.surface,
	TextColor3       = C.textSec,
	Text             = "🎵 Open Player",
	Font             = Enum.Font.GothamBold,
	TextSize         = 10,
	BorderSizePixel  = 0,
	Visible          = false,
}, screenGui)
corner(RADIUS.pill, restoreBadge)
stroke(C.border, 1, 0.4, restoreBadge)

restoreBadge.MouseEnter:Connect(function()
	tween(restoreBadge, {BackgroundColor3 = C.surfacePop, TextColor3 = C.white}, 0.1)
end)
restoreBadge.MouseLeave:Connect(function()
	tween(restoreBadge, {BackgroundColor3 = C.surface, TextColor3 = C.textSec}, 0.1)
end)

-- ─────────────────────────────────────────────
--  CREDITS & INFO MODAL
-- ─────────────────────────────────────────────
local modalBackdrop = make("TextButton", {
	Name                   = "ModalBackdrop",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundColor3       = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.5,
	BorderSizePixel        = 0,
	Visible                = false,
	ZIndex                 = 90,
	Text                   = "",
	AutoButtonColor        = false,
}, screenGui)

local creditsModal = make("Frame", {
	Name             = "CreditsModal",
	Size             = UDim2.new(0, 440, 0, 460),
	Position         = UDim2.new(0.5, -220, 0.5, -230),
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
	Visible          = false,
	ZIndex           = 100,
}, screenGui)
corner(RADIUS.window, creditsModal)
stroke(C.border, 1.2, 0.45, creditsModal)
gradient(Color3.fromRGB(25, 28, 38), Color3.fromRGB(15, 17, 23), 135, creditsModal)

local cmAccent = make("Frame", {
	Size             = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = C.spotify,
	BorderSizePixel  = 0,
	ZIndex           = 101,
}, creditsModal)
corner(UDim.new(0, 3), cmAccent)

local cmHdr = make("Frame", {
	Size             = UDim2.new(1, 0, 0, 48),
	Position         = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
	ZIndex           = 101,
}, creditsModal)
corner(UDim.new(0, 14), cmHdr)
make("Frame", {
	Size             = UDim2.new(1, 0, 0.5, 0),
	Position         = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
	ZIndex           = 101,
}, cmHdr)

make("TextLabel", {
	Size             = UDim2.new(1, -60, 1, 0),
	Position         = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text             = "Credits & Help",
	TextColor3       = C.textPrimary,
	Font             = Enum.Font.GothamBold,
	TextSize         = 15,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 102,
}, cmHdr)

local closeCreditsBtn = make("TextButton", {
	Size             = UDim2.new(0, 26, 0, 26),
	Position         = UDim2.new(1, -38, 0.5, -13),
	BackgroundColor3 = Color3.fromRGB(220, 60, 60),
	TextColor3       = C.white,
	Text             = "✕",
	Font             = Enum.Font.GothamBold,
	TextSize         = 11,
	BorderSizePixel  = 0,
	ZIndex           = 102,
}, cmHdr)
corner(RADIUS.pill, closeCreditsBtn)

local cmBody = make("Frame", {
	Size                   = UDim2.new(1, -28, 1, -66),
	Position               = UDim2.new(0, 14, 0, 56),
	BackgroundTransparency = 1,
	ZIndex                 = 101,
}, creditsModal)
make("UIListLayout", {
	Padding                = UDim.new(0, 8),
	SortOrder              = Enum.SortOrder.LayoutOrder,
}, cmBody)

local function cmCard(h, lo)
	local f = make("Frame", {
		Size             = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = C.surfaceHigh,
		BorderSizePixel  = 0,
		LayoutOrder      = lo,
		ZIndex           = 102,
	}, cmBody)
	corner(RADIUS.card, f)
	stroke(C.borderSub, 1, 0.35, f)
	return f
end

local c1 = cmCard(50, 1)
make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 20),
	Position         = UDim2.new(0, 12, 0, 6),
	BackgroundTransparency = 1,
	Text             = "🎵  Roblox VC Music Player v3.5",
	TextColor3       = C.spotify,
	Font             = Enum.Font.GothamBold,
	TextSize         = 14,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c1)
make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 16),
	Position         = UDim2.new(0, 12, 0, 26),
	BackgroundTransparency = 1,
	Text             = "Created by borthdayzz  ·  boggle.cc",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c1)

local c2 = cmCard(74, 2)
make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 14),
	Position         = UDim2.new(0, 12, 0, 8),
	BackgroundTransparency = 1,
	Text             = "CHAT COMMANDS (Whitelisted users only)",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.GothamBold,
	TextSize         = 9,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c2)
make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 48),
	Position         = UDim2.new(0, 12, 0, 24),
	BackgroundTransparency = 1,
	Text             = "!play <song name / link>  ·  Search or stream\n!pause  ·  !resume  ·  !stop  ·  !skip",
	TextColor3       = C.textSec,
	Font             = Enum.Font.Gotham,
	TextSize         = 11,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c2)

local c3 = cmCard(58, 3)
c3.BackgroundColor3 = Color3.fromRGB(24, 28, 56)
make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 14),
	Position         = UDim2.new(0, 12, 0, 6),
	BackgroundTransparency = 1,
	Text             = "COMMUNITY & SUPPORT",
	TextColor3       = Color3.fromRGB(150, 165, 255),
	Font             = Enum.Font.GothamBold,
	TextSize         = 9,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c3)

local discordLabel = make("TextLabel", {
	Size             = UDim2.new(1, -96, 0, 24),
	Position         = UDim2.new(0, 12, 0, 24),
	BackgroundTransparency = 1,
	Text             = "discord.gg/NCEfg4rKPC",
	TextColor3       = C.white,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c3)

local copyDiscordBtn = make("TextButton", {
	Size             = UDim2.new(0, 68, 0, 22),
	Position         = UDim2.new(1, -78, 0.5, -11),
	BackgroundColor3 = C.discord,
	TextColor3       = C.white,
	Text             = "Copy",
	Font             = Enum.Font.GothamBold,
	TextSize         = 10,
	BorderSizePixel  = 0,
	ZIndex           = 103,
}, c3)
corner(RADIUS.btn, copyDiscordBtn)
copyDiscordBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard("https://discord.gg/NCEfg4rKPC")
		copyDiscordBtn.Text = "Copied!"
		task.delay(1.5, function() copyDiscordBtn.Text = "Copy" end)
	end
end)

local c4 = cmCard(96, 4)
make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 14),
	Position         = UDim2.new(0, 12, 0, 6),
	BackgroundTransparency = 1,
	Text             = "WHITELIST MANAGER",
	TextColor3       = C.spotify,
	Font             = Enum.Font.GothamBold,
	TextSize         = 9,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c4)

make("TextLabel", {
	Size             = UDim2.new(1, -16, 0, 14),
	Position         = UDim2.new(0, 12, 0, 20),
	BackgroundTransparency = 1,
	Text             = "You (" .. (player and player.Name or "LocalPlayer") .. ") are always whitelisted.",
	TextColor3       = C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 9,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 103,
}, c4)

local wlInputContainer = make("Frame", {
	Size             = UDim2.new(1, -90, 0, 26),
	Position         = UDim2.new(0, 12, 0, 36),
	BackgroundColor3 = C.surfacePop,
	BorderSizePixel  = 0,
	ZIndex           = 103,
}, c4)
corner(RADIUS.btn, wlInputContainer)
stroke(C.borderSub, 1, 0.3, wlInputContainer)

local wlInputBox = make("TextBox", {
	Size             = UDim2.new(1, -12, 1, 0),
	Position         = UDim2.new(0, 8, 0, 0),
	BackgroundTransparency = 1,
	PlaceholderText  = "Username or UserId...",
	Text             = "",
	TextColor3       = C.textPrimary,
	PlaceholderColor3= C.textMuted,
	Font             = Enum.Font.Gotham,
	TextSize         = 10,
	BorderSizePixel  = 0,
	ClearTextOnFocus = false,
	TextXAlignment   = Enum.TextXAlignment.Left,
	ZIndex           = 104,
}, wlInputContainer)

local btnAddWL = make("TextButton", {
	Size             = UDim2.new(0, 64, 0, 26),
	Position         = UDim2.new(1, -74, 0, 36),
	BackgroundColor3 = C.spotify,
	TextColor3       = C.black,
	Text             = "+ Add",
	Font             = Enum.Font.GothamBold,
	TextSize         = 10,
	BorderSizePixel  = 0,
	ZIndex           = 103,
}, c4)
corner(RADIUS.btn, btnAddWL)

local wlListLabel = make("TextLabel", {
	Size             = UDim2.new(1, -24, 0, 24),
	Position         = UDim2.new(0, 12, 0, 66),
	BackgroundTransparency = 1,
	Text             = "Allowed: " .. (#CONFIG.whitelist > 0 and table.concat(CONFIG.whitelist, ", ") or "None added"),
	TextColor3       = C.textSec,
	Font             = Enum.Font.Gotham,
	TextSize         = 9,
	TextXAlignment   = Enum.TextXAlignment.Left,
	TextTruncate     = Enum.TextTruncate.AtEnd,
	ZIndex           = 103,
}, c4)

local function refreshWhitelistLabel()
	wlListLabel.Text = "Allowed: " .. (#CONFIG.whitelist > 0 and table.concat(CONFIG.whitelist, ", ") or "None added")
end

btnAddWL.MouseButton1Click:Connect(function()
	local newName = wlInputBox.Text:match("^%s*(.-)%s*$") or ""
	if newName ~= "" then
		local already = false
		for _, v in ipairs(CONFIG.whitelist) do
			if v:lower() == newName:lower() then already = true; break end
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
	if visible then refreshWhitelistLabel() end
	modalBackdrop.Visible = visible
	creditsModal.Visible  = visible
end

closeCreditsBtn.MouseButton1Click:Connect(function() toggleCredits(false) end)
modalBackdrop.MouseButton1Click:Connect(function() toggleCredits(false) end)
creditsButton.MouseButton1Click:Connect(function() toggleCredits(not creditsModal.Visible) end)

-- ─────────────────────────────────────────────
--  DRAGGING ENGINE (SYNCHRONIZED DOCKING)
-- ─────────────────────────────────────────────
local function enableDragging(dragHandle, targetFrame, onDragCallback)
	local isDragging = false
	local dragStart  = nil
	local startPos   = nil

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

	UserInputService.InputChanged:Connect(function(input, gp)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local newPos = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
			targetFrame.Position = newPos
			if onDragCallback then onDragCallback(newPos) end
		end
	end)
end

function syncQueuePosition(mainPos)
	mainPos = mainPos or shadowFrame.Position
	queueFrame.Position = UDim2.new(
		mainPos.X.Scale,
		mainPos.X.Offset + WIN_W + 22,
		mainPos.Y.Scale,
		mainPos.Y.Offset + 8
	)
end

enableDragging(header, shadowFrame, function(pos)
	syncQueuePosition(pos)
end)
enableDragging(miniFrame, miniFrame)

-- ─────────────────────────────────────────────
--  EQUALIZER & ELAPSED TIME RUNNER
-- ─────────────────────────────────────────────
local eqTick = 0
RunService.RenderStepped:Connect(function(dt)
	if isPlaying and not isPaused then
		eqTick = eqTick + dt
		for i, bar in ipairs(eqBars) do
			local targetH = math.clamp(math.floor(math.sin(eqTick * 12 + i * 1.5) * 6 + math.cos(eqTick * 8 - i) * 4 + 10), 3, 16)
			bar.Size = UDim2.new(0, 3, 0, targetH)
			bar.Position = UDim2.new(0, (i - 1) * 5, 1, -targetH)
		end

		playbackElapsed = playbackElapsed + dt
		timeElapsedLabel.Text = formatTime(playbackElapsed)

		local progWidth = math.clamp((playbackElapsed % 30) / 30, 0.05, 1.0)
		progFill.Size = UDim2.new(progWidth, 0, 1, 0)
	else
		for i, bar in ipairs(eqBars) do
			bar.Size = UDim2.new(0, 3, 0, 3)
			bar.Position = UDim2.new(0, (i - 1) * 5, 1, -3)
		end
	end
end)

-- ─────────────────────────────────────────────
--  THEME ACCENT SWITCHER
-- ─────────────────────────────────────────────
local function applyAccent(accentColor)
	currentAccent = accentColor
	topAccent.BackgroundColor3 = accentColor
	qAccent.BackgroundColor3 = accentColor
	miniAccent.BackgroundColor3 = accentColor
	progFill.BackgroundColor3 = accentColor
	miniPlayBtn.BackgroundColor3 = accentColor
	for _, bar in ipairs(eqBars) do
		bar.BackgroundColor3 = accentColor
	end
	if isPlaying then
		playHeroButton.BackgroundColor3 = Color3.fromRGB(200, 155, 30)
	else
		playHeroButton.BackgroundColor3 = accentColor
	end
	loadButton.BackgroundColor3 = accentColor
end

local function switchServiceMode(mode)
	serviceMode = mode

	local tabs = {
		spotify = {btn = tabSpotify, col = C.spotify, text = "Spotify"},
		youtube = {btn = tabYouTube, col = C.youtube, text = "YouTube"},
		apple   = {btn = tabApple,   col = C.apple,   text = "Apple"},
		auto    = {btn = tabAuto,    col = C.cyan,    text = "Auto"},
	}

	for k, t in pairs(tabs) do
		if k == mode then
			tween(t.btn, {BackgroundColor3 = t.col, BackgroundTransparency = 0, TextColor3 = (k == "spotify") and C.black or C.white}, 0.15)
		else
			tween(t.btn, {BackgroundTransparency = 1, TextColor3 = C.textMuted}, 0.15)
		end
	end

	local activeCol = tabs[mode] and tabs[mode].col or C.spotify
	applyAccent(activeCol)

	if mode == "spotify" then
		inputBox.PlaceholderText = "Paste Spotify track link or song name..."
		headerSub.Text = "v3.5  ·  spotify passthrough"
	elseif mode == "youtube" then
		inputBox.PlaceholderText = "Paste YouTube video link or song name..."
		headerSub.Text = "v3.5  ·  youtube passthrough"
	elseif mode == "apple" then
		inputBox.PlaceholderText = "Paste Apple Music track link or song name..."
		headerSub.Text = "v3.5  ·  apple music passthrough"
	else
		inputBox.PlaceholderText = "Auto-detect link (Spotify, YouTube, Apple) or song name..."
		headerSub.Text = "v3.5  ·  auto-detect passthrough"
	end

	setStatus("Switched mode: " .. mode:upper(), C.success)
end

tabSpotify.MouseButton1Click:Connect(function() switchServiceMode("spotify") end)
tabYouTube.MouseButton1Click:Connect(function() switchServiceMode("youtube") end)
tabApple.MouseButton1Click:Connect(function() switchServiceMode("apple") end)
tabAuto.MouseButton1Click:Connect(function() switchServiceMode("auto") end)

-- ─────────────────────────────────────────────
--  STATUS NOTIFIER
-- ─────────────────────────────────────────────
function setStatus(text, color)
	color = color or C.success
	statusLabel.Text           = text
	statusLabel.TextColor3     = color
	statusDot.BackgroundColor3 = color
end

-- ─────────────────────────────────────────────
--  MINI-PLAYER & VISIBILITY TOGGLE
-- ─────────────────────────────────────────────
function toggleMiniPlayer(forceMini)
	if forceMini ~= nil then
		isMiniMode = forceMini
	else
		isMiniMode = not isMiniMode
	end

	if isMiniMode then
		shadowFrame.Visible = false
		queueFrame.Visible  = false
		miniFrame.Visible   = true
	else
		miniFrame.Visible   = false
		shadowFrame.Visible = true
		syncQueuePosition()
	end
end

local function setGuiVisible(visible)
	isGuiVisible = visible
	if not visible then
		shadowFrame.Visible  = false
		queueFrame.Visible   = false
		miniFrame.Visible    = false
		creditsModal.Visible = false
		modalBackdrop.Visible= false
		restoreBadge.Visible = true
	else
		restoreBadge.Visible = false
		if isMiniMode then
			miniFrame.Visible = true
		else
			shadowFrame.Visible = true
			syncQueuePosition()
		end
	end
end

btnClose.MouseButton1Click:Connect(function()
	setGuiVisible(false)
	setStatus("Player hidden. Press [Right-Shift] or click top badge to restore.", C.warn)
end)

btnMini.MouseButton1Click:Connect(function()
	toggleMiniPlayer(true)
end)

miniExpandBtn.MouseButton1Click:Connect(function()
	toggleMiniPlayer(false)
end)

restoreBadge.MouseButton1Click:Connect(function()
	setGuiVisible(true)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CONFIG.toggleKey then
		setGuiVisible(not isGuiVisible)
	end
end)

-- ─────────────────────────────────────────────
--  ALBUM ART CACHING & UPDATER
-- ─────────────────────────────────────────────
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
	local fileName = tostring(trackId or "default") .. ext
	local filePath = "AlbumArt/" .. fileName

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
				Url = imageUrl,
				Method = "GET",
				Headers = {["Content-Type"] = "application/octet-stream"}
			})
			return res and (res.Body or res.body)
		end)
	end

	if not success or not response or #response < 100 then
		success, response = pcall(function()
			return game:HttpGet(imageUrl)
		end)
	end

	if not success or not response or #response < 100 then
		return nil
	end

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
		if ok and asset then
			setArtAsset(asset)
			return
		end
	end

	if imageUrl and imageUrl ~= "" then
		local cached = downloadAndCacheAlbumArt(imageUrl, trackId)
		if cached then
			setArtAsset(cached)
			return
		end
	end

	setFallback()
end

-- ─────────────────────────────────────────────
--  QUEUE UI MANAGEMENT
-- ─────────────────────────────────────────────
function updateQueueUI()
	for _, c in ipairs(queueList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	emptyQueueLabel.Visible = (#songQueue == 0)
	queueToggleBtn.Text     = string.format("≡  Queue (%d)", #songQueue)

	for i, song in ipairs(songQueue) do
		local item = make("Frame", {
			Name             = "QueueItem_" .. i,
			Size             = UDim2.new(1, -6, 0, 52),
			BackgroundColor3 = C.surfaceHigh,
			BorderSizePixel  = 0,
			LayoutOrder      = i,
		}, queueList)
		corner(RADIUS.card, item)
		stroke(C.borderSub, 1, 0.35, item)

		local idxBadge = make("TextLabel", {
			Size             = UDim2.new(0, 22, 0, 22),
			Position         = UDim2.new(0, 8, 0.5, -11),
			BackgroundColor3 = C.surfacePop,
			TextColor3       = C.textMuted,
			Text             = tostring(i),
			Font             = Enum.Font.GothamBold,
			TextSize         = 10,
			BorderSizePixel  = 0,
		}, item)
		corner(RADIUS.pill, idxBadge)

		local qSongTitle = make("TextLabel", {
			Size             = UDim2.new(1, -96, 0, 18),
			Position         = UDim2.new(0, 36, 0, 8),
			BackgroundTransparency = 1,
			Text             = song.title or "Unknown",
			TextColor3       = C.textPrimary,
			Font             = Enum.Font.GothamBold,
			TextSize         = 11,
			TextXAlignment   = Enum.TextXAlignment.Left,
			TextTruncate     = Enum.TextTruncate.AtEnd,
		}, item)

		local qSongArtist = make("TextLabel", {
			Size             = UDim2.new(1, -96, 0, 14),
			Position         = UDim2.new(0, 36, 0, 26),
			BackgroundTransparency = 1,
			Text             = song.artist or "Unknown",
			TextColor3       = C.textMuted,
			Font             = Enum.Font.Gotham,
			TextSize         = 9,
			TextXAlignment   = Enum.TextXAlignment.Left,
			TextTruncate     = Enum.TextTruncate.AtEnd,
		}, item)

		local pb = make("TextButton", {
			Name             = "PlayBtn",
			Size             = UDim2.new(0, 26, 0, 26),
			Position         = UDim2.new(1, -58, 0.5, -13),
			BackgroundColor3 = currentAccent,
			TextColor3       = C.black,
			Text             = "▶",
			Font             = Enum.Font.GothamBold,
			TextSize         = 10,
			BorderSizePixel  = 0,
		}, item)
		corner(RADIUS.pill, pb)

		pb.MouseButton1Click:Connect(function()
			if not isPythonServerRunning() then setStatus("Python not running", C.error); return end
			local s = songQueue[i]
			table.remove(songQueue, i)
			updateQueueUI()
			currentSongData = s
			songTitle.Text  = s.title or "Unknown"
			songArtist.Text = s.artist or "—"
			miniTitle.Text  = s.title or "Unknown"
			miniArtist.Text = s.artist or "—"
			updateAlbumArt(s.image_path or "", s.image or "", s.track_id)
			setStatus("Playing: " .. (s.title or "Song"), C.success)
			local ok = pcall(function()
				return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.play .. "?path=" .. HttpService:UrlEncode(s.path))
			end)
			if ok then
				isPlaying = true
				isPaused  = false
				playbackElapsed = 0
				playHeroButton.Text = "⏸  Pause"
				playHeroButton.BackgroundColor3 = Color3.fromRGB(200, 155, 30)
				miniPlayBtn.Text = "⏸"
				statusPillText.Text = "PLAYING"
				statusPillText.TextColor3 = C.success
				startPlaybackMonitor()
			else
				setStatus("Failed to play song", C.error)
			end
		end)

		local rb = make("TextButton", {
			Name             = "RemoveBtn",
			Size             = UDim2.new(0, 22, 0, 22),
			Position         = UDim2.new(1, -28, 0.5, -11),
			BackgroundColor3 = C.surfacePop,
			TextColor3       = C.textMuted,
			Text             = "✕",
			Font             = Enum.Font.GothamBold,
			TextSize         = 9,
			BorderSizePixel  = 0,
		}, item)
		corner(RADIUS.pill, rb)
		rb.MouseEnter:Connect(function()
			tween(rb, {BackgroundColor3 = Color3.fromRGB(190, 50, 50), TextColor3 = C.white}, 0.1)
		end)
		rb.MouseLeave:Connect(function()
			tween(rb, {BackgroundColor3 = C.surfacePop, TextColor3 = C.textMuted}, 0.1)
		end)
		rb.MouseButton1Click:Connect(function()
			table.remove(songQueue, i)
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
	songQueue = {}
	updateQueueUI()
	setStatus("Queue cleared", C.warn)
end)

local function toggleQueueDrawer()
	queueFrame.Visible = not queueFrame.Visible
	if queueFrame.Visible then
		syncQueuePosition()
	end
end

queueToggleBtn.MouseButton1Click:Connect(toggleQueueDrawer)
headerQueueBtn.MouseButton1Click:Connect(toggleQueueDrawer)
btnQueueTraffic.MouseButton1Click:Connect(toggleQueueDrawer)

-- ─────────────────────────────────────────────
--  SERVER STATUS & PLAYBACK MONITOR
-- ─────────────────────────────────────────────
function isPythonServerRunning()
	local ok, res = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.health) end)
	if not ok or not res then return false end
	local s, data = pcall(function() return HttpService:JSONDecode(res) end)
	return s and type(data) == "table" and data.status == "ok"
end

function playNextInQueue()
	if #songQueue > 0 then
		local nextSong = table.remove(songQueue, 1)
		updateQueueUI()
		currentSongData = nextSong
		songTitle.Text  = nextSong.title or "Unknown"
		songArtist.Text = nextSong.artist or "—"
		miniTitle.Text  = nextSong.title or "Unknown"
		miniArtist.Text = nextSong.artist or "—"
		updateAlbumArt(nextSong.image_path or "", nextSong.image or "", nextSong.track_id)
		setStatus("Playing: " .. (nextSong.title or "Next"), C.success)

		local ok = pcall(function()
			return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.play .. "?path=" .. HttpService:UrlEncode(nextSong.path))
		end)
		if ok then
			isPlaying = true
			isPaused  = false
			playbackElapsed = 0
			playHeroButton.Text = "⏸  Pause"
			playHeroButton.BackgroundColor3 = Color3.fromRGB(200, 155, 30)
			miniPlayBtn.Text = "⏸"
			statusPillText.Text = "PLAYING"
			statusPillText.TextColor3 = C.success
			startPlaybackMonitor()
		else
			setStatus("Failed to play next song", C.error)
			isPlaying = false
			playHeroButton.Text = "▶  Play"
			playHeroButton.BackgroundColor3 = currentAccent
			miniPlayBtn.Text = "▶"
			statusPillText.Text = "ERROR"
			statusPillText.TextColor3 = C.error
		end
	else
		isPlaying = false
		isPaused  = false
		playbackElapsed = 0
		playHeroButton.Text = "▶  Play"
		playHeroButton.BackgroundColor3 = currentAccent
		miniPlayBtn.Text = "▶"
		songTitle.Text  = "No song loaded"
		songArtist.Text = "Paste a link or search below to play"
		miniTitle.Text  = "No song loaded"
		miniArtist.Text = "Idle"
		statusPillText.Text = "IDLE"
		statusPillText.TextColor3 = C.textMuted
		updateAlbumArt("", "", nil)
		setStatus("Queue finished", C.success)
	end
end

function startPlaybackMonitor()
	if playbackMonitor then return end
	playbackMonitor = task.spawn(function()
		while true do
			if not isPlaying then break end
			local ok, res = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.status) end)
			if not ok or not res then break end
			local sd
			local dok = pcall(function() sd = HttpService:JSONDecode(res) end)
			local st = dok and type(sd) == "table" and sd.status or nil
			if st == "finished" or st == "stopped" then
				isPlaying = false
				isPaused  = false
				if #songQueue > 0 then
					task.wait(0.5)
					playNextInQueue()
				else
					playHeroButton.Text = "▶  Play"
					playHeroButton.BackgroundColor3 = currentAccent
					miniPlayBtn.Text = "▶"
					songTitle.Text  = "No song loaded"
					songArtist.Text = "Paste a link or search below to play"
					miniTitle.Text  = "No song loaded"
					miniArtist.Text = "Idle"
					statusPillText.Text = "IDLE"
					statusPillText.TextColor3 = C.textMuted
					setStatus("Finished playing", C.success)
				end
				break
			end
			task.wait(1)
		end
		playbackMonitor = nil
	end)
end

-- ─────────────────────────────────────────────
--  CHAT TRANSMISSION & UTILITIES
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
--  CORE PLAYBACK CONTROLS
-- ─────────────────────────────────────────────
function playSong()
	if not currentSongData then
		setStatus("No song loaded", C.error)
		return
	end
	if not isPythonServerRunning() then
		setStatus("Python server not running", C.error)
		return
	end

	if isPaused then
		isPaused  = false
		isPlaying = true
		playHeroButton.Text = "⏸  Pause"
		playHeroButton.BackgroundColor3 = Color3.fromRGB(200, 155, 30)
		miniPlayBtn.Text = "⏸"
		statusPillText.Text = "PLAYING"
		statusPillText.TextColor3 = C.success
		setStatus("Resumed: " .. (currentSongData.title or ""), C.success)

		local ok = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.resume) end)
		if not ok then
			setStatus("Failed to resume", C.error)
			isPaused = true
			playHeroButton.Text = "▶  Resume"
		else
			startPlaybackMonitor()
		end
		return
	end

	isPlaying = true
	isPaused  = false
	playbackElapsed = 0
	playHeroButton.Text = "⏸  Pause"
	playHeroButton.BackgroundColor3 = Color3.fromRGB(200, 155, 30)
	miniPlayBtn.Text = "⏸"
	statusPillText.Text = "PLAYING"
	statusPillText.TextColor3 = C.success
	setStatus("Playing: " .. (currentSongData.title or ""), C.success)

	local ok = pcall(function()
		return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.play .. "?path=" .. HttpService:UrlEncode(currentSongData.path))
	end)
	if not ok then
		setStatus("Failed to play", C.error)
		isPlaying = false
		playHeroButton.Text = "▶  Play"
		playHeroButton.BackgroundColor3 = currentAccent
		miniPlayBtn.Text = "▶"
	else
		startPlaybackMonitor()
	end
end

function pauseSong()
	if not isPlaying or isPaused then return end
	isPaused  = true
	isPlaying = false
	playHeroButton.Text = "▶  Resume"
	playHeroButton.BackgroundColor3 = currentAccent
	miniPlayBtn.Text = "▶"
	statusPillText.Text = "PAUSED"
	statusPillText.TextColor3 = C.warn
	setStatus("Paused: " .. (currentSongData and currentSongData.title or ""), C.warn)

	local ok = pcall(function() return game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.pause) end)
	if not ok then
		setStatus("Failed to pause", C.error)
		isPaused = false
		playHeroButton.Text = "⏸  Pause"
	end
end

function stopSong()
	pcall(function() game:HttpGet(CONFIG.pythonServer .. ENDPOINTS.stop) end)
	isPlaying       = false
	isPaused        = false
	playbackElapsed = 0
	currentSongData = nil
	playHeroButton.Text = "▶  Play"
	playHeroButton.BackgroundColor3 = currentAccent
	miniPlayBtn.Text = "▶"
	statusPillText.Text = "IDLE"
	statusPillText.TextColor3 = C.textMuted
	songTitle.Text  = "No song loaded"
	songArtist.Text = "Paste a link or search below to play"
	miniTitle.Text  = "No song loaded"
	miniArtist.Text = "Idle"
	timeElapsedLabel.Text = "00:00"
	progFill.Size   = UDim2.new(0, 0, 1, 0)
	updateAlbumArt("", "", nil)
	setStatus("Stopped playback", C.success)
end

function skipSong()
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
	if not isPythonServerRunning() then
		setStatus("Python server not running", C.error)
		return
	end
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
	else
		currentSongData = sd
		songTitle.Text  = sd.title or "Unknown"
		songArtist.Text = sd.artist or "—"
		miniTitle.Text  = sd.title or "Unknown"
		miniArtist.Text = sd.artist or "—"
		updateAlbumArt(sd.image_path or "", sd.image or "", sd.track_id)
		playHeroButton.Text = "▶  Play"
		setStatus("Found: " .. (sd.title or "Song") .. " — playing...", C.success)
		pcall(function() safeSendChat("Found the song! Playing Now...") end)
		task.wait(0.3)
		playSong()
	end
end

-- ─────────────────────────────────────────────
--  UNIFIED BACKEND LOADER (URL OR SEARCH)
-- ─────────────────────────────────────────────
function callPythonBackend(rawInput)
	local text = tostring(rawInput or ""):match("^%s*(.-)%s*$") or ""
	if text == "" then
		setStatus("Please enter a link or song name", C.warn)
		return false
	end
	if not isPythonServerRunning() then
		setStatus("Python server not running (run spotify_server.py)", C.error)
		return false
	end

	local isUrl = text:find("^https?://") or text:find("spotify%.com") or text:find("youtube%.com") or text:find("youtu%.be") or text:find("music%.apple%.com")

	if not isUrl then
		searchAndPlaySong(text)
		return true
	end

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
			else
				currentSongData = sd
				songTitle.Text  = sd.title or "Unknown"
				songArtist.Text = sd.artist or "—"
				miniTitle.Text  = sd.title or "Unknown"
				miniArtist.Text = sd.artist or "—"
				updateAlbumArt(sd.image_path or "", sd.image or "", sd.track_id)
				playHeroButton.Text = "▶  Play"
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

-- ─────────────────────────────────────────────
--  BUTTON ACTIONS WIRING
-- ─────────────────────────────────────────────
loadButton.MouseButton1Click:Connect(function()
	callPythonBackend(inputBox.Text)
end)

inputBox.FocusLost:Connect(function(enter)
	if enter then callPythonBackend(inputBox.Text) end
end)

playHeroButton.MouseButton1Click:Connect(function()
	if isPlaying and not isPaused then
		pauseSong()
	else
		playSong()
	end
end)

miniPlayBtn.MouseButton1Click:Connect(function()
	if isPlaying and not isPaused then
		pauseSong()
	else
		playSong()
	end
end)

stopButton.MouseButton1Click:Connect(stopSong)
skipButton.MouseButton1Click:Connect(skipSong)
miniSkipBtn.MouseButton1Click:Connect(skipSong)

-- ─────────────────────────────────────────────
--  CHAT COMMAND LISTENER & MULTI-LAYER RECEIVER
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
--  INITIALIZATION
-- ─────────────────────────────────────────────
task.spawn(function()
	if isPythonServerRunning() then
		pythonRunning = true
		setStatus("Ready  ·  Python server connected", C.success)
	else
		setStatus("Python offline  ·  Run: python spotify_server.py", C.error)
	end
end)
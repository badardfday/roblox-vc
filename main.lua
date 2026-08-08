if not game:GetService("GuiService") then
	print("Error: Not running in Roblox environment")
	return
end

local UserInputService = game:GetService("UserInputService")

if platform == Enum.Platform.IOS or platform == Enum.Platform.Android then
	StarterGui:SetCore("SendNotification", {
		Title = "Unsupported Platform",
		Text = "This script requires a PC executor. Mobile is not supported.",
		Duration = 8,
	})
	return
end

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- ─────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────
local C = {
	bg          = Color3.fromRGB(10, 10, 12),
	surface     = Color3.fromRGB(18, 18, 22),
	surfaceHigh = Color3.fromRGB(26, 26, 32),
	surfacePop  = Color3.fromRGB(34, 34, 42),
	border      = Color3.fromRGB(48, 48, 58),
	borderSub   = Color3.fromRGB(36, 36, 44),
	textPrimary = Color3.fromRGB(240, 240, 245),
	textSec     = Color3.fromRGB(160, 160, 175),
	textMuted   = Color3.fromRGB(90, 90, 105),
	green       = Color3.fromRGB(30, 215, 96),
	greenDim    = Color3.fromRGB(22, 160, 70),
	youtube     = Color3.fromRGB(255, 48, 48),
	apple       = Color3.fromRGB(250, 34, 52),
	discord     = Color3.fromRGB(88, 101, 242),
	warn        = Color3.fromRGB(255, 200, 50),
	error       = Color3.fromRGB(240, 75, 75),
	success     = Color3.fromRGB(30, 215, 96),
	white       = Color3.fromRGB(255, 255, 255),
	black       = Color3.fromRGB(0, 0, 0),
}

local RADIUS = {
	window = UDim.new(0, 16),
	card   = UDim.new(0, 10),
	btn    = UDim.new(0, 8),
	pill   = UDim.new(0, 999),
	input  = UDim.new(0, 8),
}

-- ─────────────────────────────────────────────
--  CONFIG
-- ─────────────────────────────────────────────
local CONFIG = {
	whitelist     = {"lolwhenme"},
	pythonServer  = "http://localhost:5000",
	chatRateLimit = 5,
}

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

local QUEUE_ITEM_H = 58

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
	return make("UIStroke", {Color=color, Thickness=thick or 1, Transparency=trans or 0}, parent)
end

local function gradient(c0, c1, rot, parent)
	return make("UIGradient", {
		Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,c0), ColorSequenceKeypoint.new(1,c1)},
		Rotation = rot or 90,
	}, parent)
end

local function tween(inst, props, t, style, dir)
	local info = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	TweenService:Create(inst, info, props):Play()
end

local function debounce(fn, delay)
	local last = 0
	return function(...)
		local now = tick()
		if now - last >= delay then last = now; fn(...) end
	end
end

-- ─────────────────────────────────────────────
--  SCREEN GUI
-- ─────────────────────────────────────────────
local screenGui = make("ScreenGui", {
	Name         = "SpotifyMusicBot",
	ResetOnSpawn = false,
	DisplayOrder = 10,
}, gethui())

-- ─────────────────────────────────────────────
--  MAIN WINDOW  550 x 390
-- ─────────────────────────────────────────────
local WIN_W, WIN_H = 550, 390

local mainFrame = make("Frame", {
	Name             = "MainFrame",
	Size             = UDim2.new(0, WIN_W, 0, WIN_H),
	Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
}, screenGui)
corner(RADIUS.window, mainFrame)
stroke(C.border, 1, 0.55, mainFrame)
gradient(Color3.fromRGB(22,22,28), Color3.fromRGB(14,14,18), 135, mainFrame)

-- top accent line
local topLine = make("Frame", {
	Size=UDim2.new(1,0,0,2), BackgroundColor3=C.green, BorderSizePixel=0,
}, mainFrame)
corner(UDim.new(0,2), topLine)
gradient(C.green, C.greenDim, 0, topLine)

-- ─────────────────────────────────────────────
--  HEADER
-- ─────────────────────────────────────────────
local header = make("Frame", {
	Name=        "Header",
	Size=        UDim2.new(1,0,0,50),
	Position=    UDim2.new(0,0,0,2),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, mainFrame)
corner(UDim.new(0,14), header)
-- flatten bottom corners
make("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.bg,BorderSizePixel=0},header)

-- traffic-light dots
for i, col in ipairs({Color3.fromRGB(255,92,92), Color3.fromRGB(255,189,68), Color3.fromRGB(40,200,80)}) do
	local d = make("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,14+(i-1)*20,0.5,-6),BackgroundColor3=col,BorderSizePixel=0},header)
	corner(RADIUS.pill,d)
end

-- service badge
local serviceIcon = make("TextLabel",{
	Name="ServiceIcon", Size=UDim2.new(0,26,0,26), Position=UDim2.new(0,94,0.5,-13),
	BackgroundColor3=C.green, TextColor3=C.black, Text="S",
	Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0,
	TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center,
},header)
corner(RADIUS.pill, serviceIcon)

local headerLabel = make("TextLabel",{
	Name="HeaderLabel", Size=UDim2.new(0,200,0,22), Position=UDim2.new(0,128,0,8),
	BackgroundTransparency=1, Text="Music Bot",
	TextColor3=C.textPrimary, Font=Enum.Font.GothamBold, TextSize=15,
	TextXAlignment=Enum.TextXAlignment.Left,
},header)

local headerSub = make("TextLabel",{
	Name="HeaderSub", Size=UDim2.new(0,200,0,14), Position=UDim2.new(0,128,0,30),
	BackgroundTransparency=1, Text="spotify · vc passthrough",
	TextColor3=C.textMuted, Font=Enum.Font.Gotham, TextSize=10,
	TextXAlignment=Enum.TextXAlignment.Left,
},header)

-- mode pill
local modeButton = make("TextButton",{
	Name="ModeButton", Size=UDim2.new(0,76,0,26), Position=UDim2.new(1,-130,0.5,-13),
	BackgroundColor3=C.green, TextColor3=C.black, Text="Spotify",
	Font=Enum.Font.GothamBold, TextSize=11, BorderSizePixel=0,
},header)
corner(RADIUS.pill, modeButton)
modeButton.MouseEnter:Connect(function() tween(modeButton,{BackgroundTransparency=0.15},0.1) end)
modeButton.MouseLeave:Connect(function() tween(modeButton,{BackgroundTransparency=0},0.1) end)

-- credits button
local creditsButton = make("TextButton",{
	Size=UDim2.new(0,32,0,32), Position=UDim2.new(1,-44,0.5,-16),
	BackgroundColor3=C.surfacePop, TextColor3=C.white,
	Text="ℹ", Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0,
},header)
corner(RADIUS.btn, creditsButton)
stroke(C.border, 1, 0.4, creditsButton)
creditsButton.MouseEnter:Connect(function() tween(creditsButton,{BackgroundTransparency=0.25},0.1) end)
creditsButton.MouseLeave:Connect(function() tween(creditsButton,{BackgroundTransparency=0},0.1) end)

-- ─────────────────────────────────────────────
--  BODY
-- ─────────────────────────────────────────────
local body = make("Frame",{
	Size=UDim2.new(1,-24,1,-62), Position=UDim2.new(0,12,0,56),
	BackgroundTransparency=1,
},mainFrame)

-- ── NOW PLAYING CARD ──────────────────────────
local npCard = make("Frame",{
	Name="NowPlayingCard", Size=UDim2.new(1,0,0,100),
	BackgroundColor3=C.surfaceHigh, BorderSizePixel=0,
},body)
corner(RADIUS.card, npCard)
stroke(C.borderSub, 1, 0.35, npCard)

-- album art
local albumArt = make("ImageLabel",{
	Name="AlbumArt",
	Size=UDim2.new(0,88,0,88), Position=UDim2.new(0,6,0.5,-44),
	BackgroundColor3=C.surfacePop, BorderSizePixel=0,
	Image="rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png",
	ScaleType=Enum.ScaleType.Crop,
	ImageColor3=C.textMuted,
},npCard)
corner(RADIUS.card, albumArt)
local albumArtGradient = gradient(Color3.fromRGB(42,42,52), Color3.fromRGB(22,22,28), 135, albumArt)

local playingDots = make("Frame",{
	Size=UDim2.new(0,18,0,14), Position=UDim2.new(1,-28,0,8),
	BackgroundTransparency=1, Visible=false,
},npCard)
for i=1,3 do
	local h = 8+(i%2)*6
	make("Frame",{
		Size=UDim2.new(0,3,0,h), Position=UDim2.new(0,(i-1)*7,1,-h),
		BackgroundColor3=C.green, BorderSizePixel=0,
	},playingDots)
end

local songTitle = make("TextLabel",{
	Name="SongTitle", Size=UDim2.new(1,-106,0,24), Position=UDim2.new(0,96,0,18),
	BackgroundTransparency=1, Text="No song loaded",
	TextColor3=C.textPrimary, Font=Enum.Font.GothamBold, TextSize=15,
	TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
},npCard)

local songArtist = make("TextLabel",{
	Name="SongArtist", Size=UDim2.new(1,-106,0,18), Position=UDim2.new(0,96,0,44),
	BackgroundTransparency=1, Text="—",
	TextColor3=C.textSec, Font=Enum.Font.Gotham, TextSize=12,
	TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
},npCard)

-- progress bar
local progTrack = make("Frame",{
	Size=UDim2.new(1,-106,0,3), Position=UDim2.new(0,96,0,72),
	BackgroundColor3=C.surfacePop, BorderSizePixel=0,
},npCard)
corner(RADIUS.pill, progTrack)
local progFill = make("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.green,BorderSizePixel=0},progTrack)
corner(RADIUS.pill, progFill)

-- ── INPUT ROW ─────────────────────────────────
local inputRow = make("Frame",{
	Size=UDim2.new(1,0,0,38), Position=UDim2.new(0,0,0,110),
	BackgroundTransparency=1,
},body)

local inputBox = make("TextBox",{
	Name="InputBox", Size=UDim2.new(1,-96,1,0),
	BackgroundColor3=C.surfacePop, TextColor3=C.textPrimary,
	PlaceholderColor3=C.textMuted, Text="",
	PlaceholderText="Paste a Spotify / YouTube / Apple Music link…",
	TextSize=11, Font=Enum.Font.Gotham, BorderSizePixel=0, ClearTextOnFocus=false,
},inputRow)
corner(RADIUS.input, inputBox)
stroke(C.borderSub, 1, 0.3, inputBox)
make("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},inputBox)
inputBox.Focused:Connect(function() tween(inputBox,{BackgroundColor3=Color3.fromRGB(38,38,48)},0.15) end)
inputBox.FocusLost:Connect(function() tween(inputBox,{BackgroundColor3=C.surfacePop},0.15) end)

local loadButton = make("TextButton",{
	Name="LoadButton", Size=UDim2.new(0,88,1,0), Position=UDim2.new(1,-88,0,0),
	BackgroundColor3=C.green, TextColor3=C.black, Text="Load",
	Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0,
},inputRow)
corner(RADIUS.input, loadButton)
loadButton.MouseEnter:Connect(function() tween(loadButton,{BackgroundColor3=Color3.fromRGB(40,230,110)},0.12) end)
loadButton.MouseLeave:Connect(function() tween(loadButton,{BackgroundColor3=C.green},0.12) end)

-- ── CONTROLS ROW ──────────────────────────────
local ctrlRow = make("Frame",{
	Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,158),
	BackgroundTransparency=1,
},body)

local function makeCtrlBtn(text, bg, w, x, tcol)
	local b = make("TextButton",{
		Size=UDim2.new(0,w,1,0), Position=UDim2.new(0,x,0,0),
		BackgroundColor3=bg, TextColor3=tcol or C.white, Text=text,
		Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0, Visible=false,
	},ctrlRow)
	corner(RADIUS.btn,b)
	b.MouseEnter:Connect(function() tween(b,{BackgroundTransparency=0.2},0.1) end)
	b.MouseLeave:Connect(function() tween(b,{BackgroundTransparency=0},0.1) end)
	return b
end

local playButton  = makeCtrlBtn("▶  Play",  C.green,                           162, 0,   C.black)
local pauseButton = makeCtrlBtn("⏸  Pause", Color3.fromRGB(200,155,30),        110, 170, C.white)
local stopButton  = makeCtrlBtn("⏹  Stop",  Color3.fromRGB(190,55,55),          82, 288, C.white)

local queueButton = make("TextButton",{
	Name="QueueButton", Size=UDim2.new(0,100,1,0), Position=UDim2.new(1,-100,0,0),
	BackgroundColor3=C.surfacePop, TextColor3=C.textSec,
	Text="≡  Queue", Font=Enum.Font.GothamBold, TextSize=12, BorderSizePixel=0,
},ctrlRow)
corner(RADIUS.btn, queueButton)
stroke(C.border, 1, 0.4, queueButton)
queueButton.MouseEnter:Connect(function() tween(queueButton,{TextColor3=C.textPrimary},0.12) end)
queueButton.MouseLeave:Connect(function() tween(queueButton,{TextColor3=C.textSec},0.12) end)

-- ── STATUS BAR ────────────────────────────────
local statusBar = make("Frame",{
	Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,208),
	BackgroundColor3=C.bg, BorderSizePixel=0,
},body)
corner(RADIUS.card, statusBar)
stroke(C.borderSub, 1, 0.5, statusBar)

local statusDot = make("Frame",{
	Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,12,0.5,-3),
	BackgroundColor3=C.success, BorderSizePixel=0,
},statusBar)
corner(RADIUS.pill, statusDot)

local statusLabel = make("TextLabel",{
	Name="Status", Size=UDim2.new(1,-32,1,0), Position=UDim2.new(0,26,0,0),
	BackgroundTransparency=1, Text="Ready",
	TextColor3=C.textSec, Font=Enum.Font.Gotham, TextSize=11,
	TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center,
},statusBar)

-- ─────────────────────────────────────────────
--  QUEUE PANEL
-- ─────────────────────────────────────────────
local QUEUE_W = 280

local queueFrame = make("Frame",{
	Name="QueueFrame", Size=UDim2.new(0,QUEUE_W,0,WIN_H),
	Position=UDim2.new(0.5,WIN_W/2+10,0.5,-WIN_H/2),
	BackgroundColor3=C.surface, BorderSizePixel=0, Visible=false,
},screenGui)
corner(RADIUS.window, queueFrame)
stroke(C.border, 1, 0.45, queueFrame)
gradient(Color3.fromRGB(20,20,26), Color3.fromRGB(14,14,18), 135, queueFrame)

local qHdr = make("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.bg,BorderSizePixel=0},queueFrame)
corner(UDim.new(0,14),qHdr)
make("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.bg,BorderSizePixel=0},qHdr)
make("TextLabel",{Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,
	Text="Queue",TextColor3=C.textPrimary,Font=Enum.Font.GothamBold,TextSize=14,
	TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},qHdr)

local queueCountLabel = make("TextLabel",{
	Size=UDim2.new(0,36,0,20), Position=UDim2.new(1,-48,0.5,-10),
	BackgroundColor3=C.surfacePop, TextColor3=C.textMuted,
	Font=Enum.Font.GothamBold, TextSize=10, Text="0",
	TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,
	BorderSizePixel=0,
},qHdr)
corner(RADIUS.pill, queueCountLabel)

local queueList = make("ScrollingFrame",{
	Name="QueueList", Size=UDim2.new(1,-16,1,-54), Position=UDim2.new(0,8,0,50),
	BackgroundTransparency=1, BorderSizePixel=0,
	ScrollBarThickness=3, ScrollBarImageColor3=C.border, CanvasSize=UDim2.new(0,0,0,0),
},queueFrame)
local queueLayout = make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},queueList)

-- ─────────────────────────────────────────────
--  CREDITS MODAL
-- ─────────────────────────────────────────────
local creditsModal = make("Frame",{
	Name="CreditsModal", Size=UDim2.new(0,380,0,336),
	Position=UDim2.new(0.5,-190,0.5,-168),
	BackgroundColor3=C.surface, BorderSizePixel=0, Visible=false, ZIndex=100,
},screenGui)
corner(RADIUS.window, creditsModal)
stroke(C.border, 1, 0.4, creditsModal)
gradient(Color3.fromRGB(22,22,28), Color3.fromRGB(14,14,18), 135, creditsModal)
make("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=C.green,BorderSizePixel=0,ZIndex=101},creditsModal)
gradient(C.green,C.greenDim,0,creditsModal:FindFirstChild("Frame"))

local cmHdr = make("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,0,2),
	BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=101},creditsModal)
corner(UDim.new(0,14),cmHdr)
make("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=101},cmHdr)
make("TextLabel",{Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,
	Text="Credits & Info",TextColor3=C.textPrimary,Font=Enum.Font.GothamBold,TextSize=15,
	TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=102},cmHdr)

local closeBtn = make("TextButton",{
	Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-40,0.5,-14),
	BackgroundColor3=Color3.fromRGB(190,55,55),TextColor3=C.white,
	Text="✕",Font=Enum.Font.GothamBold,TextSize=13,BorderSizePixel=0,ZIndex=102},cmHdr)
corner(RADIUS.pill,closeBtn)
closeBtn.MouseEnter:Connect(function() tween(closeBtn,{BackgroundColor3=Color3.fromRGB(220,80,80)},0.1) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn,{BackgroundColor3=Color3.fromRGB(190,55,55)},0.1) end)

local cmBody = make("Frame",{Size=UDim2.new(1,-28,1,-68),Position=UDim2.new(0,14,0,58),
	BackgroundTransparency=1,ZIndex=101},creditsModal)
make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},cmBody)

local function cmCard(h,lo)
	local f = make("Frame",{Size=UDim2.new(1,0,0,h),BackgroundColor3=C.surfaceHigh,
		BorderSizePixel=0,LayoutOrder=lo,ZIndex=102},cmBody)
	corner(RADIUS.card,f); stroke(C.borderSub,1,0.35,f); return f
end

local cc1 = cmCard(54,1)
make("TextLabel",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
	Text="🎸  boggle.cc",TextColor3=C.green,Font=Enum.Font.GothamBold,TextSize=17,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc1)
make("TextLabel",{Size=UDim2.new(1,-16,0,16),Position=UDim2.new(0,12,0,32),BackgroundTransparency=1,
	Text="v3",TextColor3=C.textMuted,Font=Enum.Font.Gotham,TextSize=10,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc1)

local cc2 = cmCard(50,2)
make("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
	Text="CREATED BY",TextColor3=C.textMuted,Font=Enum.Font.GothamBold,TextSize=9,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc2)
make("TextLabel",{Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,12,0,26),BackgroundTransparency=1,
	Text="👨‍💻  borthdayzz",TextColor3=C.textPrimary,Font=Enum.Font.GothamBold,TextSize=14,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc2)

local cc3 = cmCard(56,3)
make("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
	Text="DESCRIPTION",TextColor3=C.textMuted,Font=Enum.Font.GothamBold,TextSize=9,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc3)
make("TextLabel",{Size=UDim2.new(1,-16,0,34),Position=UDim2.new(0,12,0,20),BackgroundTransparency=1,
	Text="Spotify / YouTube / Apple Music → Roblox VC passthrough. Share your music in-game.",
	TextColor3=C.textSec,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
	TextWrapped=true,ZIndex=103},cc3)

local cc4 = cmCard(46,4)
cc4.BackgroundColor3 = Color3.fromRGB(28,32,68)
make("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,
	Text="COMMUNITY",TextColor3=Color3.fromRGB(140,150,255),Font=Enum.Font.GothamBold,TextSize=9,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc4)
make("TextLabel",{Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,12,0,22),BackgroundTransparency=1,
	Text="🔗  discord.gg/NCEfg4rKPC",TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=12,
	TextXAlignment=Enum.TextXAlignment.Left,ZIndex=103},cc4)

-- ─────────────────────────────────────────────
--  DRAGGING
-- ─────────────────────────────────────────────
local dragging, dragStart, frameStart = false, nil, nil

header.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging=true; dragStart=input.Position; frameStart=mainFrame.Position
	end
end)
header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
end)
UserInputService.InputChanged:Connect(function(input, gp)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		tween(mainFrame, {Position = frameStart + UDim2.new(0,d.X,0,d.Y)}, 0.04)
	end
end)

-- ─────────────────────────────────────────────
--  STATE
-- ─────────────────────────────────────────────
local currentSongData = nil
local pythonRunning   = false
local songQueue       = {}
local isPlaying       = false
local isPaused        = false
local playbackMonitor = nil
local serviceMode     = "spotify"

-- ─────────────────────────────────────────────
--  LOGIC HELPERS
-- ─────────────────────────────────────────────
local function isPlayerWhitelisted(name)
	for _, n in ipairs(CONFIG.whitelist) do
		if n:lower()==name:lower() then return true end
	end
	return false
end

local function isSpotifyLink(l) return l:find("spotify.com") and l:find("track") end
local function isYouTubeLink(l) return l:find("youtube.com") or l:find("youtu.be") end
local function isAppleMusicLink(l) return l:find("music.apple.com") end

local function validateLink(link, mode)
	link = tostring(link):match("^%s*(.-)%s*$") or ""
	if link=="" then return false end
	if mode=="spotify" then return isSpotifyLink(link) end
	if mode=="youtube" then return isYouTubeLink(link) end
	if mode=="apple"   then return isAppleMusicLink(link) end
	return false
end

local function encodeUrl(url) return HttpService:UrlEncode(url) end

local function setStatus(text, color)
	color = color or C.success
	statusLabel.Text            = text
	statusLabel.TextColor3      = color
	statusDot.BackgroundColor3  = color
end

local function downloadAndCacheAlbumArt(imageUrl, trackId)
	if not (isfolder and makefolder and writefile and getcustomasset and isfile and readfile) then
		return nil
	end
	
	if not imageUrl or imageUrl == "" then
		return nil
	end
	
	if not isfolder("AlbumArt") then
		makefolder("AlbumArt")
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
	
	pcall(function()
		writefile(filePath, response)
	end)
	
	if isfile(filePath) then
		local ok, content = pcall(readfile, filePath)
		if ok and content and #content > 100 then
			return getcustomasset(filePath)
		end
	end
	
	return nil
end

local function updateAlbumArt(imagePath, imageUrl, trackId)
	
	if not imagePath or imagePath == "" or not isfile or not isfile(imagePath) then
		if imageUrl and imageUrl ~= "" then
			local cachedAsset = downloadAndCacheAlbumArt(imageUrl, trackId)
			if cachedAsset then
				local success, err = pcall(function()
					albumArt.Image = cachedAsset
					albumArt.ImageColor3 = Color3.new(1,1,1)
					albumArtGradient.Enabled = false
				end)
				if not success then
					albumArt.Image = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png"
					albumArt.ImageColor3 = C.textMuted
					albumArtGradient.Enabled = true
				end
				return
			end
		end
		
		albumArt.Image = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png"
		albumArt.ImageColor3 = C.textMuted
		albumArtGradient.Enabled = true
		return
	end
	
	local success, err = pcall(function()
		albumArt.Image = getcustomasset(imagePath)
		albumArt.ImageColor3 = Color3.new(1,1,1)
		albumArtGradient.Enabled = false
	end)
	
	if success then return end
	
	if imageUrl and imageUrl ~= "" then
		local cachedAsset = downloadAndCacheAlbumArt(imageUrl, trackId)
		if cachedAsset then
			local success2, err2 = pcall(function()
				albumArt.Image = cachedAsset
				albumArt.ImageColor3 = Color3.new(1,1,1)
				albumArtGradient.Enabled = false
			end)
			if not success2 then
				albumArt.Image = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png"
				albumArt.ImageColor3 = C.textMuted
				albumArtGradient.Enabled = true
			end
			return
		end
	end
	
	albumArt.Image = "rbxasset://textures/ui/InGameMenu/Modern/ic-album@2x.png"
	albumArt.ImageColor3 = C.textMuted
	albumArtGradient.Enabled = true
end

local function switchServiceMode(mode)
	serviceMode = mode
	if mode=="spotify" then
		modeButton.Text="Spotify"; modeButton.BackgroundColor3=C.green; modeButton.TextColor3=C.black
		serviceIcon.Text="S"; serviceIcon.BackgroundColor3=C.green
		inputBox.PlaceholderText="Paste a Spotify track link…"
		headerSub.Text="spotify · vc passthrough"
	elseif mode=="youtube" then
		modeButton.Text="YouTube"; modeButton.BackgroundColor3=C.youtube; modeButton.TextColor3=C.white
		serviceIcon.Text="▶"; serviceIcon.BackgroundColor3=C.youtube
		inputBox.PlaceholderText="Paste a YouTube video link…"
		headerSub.Text="youtube · vc passthrough"
	elseif mode=="apple" then
		modeButton.Text="Apple"; modeButton.BackgroundColor3=C.apple; modeButton.TextColor3=C.white
		serviceIcon.Text=""; serviceIcon.BackgroundColor3=C.apple
		inputBox.PlaceholderText="Paste an Apple Music link…"
		headerSub.Text="apple music · vc passthrough"
	end
	inputBox.Text=""
	setStatus("Switched to "..mode:sub(1,1):upper()..mode:sub(2), C.success)
end

-- ─────────────────────────────────────────────
--  QUEUE UI
-- ─────────────────────────────────────────────
local function updateQueueUI()
	for _, c in ipairs(queueList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i, song in ipairs(songQueue) do
		local item = make("Frame",{Size=UDim2.new(1,0,0,QUEUE_ITEM_H),BackgroundColor3=C.surfaceHigh,BorderSizePixel=0},queueList)
		corner(RADIUS.card,item); stroke(C.borderSub,1,0.3,item)
		make("TextLabel",{Size=UDim2.new(1,-52,0,22),Position=UDim2.new(0,10,0,8),BackgroundTransparency=1,
			Text=song.title,TextColor3=C.textPrimary,Font=Enum.Font.GothamSemibold,TextSize=12,
			TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},item)
		make("TextLabel",{Size=UDim2.new(1,-52,0,16),Position=UDim2.new(0,10,0,30),BackgroundTransparency=1,
			Text=song.artist,TextColor3=C.textMuted,Font=Enum.Font.Gotham,TextSize=10,
			TextXAlignment=Enum.TextXAlignment.Left},item)
		local pb = make("TextButton",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-40,0.5,-15),
			BackgroundColor3=C.green,TextColor3=C.black,Text="▶",Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0},item)
		corner(RADIUS.pill,pb)
		pb.MouseButton1Click:Connect(function()
			if not isPythonServerRunning() then setStatus("Python not running",C.error); return end
			local s=songQueue[i]; table.remove(songQueue,i); updateQueueUI()
			currentSongData=s; songTitle.Text=s.title; songArtist.Text=s.artist
			updateAlbumArt(s.image_path or "", s.image or "", s.track_id)
			setStatus("Playing: "..s.title, C.success)
			local ok=pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.play.."?path="..encodeUrl(s.path)) end)
			if ok then
				isPlaying=true; isPaused=false
				playButton.Visible=false; pauseButton.Visible=true; stopButton.Visible=true; playingDots.Visible=true
				startPlaybackMonitor()
			else
				setStatus("Failed to play",C.error)
			end
		end)
	end
	queueList.CanvasSize = UDim2.new(0,0,0,math.max(#songQueue*(QUEUE_ITEM_H+6),1))
	queueCountLabel.Text = tostring(#songQueue)
	queueFrame.Visible = #songQueue > 0
end

local function addToQueue(songData)
	table.insert(songQueue, songData); updateQueueUI()
end

-- ─────────────────────────────────────────────
--  SERVER CHECK & PLAYBACK MONITOR
-- ─────────────────────────────────────────────
local function isPythonServerRunning()
	local ok,res = pcall(function() return game:HttpGet(CONFIG.pythonServer..ENDPOINTS.health) end)
	if not ok or not res then return false end
	local s,data = pcall(function() return HttpService:JSONDecode(res) end)
	return s and type(data)=="table" and data.status=="ok"
end

local function playNextInQueue()
	if #songQueue>0 then
		local next=table.remove(songQueue,1); updateQueueUI()
		currentSongData=next; songTitle.Text=next.title; songArtist.Text=next.artist
		updateAlbumArt(next.image_path or "", next.image or "", next.track_id)
		setStatus("Playing: "..next.title, C.success)
		local ok=pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.play.."?path="..encodeUrl(next.path)) end)
		if ok then
			isPlaying=true; isPaused=false
			playButton.Visible=false; pauseButton.Visible=true; stopButton.Visible=true; playingDots.Visible=true
			startPlaybackMonitor()
		else
			setStatus("Failed to play next",C.error); isPlaying=false
			playButton.Visible=true; pauseButton.Visible=false; stopButton.Visible=false; playingDots.Visible=false
		end
	else
		isPlaying=false; isPaused=false
		playButton.Text="▶  Play"; playButton.Visible=false
		pauseButton.Visible=false; stopButton.Visible=false; playingDots.Visible=false
		songTitle.Text="No song loaded"; songArtist.Text="—"
		updateAlbumArt("", "", nil)
		setStatus("Queue finished", C.success)
	end
end

function startPlaybackMonitor()
	if playbackMonitor then return end
	playbackMonitor = task.spawn(function()
		while true do
			if not isPlaying then break end
			local ok,res = pcall(function() return game:HttpGet(CONFIG.pythonServer..ENDPOINTS.status) end)
			if not ok or not res then break end
			local sd; local dok=pcall(function() sd=HttpService:JSONDecode(res) end)
			local st = dok and type(sd)=="table" and sd.status or nil
			if st=="finished" or st=="stopped" then
				isPlaying=false; isPaused=false
				playButton.Text="▶  Play"; playButton.Visible=true
				pauseButton.Visible=false; stopButton.Visible=false; playingDots.Visible=false
				if #songQueue>0 then task.wait(0.5); playNextInQueue()
				else songTitle.Text="No song loaded"; songArtist.Text="—"; setStatus("Queue finished",C.success) end
				break
			end
			task.wait(1)
		end
		playbackMonitor = nil
	end)
end

-- ─────────────────────────────────────────────
--  CORE PLAYBACK FUNCTIONS
-- ─────────────────────────────────────────────
local lastChatSentAt = 0
local function safeSendChat(msg)
	local now=tick()
	if now-lastChatSentAt < CONFIG.chatRateLimit then return end
	lastChatSentAt=now
	pcall(function()
		local ch=TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if ch then ch:SendAsync(msg)
		else
			local ev=ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
			if ev and ev:FindFirstChild("SayMessageRequest") then ev.SayMessageRequest:FireServer(msg,"All") end
		end
	end)
end

local function callPythonBackend(link)
	link=tostring(link):match("^%s*(.-)%s*$") or ""
	if link=="" then setStatus("Enter a link first",C.warn); return false end
	if not isPythonServerRunning() then setStatus("Python server not running",C.error); return false end
	setStatus("Fetching song data…",C.warn)
	if not validateLink(link,serviceMode) then setStatus("Invalid "..serviceMode.." link",C.error); return false end
	local ep=ENDPOINTS.spotifyFetch.."?link="..encodeUrl(link)
	if serviceMode=="youtube" then ep=ENDPOINTS.youtubeFetch.."?link="..encodeUrl(link)
	elseif serviceMode=="apple" then ep=ENDPOINTS.appleFetch.."?link="..encodeUrl(link) end
	local ok,result=pcall(function() return game:HttpGet(CONFIG.pythonServer..ep) end)
	if ok and result then
		local sd; local dok=pcall(function() sd=HttpService:JSONDecode(result) end)
		if dok and sd then
			if not sd.error then
				songTitle.Text=sd.title or "Unknown Title"; songArtist.Text=sd.artist or "Unknown Artist"
				updateAlbumArt(sd.image_path or "", sd.image or "", sd.track_id)
				if isPlaying then
					addToQueue(sd); setStatus((sd.title or "Song").." added to queue (#"..#songQueue..")",C.success)
				else
					currentSongData=sd; playButton.Visible=true; pauseButton.Visible=false; stopButton.Visible=false
					setStatus("Loaded — press Play",C.success)
				end
				return true
			else
				setStatus(sd.error or "Failed to load song",C.error); return false
			end
		else
			local errMsg = tostring(result):match("^%s*(.-)%s*$") or ""
			if errMsg == "" or #errMsg > 80 or errMsg:find("<") then
				errMsg = "Failed to parse server response"
			end
			setStatus(errMsg,C.error); return false
		end
	else
		setStatus("Python server not responding",C.error); return false
	end
end

local function playSong()
	if not currentSongData then setStatus("No song loaded",C.error); return end
	if not isPythonServerRunning() then setStatus("Python server not running",C.error); return end
	if isPaused then
		isPaused=false; isPlaying=true
		playButton.Visible=false; pauseButton.Visible=true; stopButton.Visible=true; playingDots.Visible=true
		setStatus("Resumed: "..currentSongData.title, C.success)
		local ok=pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.resume) end)
		if not ok then setStatus("Failed to resume",C.error); isPaused=true; playButton.Visible=true; pauseButton.Visible=false
		else startPlaybackMonitor() end
		return
	end
	isPlaying=true; isPaused=false
	playButton.Visible=false; pauseButton.Visible=true; stopButton.Visible=true; playingDots.Visible=true
	setStatus("Playing: "..currentSongData.title, C.success)
	local ok=pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.play.."?path="..encodeUrl(currentSongData.path)) end)
	if not ok then
		setStatus("Failed to play",C.error); isPlaying=false; isPaused=false
		playButton.Visible=true; pauseButton.Visible=false; stopButton.Visible=false; playingDots.Visible=false
	else startPlaybackMonitor() end
end

local function pauseSong()
	if not isPlaying or isPaused then return end
	isPaused=true; isPlaying=false
	playButton.Visible=true; playButton.Text="▶  Resume"
	pauseButton.Visible=false; stopButton.Visible=true; playingDots.Visible=false
	setStatus("Paused: "..(currentSongData and currentSongData.title or ""), C.warn)
	local ok=pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.pause) end)
	if not ok then setStatus("Failed to pause",C.error); isPaused=false; playButton.Visible=false; pauseButton.Visible=true end
end

local function stopSong()
	pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.stop) end)
	isPlaying=false; isPaused=false; currentSongData=nil
	playButton.Text="▶  Play"; playButton.Visible=false
	pauseButton.Visible=false; stopButton.Visible=false; playingDots.Visible=false
	songTitle.Text="No song loaded"; songArtist.Text="—"
	updateAlbumArt("", "", nil)
	setStatus("Stopped", C.success)
end

local function skipSong()
	pcall(function() game:HttpGet(CONFIG.pythonServer..ENDPOINTS.stop) end)
	task.wait(0.2)
	if #songQueue>0 then
		setStatus("Skipping…",C.success); playNextInQueue()
		pcall(function() safeSendChat("⏭ Skipped to next song.") end)
	else
		stopSong(); pcall(function() safeSendChat("⏭ Skipped: queue empty.") end)
	end
end

local function searchAndPlaySong(songName)
	if not isPythonServerRunning() then setStatus("Python not running",C.error); return end
	setStatus("Searching: "..songName, C.warn)
	local ok,result=pcall(function() return game:HttpGet(CONFIG.pythonServer..ENDPOINTS.search.."?query="..encodeUrl(songName)) end)
	if not ok or not result then setStatus("Search failed",C.error); return end
	local sd; local dok=pcall(function() sd=HttpService:JSONDecode(result) end)
	if not dok or not sd or sd.error then
		setStatus("Song not found",C.error); pcall(function() safeSendChat("Song not found!") end); return
	end
	currentSongData=sd; songTitle.Text=sd.title or "Unknown"; songArtist.Text=sd.artist or "—"
	updateAlbumArt(sd.image_path or "", sd.image or "", sd.track_id)
	playButton.Visible=true; setStatus("Found — playing now…",C.success)
	pcall(function() safeSendChat("Found the song! Playing Now...") end)
	task.wait(0.5); playSong()
end

-- ─────────────────────────────────────────────
--  CHAT COMMANDS
-- ─────────────────────────────────────────────
local function handleChatCommand(speaker, message)
	message=(message or ""):match("^%s*(.-)%s*$") or ""
	local lower=message:lower()
	local function notWL() setStatus("Not whitelisted!",C.error); pcall(function() safeSendChat("You are not whitelisted!") end) end
	if lower:sub(1,6)=="!play " or lower=="!play" then
		if not isPlayerWhitelisted(speaker) then notWL(); return end
		local name=(message:sub(7) or ""):match("^%s*(.-)%s*$") or ""
		if name~="" then pcall(function() safeSendChat("Finding "..name.."...") end); searchAndPlaySong(name)
		else setStatus("Usage: !play [song name]",C.error); pcall(function() safeSendChat("Usage: !play [song name]") end) end
	elseif lower=="!stop"   then if not isPlayerWhitelisted(speaker) then notWL(); return end; stopSong(); pcall(function() safeSendChat("⏹ Stopped.") end)
	elseif lower=="!pause"  then if not isPlayerWhitelisted(speaker) then notWL(); return end; pauseSong(); pcall(function() safeSendChat("⏸ Paused.") end)
	elseif lower=="!resume" then
		if not isPlayerWhitelisted(speaker) then notWL(); return end
		if not isPaused then setStatus("Nothing is paused",C.error); pcall(function() safeSendChat("Nothing is paused.") end); return end
		playSong(); pcall(function() safeSendChat("▶ Resumed.") end)
	elseif lower=="!skip" then if not isPlayerWhitelisted(speaker) then notWL(); return end; skipSong(); pcall(function() safeSendChat("⏭ Skipped.") end)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	pcall(function() p.Chatted:Connect(function(m) handleChatCommand(p.Name,m) end) end)
end
Players.PlayerAdded:Connect(function(p)
	pcall(function() p.Chatted:Connect(function(m) handleChatCommand(p.Name,m) end) end)
end)
pcall(function()
	if TextChatService and TextChatService.OnIncomingMessage then
		TextChatService.OnIncomingMessage:Connect(function(msg)
			local t=msg and (msg.Text or msg.Message or "")
			local n=msg and (msg.FromSpeaker or msg.SenderName or (msg.TextSource and msg.TextSource.Name) or "")
			if t and n and t~="" and n~="" then handleChatCommand(n,t) end
		end)
	end
end)

-- ─────────────────────────────────────────────
--  WIRE UP BUTTONS
-- ─────────────────────────────────────────────
loadButton.MouseButton1Click:Connect(function() callPythonBackend(inputBox.Text) end)
inputBox.FocusLost:Connect(function(enter) if enter then callPythonBackend(inputBox.Text) end end)

modeButton.MouseButton1Click:Connect(function()
	if serviceMode=="spotify" then switchServiceMode("youtube")
	elseif serviceMode=="youtube" then switchServiceMode("apple")
	else switchServiceMode("spotify") end
end)

playButton.MouseButton1Click:Connect(function()
	if not isPythonServerRunning() then setStatus("Python not running",C.error); return end
	playSong()
end)

local pauseDb=false
pauseButton.MouseButton1Click:Connect(function()
	if pauseDb then return end; pauseDb=true
	if not isPythonServerRunning() then setStatus("Python not running",C.error); pauseDb=false; return end
	pauseSong(); task.wait(0.3); pauseDb=false
end)

local stopDb=false
stopButton.MouseButton1Click:Connect(function()
	if stopDb then return end; stopDb=true
	if not isPythonServerRunning() then setStatus("Python not running",C.error); stopDb=false; return end
	stopSong(); task.wait(0.3); stopDb=false
end)

queueButton.MouseButton1Click:Connect(function()
	queueFrame.Visible = not queueFrame.Visible
end)

closeBtn.MouseButton1Click:Connect(function() creditsModal.Visible=false end)
creditsButton.MouseButton1Click:Connect(function() creditsModal.Visible = not creditsModal.Visible end)

-- ─────────────────────────────────────────────
--  INIT
-- ─────────────────────────────────────────────
if isPythonServerRunning() then
	setStatus("Ready", C.success); pythonRunning=true
else
	setStatus("Python offline  ·  run spotify_server.py", C.error)
end
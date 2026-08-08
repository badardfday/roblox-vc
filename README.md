> [!WARNING]
> We are not responsible for any actions taken with this tool. This includes account or voice chat bans issued by Roblox. Playing inappropriate or explicit music violates Roblox's Terms of Service and **can get you VC banned.** Use at your own risk.

> [!IMPORTANT]
> This tool does **NOT** support mobile due to limited access to audio drivers.

# 🎵 Roblox VC Music Bot

A multi-platform music player for Roblox Voice Chat. Stream songs from **Spotify**, **YouTube**, and **Apple Music** directly through your microphone using a local Python server and a virtual audio cable.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/badardfday/roblox-vc/main/main.lua"))()
```

## ✨ Features

- **Multi-Platform**: Fetch and play songs from Spotify, YouTube, and Apple Music
- **YouTube Audio Streaming**: Downloads full songs from YouTube via yt-dlp
- **Album Art**: Automatically downloads and displays cover art / thumbnails in the UI
- **Queue System**: Add multiple songs to a queue with auto-play on finish
- **Play / Pause / Resume / Stop**: Full playback controls with seek support
- **Chat Commands**: Use `!play`, `!pause`, `!resume`, `!stop`, `!skip` in-game
- **Whitelist System**: Control who can use chat commands

## 📋 Prerequisites

- **Roblox Executor** with HTTP support (Volt, Solara, Velocity, etc)
- **Python 3.8+**
- **FFmpeg / FFplay** (for audio playback)
- **Spotify Developer Account** (for Spotify features — optional if only using YouTube/Apple Music)
- **VB-Audio Virtual Cable** (to route audio into Roblox VC)

## 🚀 Installation

### Step 1: Install Python Dependencies

```bash
pip install flask spotipy yt-dlp requests python-dotenv
```

### Step 2: Install FFmpeg

**Windows (Chocolatey):**
```bash
choco install ffmpeg
```

**Or download from:** https://ffmpeg.org/download.html

Verify installation:
```bash
ffmpeg -version
ffplay -version
```

### Step 3: Configure Spotify API Credentials (Optional)

> Only required if you want to use Spotify links. YouTube and Apple Music work without this.

1. Go to https://developer.spotify.com/dashboard
2. Log in or create a Spotify account
3. Create a new app
4. Copy your **Client ID** and **Client Secret**
5. Create a `.env` file in the project root:

```env
SPOTIPY_CLIENT_ID=your_client_id_here
SPOTIPY_CLIENT_SECRET=your_client_secret_here
```

### Step 4: (Optional) Export YouTube Cookies

To avoid bot detection when downloading from YouTube:

1. Install a cookie export extension for your browser
2. Go to youtube.com and log in
3. Export cookies to a file named `cookies.txt`
4. Place `cookies.txt` in the same folder as `spotify_server.py`

### Step 5: Start the Python Server

```bash
python spotify_server.py
```

You should see:
```
🎵 Music Bot Server running on http://localhost:5000
Supported services: Spotify, Apple Music, YouTube
```

### Step 6: Run the Lua Script

1. Open your Roblox executor
2. Execute `main.lua` or the loadstring above
3. The UI will appear in the center of your screen

## 🎮 Usage Guide

### Loading a Song

Use the **mode button** in the header to switch between Spotify, YouTube, and Apple Music.

**Spotify:**
1. Switch mode to **Spotify**
2. Paste a Spotify track link
3. Click **Load** → Click **▶ Play**

**YouTube:**
1. Switch mode to **YouTube**
2. Paste a YouTube video link
3. Click **Load** → Click **▶ Play**

**Apple Music:**
1. Switch mode to **Apple**
2. Paste an Apple Music song link
3. Click **Load** → Click **▶ Play**

### Setting Up Audio Passthrough

1. Install [VB-Audio Virtual Cable](https://vb-audio.com/Cable/)
2. Set **CABLE Output** as your **microphone input** in Roblox settings
3. Set **CABLE Input** as your **default playback device** in Windows Sound settings
4. Click the **🔇 VC Bypass** button in the UI header to apply the voice chat bypass

### Chat Commands

| Command | Action |
|---------|--------|
| `!play [song name]` | Search and play a song by name |
| `!pause` | Pause current playback |
| `!resume` | Resume paused playback |
| `!stop` | Stop and clear current song |
| `!skip` | Skip to next song in queue |

> Only whitelisted players can use chat commands.

### Playback Controls

| Button | Action |
|--------|--------|
| ▶ Play | Start playing the loaded song |
| ▶ Resume | Resume from where you paused |
| ⏸ Pause | Pause current playback |
| ⏹ Stop | Stop and clear current song |

### Queue Management

- Click **≡ Queue** to toggle the queue panel
- Songs added while another is playing are auto-queued
- Click the **▶** button on a queue item to play it immediately
- Queue auto-plays when the current song finishes

## ⚙️ Configuration

### Whitelist Users

Edit the whitelist table in `main.lua`:

```lua
local CONFIG = {
    whitelist = {"lolwhenme", "your_username"},
    ...
}
```

### Change Server URL

If running the Python server on a different machine or port:

```lua
pythonServer = "http://192.168.1.100:5000"
```

### Adjust Audio Quality

In `spotify_server.py`, change the MP3 bitrate:

```python
"preferredquality": "320"  -- Options: 128, 192, 256, 320
```

## 🐛 Troubleshooting

### "Python server not running"
- Ensure `python spotify_server.py` is running in a terminal
- Check that port 5000 is not blocked by a firewall
- Verify HTTP requests are enabled in your executor

### Album art not loading
- The server downloads and caches album art locally, then serves it via `http://localhost:5000/files/...`
- Delete the `AlbumArt` folder in your executor's workspace to clear corrupted cache
- Check the Python server console for download errors

### FFmpeg not found
- Make sure FFmpeg and FFplay are installed and in your system PATH
- Test: `ffplay -version` in command prompt

### Songs not downloading
- Check YouTube is accessible from your machine
- Export YouTube cookies (see Installation Step 4)
- Update yt-dlp: `pip install -U yt-dlp`

### Apple Music not working
- Apple Music uses a scraped developer token from Apple's web player
- If it breaks, the JS bundle structure may have changed — open an issue

## 📂 Project Structure

```
roblox-vc-spotify/
├── main.lua              # Roblox client script (UI + playback logic)
├── spotify_server.py     # Flask server (fetches metadata, downloads audio, serves files)
├── spotify_backend.py    # Standalone CLI backend (optional)
├── loadstring.lua        # Remote loadstring wrapper
├── .env                  # Spotify API credentials (not committed)
├── requirements.txt      # Python dependencies
├── files/                # Cached audio and album art (auto-created)
│   └── album_art/        # Downloaded cover images
└── README.md
```

## 📞 Support

If you encounter issues:

1. Check that all prerequisites are installed
2. Verify the Python server is running: `http://localhost:5000/health`
3. Check your Roblox executor has HTTP enabled
4. Check the Python server console output for error details

**Discord:** [discord.gg/NCEfg4rKPC](https://discord.gg/NCEfg4rKPC)

## 📜 License

This project is for personal and educational use. Respect Spotify, YouTube, and Apple Music's terms of service.

---

**Made by [borthdayzz](https://github.com/borthdayzz)** · v3

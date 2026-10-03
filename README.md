# Roblox VC Music Player

A Roblox Voice Chat music player with a local Python backend. The Roblox UI requests track metadata and audio from the backend; `ffplay` plays the audio through the computer's selected output device. A virtual audio cable can route that output to Roblox Voice Chat.

> [!WARNING]
> Mobile is not supported. This setup requires desktop audio routing and a running Python server.
>
> Use only audio you have the right to play, and follow Roblox's Community Standards and Voice Chat rules. Inappropriate or unauthorized audio may result in moderation, including a Voice Chat ban. Use this project at your own risk.

## Features

- Load tracks from Spotify, YouTube, and Apple Music links.
- Search by song title; searches use YouTube and load the first result.
- Play, pause, resume, stop, and skip tracks.
- View album art, playback status, elapsed time, and duration.
- Seek through a track with the timeline when its duration is available.
- Queue tracks, play a queued track immediately, move it up or down, remove it, or clear the queue. The next queued track starts when playback finishes.
- Switch between Spotify, YouTube, Apple Music, and Auto link detection.
- Choose a UI theme: Midnight, Ocean, Sunset, or Light.
- Manage the chat-command whitelist and Python server address in **About & Settings**.
- Minimize the player, hide it, and restore it with **Right Shift**.

## Requirements

- Windows desktop
- Python and the packages listed in [`requirements.txt`](./requirements.txt)
- FFmpeg tools, including **ffplay** for playback. **ffprobe** is recommended for accurate track durations.
- A Roblox client/executor with HTTP request support
- Optional: VB-Audio Virtual Cable (or a comparable virtual audio cable) to route audio to the Roblox microphone
- Optional: Spotify Developer credentials to load Spotify links

## Setup

### 1. Install Python dependencies

From the project folder, run:

```powershell
python -m pip install -r requirements.txt
```

### 2. Install FFmpeg

Install FFmpeg for Windows and make sure `ffplay` is available on your `PATH`. `ffprobe` is optional, but enables duration detection from downloaded audio files.

Verify the tools in PowerShell:

```powershell
ffplay -version
ffprobe -version
```

### 3. Configure Spotify (optional)

Spotify credentials are only needed for Spotify links. Create a Spotify app in the Spotify Developer Dashboard, then set the credentials in a `.env` file in the project folder:

```env
SPOTIPY_CLIENT_ID=your_client_id
SPOTIPY_CLIENT_SECRET=your_client_secret
```

Keep `.env` private; do not publish or share your credentials. YouTube links and title searches do not require Spotify credentials. Apple Music links use the backend's Apple Music metadata lookup.

### 4. Start the Python server

In the project folder, run:

```powershell
python start_server.py
```

The launcher checks the `main` branch of this repository for a newer `spotify_server.py`, validates its Python syntax, backs up the current file as `spotify_server.py.bak`, and installs the update before starting the server. Updates are checked each time you use the launcher; the running server is not interrupted to install updates.

If the GitHub check fails, the existing server version is started. If Git detects local changes to `spotify_server.py`, the launcher skips the update to protect those changes. Once the updater has installed a version, it records its checksum and can continue updating that version on future starts. To run the backend without checking for updates, use `python spotify_server.py`.

The default address is `http://localhost:5000`. Check that it responds by opening [http://localhost:5000/health](http://localhost:5000/health); a running server returns `{"status":"ok"}`.

The server's address can also be changed in **About & Settings → Settings** in the player. By default, the backend binds to localhost. Do not expose this unauthenticated local-control server to the public internet.

### 5. Run the Roblox UI

Run `main.lua` in a compatible desktop environment with HTTP requests enabled. The player checks the Python server before enabling playback controls.

The published loadstring is:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/badardfday/roblox-vc/main/main.lua"))()
```

Only run scripts you trust and have reviewed.

## Audio routing

`ffplay` outputs audio through the computer's current default playback device. To route it into Voice Chat with VB-Audio Virtual Cable:

1. Install VB-Audio Virtual Cable.
2. Set **CABLE Input** as the Windows playback/output device so `ffplay` sends audio into the cable.
3. Select **CABLE Output** as the microphone/input device in Roblox.
4. Start playback and confirm the correct input and output devices are selected.

Device names or Windows sound settings may vary. Do not play disruptive or inappropriate audio in Voice Chat.

## Using the player

### Load and play tracks

- Paste a supported Spotify, YouTube, or Apple Music link into the input and select **Load**. The player detects the link type automatically; the **Auto** mode can also be selected.
- Type a song title and select **Load** to search YouTube. The backend downloads the first result.
- If a track is already playing, newly loaded tracks are added to the queue. Otherwise, the track is loaded and can be started with **Play**.

Spotify links provide metadata through Spotify and use the backend's YouTube audio lookup for playback; this project does not stream audio from Spotify. Apple Music is used for metadata lookup, and playback audio is fetched separately by the backend.

### Playback controls

| Control | Action |
| --- | --- |
| Play / Pause | Start a loaded track or toggle playback |
| Stop | Stop playback and clear the current track |
| Skip | Stop the current track and play the next queued track |
| Timeline | Click or drag to seek when a duration is known |
| Queue | Open or close the queue panel |

Seeking restarts `ffplay` at the chosen position. Track duration is read from the downloaded audio with `ffprobe` when available, or uses source metadata as a fallback. If no duration is known, the timeline cannot seek.

### Queue

- Use the queue button in the player to open the queue.
- Select **Play** on an item to play it immediately.
- Use **↑ / ↓** to reorder items.
- Use **×** to remove one item, or **Clear** to empty the queue.
- Queued items are held in memory and are cleared when the script is restarted.

### About & Settings

Open the **About & Settings** panel from the player header:

- **Appearance:** choose Midnight, Ocean, Sunset, or Light. The selected theme is saved locally when file persistence is available.
- **Python server:** enter the server base URL, select **Test** to check its `/health` endpoint, and select **Save** to use and persist it. Example: `http://localhost:5000`.
- **Whitelist manager:** add usernames or UserIds permitted to use chat commands, and remove entries from the list. The local player is always permitted. Whitelist changes are saved to `MusicBot_Whitelist.json` when file persistence is available.

If the server runs on another machine, use a URL reachable from the machine running the Roblox client and configure the backend to listen on an appropriate trusted network interface. Use a private network and firewall; the backend does not provide authentication.

## Chat commands

Whitelisted users can use these commands in Roblox chat:

| Command | Action |
| --- | --- |
| `!play <song or link>` | Search for a title or load a supported music link |
| `!pause` | Pause playback |
| `!resume` | Resume playback |
| `!stop` | Stop and clear the current track |
| `!skip` | Skip to the next queued track |

The whitelist is managed locally in the player settings. Commands depend on the Roblox chat system being available and may be subject to the script's chat rate limit.

## Troubleshooting

### The player says the Python server is offline

- Start the backend with `python spotify_server.py`.
- Visit `http://localhost:5000/health` on the machine running the backend.
- In **About & Settings → Settings**, confirm the server URL, then select **Test** and **Save**.
- If the backend is on another machine, confirm the client can reach that machine and that the server/firewall configuration permits the connection.
- Confirm HTTP requests are enabled in the client environment.

### Playback does not start or there is no sound

- Confirm `ffplay -version` works in PowerShell and that FFmpeg is on `PATH`.
- Check the selected Windows playback device. For Voice Chat routing, select the virtual cable's playback device for Windows and its recording device in Roblox.
- Check the backend terminal for download or playback errors.

### Seeking is unavailable or duration is missing

- Seeking requires a known duration.
- Install FFprobe and ensure it is on `PATH`, then restart the backend. Source metadata may provide a duration if probing is unavailable.

### YouTube downloads fail

- Check that YouTube is reachable from the backend machine.
- Update the dependencies with `python -m pip install -r requirements.txt --upgrade`.
- If YouTube requires authentication for a video, an exported `cookies.txt` may be placed beside `spotify_server.py`. Keep cookies private and do not commit or share them.

### Spotify links fail

- Confirm `SPOTIPY_CLIENT_ID` and `SPOTIPY_CLIENT_SECRET` are set correctly in `.env`.
- Restart the Python server after changing `.env`.
- Confirm the Spotify track is available in the region/account context used by the API.

### Album art does not load

- Check that the Python server is reachable and review its console output.
- Album art is cached by the client when supported file functions are available; otherwise, the UI uses its fallback artwork.

## Project files

```text
main.lua             Roblox player UI and controls
spotify_server.py    Flask backend for metadata, downloads, playback, and local file serving
start_server.py      Startup updater and launcher for spotify_server.py
spotify_backend.py   Standalone backend script
loadstring.lua       Loader script
requirements.txt     Python dependencies
files/               Downloaded audio and cached album art (created by the backend)
.env                 Optional Spotify credentials (create locally; do not share)
```

## Support

- Check the troubleshooting section and the Python server console output.
- Confirm the backend health endpoint responds: `http://localhost:5000/health`.
- Community: [discord.gg/NCEfg4rKPC](https://discord.gg/NCEfg4rKPC)

## License

See [`LICENSE`](./LICENSE). Use this software and third-party services in accordance with their applicable terms and policies.

---

Made by [borthdayzz](https://github.com/borthdayzz).

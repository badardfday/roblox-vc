from flask import Flask, request, jsonify, send_from_directory
from pathlib import Path
import json
import subprocess
import threading
import time
import os
import requests
from urllib.parse import urlparse, parse_qs
import shutil
import logging
import hashlib
from pathlib import Path
try:
	from dotenv import load_dotenv
	load_dotenv()
except Exception:
	env_path = Path(__file__).parent / ".env"
	if env_path.exists():
		with open(env_path, "r", encoding="utf-8") as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith("#"):
					continue
				if "=" in line:
					k, v = line.split("=", 1)
					os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
		print("Loaded .env from project directory")

try:
	import spotipy
	from spotipy.oauth2 import SpotifyClientCredentials
	import yt_dlp
except ImportError:
	print("Install: pip install flask spotipy yt-dlp")
	exit(1)

apple_music_token = None
apple_music_token_time = 0
APPLE_MUSIC_TOKEN_CACHE_TIME = 3600

current_process = None
is_paused = False
playback_lock = threading.Lock()
playback_start_time = None   # timestamp when playback started (adjusted for seeks)
paused_offset = 0.0          # seconds into track where we paused
current_path = None          # currently playing file path

app = Flask(__name__)

WORKSPACE_FOLDER = Path(__file__).parent / "files"
WORKSPACE_FOLDER.mkdir(parents=True, exist_ok=True)

ALBUM_ART_FOLDER = Path(__file__).parent / "files" / "album_art"
ALBUM_ART_FOLDER.mkdir(parents=True, exist_ok=True)

@app.after_request
def add_cors_headers(response):
	response.headers['Access-Control-Allow-Origin'] = '*'
	response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
	response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
	response.headers['Cache-Control'] = 'public, max-age=86400'
	return response

SPOTIFY_CLIENT_ID = os.getenv("SPOTIPY_CLIENT_ID") or os.getenv("SPOTIFY_CLIENT_ID")
SPOTIFY_CLIENT_SECRET = os.getenv("SPOTIPY_CLIENT_SECRET") or os.getenv("SPOTIFY_CLIENT_SECRET")

HOST = os.getenv("HOST", "localhost")
PORT = int(os.getenv("PORT", "5000"))

def check_dependencies():
	"""Ensure required external executables are available."""
	missing = []
	if shutil.which("ffplay") is None and shutil.which("ffmpeg") is None:
		missing.append("ffplay/ffmpeg")
	if missing:
		logging.error("Missing dependencies: %s. Install ffmpeg/ffplay and ensure they're in PATH.", ", ".join(missing))
		print(f"Error: Missing dependencies: {', '.join(missing)}. Install ffmpeg/ffplay and ensure they're in PATH.")
		exit(1)

check_dependencies()


def download_and_cache_album_art(image_url, track_id):
	"""Download album art from URL and cache it locally"""
	if not image_url or not track_id:
		return None
	
	safe_id = "".join(c for c in str(track_id) if c.isalnum() or c in ('-', '_'))
	
	try:
		response = requests.head(image_url, timeout=5, allow_redirects=True)
		content_type = response.headers.get('content-type', 'image/png').lower()
		
		ext_map = {
			'image/png': '.png',
			'image/jpeg': '.jpg',
			'image/jpg': '.jpg',
			'image/webp': '.webp',
			'image/gif': '.gif'
		}
		
		ext = '.png'  # default
		for ct, extension in ext_map.items():
			if ct in content_type:
				ext = extension
				break
		
		image_path = ALBUM_ART_FOLDER / f"{safe_id}{ext}"
		
		if image_path.exists():
			print(f"Album art already cached: {image_path}")
			return str(image_path)
		
		response = requests.get(image_url, timeout=10)
		response.raise_for_status()
		
		if response.status_code == 200 and response.content:
			image_path.parent.mkdir(parents=True, exist_ok=True)
			with open(image_path, 'wb') as f:
				f.write(response.content)
			print(f"Downloaded and cached album art: {image_path} (size: {len(response.content)} bytes)")
			return str(image_path)
		else:
			print(f"Failed to download album art: HTTP {response.status_code}")
	except Exception as e:
		print(f"Failed to download album art from {image_url}: {e}")
		import traceback
		traceback.print_exc()
	
	return None


def clean_youtube_url(url):
	"""Extract video ID from YouTube URL and return clean URL, removing extra parameters"""
	try:
		parsed_url = urlparse(url)
		if "youtube.com" in parsed_url.netloc:
			query_params = parse_qs(parsed_url.query)
			if "v" in query_params:
				video_id = query_params["v"][0]
				return f"https://www.youtube.com/watch?v={video_id}"
		elif "youtu.be" in parsed_url.netloc:
			video_id = parsed_url.path.lstrip("/").split("?")[0]
			return f"https://www.youtube.com/watch?v={video_id}"
	except Exception as e:
		print(f"URL cleaning error: {e}")
	
	return url

def get_spotify_client():
	"""Initialize Spotify client"""
	auth_manager = SpotifyClientCredentials(
		client_id=SPOTIFY_CLIENT_ID,
		client_secret=SPOTIFY_CLIENT_SECRET
	)
	return spotipy.Spotify(auth_manager=auth_manager)

def get_spotify_client_with_creds(client_id, client_secret):
	"""Return a Spotify client initialized with provided credentials."""
	if not client_id or not client_secret:
		raise ValueError("Missing Spotify credentials")
	auth_manager = SpotifyClientCredentials(client_id=client_id, client_secret=client_secret)
	return spotipy.Spotify(auth_manager=auth_manager)

def extract_track_id(spotify_link):
	"""Extract track ID from Spotify link"""
	parsed_url = urlparse(spotify_link)
	if "spotify.com" in parsed_url.netloc:
		if "track" in parsed_url.path:
			return parsed_url.path.split("/")[-1].split("?")[0]
	return None

def fetch_song_data(spotify_link, client_id=None, client_secret=None):
	"""Fetch song metadata from Spotify"""
	try:
		sp = get_spotify_client_with_creds(client_id or SPOTIFY_CLIENT_ID, client_secret or SPOTIFY_CLIENT_SECRET)
		track_id = extract_track_id(spotify_link)
		
		if not track_id:
			return {"error": "Invalid Spotify link"}
		
		track = sp.track(track_id)
		
		song_data = {
			"title": track["name"],
			"artist": ", ".join([artist["name"] for artist in track["artists"]]),
			"image": track["album"]["images"][0]["url"] if track["album"]["images"] else "",
			"preview_url": track["preview_url"],
			"track_id": track_id
		}
		
		return song_data
	except Exception as e:
		return {"error": str(e)}

def get_apple_music_token():
	"""Extract Apple Music token from Apple Music website"""
	global apple_music_token, apple_music_token_time
	
	if apple_music_token and (time.time() - apple_music_token_time) < APPLE_MUSIC_TOKEN_CACHE_TIME:
		return apple_music_token
	
	try:
		main_page_url = "https://beta.music.apple.com"
		headers = {
			"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
		}
		
		response = requests.get(main_page_url, headers=headers, timeout=10)
		if response.status_code != 200:
			return None
		
		import re
		js_file_match = re.search(r"/assets/index[~-][^/]+\.js", response.text)
		if not js_file_match:
			print("Could not find index JS file")
			return None
		
		js_file_uri = js_file_match.group(0)
		js_file_url = main_page_url + js_file_uri
		
		js_response = requests.get(js_file_url, headers=headers, timeout=10)
		if js_response.status_code != 200:
			return None
		
		token_match = re.search(r"eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_=]*", js_response.text)
		if not token_match:
			print("Could not extract token from JS file")
			return None
		
		apple_music_token = token_match.group(0)
		apple_music_token_time = time.time()
		print(f"Apple Music token extracted successfully")
		return apple_music_token
	
	except Exception as e:
		print(f"Apple Music token extraction error: {e}")
		return None

def extract_track_id_apple(apple_music_link):
	"""Extract track ID from Apple Music link
	Examples:
	- https://music.apple.com/us/album/song-name/id?i=trackid
	- https://music.apple.com/us/song/song-name/id
	"""
	try:
		parsed_url = urlparse(apple_music_link)
		if "music.apple.com" not in parsed_url.netloc:
			return None
		
		query_params = parse_qs(parsed_url.query)
		if "i" in query_params:
			return query_params["i"][0]
		
		path_parts = parsed_url.path.split("/")
		if "song" in path_parts:
			song_index = path_parts.index("song")
			if song_index + 2 < len(path_parts):
				return path_parts[-1]
		
		return None
	except Exception as e:
		print(f"Apple Music ID extraction error: {e}")
		return None

def fetch_song_data_apple(apple_music_link):
	"""Fetch song metadata from Apple Music"""
	try:
		token = get_apple_music_token()
		if not token:
			return {"error": "Could not retrieve Apple Music token"}
		
		track_id = extract_track_id_apple(apple_music_link)
		if not track_id:
			return {"error": "Invalid Apple Music link"}
		
		storefront = "us"
		parsed_url = urlparse(apple_music_link)
		path_parts = parsed_url.path.split("/")
		if len(path_parts) > 1 and len(path_parts[1]) == 2:
			storefront = path_parts[1]
		
		amp_api_url = f"https://amp-api.music.apple.com/v1/catalog/{storefront}/songs/{track_id}"
		
		query_params = {
			"include": "albums,artists,explicit",
			"extend": "extendedAssetUrls",
			"l": ""
		}
		
		headers = {
			"Authorization": f"Bearer {token}",
			"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
			"Origin": "https://music.apple.com"
		}
		
		response = requests.get(amp_api_url, params=query_params, headers=headers, timeout=10)
		if response.status_code != 200:
			return {"error": f"Apple Music API error: {response.status_code}"}
		
		data = response.json()
		if "data" not in data or len(data["data"]) == 0:
			return {"error": "Song not found"}
		
		song = data["data"][0]
		
		title = song.get("attributes", {}).get("name", "Unknown")
		artist_names = []
		
		if "relationships" in song and "artists" in song["relationships"]:
			for artist in song["relationships"]["artists"].get("data", []):
				artist_name = artist.get("attributes", {}).get("name")
				if artist_name:
					artist_names.append(artist_name)
		
		if not artist_names and "attributes" in song:
			composer = song["attributes"].get("composerName")
			if composer:
				artist_names.append(composer)
		
		artist = ", ".join(artist_names) if artist_names else "Unknown Artist"
		
		if not artist_names:
			print(f"Warning: Could not extract artist for song {track_id}. API response: {song.get('attributes', {})}")
		
		artwork = song.get("attributes", {}).get("artwork", {})
		artwork_url = artwork.get("url", "")
		if artwork_url:
			artwork_url = artwork_url.replace("{w}", "300").replace("{h}", "300")
		
		song_data = {
			"title": title,
			"artist": artist,
			"image": artwork_url,
			"track_id": track_id,
			"url": apple_music_link
		}
		
		return song_data
	except Exception as e:
		return {"error": str(e)}


def get_ydl_opts(quiet=False):
	"""Get common yt-dlp options"""
	cookie_file = Path(__file__).parent / "cookies.txt"
	return {
		"format": "bestaudio[ext=m4a]/bestaudio/best",
		"quiet": quiet,
		"no_warnings": quiet,
		"socket_timeout": 30,
		"http_headers": {
			"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
			"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
			"Accept-Language": "en-US,en;q=0.5",
			"Accept-Encoding": "gzip, deflate",
			"Connection": "keep-alive",
			"Upgrade-Insecure-Requests": "1",
			"Sec-Fetch-Dest": "document",
			"Sec-Fetch-Mode": "navigate",
			"Sec-Fetch-Site": "none",
			"Cache-Control": "max-age=0"
		},
		"cookiefile": str(cookie_file) if cookie_file.exists() else None,
		"skip_unavailable_fragments": True,
		"extractor_args": {"youtube": {"skip": ["hls", "dash"], "player_client": ["web", "android"]}},
	}


def download_audio(video_id, search_query=None, is_url=False):
	"""Download audio from YouTube using yt-dlp. Returns path to mp3 or None"""
	try:
		output_path = WORKSPACE_FOLDER / f"{video_id}.mp3"
		
		if output_path.exists():
			return str(output_path)
		
		cookie_file = Path(__file__).parent / "cookies.txt"
		download_opts = get_ydl_opts(quiet=False)
		download_opts["postprocessors"] = [{
			"key": "FFmpegExtractAudio",
			"preferredcodec": "mp3",
			"preferredquality": "192",
		}]
		download_opts["outtmpl"] = str(WORKSPACE_FOLDER / f"{video_id}")
		
		with yt_dlp.YoutubeDL(download_opts) as ydl:
			if is_url:
				print(f"Downloading: {search_query}")
				ydl.extract_info(search_query, download=True)
			else:
				print(f"Downloading: {search_query}")
				ydl.extract_info(f"ytsearch:{search_query}", download=True)
		
		return str(output_path)
	except Exception as e:
		print(f"Download error: {e}")
		return None


def download_song(track_info):
	"""Download full song from YouTube using yt-dlp"""
	track_id = track_info["track_id"]
	title = track_info["title"]
	artist = track_info["artist"]
	search_query = f"{artist} - {title}"
	return download_audio(track_id, search_query, is_url=False)

def download_image(image_url):
	"""Download image from URL and save to workspace folder. Returns filename or None"""
	try:
		response = requests.get(image_url, timeout=10)
		if response.status_code != 200:
			return None
		
		filename = hashlib.md5(image_url.encode()).hexdigest() + ".jpg"
		output_path = WORKSPACE_FOLDER / filename
		
		output_path.parent.mkdir(parents=True, exist_ok=True)
		with open(output_path, "wb") as f:
			f.write(response.content)
		
		return filename
	except Exception as e:
		print(f"Image download error: {e}")
		return None

@app.route("/health", methods=["GET"])
def health():
	"""Check if server is running"""
	return jsonify({"status": "ok"}), 200

@app.route("/files/<path:path>", methods=["GET"])
def serve_files(path):
	"""Serve local files (like album art and audio cache)"""
	return send_from_directory(WORKSPACE_FOLDER, path)





@app.route("/spotify/fetch", methods=["GET"])
def spotify_fetch():
	"""Fetch song data from Spotify link and download from YouTube"""
	if not SPOTIFY_CLIENT_ID or not SPOTIFY_CLIENT_SECRET:
		return jsonify({"error": "Spotify credentials not configured. Set SPOTIPY_CLIENT_ID and SPOTIPY_CLIENT_SECRET environment variables to use Spotify features."}), 400
	
	link = request.args.get("link")
	client_id = request.args.get("client_id") or SPOTIFY_CLIENT_ID
	client_secret = request.args.get("client_secret") or SPOTIFY_CLIENT_SECRET
	
	if not link:
		return jsonify({"error": "No link provided"}), 400
	
	song_data = fetch_song_data(link, client_id=client_id, client_secret=client_secret)
	if "error" in song_data:
		return jsonify(song_data), 400
	
	audio_path = download_song(song_data)
	song_data["path"] = audio_path
	
	if song_data.get("image"):
		album_art_path = download_and_cache_album_art(song_data["image"], song_data.get("track_id"))
		if album_art_path:
			try:
				rel_path = str(Path(album_art_path).relative_to(Path(__file__).parent))
				rel_path = rel_path.replace('\\', '/')
				song_data["image_path"] = rel_path
				song_data["image"] = f"http://{request.host}/{rel_path}"
				print(f"Returning relative image path: {rel_path} and local URL: {song_data['image']}")
			except ValueError:
				song_data["image_path"] = album_art_path
	
	return jsonify(song_data), 200

@app.route("/apple/fetch", methods=["GET"])
def apple_fetch():
	"""Fetch song data from Apple Music link and download from YouTube"""
	link = request.args.get("link")
	
	if not link:
		return jsonify({"error": "No link provided"}), 400
	
	song_data = fetch_song_data_apple(link)
	if "error" in song_data:
		return jsonify(song_data), 400
	
	audio_path = download_song(song_data)
	song_data["path"] = audio_path
	
	if song_data.get("image"):
		album_art_path = download_and_cache_album_art(song_data["image"], song_data.get("track_id"))
		if album_art_path:
			try:
				rel_path = str(Path(album_art_path).relative_to(Path(__file__).parent))
				rel_path = rel_path.replace('\\', '/')
				song_data["image_path"] = rel_path
				song_data["image"] = f"http://{request.host}/{rel_path}"
				print(f"Returning relative image path: {rel_path} and local URL: {song_data['image']}")
			except ValueError:
				song_data["image_path"] = album_art_path
	
	return jsonify(song_data), 200


@app.route("/youtube/fetch", methods=["GET"])
def youtube_fetch():
	"""Fetch song data from YouTube link"""
	link = request.args.get("link")
	
	if not link:
		return jsonify({"error": "No link provided"}), 400
	
	link = clean_youtube_url(link)
	print(f"Cleaned link: {link}")
	
	try:
		print(f"Fetching YouTube video: {link}")
		
		ydl_opts = get_ydl_opts(quiet=False)
		
		try:
			with yt_dlp.YoutubeDL(ydl_opts) as ydl:
				info = ydl.extract_info(link, download=False)
				
				if not info:
					return jsonify({"error": "Could not fetch video information"}), 404
				
				video_id = info.get("id", "unknown")
				title = info.get("title", "Unknown")
				thumbnail_url = info.get("thumbnail", "")
				
				audio_path = download_audio(video_id, link, is_url=True)
				if not audio_path:
					return jsonify({"error": "Failed to download audio"}), 500
				
				song_data = {
					"title": title,
					"artist": "YouTube",
					"image": thumbnail_url,
					"track_id": video_id,
					"path": audio_path
				}

				if thumbnail_url:
					album_art_path = download_and_cache_album_art(thumbnail_url, video_id)
					if album_art_path:
						try:
							rel_path = str(Path(album_art_path).relative_to(Path(__file__).parent))
							rel_path = rel_path.replace('\\', '/')
							song_data["image_path"] = rel_path
							song_data["image"] = f"http://{request.host}/{rel_path}"
						except ValueError:
							song_data["image_path"] = album_art_path

				print(f"Downloaded: {title}")
				return jsonify(song_data), 200

		except AttributeError as ae:
			# Workaround for yt-dlp bug with UrllibResponseAdapter
			if "_http_error" in str(ae):
				print(f"yt-dlp AttributeError (known bug): {ae}")
				return jsonify({"error": "YouTube API temporarily unavailable. Try again in a few moments."}), 429
			raise
		except yt_dlp.utils.DownloadError as ydl_error:
			print(f"yt-dlp download error: {ydl_error}")
			return jsonify({"error": f"YouTube error: {str(ydl_error)}"}), 400
		except Exception as ydl_error:
			print(f"yt-dlp extraction error: {ydl_error}")
			import traceback
			traceback.print_exc()
			# Return a more generic error if it's a network error
			if "HTTP" in str(ydl_error) or "400" in str(ydl_error):
				return jsonify({"error": "YouTube rejected the request. This may be due to rate limiting or region blocking. Try again later or check your internet connection."}), 429
			raise
	
	except Exception as e:
		print(f"YouTube fetch error: {e}")
		return jsonify({"error": str(e)}), 500

@app.route("/play", methods=["GET"])
def play():
	"""Play song through microphone (supports starting from paused offset)"""
	global current_process, is_paused, playback_start_time, paused_offset, current_path
	
	path = request.args.get("path")
	
	if not path or not os.path.exists(path):
		return jsonify({"error": "File not found"}), 400
	
	try:
		with playback_lock:
			if current_path != path:
				paused_offset = 0.0
				current_path = path
			
			if current_process:
				try:
					current_process.terminate()
					current_process.wait(timeout=1)
				except:
					try:
						current_process.kill()
					except:
						pass
				current_process = None
			

			cmd = ["ffplay", "-nodisp", "-autoexit"]
			if paused_offset and paused_offset > 0:
				cmd += ["-ss", str(paused_offset)]
			cmd += [path]
			
			current_process = subprocess.Popen(
				cmd,
				stdin=subprocess.PIPE,
				stdout=subprocess.PIPE,
				stderr=subprocess.PIPE
			)
			
			time.sleep(0.2)
			if current_process.poll() is not None:
				err = current_process.stderr.read().decode("utf-8", errors="ignore") if current_process.stderr else ""
				current_process = None
				return jsonify({"error": "ffplay failed to start", "stderr": err}), 500
			
			playback_start_time = time.time() - paused_offset
			is_paused = False
		
		print(f"Playing: {path} at {paused_offset:.2f}s")
		return jsonify({"status": "playing", "path": path, "offset": paused_offset}), 200
	except Exception as e:
		return jsonify({"error": str(e)}), 500

@app.route("/pause", methods=["GET"])
def pause():
	"""Pause current song by recording elapsed time and stopping playback"""
	global current_process, is_paused, playback_start_time, paused_offset, current_path
	
	if not current_process or current_process.poll() is not None:
		return jsonify({"error": "No song playing"}), 400
	
	try:
		with playback_lock:
			if playback_start_time:
				paused_offset = time.time() - playback_start_time
			else:
				paused_offset = 0.0
			
			try:
				current_process.terminate()
				current_process.wait(timeout=1)
			except:
				try:
					current_process.kill()
				except:
					pass
			current_process = None
			is_paused = True
		
		print(f"Paused at {paused_offset:.2f}s")
		return jsonify({"status": "paused", "offset": paused_offset}), 200
	except Exception as e:
		print(f"Pause error: {e}")
		return jsonify({"error": str(e)}), 500

@app.route("/resume", methods=["GET"])
def resume():
	"""Resume paused song by restarting ffplay at paused_offset"""
	global current_process, is_paused, playback_start_time, paused_offset, current_path
	
	if not current_path:
		return jsonify({"error": "No song to resume"}), 400
	
	if not os.path.exists(current_path):
		return jsonify({"error": "File not found"}), 400
	
	try:
		with playback_lock:
			if current_process and current_process.poll() is None:
				return jsonify({"status": "already_playing"}), 200
			
			cmd = ["ffplay", "-nodisp", "-autoexit"]
			if paused_offset and paused_offset > 0:
				cmd += ["-ss", str(paused_offset)]
			cmd += [current_path]
			
			current_process = subprocess.Popen(
				cmd,
				stdin=subprocess.PIPE,
				stdout=subprocess.PIPE,
				stderr=subprocess.PIPE
			)
			
			time.sleep(0.2)
			if current_process.poll() is not None:
				err = current_process.stderr.read().decode("utf-8", errors="ignore") if current_process.stderr else ""
				current_process = None
				return jsonify({"error": "ffplay failed to start", "stderr": err}), 500
			
			playback_start_time = time.time() - paused_offset
			is_paused = False
		
		print(f"Resumed: {current_path} at {paused_offset:.2f}s")
		return jsonify({"status": "resumed", "path": current_path, "offset": paused_offset}), 200
	except Exception as e:
		print(f"Resume error: {e}")
		return jsonify({"error": str(e)}), 500

@app.route("/stop", methods=["GET"])
def stop():
	"""Stop current song"""
	global current_process, is_paused
	
	with playback_lock:
		if current_process:
			try:
				current_process.terminate()
				current_process.wait(timeout=1)
			except:
				try:
					current_process.kill()
				except:
					pass
		
		current_process = None
		is_paused = False
	
	print("Song stopped")
	return jsonify({"status": "stopped"}), 200

@app.route("/status", methods=["GET"])
def status():
	"""Check if song is still playing"""
	global current_process
	
	if not current_process:
		return jsonify({"status": "stopped"}), 200
	
	if current_process.poll() is None:
		return jsonify({"status": "playing"}), 200
	else:
		return jsonify({"status": "finished"}), 200

@app.route("/search", methods=["GET"])
def search():
	"""Search for a song by name and download from YouTube"""
	query = request.args.get("query")
	
	if not query or query.strip() == "":
		return jsonify({"error": "No search query provided"}), 400
	
	try:
		print(f"Searching for: {query}")
		
		ydl_opts = get_ydl_opts(quiet=False)
		
		try:
			with yt_dlp.YoutubeDL(ydl_opts) as ydl:
				info = ydl.extract_info(f"ytsearch1:{query}", download=False)
				
				if not info or "entries" not in info or len(info["entries"]) == 0:
					return jsonify({"error": "No results found"}), 404
				
				video = info["entries"][0]
				title = video.get("title", "Unknown")
				track_id = video.get("id", "unknown")
				thumbnail_url = video.get("thumbnail", "")
		except AttributeError as ae:
			# Workaround for yt-dlp bug with UrllibResponseAdapter
			if "_http_error" in str(ae):
				print(f"yt-dlp AttributeError (known bug): {ae}")
				return jsonify({"error": "YouTube API temporarily unavailable. Try again in a few moments."}), 429
			raise
		except yt_dlp.utils.DownloadError as ydl_error:
			print(f"yt-dlp search error: {ydl_error}")
			return jsonify({"error": f"YouTube search error: {str(ydl_error)}"}), 400
		except Exception as ydl_error:
			print(f"yt-dlp search error: {ydl_error}")
			import traceback
			traceback.print_exc()
			if "HTTP" in str(ydl_error) or "400" in str(ydl_error):
				return jsonify({"error": "YouTube rejected the request. Try again later."}), 429
			raise
		
		image_filename = download_image(thumbnail_url) if thumbnail_url else None
		
		audio_path = download_audio(track_id, f"https://www.youtube.com/watch?v={track_id}", is_url=True)
		if not audio_path:
			return jsonify({"error": "Failed to download audio"}), 500
		
		song_data = {
			"title": title,
			"artist": "YouTube",
			"track_id": track_id,
			"path": audio_path
		}
		
		if image_filename:
			song_data["image_path"] = f"files/{image_filename}"
			song_data["image"] = f"http://{request.host}/files/{image_filename}"
		
		print(f"Found and downloaded: {title}")
		return jsonify(song_data), 200
	
	except Exception as e:
		print(f"Search error: {e}")
		return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
	print(f"🎵 Music Bot Server running on http://{HOST}:{PORT}")
	print("Supported services: Spotify, Apple Music, YouTube")
	print("Tip: To route output into Roblox Voice Chat, install a virtual audio cable (e.g., VB-Audio Cable), set the virtual cable as the system default playback device, then select the cable as the microphone/input in Roblox settings.")
	print("Ensure SPOTIPY_CLIENT_ID and SPOTIPY_CLIENT_SECRET are set in the environment for Spotify support.")
	app.run(host=HOST, port=PORT, debug=False)
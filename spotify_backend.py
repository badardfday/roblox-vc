import os
import json
import subprocess
import sys
from pathlib import Path
import requests
import argparse
from urllib.parse import urlparse, parse_qs
import shutil
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

try:
	import spotipy
	from spotipy.oauth2 import SpotifyClientCredentials
	import yt_dlp
except ImportError:
	print("Install required packages: pip install spotipy requests yt-dlp")
	sys.exit(1)

WORKSPACE_FOLDER = Path(__file__).parent / "fart"
WORKSPACE_FOLDER.mkdir(parents=True, exist_ok=True)

SPOTIFY_CLIENT_ID = os.getenv("SPOTIPY_CLIENT_ID") or os.getenv("SPOTIFY_CLIENT_ID")
SPOTIFY_CLIENT_SECRET = os.getenv("SPOTIPY_CLIENT_SECRET") or os.getenv("SPOTIFY_CLIENT_SECRET")

def check_dependencies():
	"""Ensure required external executables are available for playback."""
	if shutil.which("ffplay") is None and shutil.which("ffmpeg") is None:
		print("Warning: ffplay/ffmpeg not found in PATH. Playback via this script may fail.")

check_dependencies()

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
		if client_id or client_secret:
			sp = get_spotify_client_with_creds(client_id or SPOTIFY_CLIENT_ID, client_secret or SPOTIFY_CLIENT_SECRET)
		else:
			sp = get_spotify_client_with_creds(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
		
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

def download_song(track_info):
	"""Download full song from YouTube using yt-dlp"""
	try:
		track_id = track_info["track_id"]
		title = track_info["title"]
		artist = track_info["artist"]
		output_path = WORKSPACE_FOLDER / f"{track_id}.mp3"
		
		if output_path.exists():
			return str(output_path)
		
		search_query = f"{artist} - {title}"
		
		ydl_opts = {
			"format": "bestaudio/best",
			"postprocessors": [{
				"key": "FFmpegExtractAudio",
				"preferredcodec": "mp3",
				"preferredquality": "192",
			}],
			"outtmpl": str(WORKSPACE_FOLDER / f"{track_id}"),
			"quiet": False,
			"no_warnings": False,
		}
		
		with yt_dlp.YoutubeDL(ydl_opts) as ydl:
			print(f"Downloading: {search_query}")
			ydl.extract_info(f"ytsearch:{search_query}", download=True)
		
		return str(output_path)
	except Exception as e:
		print(f"Download error: {e}")
		return None

def play_through_microphone(audio_path):
	"""Play audio through microphone using VB-Audio or similar"""
	try:
		# For Windows: use VB-Audio Virtual Cable
		# Install: https://vb-audio.com/Cable/
		
		subprocess.Popen([
			"ffplay",
			"-nodisp",
			"-autoexit",
			audio_path
		])
		
		return True
	except Exception as e:
		print(f"Playback error: {e}")
		return False

def parse_args():
	parser = argparse.ArgumentParser()
	parser.add_argument("spotify_link", nargs="?", help="Spotify track link")
	parser.add_argument("--client-id", help="Spotify client id (overrides env)")
	parser.add_argument("--client-secret", help="Spotify client secret (overrides env)")
	return parser.parse_args()

def main():
	"""Main function"""
	args = parse_args()
	if not args.spotify_link:
		print("Usage: python spotify_backend.py <spotify_link> [--client-id CLIENT_ID --client-secret CLIENT_SECRET]")
		return
	spotify_link = args.spotify_link
	client_id = args.client_id or SPOTIFY_CLIENT_ID
	client_secret = args.client_secret or SPOTIFY_CLIENT_SECRET
	if not client_id or not client_secret:
		print(json.dumps({"error": "Spotify credentials not configured. Pass --client-id and --client-secret or set SPOTIPY_CLIENT_ID and SPOTIPY_CLIENT_SECRET environment variables to use Spotify features."}))
		return
	
	song_data = fetch_song_data(spotify_link, client_id=client_id, client_secret=client_secret)
	if "error" in song_data:
		print(json.dumps({"error": song_data["error"]}))
		return
	
	audio_path = download_song(song_data)
	song_data["path"] = audio_path
	
	print(json.dumps(song_data))

if __name__ == "__main__":
	main()

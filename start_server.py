"""Check for a trusted upstream server update, then start the backend."""

import hashlib
import json
import logging
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

import requests


REPOSITORY_ROOT = Path(__file__).resolve().parent
SERVER_FILE = REPOSITORY_ROOT / "spotify_server.py"
UPDATE_STATE_FILE = REPOSITORY_ROOT / ".spotify_server_update.json"
BACKUP_FILE = REPOSITORY_ROOT / "spotify_server.py.bak"
UPDATE_URL = (
	"https://raw.githubusercontent.com/"
	"badardfday/roblox-vc/main/spotify_server.py"
)

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


def sha256(content: bytes) -> str:
	return hashlib.sha256(content).hexdigest()


def write_json_atomically(path: Path, data: dict) -> None:
	temporary_path = None
	try:
		with tempfile.NamedTemporaryFile(
			mode="w",
			encoding="utf-8",
			dir=path.parent,
			prefix=f".{path.name}.",
			suffix=".tmp",
			delete=False,
		) as temporary_file:
			temporary_path = Path(temporary_file.name)
			json.dump(data, temporary_file, indent=2)
			temporary_file.write("\n")
			temporary_file.flush()
			os.fsync(temporary_file.fileno())
		os.replace(temporary_path, path)
	except OSError:
		if temporary_path and temporary_path.exists():
			temporary_path.unlink()
		raise


def updater_owns_current_file(current_hash: str) -> bool:
	try:
		state = json.loads(UPDATE_STATE_FILE.read_text(encoding="utf-8"))
	except (OSError, json.JSONDecodeError):
		state = {}
	if isinstance(state, dict) and state.get("sha256") == current_hash:
		return True

	try:
		result = subprocess.run(
			["git", "-C", str(REPOSITORY_ROOT), "diff", "--quiet", "HEAD", "--", "spotify_server.py"],
			check=False,
			capture_output=True,
			text=True,
			timeout=5,
		)
	except (OSError, subprocess.SubprocessError):
		logging.warning(
			"Cannot verify whether spotify_server.py was edited locally; "
			"skipping auto-update."
		)
		return False

	if result.returncode == 0:
		return True
	if result.returncode == 1:
		logging.warning(
			"spotify_server.py has local changes; skipping auto-update to preserve them."
		)
	elif result.returncode == 127:
		logging.warning(
			"Git is unavailable and no updater checksum matches; skipping auto-update."
		)
	else:
		logging.warning(
			"Could not verify local server changes; skipping auto-update: %s",
			result.stderr.strip() or "Git returned an error.",
		)
	return False


def install_update(content: bytes, new_hash: str) -> None:
	compile(content, str(SERVER_FILE), "exec")
	temporary_path = None
	installed = False
	try:
		with tempfile.NamedTemporaryFile(
			mode="wb",
			dir=REPOSITORY_ROOT,
			prefix=".spotify_server.",
			suffix=".py.tmp",
			delete=False,
		) as temporary_file:
			temporary_path = Path(temporary_file.name)
			temporary_file.write(content)
			temporary_file.flush()
			os.fsync(temporary_file.fileno())

		if SERVER_FILE.exists():
			shutil.copy2(SERVER_FILE, BACKUP_FILE)
		os.replace(temporary_path, SERVER_FILE)
		installed = True
		write_json_atomically(UPDATE_STATE_FILE, {"sha256": new_hash})
	except Exception:
		if temporary_path and temporary_path.exists():
			temporary_path.unlink()
		if installed and BACKUP_FILE.exists():
			restore_path = None
			try:
				with tempfile.NamedTemporaryFile(
					mode="wb",
					dir=REPOSITORY_ROOT,
					prefix=".spotify_server.restore.",
					suffix=".tmp",
					delete=False,
				) as restore_file:
					restore_path = Path(restore_file.name)
					restore_file.write(BACKUP_FILE.read_bytes())
					restore_file.flush()
					os.fsync(restore_file.fileno())
				os.replace(restore_path, SERVER_FILE)
			finally:
				if restore_path and restore_path.exists():
					restore_path.unlink()
		raise


def check_for_update() -> None:
	try:
		current_content = SERVER_FILE.read_bytes()
	except OSError as error:
		logging.error("Cannot read %s: %s", SERVER_FILE.name, error)
		return

	current_hash = sha256(current_content)
	if not updater_owns_current_file(current_hash):
		return

	try:
		response = requests.get(UPDATE_URL, timeout=(5, 15))
		response.raise_for_status()
		latest_content = response.content
		if not latest_content:
			raise ValueError("GitHub returned an empty server file.")
		latest_hash = sha256(latest_content)
		if latest_hash == current_hash:
			if not UPDATE_STATE_FILE.exists():
				write_json_atomically(UPDATE_STATE_FILE, {"sha256": current_hash})
			logging.info("Python server is up to date.")
			return

		install_update(latest_content, latest_hash)
		logging.info(
			"Updated spotify_server.py from GitHub. Previous version saved as %s.",
			BACKUP_FILE.name,
		)
	except (requests.RequestException, OSError, SyntaxError, ValueError) as error:
		logging.warning("Server update check failed; starting the existing version: %s", error)


def main() -> int:
	check_for_update()
	try:
		result = subprocess.run(
			[sys.executable, str(SERVER_FILE)],
			cwd=REPOSITORY_ROOT,
			check=False,
		)
	except OSError as error:
		logging.error("Could not start spotify_server.py: %s", error)
		return 1
	return result.returncode


if __name__ == "__main__":
	raise SystemExit(main())

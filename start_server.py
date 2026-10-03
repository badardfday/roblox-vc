"""Check for a trusted upstream server update, then start the backend."""

import hashlib
import logging
import os
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import Optional

import requests


REPOSITORY_ROOT = Path(__file__).resolve().parent
SERVER_FILE = REPOSITORY_ROOT / "spotify_server.py"
UPDATE_URL = (
	"https://raw.githubusercontent.com/"
	"badardfday/roblox-vc/main/spotify_server.py"
)

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


def sha256(content: bytes) -> str:
	return hashlib.sha256(content).hexdigest()


def install_update(content: bytes) -> Optional[Path]:
	compile(content, str(SERVER_FILE), "exec")
	temporary_path = None
	backup_file = None
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
			timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
			backup_file = REPOSITORY_ROOT / f"spotify_server.py.{timestamp}.bak"
			shutil.copy2(SERVER_FILE, backup_file)
		os.replace(temporary_path, SERVER_FILE)
		return backup_file
	except Exception:
		if temporary_path and temporary_path.exists():
			temporary_path.unlink()
		if backup_file and backup_file.exists():
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
					restore_file.write(backup_file.read_bytes())
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
	try:
		response = requests.get(UPDATE_URL, timeout=(5, 15))
		response.raise_for_status()
		latest_content = response.content
		if not latest_content:
			raise ValueError("GitHub returned an empty server file.")
		latest_hash = sha256(latest_content)
		if latest_hash == current_hash:
			logging.info("Python server is up to date.")
			return

		backup_file = install_update(latest_content)
		if backup_file:
			logging.info(
				"Updated spotify_server.py from GitHub. Previous version saved as %s.",
				backup_file.name,
			)
		else:
			logging.info("Updated spotify_server.py from GitHub.")
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

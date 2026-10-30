#!/usr/bin/env python3
"""Download and unpack a Vosk model zip into <models dir>/<language>."""
import argparse
import shutil
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url", help="URL of a Vosk model zip")
    parser.add_argument("dest", help="Target directory, e.g. /share/vosk/models/de")
    args = parser.parse_args()

    dest = Path(args.dest)
    if dest.exists():
        print(f"Model already present: {dest}")
        return

    # Work next to the destination so the final move is a rename
    with tempfile.TemporaryDirectory(dir=dest.parent, prefix=".download-") as tmp:
        tmp_dir = Path(tmp)
        zip_path = tmp_dir / "model.zip"
        print(f"Downloading {args.url}")
        with urllib.request.urlopen(args.url) as response, open(zip_path, "wb") as f:
            shutil.copyfileobj(response, f)

        extract_dir = tmp_dir / "extracted"
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(extract_dir)

        # Model zips usually contain a single top-level directory
        entries = list(extract_dir.iterdir())
        model_dir = entries[0] if len(entries) == 1 and entries[0].is_dir() else extract_dir
        model_dir.rename(dest)

    print(f"Model installed: {dest}")


if __name__ == "__main__":
    try:
        main()
    except Exception as err:  # pylint: disable=broad-except
        print(f"ERROR: model download failed: {err}", file=sys.stderr)
        sys.exit(1)

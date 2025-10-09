#!/usr/bin/env bash
# Convert all .mp3 and .wav under SRC_DIR to .ogg under DST_DIR, preserving folders.
# Usage:
#   ./convert_audio_to_ogg.sh [SRC_DIR] [DST_DIR]
# Defaults:
#   SRC_DIR=audio_src   DST_DIR=audio

set -euo pipefail

SRC_DIR="${1:-audio_src}"
DST_DIR="${2:-audio}"

# Check deps
command -v ffmpeg >/dev/null 2>&1 || { echo "ERROR: ffmpeg not found. Install it: sudo apt install ffmpeg"; exit 1; }

# Make sure src exists
if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source dir not found: $SRC_DIR"
  exit 1
fi

# Prepare dest
mkdir -p "$DST_DIR"

# Find .mp3 and .wav recursively, safely (handles spaces)
mapfile -d '' FILES < <(find "$SRC_DIR" -type f \( -iname '*.mp3' -o -iname '*.wav' \) -print0)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No .mp3 or .wav files found under: $SRC_DIR"
  exit 0
fi

ok=0
fail=0

for f in "${FILES[@]}"; do
  rel="${f#$SRC_DIR/}"                     # relative path from SRC_DIR
  out="$DST_DIR/${rel%.*}.ogg"             # change extension to .ogg
  mkdir -p "$(dirname "$out")"             # ensure destination subfolder exists

  # Convert with Vorbis VBR (q=4 ≈ ~160 kbps, good quality for games)
  if ffmpeg -v error -y -i "$f" -c:a libvorbis -qscale:a 4 "$out"; then
    echo "OK: $f -> $out"
    ((ok++))
  else
    echo "FAIL: $f" >&2
    ((fail++))
  fi
done

echo "--------"
echo "Done. OK: $ok, FAIL: $fail"
[ "$fail" -eq 0 ] || exit 1


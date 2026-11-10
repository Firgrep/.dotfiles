#!/usr/bin/env bash
# One-time setup for the read-aloud mod: a Python venv with Kokoro (local
# neural TTS, CPU) and its model files, kept outside the repo.
set -euo pipefail

DATA="$HOME/.local/share/claude-tts"
BASE=https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0

command -v uv >/dev/null || { echo "install uv first: https://docs.astral.sh/uv/" >&2; exit 1; }
command -v pw-cat >/dev/null || { echo "pw-cat (pipewire-bin) is required for playback" >&2; exit 1; }

mkdir -p "$DATA" "$HOME/.cache/claude-tts/tmp" "$HOME/.cache/claude-tts/spool"
[ -d "$DATA/.venv" ] || uv venv -q "$DATA/.venv"
uv pip install -q --python "$DATA/.venv/bin/python" kokoro-onnx
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -f "$DATA/$f" ] || curl -fL --progress-bar -o "$DATA/$f" "$BASE/$f"
done
echo "read-aloud is ready. Use /speak in Claude Code."

#!/usr/bin/env python3
"""Speech worker for the read-aloud mod.

Watches a spool directory for sentences (`<ms>-<n>.txt`), turns each into audio
with Kokoro (CPU, ONNX) and streams it to PipeWire through one long-lived
`pw-cat`, so consecutive sentences play gaplessly while the next one is still
being generated.

Spool protocol (written by the mod):
  <ms>-<n>.txt   one chunk of text to speak, in order of name
  stop           contents = ms timestamp; everything older is dropped and the
                 current playback is cut off
  config.json    {"voice": "af_heart", "speed": 1.0}, read before each sentence
"""

import fcntl
import json
import os
import queue
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

# Models and the venv live outside the repo (see install.sh).
DATA = Path.home() / ".local/share/claude-tts"
SPOOL = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".cache/claude-tts/spool"
SPOOL.mkdir(parents=True, exist_ok=True)
SAMPLE_RATE = 24000

# phonemizer copies libespeak-ng into a temp dir and loads it from there; /tmp
# can be mounted noexec, so keep temp files under the cache dir instead.
TMP = Path.home() / ".cache/claude-tts/tmp"
TMP.mkdir(parents=True, exist_ok=True)
os.environ["TMPDIR"] = str(TMP)

# Every Claude Code session starts its own worker, but they all share one spool,
# so several workers would speak over each other. Only the lock holder runs; the
# rest block here in standby (before loading the model) and take over when the
# holder exits. The kernel drops the lock if the holder dies, however it dies.
_lock_file = open(SPOOL.parent / "worker.lock", "w")
fcntl.flock(_lock_file, fcntl.LOCK_EX)

import numpy as np  # noqa: E402
from kokoro_onnx import Kokoro  # noqa: E402

kokoro = Kokoro(str(DATA / "kokoro-v1.0.onnx"), str(DATA / "voices-v1.0.bin"))

epoch = 0  # bumped by every stop; work from an older epoch is discarded
epoch_lock = threading.Lock()
gen_q: "queue.Queue[tuple[int, str]]" = queue.Queue()
play_q: "queue.Queue[tuple[int, bytes]]" = queue.Queue()
player: "subprocess.Popen | None" = None
player_lock = threading.Lock()
running = True


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def config() -> dict:
    try:
        return json.loads((SPOOL / "config.json").read_text())
    except Exception:
        return {}


def stamp(name: str) -> int:
    try:
        return int(name.split("-", 1)[0].split(".", 1)[0])
    except ValueError:
        return 0


def kill_player() -> None:
    global player
    with player_lock:
        if player and player.poll() is None:
            player.kill()
            player.wait()
        player = None


def start_player() -> subprocess.Popen:
    global player
    with player_lock:
        if player is None or player.poll() is not None:
            player = subprocess.Popen(
                [
                    "pw-cat", "--playback",
                    "--rate", str(SAMPLE_RATE), "--channels", "1", "--format", "f32",
                    "--media-role", "Music", "-",
                ],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=sys.stderr,
            )
        return player


def generator() -> None:
    while running:
        try:
            ep, text = gen_q.get(timeout=0.5)
        except queue.Empty:
            continue
        if ep != epoch:
            continue
        cfg = config()
        try:
            audio, _ = kokoro.create(
                text,
                voice=cfg.get("voice", "af_heart"),
                speed=float(cfg.get("speed", 1.0)),
                lang=cfg.get("lang", "en-us"),
            )
        except Exception as exc:  # a bad chunk must not kill the worker
            log(f"synth failed for {text[:60]!r}: {exc}")
            continue
        if ep == epoch:
            play_q.put((ep, np.asarray(audio, dtype=np.float32).tobytes()))


def speaker() -> None:
    while running:
        try:
            ep, pcm = play_q.get(timeout=0.5)
        except queue.Empty:
            continue
        if ep != epoch:
            continue
        try:
            proc = start_player()
            # Written in slices so a stop can cut in between them.
            step = SAMPLE_RATE * 4 // 5 * 4
            for i in range(0, len(pcm), step):
                if ep != epoch:
                    break
                proc.stdin.write(pcm[i : i + step])
                proc.stdin.flush()
        except (BrokenPipeError, ValueError, OSError):
            pass  # the player was killed by a stop; the next chunk restarts it


def handle_stop(marker: Path) -> None:
    global epoch
    cutoff = stamp(marker.read_text().strip() or "0")
    with epoch_lock:
        epoch += 1
    for q in (gen_q, play_q):
        while True:
            try:
                q.get_nowait()
            except queue.Empty:
                break
    kill_player()
    for f in SPOOL.glob("*.txt"):
        if stamp(f.name) <= cutoff:
            f.unlink(missing_ok=True)
    marker.unlink(missing_ok=True)


def shutdown(*_: object) -> None:
    global running
    running = False
    kill_player()
    sys.exit(0)


def main() -> None:
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    threading.Thread(target=generator, daemon=True).start()
    threading.Thread(target=speaker, daemon=True).start()
    log(f"ready, spool={SPOOL}")
    while running:
        marker = SPOOL / "stop"
        if marker.exists():
            handle_stop(marker)
        now = time.time()
        for f in sorted(SPOOL.glob("*.txt"), key=lambda p: p.name):
            try:
                if now - f.stat().st_mtime < 0.03:
                    continue  # still being written
                text = f.read_text().strip()
                f.unlink(missing_ok=True)
            except OSError:
                continue
            if text:
                gen_q.put((epoch, text))
        time.sleep(0.04)


if __name__ == "__main__":
    main()

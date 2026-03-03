#!/usr/bin/env bash
# tts-queue-daemon.sh — Persistent audio queue player.
# Plays queued audio files sequentially, exits after 30s idle.

set -uo pipefail

# Source cross-platform abstraction layer
source "$(cd "$(dirname "$0")" && pwd)/platform.sh"

QUEUE_DIR="${TMPDIR:-/tmp}/claude_tts_queue"
mkdir -p "$QUEUE_DIR"

PID_FILE="${QUEUE_DIR}/daemon.pid"
echo $$ > "$PID_FILE"

cleanup() {
  rm -f "$PID_FILE"
}
trap cleanup EXIT

IDLE=0

while true; do
  # Find the next audio file (mp3 or wav, sorted by name for sequence order)
  NEXT=$(ls -1 "${QUEUE_DIR}/"*.mp3 "${QUEUE_DIR}/"*.wav 2>/dev/null | sort | head -1 || true)

  if [[ -n "$NEXT" && -f "$NEXT" ]]; then
    IDLE=0
    # Play audio (blocking)
    play_audio "$NEXT" 2>/dev/null || true
    # Remove after playing
    rm -f "$NEXT"
  else
    IDLE=$((IDLE + 1))
    sleep 1
    # Exit after 30 seconds idle
    if [[ $IDLE -ge 30 ]]; then
      exit 0
    fi
  fi
done

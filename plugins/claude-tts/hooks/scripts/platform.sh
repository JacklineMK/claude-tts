#!/usr/bin/env bash
# platform.sh — Cross-platform abstraction layer for claude-tts.
# Source this file from other scripts: source "$(dirname "$0")/platform.sh"
# Provides: detect_os, play_audio, tts_local, tts_local_speak, file_size,
#           install_hint, check_audio_player, check_local_tts

# --- OS Detection ---
detect_os() {
  case "$(uname -s)" in
    Darwin*)  CLAUDE_TTS_OS="macos"   ;;
    Linux*)   CLAUDE_TTS_OS="linux"   ;;
    CYGWIN*|MINGW*|MSYS*) CLAUDE_TTS_OS="windows" ;;
    *)        CLAUDE_TTS_OS="linux"   ;; # default to linux for unknown
  esac
  export CLAUDE_TTS_OS
}

# --- Audio Playback ---
play_audio() {
  local file="$1"
  case "$CLAUDE_TTS_OS" in
    macos)
      afplay "$file" 2>/dev/null
      ;;
    linux)
      if command -v mpv &>/dev/null; then
        mpv --no-terminal "$file" 2>/dev/null
      elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet "$file" 2>/dev/null
      elif command -v paplay &>/dev/null; then
        paplay "$file" 2>/dev/null
      elif command -v aplay &>/dev/null; then
        aplay "$file" 2>/dev/null
      else
        return 1
      fi
      ;;
    windows)
      local wfile
      wfile=$(cygpath -w "$file" 2>/dev/null || echo "$file")
      local ext="${file##*.}"
      if [[ "$ext" == "wav" ]]; then
        powershell.exe -NoProfile -Command "
          \$p = New-Object System.Media.SoundPlayer '$wfile';
          \$p.PlaySync(); \$p.Dispose()" 2>/dev/null
      else
        powershell.exe -NoProfile -Command "
          Add-Type -AssemblyName PresentationCore;
          \$m = New-Object System.Windows.Media.MediaPlayer;
          \$m.Open([uri]'$wfile'); \$m.Play();
          Start-Sleep -Seconds 30; \$m.Close()" 2>/dev/null
      fi
      ;;
  esac
}

check_audio_player() {
  case "$CLAUDE_TTS_OS" in
    macos)   command -v afplay &>/dev/null ;;
    linux)   command -v mpv &>/dev/null || command -v ffplay &>/dev/null ||
             command -v paplay &>/dev/null || command -v aplay &>/dev/null ;;
    windows) command -v powershell.exe &>/dev/null ;;
  esac
}

# --- Local TTS ---
tts_local() {
  local text="$1"
  local outfile="$2"
  case "$CLAUDE_TTS_OS" in
    macos)
      if command -v say &>/dev/null; then
        say --data-format=LEI16@22050 -o "$outfile" "$text" 2>/dev/null
      else
        return 1
      fi
      ;;
    linux)
      if command -v espeak-ng &>/dev/null; then
        espeak-ng -w "$outfile" "$text" 2>/dev/null
      elif command -v espeak &>/dev/null; then
        espeak -w "$outfile" "$text" 2>/dev/null
      elif command -v piper &>/dev/null; then
        echo "$text" | piper --output_file "$outfile" 2>/dev/null
      else
        return 1
      fi
      ;;
    windows)
      local wfile
      wfile=$(cygpath -w "$outfile" 2>/dev/null || echo "$outfile")
      local tmptext
      tmptext=$(mktemp "${TMPDIR:-/tmp}/claude_tts_text.XXXXXX")
      printf '%s' "$text" > "$tmptext"
      local wtmptext
      wtmptext=$(cygpath -w "$tmptext" 2>/dev/null || echo "$tmptext")
      powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName System.Speech;
        \$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer;
        \$synth.SetOutputToWaveFile('$wfile');
        \$synth.Speak([IO.File]::ReadAllText('$wtmptext'));
        \$synth.Dispose()" 2>/dev/null
      rm -f "$tmptext"
      ;;
  esac
}

tts_local_speak() {
  local text="$1"
  case "$CLAUDE_TTS_OS" in
    macos)
      say "$text" 2>/dev/null
      ;;
    linux)
      if command -v espeak-ng &>/dev/null; then
        espeak-ng "$text" 2>/dev/null
      elif command -v espeak &>/dev/null; then
        espeak "$text" 2>/dev/null
      elif command -v piper &>/dev/null; then
        echo "$text" | piper --output_raw 2>/dev/null | aplay -r 22050 -f S16_LE 2>/dev/null
      else
        return 1
      fi
      ;;
    windows)
      local tmptext
      tmptext=$(mktemp "${TMPDIR:-/tmp}/claude_tts_text.XXXXXX")
      printf '%s' "$text" > "$tmptext"
      local wtmptext
      wtmptext=$(cygpath -w "$tmptext" 2>/dev/null || echo "$tmptext")
      powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName System.Speech;
        \$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer;
        \$synth.Speak([IO.File]::ReadAllText('$wtmptext'));
        \$synth.Dispose()" 2>/dev/null
      rm -f "$tmptext"
      ;;
  esac
}

check_local_tts() {
  case "$CLAUDE_TTS_OS" in
    macos)   command -v say &>/dev/null ;;
    linux)   command -v espeak-ng &>/dev/null || command -v espeak &>/dev/null ||
             command -v piper &>/dev/null ;;
    windows) command -v powershell.exe &>/dev/null ;;
  esac
}

# --- File Size ---
file_size() {
  local file="$1"
  if [[ "$CLAUDE_TTS_OS" == "macos" ]]; then
    stat -f%z "$file" 2>/dev/null || echo "0"
  elif stat --version &>/dev/null 2>&1; then
    stat -c%s "$file" 2>/dev/null || echo "0"
  else
    wc -c < "$file" 2>/dev/null | tr -d ' ' || echo "0"
  fi
}

# --- Install Hints ---
install_hint() {
  local pkg="$1"
  case "$CLAUDE_TTS_OS" in
    macos)
      echo "brew install $pkg"
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        echo "sudo apt install $pkg"
      elif command -v dnf &>/dev/null; then
        echo "sudo dnf install $pkg"
      elif command -v pacman &>/dev/null; then
        echo "sudo pacman -S $pkg"
      else
        echo "Install '$pkg' with your package manager"
      fi
      ;;
    windows)
      if command -v scoop &>/dev/null; then
        echo "scoop install $pkg"
      elif command -v choco &>/dev/null; then
        echo "choco install $pkg"
      else
        echo "Install '$pkg' (see: https://jqlang.github.io/jq/download/)"
      fi
      ;;
  esac
}

# Auto-detect OS when sourced
detect_os

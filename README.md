# claude-tts

Text-to-speech plugin for Claude Code. Automatically speaks Claude's responses aloud using ElevenLabs TTS with macOS `say` fallback.

## Requirements

- macOS (uses `afplay` for audio playback)
- `jq` (`brew install jq`)
- ElevenLabs API key (optional — falls back to macOS `say` if not configured)

## Install

### From the marketplace

```
claude plugin install claude-tts
```

### Manual install

```bash
git clone https://github.com/MatiousCorp/claude-tts.git ~/.claude/plugins/claude-tts
```

Or symlink for development:

```bash
git clone https://github.com/MatiousCorp/claude-tts.git ~/Documents/claude-tts
ln -s ~/Documents/claude-tts ~/.claude/plugins/claude-tts
```

Restart Claude Code after installing.

## Setup

In Claude Code, run:

```
/claude-tts:tts-setup sk_your_elevenlabs_api_key
```

This will:
1. Save your API key to `~/.claude/claude-tts.local.md`
2. Enable TTS
3. Test the pipeline with a sample phrase

Get your ElevenLabs API key at: https://elevenlabs.io/app/settings/api-keys

### Without an API key

The plugin works without an API key using macOS built-in `say` command (lower quality but free and offline).

## Usage

Once set up, TTS works automatically. Every time Claude finishes a response, the text is cleaned and spoken aloud.

### Commands

| Command | Description |
|---------|-------------|
| `/claude-tts:tts-on` | Enable TTS |
| `/claude-tts:tts-off` | Disable TTS |
| `/claude-tts:tts-status` | Show current status |
| `/claude-tts:tts-setup <key>` | Configure API key |

## Configuration

Config is stored in `~/.claude/claude-tts.local.md`:

```markdown
---
elevenlabs_api_key: "sk_..."
voice_id: "21m00Tcm4TlvDq8ikWAM"
model_id: "eleven_flash_v2_5"
---
```

### Voice customization

Change `voice_id` to use a different ElevenLabs voice. Browse voices at:
https://elevenlabs.io/docs/api-reference/get-voices

### Environment variable

Set `ELEVENLABS_API_KEY` in your shell profile to skip the config file. The env var takes precedence.

## How it works

1. Claude finishes a response (Stop hook fires)
2. The hook reads the last assistant message from the JSONL transcript
3. Text is cleaned: code blocks, URLs, file paths, and markdown formatting are stripped
4. A background worker sends the text to ElevenLabs (or macOS `say`)
5. Audio files are queued and played sequentially via `afplay`

The hook exits immediately so Claude Code is never blocked.

## Text cleaning

The following are stripped before speaking:
- Fenced code blocks
- Inline code
- URLs
- File paths
- Markdown formatting (headings, bold, italic, lists, tables, links)
- Responses under 5 characters are skipped

Text is truncated to 5000 characters to control API costs.

## Troubleshooting

**No audio playing**
1. Run `/claude-tts:tts-status` to check configuration
2. Make sure `jq` is installed: `brew install jq`
3. Check that `~/.claude/tts-enabled` exists

**ElevenLabs errors**
- Verify your API key at https://elevenlabs.io/app/settings/api-keys
- Check your ElevenLabs usage quota
- The plugin falls back to macOS `say` automatically on API errors

**Audio queue stuck**
- Kill the daemon: `kill $(cat ${TMPDIR}/claude_tts_queue/daemon.pid)`
- Clear the queue: `rm -f ${TMPDIR}/claude_tts_queue/*.mp3 ${TMPDIR}/claude_tts_queue/*.aiff`

**Plugin not loading**
- Ensure the plugin is in `~/.claude/plugins/claude-tts/`
- Restart Claude Code after installing

## Platform notes

- **macOS only** — relies on `afplay` for playback and `say` for fallback
- Linux/Windows: would need alternative audio players (not yet supported)

## License

MIT

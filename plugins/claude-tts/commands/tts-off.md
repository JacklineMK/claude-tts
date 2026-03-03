---
description: Disable text-to-speech for Claude responses
allowed-tools: [Bash]
---

Run this exact command:

```bash
rm -f ~/.claude/tts-enabled && QUEUE_DIR="${TMPDIR:-/tmp}/claude_tts_queue" && if [[ -f "$QUEUE_DIR/daemon.pid" ]]; then kill $(cat "$QUEUE_DIR/daemon.pid") 2>/dev/null || true; rm -f "$QUEUE_DIR/daemon.pid"; fi && echo "TTS disabled. Claude responses will no longer be spoken."
```

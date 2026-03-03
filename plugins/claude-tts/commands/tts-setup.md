---
description: Set up TTS plugin with your ElevenLabs API key
allowed-tools: [Bash]
argument-hint: <elevenlabs-api-key>
---

You MUST run this exact command and nothing else:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/tts-setup.sh" $ARGUMENTS
```

If $ARGUMENTS is empty, tell the user: "Please provide your ElevenLabs API key: `/claude-tts:tts-setup sk_your_key_here`"

Do NOT run any other scripts. Do NOT invent script names. Only run tts-setup.sh.

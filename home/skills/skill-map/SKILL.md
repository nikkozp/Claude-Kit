---
name: skill-map
description: Draw a map of all skills and highlight broken links between them.
disable-model-invocation: true
allowed-tools: Bash(powershell *) Read
---
Run `powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/skill-map.ps1" -NoPlugins`.
Then read `~/.claude/skill-map.md` and explain every red link: which skill calls which,
why it will not work (missing skill or manual-only child) and the exact fix.

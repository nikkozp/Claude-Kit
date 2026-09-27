#!/usr/bin/env bash
# Links ~/.claude to this repo on macOS, Linux or WSL. Safe to re-run.
# Note: home/settings.json hooks call powershell.exe (Windows). Adjust them for Linux/macOS.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
dst="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dst"
for i in settings.json CLAUDE.md skills agents hooks scripts rules output-styles; do
  src="$repo/home/$i"; [ -e "$src" ] || continue
  t="$dst/$i"
  if [ -L "$t" ]; then rm "$t"; elif [ -e "$t" ]; then mv "$t" "$t.bak-$stamp"; echo "backup: $i"; fi
  ln -s "$src" "$t"; echo "linked: $i"
done
rc="$HOME/.bashrc"; [ -n "${ZSH_VERSION:-}" ] && rc="$HOME/.zshrc"
grep -q CLAUDE_AUTOCOMPACT_PCT_OVERRIDE "$rc" 2>/dev/null || echo 'export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70' >> "$rc"
echo "Done. Open a new shell and run: claude doctor"

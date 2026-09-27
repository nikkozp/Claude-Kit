# Links ~/.claude to this repo. Safe to re-run. ASCII-only.
# Usage: .\install.ps1          (symlinks/junctions, edits flow back into the repo)
#        .\install.ps1 -Copy    (plain copy, no Developer Mode needed)
param([switch]$Copy)
$ErrorActionPreference = 'Stop'
$repo  = $PSScriptRoot
$dst   = Join-Path $env:USERPROFILE '.claude'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
New-Item -ItemType Directory -Force $dst | Out-Null

$items = 'settings.json','CLAUDE.md','skills','agents','hooks','scripts','rules','output-styles'
foreach ($i in $items) {
  $src = Join-Path $repo "home\$i"
  if (-not (Test-Path $src)) { continue }
  $target = Join-Path $dst $i

  if (Test-Path $target) {
    $item = Get-Item $target -Force
    if ($item.LinkType) {
      # remove only the link itself, never the files it points to
      if ($item.PSIsContainer) { [IO.Directory]::Delete($target) } else { Remove-Item $target -Force }
    } else {
      Rename-Item $target "$i.bak-$stamp"
      "backup:  $i -> $i.bak-$stamp"
    }
  }

  $isDir = (Get-Item $src).PSIsContainer
  if ($Copy) {
    Copy-Item $src $target -Recurse
    "copied:  $i"
  } elseif ($isDir) {
    New-Item -ItemType Junction -Path $target -Target $src | Out-Null
    "linked:  $i (junction)"
  } else {
    try {
      New-Item -ItemType SymbolicLink -Path $target -Target $src | Out-Null
      "linked:  $i (symlink)"
    } catch {
      Copy-Item $src $target
      "copied:  $i (symlink failed - enable Developer Mode to link files)"
    }
  }
}

setx CLAUDE_AUTOCOMPACT_PCT_OVERRIDE 70 | Out-Null
""
"Done. Next:"
"  1. Restart the terminal (for CLAUDE_AUTOCOMPACT_PCT_OVERRIDE)."
"  2. Run: claude doctor"
"  3. In Claude Code run /plugin and check that the plugins from README are installed."

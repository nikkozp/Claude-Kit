# Builds a Mermaid map of all skills and highlights broken links. ASCII-only.
# Usage: powershell -File ~/.claude/scripts/skill-map.ps1 [-NoPlugins] [-Out path]
param([string]$Out = "$env:USERPROFILE\.claude\skill-map.md", [switch]$NoPlugins)

$plug  = Join-Path $env:USERPROFILE '.claude\plugins\cache'
$roots = @((Join-Path $env:USERPROFILE '.claude\skills'), (Join-Path (Get-Location) '.claude\skills'))
if (-not $NoPlugins) { $roots += $plug }
$files = foreach ($r in $roots) { if (Test-Path $r) { Get-ChildItem $r -Recurse -Filter SKILL.md } }

$skills = @{}
foreach ($f in $files) {
  $t = Get-Content -LiteralPath $f.FullName -Raw
  $n = if ($t -match '(?m)^name:\s*([\w-]+)') { $Matches[1] } else { $f.Directory.Name }
  $skills[$n] = @{
    Manual = $t -match '(?m)^disable-model-invocation:\s*true'
    Fork   = $t -match '(?m)^context:\s*fork'
    Plugin = $f.FullName.StartsWith($plug)
    Text   = $t
  }
}

function Id($n) { 's_' + ($n -replace '[^\w]', '_') }
$md = @('```mermaid', 'flowchart LR')
$links = New-Object System.Collections.ArrayList
$bad = @()

foreach ($n in $skills.Keys) {
  $s = $skills[$n]
  $tag = if ($s.Manual) { ' - manual' } elseif ($s.Fork) { ' - fork' } else { '' }
  $cls = if ($s.Plugin) { 'plugin' } elseif ($s.Manual) { 'manual' } else { 'auto' }
  $md += "  $(Id $n)[""$n$tag""]:::$cls"
}
foreach ($n in $skills.Keys) {
  $t = $skills[$n].Text
  foreach ($m in [regex]::Matches($t, 'Invoke the `([\w-]+)` skill')) {
    $c = $m.Groups[1].Value
    if (-not $skills.ContainsKey($c)) {
      $md += "  $(Id $c)[""$c - missing""]:::missing"
      [void]$links.Add("  $(Id $n) -->|""missing""| $(Id $c)"); $bad += $links.Count - 1
    } elseif ($skills[$c].Manual) {
      [void]$links.Add("  $(Id $n) -->|""blocked: manual-only""| $(Id $c)"); $bad += $links.Count - 1
    } else {
      [void]$links.Add("  $(Id $n) -->|""invoke""| $(Id $c)")
    }
  }
  foreach ($m in [regex]::Matches($t, 'skills[\\/]([\w-]+)[\\/]SKILL\.md')) {
    [void]$links.Add("  $(Id $n) -.->|""reads file""| $(Id $m.Groups[1].Value)")
  }
}
$md += $links
foreach ($i in $bad) { $md += "  linkStyle $i stroke:#E24B4A,stroke-width:2px" }
$md += '  classDef auto fill:#E1F5EE,stroke:#0F6E56'
$md += '  classDef manual fill:#FAEEDA,stroke:#854F0B'
$md += '  classDef plugin fill:#EEEDFE,stroke:#534AB7'
$md += '  classDef missing fill:#FCEBEB,stroke:#A32D2D,stroke-dasharray:4 3'
$md += '```'
Set-Content -LiteralPath $Out -Value $md -Encoding UTF8
"Skills: $($skills.Count). Links: $($links.Count). Problems: $($bad.Count). Map: $Out"

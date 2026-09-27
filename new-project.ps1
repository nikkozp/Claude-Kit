# Copies one or more project templates into a repository. Existing files are skipped unless -Force.
# Usage: .\new-project.ps1 -Template dotnet,blazor [-Target C:\src\MyRepo] [-Force]
# ASCII-only.
param(
  [Parameter(Mandatory)][ValidateSet('dotnet','blazor','sdlc','knowledge')][string[]]$Template,
  [string]$Target = (Get-Location).Path,
  [switch]$Force
)
$ErrorActionPreference = 'Stop'
foreach ($t in $Template) {
  $src = Join-Path $PSScriptRoot "templates\$t"
  Get-ChildItem $src -Recurse -File -Force | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length).TrimStart('\','/')
    $dst = Join-Path $Target $rel
    if ((Test-Path $dst) -and -not $Force) { "skip (exists): $rel"; return }
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Copy-Item $_.FullName $dst -Force
    "copied: $rel"
  }
  "Template '$t' applied to $Target."
}
"Review the files, fill in CLAUDE.md, then commit them to the project repo."

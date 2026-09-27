# Optional Stop hook: rejects diffs with narrating or excessive code comments.
# Not enabled by default - see README, section "Optional hooks". ASCII-only.
$in = [Console]::In.ReadToEnd() | ConvertFrom-Json
if ($in.stop_hook_active) { exit 0 }

$added = @(git diff -U0 HEAD -- '*.cs' 2>$null | Where-Object { $_ -match '^\+(?!\+\+)' })
foreach ($f in (git ls-files -o --exclude-standard -- '*.cs')) {
  $added += (Get-Content -LiteralPath $f | ForEach-Object { "+$_" })
}
if (-not $added) { exit 0 }

$comments  = @($added | Where-Object { $_ -match '^\+\s*//(?!/)' })
$code      = @($added | Where-Object { $_ -notmatch '^\+\s*(//|$)' }).Count
$narration = @($comments | Where-Object {
  $_ -match '(?i)//\s*(added|changed|updated|removed|fixed|now\b|new:|as requested|per (the )?(task|request|plan)|step \d)'
})
$tooMany = $comments.Count -gt [math]::Max(3, [math]::Ceiling($code * 0.15))

if ($narration.Count -gt 0 -or $tooMany) {
  [Console]::Error.WriteLine("Comment policy: $($comments.Count) comment lines for $code code lines. " +
    "Remove comments that restate code or narrate the change; keep only non-obvious WHY.")
  $narration | Select-Object -First 10 | ForEach-Object { [Console]::Error.WriteLine($_) }
  exit 2
}
exit 0

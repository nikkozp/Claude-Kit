# Stop hook: does not let the turn end while tests are red. ASCII-only.
$in = [Console]::In.ReadToEnd() | ConvertFrom-Json
if ($in.stop_hook_active) { exit 0 }

git diff --quiet HEAD -- '*.cs' 2>$null
$changed   = ($LASTEXITCODE -ne 0)
$untracked = @(git ls-files -o --exclude-standard -- '*.cs')
if (-not $changed -and $untracked.Count -eq 0) { exit 0 }

$out = dotnet test --nologo -v q 2>&1
if ($LASTEXITCODE -ne 0) {
  [Console]::Error.WriteLine('Tests are failing, keep fixing:')
  $out | Select-String -Pattern 'Failed|error' | Select-Object -First 40 |
    ForEach-Object { [Console]::Error.WriteLine($_.Line) }
  exit 2
}
exit 0

# PostToolUse hook: formats only the edited C# file. Never blocks. ASCII-only.
$in = [Console]::In.ReadToEnd() | ConvertFrom-Json
$f  = [string]$in.tool_input.file_path
if ($f -like '*.cs' -and (Test-Path -LiteralPath $f)) {
  dotnet format --include $f *> $null
}
exit 0

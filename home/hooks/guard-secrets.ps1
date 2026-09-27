# PreToolUse hook: blocks reading secrets via Read/Grep/Glob and via shell commands.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
[Console]::InputEncoding = [Text.Encoding]::UTF8
$in = [Console]::In.ReadToEnd() | ConvertFrom-Json
$t  = @($in.tool_input.file_path, $in.tool_input.path,
        $in.tool_input.pattern, $in.tool_input.command) -join ' '
$rx = '(^|[\\/\s''"])\.env(\.[\w-]+)?($|[\s''"])|appsettings\.[^\\/\s]*\.local\.json' +
      '|UserSecrets|NuGet\.Config|\.pfx|\.pem|[\\/]\.(ssh|aws|azure)[\\/]'
if ($t -match $rx) {
  [Console]::Error.WriteLine('Access to secrets is blocked by policy. Use user-secrets or Key Vault instead.')
  exit 2
}
exit 0

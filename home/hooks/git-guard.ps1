# PreToolUse hook for Bash/PowerShell: enforces the git branch policy.
#   - no push to a protected branch (main, master, origin/HEAD, $env:CLAUDE_GIT_PROTECTED)
#   - no force: push --force/-f/--force-with-lease/+refspec, switch -C, checkout -B, branch -f
#   - a branch whose upstream is a protected branch cannot be pushed implicitly
#   - new branches start only from the local main branch, and only when it equals origin/main
#     after a fresh fetch; never from origin/<x> and never with --track
# Exit 2 blocks the tool call and shows stderr to Claude. Git flags are case-sensitive,
# hence the -c* operators. ASCII-only: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
[Console]::InputEncoding = [Text.Encoding]::UTF8
$in  = [Console]::In.ReadToEnd() | ConvertFrom-Json
$cmd = [string]$in.tool_input.command
if ($cmd -notmatch '(^|[\s;&|(])git(\.exe)?\s') { exit 0 }

function Deny([string]$msg) { [Console]::Error.WriteLine("git policy: $msg"); exit 2 }

function G([string]$dir, [string[]]$a) {
  $o = & git -C $dir @a 2>$null
  if ($LASTEXITCODE -ne 0 -or $null -eq $o) { return $null }
  [string](@($o)[0])
}

function Resolve-Dir([string]$base, [string]$p) {
  if (-not $p) { return $base }
  if ($p -match '^/([a-zA-Z])(/|$)') { $p = $p -replace '^/([a-zA-Z])', '$1:' }
  if ($p -match '^~') { $p = $env:USERPROFILE + $p.Substring(1) }
  $p = $p -replace '/', '\'
  if (-not [IO.Path]::IsPathRooted($p)) { $p = Join-Path $base $p }
  if (Test-Path -LiteralPath $p -PathType Container) { return (Resolve-Path -LiteralPath $p).Path }
  $base
}

function Get-MainName([string]$dir) {
  $h = G $dir @('symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD')
  if ($h) { return ($h -replace '^origin/', '') }
  foreach ($m in 'main', 'master') {
    if (G $dir @('rev-parse', '--verify', '--quiet', "refs/heads/$m")) { return $m }
  }
  'main'
}

function Get-Protected([string]$dir) {
  $set = @('main', 'master', (Get-MainName $dir))
  if ($env:CLAUDE_GIT_PROTECTED) { $set += ($env:CLAUDE_GIT_PROTECTED -split '[,; ]+' | Where-Object { $_ }) }
  $set | Select-Object -Unique
}

# "origin/main", "refs/remotes/origin/main", "refs/heads/main", "main" -> "main"
function Branch-Name([string]$r, [switch]$Remote) {
  $r = $r -replace '^refs/heads/', '' -replace '^refs/remotes/', ''
  if ($Remote) { $r = $r -replace '^[^/]+/', '' }
  $r
}

function Split-Commands([string]$s) {
  $segs = New-Object System.Collections.Generic.List[string]
  $sb = New-Object Text.StringBuilder
  $q = [char]0
  foreach ($c in $s.ToCharArray()) {
    if ($q -ne [char]0) { if ($c -eq $q) { $q = [char]0 }; [void]$sb.Append($c); continue }
    if ($c -eq [char]'"' -or $c -eq [char]"'") { $q = $c; [void]$sb.Append($c); continue }
    if (';|&()'.IndexOf($c) -ge 0 -or $c -eq [char]10 -or $c -eq [char]13) {
      $segs.Add($sb.ToString()); [void]$sb.Clear(); continue
    }
    [void]$sb.Append($c)
  }
  $segs.Add($sb.ToString())
  $segs
}

function Get-Positional([string[]]$a) {
  $a | Where-Object { $_ -notlike '-*' }
}

function Check-Push([string]$dir, [string[]]$a) {
  $flags = @($a | Where-Object { $_ -like '-*' })
  $pos   = @(Get-Positional $a)
  foreach ($f in $flags) {
    if ($f -cmatch '^--(force|force-with-lease|force-if-includes)($|=)' -or $f -cmatch '^-[a-zA-Z]*f[a-zA-Z]*$') {
      Deny 'force push is forbidden. Integrate main with "git merge origin/main" and push normally.'
    }
  }
  if ($flags -ccontains '--mirror' -or $flags -ccontains '--all') { Deny '--all/--mirror would push protected branches. Push only your feature branch.' }
  $prot = Get-Protected $dir
  $cur  = G $dir @('branch', '--show-current')
  $refspecs = if ($pos.Count -gt 1) { $pos[1..($pos.Count - 1)] } else { @() }
  foreach ($rs in $refspecs) {
    if ($rs.StartsWith('+')) { Deny "force refspec '$rs' is forbidden." }
    $dst = if ($rs.Contains(':')) { $rs.Split(':')[-1] } else { $rs }
    if ($dst -eq 'HEAD' -or $dst -eq '') { $dst = $cur }
    $dst = Branch-Name $dst
    if ($dst -in $prot) { Deny "pushing to protected branch '$dst' is forbidden. Push a feature branch and open a PR." }
  }
  if ($refspecs.Count -eq 0) {
    if ($cur -and $cur -in $prot) { Deny "you are on protected branch '$cur'. Create a feature branch from the pulled $cur and push that." }
    $up = G $dir @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}')
    if ($up -and ((Branch-Name $up -Remote:($up.Contains('/'))) -in $prot)) {
      Deny "branch '$cur' tracks '$up', so a plain push would target it. Run 'git branch --unset-upstream', then 'git push -u origin HEAD'."
    }
  }
}

function Check-NewBranch([string]$dir, [string]$start) {
  $main = Get-MainName $dir
  $how  = "Run 'git switch $main' and 'git pull --ff-only' as a separate command first, then 'git switch -c <name>' with no start point."
  if ($start) {
    if ($start -ne $main -or -not (G $dir @('rev-parse', '--verify', '--quiet', "refs/heads/$start"))) {
      Deny "start point '$start' is not allowed: branches start from the pulled local '$main' (a remote start point such as origin/$main becomes the upstream). $how"
    }
  } else {
    $cur = G $dir @('branch', '--show-current')
    if ($cur -ne $main) { Deny "branches must start from '$main' (current: '$cur'). $how" }
  }
  if (-not (G $dir @('remote', 'get-url', 'origin'))) { return }
  & git -C $dir fetch --quiet origin $main 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { Deny "could not fetch origin/$main to verify that '$main' is pulled. Fix connectivity and retry." }
  $local  = G $dir @('rev-parse', "refs/heads/$main")
  $remote = G $dir @('rev-parse', "refs/remotes/origin/$main")
  if ($remote -and $local -ne $remote) { Deny "local '$main' differs from 'origin/$main'. $how" }
}

function After([string[]]$a, [int]$i) {
  if ($i + 1 -le $a.Count - 1) { [string[]]$a[($i + 1)..($a.Count - 1)] } else { [string[]]@() }
}

function Check-Branch([string]$dir, [string]$sub, [string[]]$a) {
  $flags = @($a | Where-Object { $_ -like '-*' })
  foreach ($f in $flags) {
    if ($f -cmatch '^--track($|=)|^-t$') { Deny '--track is forbidden: a new branch must not track origin/main. Create it from the pulled local main.' }
  }
  switch -CaseSensitive ($sub) {
    'checkout' {
      if ($flags -ccontains '-B') { Deny 'checkout -B force-resets a branch and is forbidden.' }
      $i = [array]::IndexOf($a, '-b')
      if ($i -ge 0) { $p = @(Get-Positional (After $a ($i + 1))); Check-NewBranch $dir ($(if ($p.Count) { $p[0] } else { '' })) }
    }
    'switch' {
      if ($flags -ccontains '-C' -or $flags -ccontains '--force-create') { Deny 'switch -C force-resets a branch and is forbidden.' }
      $i = [array]::IndexOf($a, '-c'); if ($i -lt 0) { $i = [array]::IndexOf($a, '--create') }
      if ($i -ge 0) { $p = @(Get-Positional (After $a ($i + 1))); Check-NewBranch $dir ($(if ($p.Count) { $p[0] } else { '' })) }
    }
    'branch' {
      $prot = Get-Protected $dir
      for ($k = 0; $k -lt $a.Count; $k++) {
        $up = $null
        if ($a[$k] -cmatch '^--set-upstream-to=(.+)$') { $up = $Matches[1] }
        elseif ($a[$k] -cin '-u', '--set-upstream-to' -and $k + 1 -lt $a.Count) { $up = $a[$k + 1] }
        if ($up -and ((Branch-Name $up -Remote:($up.Contains('/'))) -in $prot)) {
          Deny "setting upstream to protected branch '$up' is forbidden. Use 'git push -u origin HEAD'."
        }
      }
      if ($flags | Where-Object { $_ -cmatch '^(-f|--force)$' }) { Deny 'branch -f force-resets a branch and is forbidden.' }
      $nonCreate = '^(-[dDmMcClarvu]|-vv|--(delete|move|copy|list|all|remotes|show-current|verbose|contains|no-contains|merged|no-merged|edit-description|unset-upstream|set-upstream-to|format|sort|points-at|column|no-column|color|no-color|abbrev|no-abbrev|ignore-case))'
      if ($flags | Where-Object { $_ -cmatch $nonCreate }) { return }
      $p = @(Get-Positional $a)
      if ($p.Count -ge 1) { Check-NewBranch $dir ($(if ($p.Count -ge 2) { $p[1] } else { '' })) }
    }
    'worktree' {
      if ($a.Count -and $a[0] -ceq 'add') {
        if ($flags -ccontains '-B') { Deny 'worktree add -B force-resets a branch and is forbidden.' }
        $i = [array]::IndexOf($a, '-b')
        if ($i -ge 0) {
          $rest = @(@(After $a 0) | Where-Object { $_ -ne $a[$i + 1] })
          $p = @(Get-Positional $rest)
          Check-NewBranch $dir ($(if ($p.Count -ge 2) { $p[1] } else { '' }))
        }
      }
    }
  }
}

# Drop heredoc and here-string bodies so commit messages are not parsed as commands;
# text after the heredoc marker on the same line (e.g. "&& git push") is kept.
$clean = [regex]::Replace($cmd, "(?s)<<-?\s*['""]?(\w+)['""]?([^\r\n]*)\r?\n(?:.*?\r?\n)?\1[ \t]*(?=\r?\n|$)", '$2')
$clean = [regex]::Replace($clean, "(?s)@'\r?\n.*?\r?\n'@|@""\r?\n.*?\r?\n""@", "''")

$dir = if ($in.cwd) { [string]$in.cwd } else { (Get-Location).Path }
foreach ($seg in (Split-Commands $clean)) {
  $tok = @([regex]::Matches($seg, '"[^"]*"|''[^'']*''|\S+') | ForEach-Object { $_.Value.Trim('"', "'") })
  if ($tok.Count -eq 0) { continue }
  if ($tok[0] -in 'cd', 'Set-Location', 'sl', 'pushd', 'Push-Location', 'chdir') {
    $dir = Resolve-Dir $dir ($(if ($tok.Count -gt 1) { $tok[-1] } else { $env:USERPROFILE }))
    continue
  }
  if ($tok[0] -notmatch '^git(\.exe)?$') { continue }
  $gdir = $dir; $i = 1
  while ($i -lt $tok.Count -and $tok[$i] -like '-*') {
    if ($tok[$i] -ceq '-C' -and $i + 1 -lt $tok.Count) { $gdir = Resolve-Dir $gdir $tok[$i + 1]; $i += 2; continue }
    if ($tok[$i] -ceq '-c' -and $i + 1 -lt $tok.Count) { $i += 2; continue }
    $i++
  }
  if ($i -ge $tok.Count) { continue }
  $sub  = $tok[$i]
  $rest = After $tok $i
  if ($sub -cnotin 'push', 'checkout', 'switch', 'branch', 'worktree') { continue }
  if (-not (G $gdir @('rev-parse', '--git-dir'))) { continue }
  if ($sub -ceq 'push') { Check-Push $gdir $rest } else { Check-Branch $gdir $sub $rest }
}
exit 0

# Daily auto commit and push to GitHub (run by Task Scheduler at 17:00)
$repo = Split-Path -Parent $PSScriptRoot
$log  = Join-Path $repo 'scripts\auto-push.log'
Set-Location $repo
function Write-Log($m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File $log -Append -Encoding utf8 }

git add -A 2>&1 | Out-Null
$changes = git status --porcelain
if ($changes) {
    $n = ($changes | Measure-Object).Count
    git commit -q -m "Daily auto backup $(Get-Date -Format 'yyyy-MM-dd') ($n files)" 2>&1 | Out-Null
    Write-Log "Committed $n files"
} else {
    Write-Log "No changes to commit"
}
$out = git push origin main 2>&1
if ($LASTEXITCODE -eq 0) { Write-Log "Push OK" } else { Write-Log "Push FAILED: $out" }

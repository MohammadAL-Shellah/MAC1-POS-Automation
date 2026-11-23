# Re-reads the CURRENT state of the given work items from Azure DevOps and writes it as JSON.
# For bugs it also returns the state history (every State change with its time).
# Read only: this script never creates or changes anything in Azure DevOps.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File refresh-items.ps1 -IdsFile ids.txt -Config ..\config\team.json -Out out.json
param(
  [Parameter(Mandatory = $true)][string]$IdsFile,
  [Parameter(Mandatory = $true)][string]$Config,
  [Parameter(Mandatory = $true)][string]$Out
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$cfg = [IO.File]::ReadAllText((Resolve-Path $Config)) | ConvertFrom-Json
$base = $cfg.devops.collection.TrimEnd('/')
$ids = @([IO.File]::ReadAllText($IdsFile).Split(',') | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } | Sort-Object -Unique)

function Get-Rest($url) { Invoke-RestMethod -UseDefaultCredentials -Uri $url }
function Get-Name($v) { if (-not $v) { return '' }; if ($v -is [string]) { return ($v -replace '\s*<.*>$', '') }; return [string]$v.displayName }
function Get-LinkId($w, $rel) {
  foreach ($x in @($w.relations)) { if ($x -and $x.rel -eq $rel) { return [int]($x.url -replace '.*/', '') } }
  return $null
}

$items = @()
$missing = @()
for ($i = 0; $i -lt $ids.Count; $i += 200) {
  $chunk = ($ids[$i..([Math]::Min($i + 199, $ids.Count - 1))]) -join ','
  # errorPolicy=omit: a deleted or inaccessible item comes back as null instead of failing the whole batch
  $r = Get-Rest "$base/_apis/wit/workitems?ids=$chunk&`$expand=relations&errorPolicy=omit&api-version=5.0"
  $items += @($r.value | Where-Object { $_ })
}
$found = @{}
foreach ($w in $items) { $found[[int]$w.id] = $true }
foreach ($id in $ids) { if (-not $found.ContainsKey($id)) { $missing += $id } }

# Parent and tested story candidates, to keep only links to real User Stories
$cand = @($items | ForEach-Object { Get-LinkId $_ 'System.LinkTypes.Hierarchy-Reverse'; Get-LinkId $_ 'Microsoft.VSTS.Common.TestedBy-Reverse' } | Where-Object { $_ } | Sort-Object -Unique)
$types = @{}
for ($i = 0; $i -lt $cand.Count; $i += 200) {
  $chunk = ($cand[$i..([Math]::Min($i + 199, $cand.Count - 1))]) -join ','
  $r = Get-Rest "$base/_apis/wit/workitems?ids=$chunk&fields=System.WorkItemType&errorPolicy=omit&api-version=5.0"
  foreach ($v in @($r.value | Where-Object { $_ })) { $types[[int]$v.id] = [string]$v.fields.'System.WorkItemType' }
}

$result = foreach ($w in $items) {
  $f = $w.fields
  $type = [string]$f.'System.WorkItemType'
  $story = $null
  foreach ($c in @((Get-LinkId $w 'System.LinkTypes.Hierarchy-Reverse'), (Get-LinkId $w 'Microsoft.VSTS.Common.TestedBy-Reverse'))) {
    if ($c -and $types[$c] -eq 'User Story') { $story = $c; break }
  }
  $log = @()
  if ($type -eq 'Bug' -or $type -eq 'User Story') {
    foreach ($u in @((Get-Rest "$base/_apis/wit/workitems/$($w.id)/updates?api-version=5.0").value)) {
      $st = $u.fields.'System.State'
      if ($st -and $st.newValue) {
        $at = if ($u.fields.'System.ChangedDate') { [string]$u.fields.'System.ChangedDate'.newValue } else { [string]$u.revisedDate }
        $log += , ([ordered]@{ state = [string]$st.newValue; at = $at; by = (Get-Name $u.revisedBy) })
      }
    }
  }
  [ordered]@{
    id         = [int]$w.id
    type       = $type
    title      = [string]$f.'System.Title'
    state      = [string]$f.'System.State'
    assignedTo = Get-Name $f.'System.AssignedTo'
    storyId    = $story
    changedAt  = [string]$f.'System.ChangedDate'
    issueType  = [string]$f.'Custom.IssueType'
    qaBugType  = [string]$f.'Custom.QABugType'
    severity   = [string]$f.'Microsoft.VSTS.Common.Severity'
    screen     = ([string]$f.'Custom.ScreenName').Trim()
    statusLog  = $log
  }
}

$outObj = [ordered]@{ items = @($result); missing = $missing }
[IO.File]::WriteAllText($Out, ($outObj | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Output "OK items=$(@($result).Count) missing=$($missing.Count)"

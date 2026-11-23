# Reads one day of Azure DevOps activity for me and the QA team and writes it as JSON.
# Read only: this script never creates or changes anything in Azure DevOps.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File fetch-devops.ps1 -Date 2026-11-15 -Config ..\config\team.json -Out out.json
param(
  [Parameter(Mandatory = $true)][string]$Date,
  [Parameter(Mandatory = $true)][string]$Config,
  [Parameter(Mandatory = $true)][string]$Out
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$cfg = [IO.File]::ReadAllText((Resolve-Path $Config)) | ConvertFrom-Json
$base = $cfg.devops.collection.TrimEnd('/')
$proj = $cfg.devops.project
$tz = [TimeZoneInfo]::FindSystemTimeZoneById($cfg.windowsTimezone)
$inv = [Globalization.CultureInfo]::InvariantCulture

$dayLocal = [datetime]::ParseExact($Date, 'yyyy-MM-dd', $inv)
$startUtc = [TimeZoneInfo]::ConvertTimeToUtc([datetime]::SpecifyKind($dayLocal, 'Unspecified'), $tz)
$endUtc = $startUtc.AddDays(1)

function Get-Utc($v) {
  if (-not $v) { return $null }
  return [DateTimeOffset]::Parse([string]$v, $inv).UtcDateTime
}
function In-Day($v) {
  $d = Get-Utc $v
  if ($null -eq $d) { return $false }
  return ($d -ge $startUtc -and $d -lt $endUtc)
}
function Get-Account($v) {
  if (-not $v) { return '' }
  if ($v -is [string]) {
    if ($v -match '<(.+)>') { return $Matches[1].ToLower() }
    return $v.ToLower()
  }
  return ([string]$v.uniqueName).ToLower()
}
function Get-Rest($url) { Invoke-RestMethod -UseDefaultCredentials -Uri $url }

# 1. Every work item changed since the day before the selected day (WIQL works at day precision).
$since = $dayLocal.AddDays(-1).ToString('yyyy-MM-dd', $inv)
$wiql = @{ query = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '$proj' AND [System.ChangedDate] >= '$since' ORDER BY [System.Id]" } | ConvertTo-Json
$res = Invoke-RestMethod -UseDefaultCredentials -Method Post -ContentType 'application/json' -Body $wiql -Uri "$base/$proj/_apis/wit/wiql?api-version=5.0"
$ids = @($res.workItems | ForEach-Object { $_.id })

$items = @()
for ($i = 0; $i -lt $ids.Count; $i += 200) {
  $chunk = ($ids[$i..([Math]::Min($i + 199, $ids.Count - 1))]) -join ','
  $r = Get-Rest "$base/_apis/wit/workitems?ids=$chunk&`$expand=relations&api-version=5.0"
  $items += $r.value
}

function Get-LinkId($w, $rel) {
  foreach ($x in @($w.relations)) {
    if ($x -and $x.rel -eq $rel) { return [int]($x.url -replace '.*/', '') }
  }
  return $null
}

$rows = foreach ($w in $items) {
  $f = $w.fields
  [pscustomobject]@{
    id          = [int]$w.id
    type        = [string]$f.'System.WorkItemType'
    title       = [string]$f.'System.Title'
    state       = [string]$f.'System.State'
    createdBy   = Get-Account $f.'System.CreatedBy'
    createdDate = [string]$f.'System.CreatedDate'
    changedBy   = Get-Account $f.'System.ChangedBy'
    changedDate = [string]$f.'System.ChangedDate'
    assignedTo  = Get-Account $f.'System.AssignedTo'
    closedBy    = Get-Account $f.'Microsoft.VSTS.Common.ClosedBy'
    closedDate  = [string]$f.'Microsoft.VSTS.Common.ClosedDate'
    parentId    = Get-LinkId $w 'System.LinkTypes.Hierarchy-Reverse'
    testedStory = Get-LinkId $w 'Microsoft.VSTS.Common.TestedBy-Reverse'
    issueType   = [string]$f.'Custom.IssueType'
    qaBugType   = [string]$f.'Custom.QABugType'
    severity    = [string]$f.'Microsoft.VSTS.Common.Severity'
    screen      = ([string]$f.'Custom.ScreenName').Trim()
  }
}

# 2. Story details for every referenced parent, so a bug is only grouped under a real User Story.
$refs = @{}
foreach ($x in $rows) { if ($x.type -eq 'User Story') { $refs[$x.id] = @{ title = $x.title; state = $x.state; type = $x.type } } }
$need = @($rows | ForEach-Object { $_.parentId; $_.testedStory } | Where-Object { $_ -and -not $refs.ContainsKey($_) } | Sort-Object -Unique)
for ($i = 0; $i -lt $need.Count; $i += 200) {
  $chunk = ($need[$i..([Math]::Min($i + 199, $need.Count - 1))]) -join ','
  $r = Get-Rest "$base/_apis/wit/workitems?ids=$chunk&fields=System.WorkItemType,System.Title,System.State&api-version=5.0"
  foreach ($v in $r.value) { $refs[[int]$v.id] = @{ title = [string]$v.fields.'System.Title'; state = [string]$v.fields.'System.State'; type = [string]$v.fields.'System.WorkItemType' } }
}
function Get-StoryId($x) {
  foreach ($c in @($x.parentId, $x.testedStory)) {
    if ($c -and $refs.ContainsKey($c) -and $refs[$c].type -eq 'User Story') { return $c }
  }
  return $null
}
function To-Item($x, $reason) {
  [ordered]@{ id = $x.id; title = $x.title; state = $x.state; storyId = (Get-StoryId $x); reason = $reason; createdDate = $x.createdDate; closedDate = $x.closedDate; issueType = $x.issueType; qaBugType = $x.qaBugType; severity = $x.severity; screen = $x.screen }
}

function Get-Person($acct, $isMe) {
  $acct = $acct.ToLower()
  # Only work assigned to the person or created by them. Items they only edited are not their tasks.
  $stories = [ordered]@{}
  $testcases = @(); $bugsOpened = @(); $bugsClosed = @()
  foreach ($x in $rows) {
    if ($x.type -eq 'Test Case' -and $x.createdBy -eq $acct -and (In-Day $x.createdDate)) { $testcases += , (To-Item $x 'written') }
    if ($x.type -eq 'Bug' -and $x.createdBy -eq $acct -and (In-Day $x.createdDate)) { $bugsOpened += , (To-Item $x 'opened') }
    if ($x.type -eq 'Bug' -and $x.closedBy -eq $acct -and (In-Day $x.closedDate)) { $bugsClosed += , (To-Item $x 'closed') }
    if ($x.type -eq 'User Story') {
      $reason = $null
      if ($x.assignedTo -eq $acct -and (In-Day $x.changedDate)) { $reason = 'assigned' }
      elseif ($x.createdBy -eq $acct -and (In-Day $x.createdDate)) { $reason = 'created' }
      if ($reason) { $stories[[string]$x.id] = [ordered]@{ id = $x.id; title = $x.title; state = $x.state; reason = $reason } }
    }
  }
  # A story counts as worked on when the person wrote its test cases or opened or closed its bugs that day.
  foreach ($t in @($testcases + $bugsOpened + $bugsClosed)) {
    $s = $t.storyId
    if ($s -and -not $stories.Contains([string]$s)) { $stories[[string]$s] = [ordered]@{ id = $s; title = $refs[$s].title; state = $refs[$s].state; reason = 'linked work' } }
  }
  [ordered]@{ stories = @($stories.Values); testcases = $testcases; bugsOpened = $bugsOpened; bugsClosed = $bugsClosed }
}

$result = [ordered]@{
  date      = $Date
  fetchedAt = (Get-Date).ToUniversalTime().ToString('o')
  scanned   = $rows.Count
  me        = Get-Person $cfg.me.account $true
  team      = @(foreach ($m in $cfg.team) { $p = Get-Person $m.account $false; $p['name'] = $m.name; $p })
  storyRefs = [ordered]@{}
}
foreach ($k in $refs.Keys) { if ($refs[$k].type -eq 'User Story') { $result.storyRefs[[string]$k] = [ordered]@{ title = $refs[$k].title; state = $refs[$k].state } } }

[IO.File]::WriteAllText($Out, ($result | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Output "OK scanned=$($rows.Count)"

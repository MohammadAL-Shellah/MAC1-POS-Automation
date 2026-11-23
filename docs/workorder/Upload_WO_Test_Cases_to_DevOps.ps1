param([switch]$Apply)
# Uploads docs/workorder/WO_Test_Cases.md to DevOps: Test Plan, suites, Shared Steps, Test Cases. Idempotent via WO_Test_Cases_DevOps_IDs.json.
$ErrorActionPreference = 'Stop'; $D = [string][char]0x2014
$base = "https://devops2.minerets.com/DefaultCollection/Shop"
$S = Split-Path $MyInvocation.MyCommand.Path
$md = Get-Content "c:\Users\m.alshellah\playwright-js-project\docs\workorder\WO_Test_Cases.md" -Encoding UTF8
$state = if (Test-Path "$S\WO_Test_Cases_DevOps_IDs.json") { Get-Content "$S\WO_Test_Cases_DevOps_IDs.json" -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
function Save { $state | ConvertTo-Json -Depth 5 | Set-Content "$S\WO_Test_Cases_DevOps_IDs.json" }
function Has($k) { $state.PSObject.Properties.Name -contains $k }
function SetK($k, $v) { $state | Add-Member -NotePropertyName $k -NotePropertyValue $v -Force; Save }
function Esc($t) { [Security.SecurityElement]::Escape("<DIV><P>" + [Security.SecurityElement]::Escape($t) + "</P></DIV>") }
function Cells($line) { $c = $line.Trim().Trim('|').Split('|') | % { $_.Trim() }; ,$c }
function SplitSteps($t) { ($t -split '(?:^|\s)\d+\.\s+' | % { $_.Trim().TrimEnd('.') } | ? { $_ }) }
function StepsXml($stepsText, $expected) {
  $parts = @(SplitSteps $stepsText); $x = ''; $id = 1; $realIdx = @()
  for ($i = 0; $i -lt $parts.Count; $i++) {
    $p = $parts[$i]; $id++
    if ($p -match '^SS-WO-\d\d$') { $x += "<compref id=`"$id`" ref=`"$($state.$p)`" />" }
    else { $realIdx += $i; $x += "STEP$i" }
  }
  if ($realIdx.Count -eq 0) { $id++; $x += "<step id=`"$id`" type=`"ValidateStep`"><parameterizedString isformatted=`"true`">$(Esc 'Check the result')</parameterizedString><parameterizedString isformatted=`"true`">$(Esc $expected)</parameterizedString><description/></step>" }
  $sid = 1
  for ($i = 0; $i -lt $parts.Count; $i++) {
    $sid++
    if ($realIdx -contains $i) {
      $isLast = ($i -eq $realIdx[-1]); $type = if ($isLast) { 'ValidateStep' } else { 'ActionStep' }; $exp = if ($isLast) { Esc $expected } else { '' }
      $x = $x.Replace("STEP$i", "<step id=`"$sid`" type=`"$type`"><parameterizedString isformatted=`"true`">$(Esc $parts[$i])</parameterizedString><parameterizedString isformatted=`"true`">$exp</parameterizedString><description/></step>")
    }
  }
  "<steps id=`"0`" last=`"$id`">$x</steps>"
}
function NewWI($type, $fields) {
  $ops = @(); foreach ($k in $fields.Keys) { $ops += @{ op = 'add'; path = "/fields/$k"; value = $fields[$k] } }
  $body = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -Depth 5 $ops))
  (Invoke-RestMethod -UseDefaultCredentials -Method Post -Uri "$base/_apis/wit/workitems/`$$([uri]::EscapeDataString($type))?api-version=5.0" -ContentType 'application/json-patch+json' -Body $body).id
}
$common = @{ 'System.AreaPath' = 'Shop\myShop'; 'System.IterationPath' = 'Shop'; 'System.AssignedTo' = 'MINERETS\m.alshellah' }

# Parse
$shared = @(); $cases = @(); $suite = $null
foreach ($l in $md) {
  if ($l -match '^### 3\.\d+ (.+)$') { $suite = $matches[1].Trim(); continue }
  if ($l -match '^\| (SS-WO-\d\d) \|') { $c = Cells $l; $shared += [pscustomobject]@{ id = $c[0]; title = $c[1]; steps = $c[2]; exp = $c[3] } }
  if ($l -match '^\| (TC-WO-\d{3}) \|') { $c = Cells $l; $cases += [pscustomobject]@{ id = $c[0]; p = [int]$c[1]; title = $c[2]; pre = $c[3]; steps = $c[4]; exp = $c[5]; suite = $suite } }
}
"parsed: $($shared.Count) shared steps, $($cases.Count) cases, suites: " + (($cases.suite | Select -Unique) -join ', ')
if (-not $Apply) { $cases | Group suite | % { "$($_.Name): $($_.Count)" }; StepsXml $cases[0].steps $cases[0].exp; return }

# Test plan + suites
if (-not (Has 'plan')) {
  $body = @{ name = 'MAC1 - Workorder (QA)'; area = @{ name = 'Shop\myShop' }; iteration = 'Shop' } | ConvertTo-Json
  $p = Invoke-RestMethod -UseDefaultCredentials -Method Post -Uri "$base/_apis/test/plans?api-version=5.0" -ContentType 'application/json' -Body $body
  SetK 'plan' $p.id; SetK 'root' ([int]$p.rootSuite.id)
}
"plan $($state.plan), root suite $($state.root)"
foreach ($sn in ($cases.suite | Select -Unique)) {
  $k = "suite:$sn"
  if (-not (Has $k)) { $b = @{ suiteType = 'StaticTestSuite'; name = $sn } | ConvertTo-Json; $r = Invoke-RestMethod -UseDefaultCredentials -Method Post -Uri "$base/_apis/test/plans/$($state.plan)/suites/$($state.root)?api-version=5.0" -ContentType 'application/json' -Body $b; SetK $k $r.value[0].id }
}
# Shared steps
foreach ($ss in $shared) {
  if (Has $ss.id) { continue }
  $f = $common.Clone(); $f['System.Title'] = "$($ss.id) $D $($ss.title)"; $f['System.Tags'] = 'Workorder; Shared Steps; Provisional'
  $f['Microsoft.VSTS.TCM.Steps'] = StepsXml $ss.steps $ss.exp
  SetK $ss.id (NewWI 'Shared Steps' $f)
}
# Test cases
foreach ($c in $cases) {
  if (Has $c.id) { continue }
  $tags = @('Workorder', $c.suite, $(if ($c.title -match 'refused|cannot|does not|not move|leaves') { 'Negative' } else { 'Positive' }))
  if ($c.suite -match 'Totals|Payment|Discount|Stock') { $tags += 'Calculation' }
  $tags += 'Provisional'
  $f = $common.Clone(); $f['System.Title'] = "$($c.id) $D $($c.title)"; $f['Microsoft.VSTS.Common.Priority'] = $c.p; $f['System.Tags'] = ($tags -join '; ')
  if ($c.pre) { $f['System.Description'] = "<p><b>Preconditions:</b> $([Security.SecurityElement]::Escape($c.pre))</p><p>Test data: docs/workorder/WO_Test_Cases.md, section 1.</p>" }
  $f['Microsoft.VSTS.TCM.Steps'] = StepsXml $c.steps $c.exp
  SetK $c.id (NewWI 'Test Case' $f)
}
# Add cases to suites
foreach ($g in ($cases | Group suite)) {
  $sid = $state."suite:$($g.Name)"
  $have = @((Invoke-RestMethod -UseDefaultCredentials -Uri "$base/_apis/test/plans/$($state.plan)/suites/$sid/testcases?api-version=5.0").value.testCase.id)
  $add = @($g.Group | % { $state.($_.id) } | ? { "$_" -notin $have })
  if ($add.Count) { Invoke-RestMethod -UseDefaultCredentials -Method Post -Uri "$base/_apis/test/plans/$($state.plan)/suites/$sid/testcases/$($add -join ',')?api-version=5.0" -ContentType 'application/json' -Body '{}' | Out-Null }
  $n = (Invoke-RestMethod -UseDefaultCredentials -Uri "$base/_apis/test/plans/$($state.plan)/suites/$sid/testcases?api-version=5.0").count
  "$($g.Name) (suite $sid): $n of $($g.Count)"
}
"shared: " + (($shared | % { "$($_.id)=$($state.($_.id))" }) -join ', ')
"cases: " + (($cases | % { $state.($_.id) }) | Measure -Minimum -Maximum | % { "$($_.Count) ids $($_.Minimum)-$($_.Maximum)" })

param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$S = "C:\Users\M23C3~1.ALS\AppData\Local\Temp\claude\81024534af02beec\f84659e9-f7eb-49b2-9689-1215e1e0782c\scratchpad"
$E6 = "c:\Users\m.alshellah\playwright-js-project\docs\macone-app\pos-dashboard\evidence\run6-2026-11-19"
$R = "$S\run8"
$base = "https://devops2.minerets.com/DefaultCollection/Shop"
$d = [IO.File]::ReadAllText("$S\task2179_desc_rev2.html")

# TC number -> work item id
$ids = @{}; foreach ($l in Get-Content "$S\tc_titles.txt") { $p = $l.Split('|'); if ($p[1] -match 'TC-POS-(\d{3})') { $ids[$matches[1]] = @{ id = $p[0]; title = ($p[1] -replace '^TC-POS-\d{3}\s*[^A-Za-z]*', '') } } }

$colors = @{ 'Pass' = '#107c10'; 'Fail' = '#d13438'; 'N/A' = '#8a8886'; 'Pending BA' = '#ca5010'; 'Not Run' = '#605e5c'; 'Blocked' = '#8764b8' }
$fig = 0
function Row($tc, $res, $note) {
  $i = $ids[$tc]; $c = $colors[$res]
  "<tr><td style='border:1px solid #ccc;padding:4px'><a href='$base/_workitems/edit/$($i.id)'>TC-$tc</a> $($i.title)</td><td style='border:1px solid #ccc;padding:4px;color:#fff;background:$c;font-weight:bold;text-align:center'>$res</td><td style='border:1px solid #ccc;padding:4px'>$note</td></tr>"
}
function Block($title, $rows, $imgs) {
  if ($imgs.Count -gt 0 -and $imgs[0] -is [string]) { $imgs = ,$imgs }
  $h = "<div style='border-left:4px solid #0078d4;background:#f3f9fd;padding:8px;margin:10px 0'><b>QA Results: $title</b>"
  $h += "<table style='border-collapse:collapse;width:100%;margin-top:6px'><tr style='background:#0078d4;color:#fff'><th style='padding:4px;width:38%'>Case</th><th style='padding:4px;width:10%'>Result</th><th style='padding:4px'>Note</th></tr>"
  foreach ($r in $rows) { $h += Row $r[0] $r[1] $r[2] }
  $h += "</table>"
  foreach ($im in $imgs) {
    $script:fig++
    $url = "IMG::" + $im[0]
    if ($Apply) {
      $bytes = [IO.File]::ReadAllBytes($im[0]); $name = "2179_fig$($script:fig)_" + [IO.Path]::GetFileName($im[0])
      $a = Invoke-RestMethod -UseDefaultCredentials -Method Post -Uri "$base/_apis/wit/attachments?fileName=$name&api-version=5.0" -ContentType "application/octet-stream" -Body $bytes
      $url = $a.url
    }
    $h += "<p><b>Figure $($script:fig): $($im[1])</b><br><img src='$url' style='max-width:900px;width:100%;border:1px solid #ccc'></p>"
    $key = [IO.Path]::GetFileNameWithoutExtension($im[0])
    if ($script:cmp.Contains($key) -and $im[1] -notmatch 'same query') {
      $h += "<table style='border-collapse:collapse;margin:0 0 10px 0'><tr style='background:#0078d4;color:#fff'><th style='padding:4px 8px'>Value</th><th style='padding:4px 8px'>Dashboard</th><th style='padding:4px 8px'>Database (from the query above)</th><th style='padding:4px 8px'>Result</th></tr>"
      foreach ($c in $script:cmp[$key]) {
        $res = $c[3]; $bg = if ($res -eq 'MATCH') { '#2e7d32' } else { '#c62828' }
        $h += "<tr><td style='border:1px solid #ccc;padding:3px 8px'>$($c[0])</td><td style='border:1px solid #ccc;padding:3px 8px'>$($c[1])</td><td style='border:1px solid #ccc;padding:3px 8px'>$($c[2])</td><td style='border:1px solid #ccc;padding:3px 8px;background:$bg;color:#fff;font-weight:bold;text-align:center'>$res</td></tr>"
      }
      $h += "</table>"
    }
  }
  $h += "</div><hr style='border:0;border-top:2px solid #0078d4;margin:14px 0'>"
  $h
}


# 20/11 run. "Re-run 20/11" = executed today with today's data. "19/11 run" = UI-only behaviour, not re-executed today (same build 1.2.498).
$C = '19/11 run (same build, UI behaviour, not re-executed today): '
$sections = @(
  @{ before = '4. Overview Dashboard'; title = '3. Dashboard Navigation'; rows = @(
    @('001','Pass','Re-run 20/11: Overview opens by default after app start and Open Day.'),
    @('002','Pass','Re-run 20/11: Overview, Sales, WO info, Cash, Inventory all open.'),
    @('003','N/A','Permissions not configurable for the QA user.'),
    @('004','N/A','Single branch / terminal / session in QA.')); imgs = @(@("$R\01_overview_baseline.png",'Overview after Open Day 20/11, before any sale (baseline)')) },
  @{ before = '4.2 Invoices Today'; title = '4.1 Daily Sales KPI'; rows = @(
    @('005','Pass','Re-run 20/11: 825.00 = 850.00 invoices - 25.00 return. DB match.'),
    @('008','Pass','Re-run 20/11: yesterday 1,307.59; (825 - 1,307.59) / 1,307.59 = -36.9%. DB match.'),
    @('068','Pass','Re-run 20/11: INV-TO_11000131 paid 40 Cash + 60 Mada: Cash +40, Mada +60, 2 payment lines, Expected Cash +40 only. DB match.'),
    @('006','Blocked','Re-run 20/11: credit limit 0; confirming with 60 remaining shows "Please enter a valid payment amount". A credit customer is needed.'),
    @('007','Pass','Re-run 20/11: WO-TO_11000176 voided: Voided 1, Daily Sales unchanged 850.00.'),
    @('011','Pass',($C + 'Daily Sales opens Sales, Daily, All.')),
    @('012','Pass',($C + 'Refund amount opens Sales > Refunds.')),
    @('009','Not Run','Needs a day after a no-sales day.'),
    @('010','Not Run','Needs two consecutive no-sales days.'),
    @('067','Pass','21/11 after Close Day (build 1.2.498): before any sale 0 vs 2,270 = -100% red, down arrow; after INV-TO_11000137 (100 cash) -95.6% = (100 - 2,270) / 2,270. DB match.')); imgs = @(@("$R\wo1_cart.png",'WO-TO_11000172 cart: Tire - Item + Car Wash = 600.00'), @("$R\068_split_payment.png",'TC-068: split payment 40 Cash + 60 Mada'), @("$R\068_overview_after.png",'TC-068: Overview after the split payment'), @("$R\006_blocked_full_payment_required.png",'TC-006: partial payment refused'), @("$R\007_overview_after_void.png",'TC-007: Overview after voiding WO-TO_11000176')) },
  @{ before = '4.3 Work Orders Today'; title = '4.2 Invoices Today'; rows = @(
    @('013','Pass','Re-run 20/11: Invoices Today 4, Fully Paid 4. DB match.'),
    @('069','Pass','Re-run 20/11: Fully Refunded 1 after RTN-TO_11000019 (full return of INV-TO_11000132).'),
    @('070','Pass','Re-run 20/11: only Total, Fully Paid and Fully Refunded shown.'),
    @('014','Pass',($C + 'opens Sales > All.')),
    @('015','Pass',($C + 'opens Sales > Invoices.')),
    @('016','Pass',($C + 'Fully Refunded opens Refunds.'))); imgs = @(@("$R\refund_form.png",'Full return of INV-TO_11000132 (Cash refund)'), @("$R\ov_after_refund.png",'Overview after the refund')) },
  @{ before = '4.4 Inventory KPI'; title = '4.3 Work Orders Today'; rows = @(
    @('017','Pass','Re-run 20/11: Total 6, Pending 0, Completed 4, Voided 2. DB: Submitted 4, Cancelled 2.'),
    @('018','Pass',($C + 'each status opens WO Info on the matching sub-tab.')),
    @('071','Pending BA','21/11: WO-TO_11000182 created 20/11, Carry to Next Day at Close Day. Before Open Day: Total 0. After Open Day 21/11: Total 1, Pending 1 (WorkingDayID moved to the new day). Story says count by creation date; question raised. On Complete its WorkOrderDate changed to 21/11.')); imgs = @(@("$S\run9\067B_overview_before_open.png",'TC-067 B / TC-071: 21/11 before Open Day: -100%, WOs 0'), @("$S\run9\071_overview_after_open.png",'TC-071: after Open Day, carried WO-182 counts as Pending 1'), @("$S\run9\r01.png",'TC-067 A: after INV-TO_11000137, -95.6% vs yesterday, Expected Cash 200'), @("$S\run9\ssms\q3_growth.png",'SSMS: net sales 20/11 (2,295 - 25 = 2,270) vs 21/11 (100)'), @("$S\run9\ssms\q2_wo182.png",'SSMS: WO-TO_11000182 working day and INV-TO_11000137')) },
  @{ before = '5. Cash Register Section'; title = '4.4 Inventory KPI'; rows = @(
    @('019','Pass','Re-run 20/11: Negative 22 and Low 1 match DB.'),
    @('072','Pass','Re-run 20/11: Overview counts equal Inventory tab (363 / 1 / 12 / 22).'),
    @('020','Pass',($C + 'Low / Out / Negative open Inventory on the matching sub-tab.'))); imgs = @() },
  @{ before = '6. Top Selling (Today)'; title = '5. Cash Register Section'; rows = @(
    @('021','Pass','Re-run 20/11: Register TO_11000031, m.alshellah, opened 2026/11/20 03:34 PM, opening cash 100.00.'),
    @('022','Pass','Re-run 20/11: Expected 715.00 = 100 + 640 - 25. DB match.'),
    @('023','Pass','Re-run 20/11: Mada 185 and Master 25 not added to physical cash.'),
    @('024','Pass','Re-run 20/11: only this session''s cash moves counted.'),
    @('074','Pass','Re-run 20/11: Cash Sales 640.00, Cash Refunds 25.00. DB match.'),
    @('076','Pass','Re-run 20/11: values updated after each sale, refund and void without reopening.'),
    @('028','Pass','Re-run 20/11: on WO-TO_11000177 a 40 Cash line was added then deleted before confirming, and the WO voided: Cash stayed 615, transactions stayed 5.'),
    @('075','Fail','Executed 20/11 after Close Day (counted 2,060, deposit 1,960, left 100). Days appear in Select Days only after choosing a Cash Collector. Draft deposit TO_11000004: no effect (correct). After Submit (DB linked to day 20/11): Expected Cash still 2,060 on Overview and Cash, expected 100. Bug draft on the dashboard.')); imgs = @(@("$R\tab_Cash.png",'Cash tab: register block 20/11'), @("$R\028_payment_line_removed.png",'TC-028: payment line removed before confirming'), @("$R\cd10.png",'Close Day: counted payment, Cash 2,060 = dashboard Expected'), @("$R\cd13_deposit100.png",'Close Day: left 100, deposit 1,960'), @("$R\cd14_lock.png",'Z-Report 20/11'), @("$R\075_r7_sel.png",'TC-075: deposit TO_11000004 for day 20/11, 1,960'), @("$R\075_r13_cash_after.png",'TC-075: after Submit, Expected Cash still 2,060 (expected 100)'), @("$S\run9\ssms\q1_days.png",'SSMS: day 20/11 closed (2,060 / 1,960 / 100) linked to deposit TO_11000004; day 21/11 opened with 100')) },
  @{ before = '7. Value per Payment Method'; title = '6. Top Selling (Today)'; rows = @(
    @('025','Pass','Re-run 20/11: Tire 500, Car Wash 200, RService 100, Brake Check 25 (50 sold - 25 returned). DB match.'),
    @('026','Pass',($C + 'View All opens Today Top Selling items.')),
    @('073','Pass','Re-run 20/11: four items shown, no empty placeholders.')); imgs = @() },
  @{ before = '8. Executive Summary'; title = '7. Value per Payment Method'; rows = @(,
    @('027','Pass','Re-run 20/11: Cash 615 (640 - 25), Mada 185, Master 25. DB match.')); imgs = @() },
  @{ before = 'Sales Tab'; title = '8. Executive Summary'; rows = @(
    @('029','Fail','Re-run 20/11: Purchase Invoice PR-TO_11000003 added stock worth 200.00 (DB) but Inventory Value rose by 5,000.00 (59,510 to 64,510). DB branch value about 662,219.'),
    @('031','Pass','Re-run 20/11: Gross Profit 675.44 = 730.44 - COGS 55. DB match.'),
    @('032','Fail','19/11 run: negative Gross Margin shown in green. Today margin is positive (92.47%), not re-verifiable.'),
    @('034','Pass','Re-run 20/11: Output VAT 94.56 = 97.82 - 3.26. DB match.'),
    @('035','Pass','Re-run 20/11: Purchase Invoice PR-TO_11000003 (2 x 100 + 15% VAT): Input VAT 30.00.'),
    @('036','Pass','Re-run 20/11: Net VAT Payable 64.56 = 94.56 - 30.00.'),
    @('077','Pass','Re-run 20/11: Daily Sales 825.00 incl. VAT, Net 730.44 excl. VAT. DB match.'),
    @('030','N/A','No historical Inventory Value selector.'),
    @('033','Not Run','Needs a day with zero net sales.')); imgs = @(@("$R\035_pi_summary.png",'TC-035: Purchase Invoice summary'), @("$R\035_overview_after_pi.png",'Executive Summary after the Purchase Invoice')) },
  @{ before = 'WO Info TAB'; title = 'Sales Tab'; rows = @(
    @('037','Pass','Re-run 20/11: opens on Daily 20/11 - 20/11.'),
    @('038','Pass','Re-run 20/11: MTD 01/11 - 20/11: 69,765.66, 105 invoices, Refunds 19, Net 60,978.88, Avg 664.43, Return Rate 24.5%. DB match.'),
    @('043','Pass','Re-run 20/11: Daily 825.00, 4 invoices.'),
    @('044','Pass','Re-run 20/11: All (5), Refunds (1), Invoices (4).'),
    @('045','Pass','Re-run 20/11: Avg Invoice 206.25 = 825 / 4.'),
    @('046','Pending BA','Re-run 20/11: Return Rate 2.9% = 25 / 850 (gross). Denominator rule still open.'),
    @('049','Pass','Re-run 20/11: columns correct.'),
    @('079','Pass','Re-run 20/11: INV-TO_11000131 Method "Cash + Mada".'),
    @('039','Pass',($C + 'custom single-day range.')),
    @('040','Pass',($C + 'From after To is rejected.')),
    @('041','Pass',($C + 'editing a date clears the period selection.')),
    @('042','Pass',($C + 'range kept across sub-tabs.')),
    @('047','Pass',($C + 'zero-sales range, no division error.')),
    @('048','Pass',($C + 'category tabs and counts.')),
    @('050','Pass',($C + 'search.')),
    @('051','Pass',($C + 'Export .xlsx.')),
    @('078','Pass',($C + 'boundary dates included.')),
    @('080','Pass',($C + 'KPIs follow the period, not the search.')),
    @('081','Pass',($C + 'Export format .xlsx.')),
    @('082','Not Run','Needs a refunds-only day.')); imgs = @(@("$R\tab_Sales.png",'Sales tab Daily 20/11'), @("$R\s_mtd.png",'Sales tab MTD 01/11 - 20/11')) },
  @{ before = 'CASH TAB'; title = 'WO Info Tab'; rows = @(
    @('052','Pass','Re-run 20/11: MTD 148 WOs.'),
    @('053','Pass','Re-run 20/11: Daily 6 WOs, 1 customer; MTD 6 customers. DB match.'),
    @('054','Pass','Re-run 20/11: Daily 0.0% / 66.7% / 33.3%; MTD 68.9% / 31.1% (102 / 46 of 148). DB match.'),
    @('056','Pass','Re-run 20/11: columns correct.'),
    @('055','Pass',($C + 'range and counts kept across sub-tabs.')),
    @('057','Pass',($C + 'Export.')),
    @('083','Pass',($C + 'empty range.')),
    @('084','Pass',($C + 'Complete action on a pending WO.'))); imgs = @(@("$R\tab_WOinfo.png",'WO Info Daily 20/11'), @("$R\wo_mtd.png",'WO Info MTD')) },
  @{ before = 'Inventory TAB'; title = 'Cash Tab'; rows = @(
    @('058','Pass','Re-run 20/11: Daily Net Payment 825.00 (Received 850 - Refund 25); Net Cash 615; Net Electronic 210.'),
    @('059','Pass','Re-run 20/11: MTD 69,765.66 = Net Cash 20,215.61 + Net Electronic 49,550.05. DB match.'),
    @('061','Pass','Re-run 20/11: register block equals Overview and ignores the period filter.'),
    @('085','Pending BA','Re-run 20/11: Cash 74.5% = 615 / 825. Rule still open.'),
    @('060','N/A','Cash Deposit button removed from the story (rev 80).'),
    @('086','Pass',($C + 'From after To is rejected.'))); imgs = @(@("$R\cash_mtd.png",'Cash tab MTD')) },
  @{ before = $null; title = 'Inventory Tab'; rows = @(
    @('062','Fail','Re-run 20/11: Stock Value 64,510.00 does not match DB (see TC-029).'),
    @('063','Pass','Re-run 20/11: Tire - Item Branch-2 qty 6 (7 - 1 sold), Min 10, Max 100 = Low Stock. DB match.'),
    @('064','Pending BA','Re-run 20/11: tabs 353 + 1 + 12 + 22 = 388 vs All 363; DB 384 branch rows with movement.'),
    @('065','Pass','Re-run 20/11: columns correct.'),
    @('087','Pass','Re-run 20/11: portal item QA214-087 submitted + MAC1 Sync: All 364; item Cancelled on portal + Sync: All 363.'),
    @('066','Pass',($C + 'search by item.'))); imgs = @(@("$R\tab_Inventory.png",'Inventory tab 20/11'), @("$R\087_after_sync_364.png",'TC-087: after Submit + Sync, 364 items'), @("$R\087_portal_cancelled.png",'TC-087: item Cancelled on the portal'), @("$R\087_after_cancel_sync_363.png",'TC-087: after Cancel + Sync, back to 363')) }
)

$blocks = @()
$DB = "$R\ssms"
$script:cmp = @{
  'db01_daily_sales' = @(@('Daily Sales','825.00','850.00 - 25.00 = 825.00','MATCH'),@('Daily Net Sales','730.44','752.18 - 21.74 = 730.44','MATCH'),@('Output VAT','94.56','97.82 - 3.26 = 94.56','MATCH'),@('Invoices Today','4','4','MATCH'),@('Refunds','25.00 (1)','25.00 (1)','MATCH'))
  'db03_yesterday' = @(@('Yesterday sales','1,307.59','1,432.49 invoices - 124.90 returns','MATCH'),@('Growth','-36.9%','(825 - 1,307.59) / 1,307.59 = -36.9%','MATCH'))
  'db08_wo' = @(@('Today Completed / Voided','4 / 2','Submitted 4 / Cancelled 2','MATCH'),@('MTD Completed / Voided','102 / 46','98 + 4 / 44 + 2','MATCH'))
  'db11_negative' = @(@('Negative Stock','22','22','MATCH'),@('All','363','384 rows with movement','MISMATCH'))
  'db05_register' = @(@('Opened','2026/11/20 03:34 PM','2026-11-20 15:34','MATCH'),@('Opening Cash','100.00','100.00','MATCH'),@('Invoices in session','4','4','MATCH'))
  'db09_top_selling' = @(@('Tire - Item','500.00','500.00','MATCH'),@('Car Wash','200.00','200.00','MATCH'),@('RService','100.00','100.00','MATCH'),@('QA_SST Brake Check','25.00 (Qty 1)','50.00 sold - 25.00 returned','MATCH'))
  'db04_payments' = @(@('Cash','615.00','640.00 - 25.00','MATCH'),@('Mada','185.00','185.00','MATCH'),@('Master','25.00','25.00','MATCH'))
  'db10b_cogs_today' = @(@('COGS','55.00','55.00 (INV-TO_11000129)','MATCH'),@('Gross Profit','675.44','730.44 - 55.00','MATCH'),@('Gross Margin','92.47%','675.44 / 730.44','MATCH'))
  'db13_inventory_value' = @(@('Stock Value','64,510.00','661,037.71 + 1,181.70 = 662,219.41','MISMATCH'),@('Change after PR-TO_11000003','+5,000.00','+200.00 (4 base units x 50)','MISMATCH'))
  'db06_mtd_sales' = @(@('Total Sales MTD','69,765.66','92,460.26 - 22,694.60','MATCH'),@('Net Sales MTD','60,978.88','80,752.43 - 19,773.55','MATCH'),@('Invoices / Refunds','105 / 19','105 / 19','MATCH'),@('Return Rate','24.5%','22,694.60 / 92,460.26','MATCH'))
  'db07_cash_mtd' = @(@('Net Cash MTD','20,215.61','35,481.51 - 15,265.90','MATCH'),@('Net Electronic MTD','49,550.05','56,978.75 - 7,428.70','MATCH'))
  'db12_low_tire' = @(@('Branch - 2','6, Min 10, Max 100, Low Stock','6 / 10 / 100','MATCH'),@('Branch Store','34','34','MATCH'))
}
$dbImgs = @{
  '4.1 Daily Sales KPI' = @(@("$DB\db01_daily_sales.png",'SSMS: Daily Sales, Net Sales, VAT, Invoices, Returns'), @("$DB\db03_yesterday.png",'SSMS: yesterday invoices'))
  '4.3 Work Orders Today' = @(@("$DB\db08_wo.png",'SSMS: Work Orders by status'))
  '4.4 Inventory KPI' = @(@("$DB\db11_negative.png",'SSMS: negative stock and item counts'))
  '5. Cash Register Section' = @(@("$DB\db05_register.png",'SSMS: working day and opening cash'))
  '6. Top Selling (Today)' = @(@("$DB\db09_top_selling.png",'SSMS: items sold today'))
  '7. Value per Payment Method' = @(@("$DB\db04_payments.png",'SSMS: payment methods today'))
  '8. Executive Summary' = @(@("$DB\db10b_cogs_today.png",'SSMS: COGS today'), @("$DB\db13_inventory_value.png",'SSMS: Inventory Value'))
  'Sales Tab' = @(@("$DB\db06_mtd_sales.png",'SSMS: Sales MTD'))
  'Cash Tab' = @(@("$DB\db07_cash_mtd.png",'SSMS: Cash MTD'))
  'Inventory Tab' = @(@("$DB\db12_low_tire.png",'SSMS: Tire - Item stock per store'))
}
foreach ($sec in $sections) {
  $im = New-Object System.Collections.ArrayList
  foreach ($src in @($sec.imgs, $dbImgs[$sec.title])) {
    if (-not $src -or $src.Count -eq 0) { continue }
    if ($src[0] -is [string]) { [void]$im.Add(@($src[0], $src[1])) } else { foreach ($x in $src) { [void]$im.Add(@($x[0], $x[1])) } }
  }
  $im = $im.ToArray()
  $blocks += ,@($sec.before, (Block $sec.title $sec.rows $im))
}
$out = $d
for ($k = $blocks.Count - 1; $k -ge 0; $k--) {
  $anchor = $blocks[$k][0]; $html = $blocks[$k][1]
  if (-not $anchor) { $out = $out + $html; continue }
  $idx = $out.IndexOf(">$anchor"); if ($idx -lt 0) { $idx = $out.IndexOf($anchor) }
  if ($idx -lt 0) { throw "anchor not found: $anchor" }
  $div = [Math]::Max($out.LastIndexOf('<div', $idx), $out.LastIndexOf('<h1', $idx)); $out = $out.Insert($div, $html)
}

# Summary box at top
$all = $sections | ForEach-Object { $_.rows } ; $cnt = @{}; foreach ($r in $all) { $cnt[$r[1]]++ }
$total = $all.Count
$sum = @"
<div style='border:2px solid #0078d4;padding:10px;margin-bottom:14px;background:#f3f9fd'>
<h2 style='margin:0 0 6px 0'>QA Execution Summary: myShop POS - Company Dashboard (Story 214)</h2>
<b>1. Execution info</b>
<table style='border-collapse:collapse'><tr><td style='padding:3px 10px'>Build</td><td>MAC1 1.2.498</td></tr><tr><td style='padding:3px 10px'>Date</td><td>20/11/2026 (fresh data, day opened 15:34 with 100.00)</td></tr><tr><td style='padding:3px 10px'>Tester</td><td>Mohammad Al Shellah</td></tr><tr><td style='padding:3px 10px'>Test Plan / Suite</td><td>Plan 1882 / Suite 1885 (87 cases)</td></tr><tr><td style='padding:3px 10px'>Data check</td><td>Every value cross-checked against the MAC1 database in SSMS (read only), screenshots below</td></tr><tr><td style='padding:3px 10px'>Coverage note</td><td>Cases marked "Re-run 20/11" were executed today. UI-only cases marked "19/11 run" were not re-executed today (same build).</td></tr></table>
<b>2. Results</b>
<table style='border-collapse:collapse;text-align:center'><tr style='background:#0078d4;color:#fff'><th style='padding:4px 10px'>Pass</th><th style='padding:4px 10px'>Fail</th><th style='padding:4px 10px'>Blocked</th><th style='padding:4px 10px'>Pending BA</th><th style='padding:4px 10px'>Not Run</th><th style='padding:4px 10px'>N/A</th><th style='padding:4px 10px'>Total</th></tr>
<tr><td style='color:#107c10;font-weight:bold'>$($cnt['Pass'])</td><td style='color:#d13438;font-weight:bold'>$($cnt['Fail'])</td><td style='color:#8764b8;font-weight:bold'>$($cnt['Blocked'])</td><td style='color:#ca5010;font-weight:bold'>$($cnt['Pending BA'])</td><td>$($cnt['Not Run'])</td><td>$($cnt['N/A'])</td><td><b>$total</b></td></tr></table>
<b>3. QA data created on 20/11</b>
<table style='border-collapse:collapse'><tr style='background:#0078d4;color:#fff'><th style='padding:4px'>Document</th><th style='padding:4px'>Content</th><th style='padding:4px'>Amount</th></tr>
<tr><td style='padding:3px'>INV-TO_11000129 (WO-172)</td><td>Tire - Item + Car Wash, Cash</td><td>600.00</td></tr>
<tr><td style='padding:3px'>INV-TO_11000130 (WO-173)</td><td>RService + QA_SST Brake Check, Mada</td><td>125.00</td></tr>
<tr><td style='padding:3px'>INV-TO_11000131 (WO-174)</td><td>Car Wash, 40 Cash + 60 Mada</td><td>100.00</td></tr>
<tr><td style='padding:3px'>INV-TO_11000132 (WO-175)</td><td>QA_SST Brake Check, Master</td><td>25.00</td></tr>
<tr><td style='padding:3px'>WO-TO_11000176, WO-TO_11000177</td><td>Voided (177 after a removed payment line)</td><td>100.00 each</td></tr>
<tr><td style='padding:3px'>RTN-TO_11000019</td><td>Full return of INV-TO_11000132, Cash refund</td><td>25.00</td></tr>
<tr><td style='padding:3px'>PR-TO_11000003</td><td>2 x Air Filter 041 at 100.00 + 15% VAT, Branch-2</td><td>230.00</td></tr>
<tr><td style='padding:3px'>Portal item QA214-087</td><td>Submitted, synced, then Cancelled and synced</td><td>-</td></tr></table>
<b>4. Bugs (to be opened by QA)</b>
<ol><li>Inventory / Stock Value does not match stock: +5,000 shown for a 200.00 purchase (TC-029, TC-062).</li><li>Negative Gross Margin shown in green (TC-032, from 19/11).</li><li>Cosmetic: payment screen label stays "Enter Cash value" when Master is selected.</li></ol>
<b>5. Open questions</b>
<ol><li>Inventory tab: All (363) vs sum of sub-tabs (388) (TC-064).</li><li>Return Rate denominator (TC-046).</li><li>Cash Sales % / Other Payments % rule (TC-085).</li><li>A fully refunded invoice is counted in both Fully Paid (4) and Fully Refunded (1).</li><li>RService is sold without VAT while other services carry 15%: intended?</li></ol>
<b>6. Blocked / Not Run</b>
<ol><li>TC-006: needs a customer with a credit limit.</li><li>TC-075: Cash Deposit needs a closed day; retest after Close Day.</li><li>TC-009, 010, 033, 067, 071, 082: need specific days (no sales, refunds only, day change).</li></ol>
</div>
"@
# Stock tables check section (appended at the end)
$td = "border:1px solid #ccc;padding:3px 8px"
function StRow($cells, $res) { $bg = @{ 'OK'='#2e7d32'; 'ISSUE'='#c62828'; 'QUESTION'='#ca5010' }[$res]; "<tr>" + (($cells | % { "<td style='$td'>$_</td>" }) -join '') + "<td style='$td;background:$bg;color:#fff;font-weight:bold;text-align:center'>$res</td></tr>" }
$st = "<div style='border-left:4px solid #0078d4;background:#f3f9fd;padding:8px;margin:10px 0'><b>QA Results: Stock Tables Check (20/11/2026)</b>"
$st += "<p>Every stock movement of the day was traced through the database: source document -> InvStockIn / InvStockOut (RefDocumentID) -> InvStockInItem / InvStockOutItem -> InvStoreTransaction (signed BaseItemQuantity, ItemCost) -> InvItemBatch / InvItemBatchCost.</p>"
$st += "<table style='border-collapse:collapse;width:100%'><tr style='background:#0078d4;color:#fff'><th style='padding:4px'>Source document</th><th style='padding:4px'>Stock document</th><th style='padding:4px'>Item lines (base qty)</th><th style='padding:4px'>Store transaction</th><th style='padding:4px'>Result</th></tr>"
$st += StRow @('INV-TO_11000129 (Tire - Item sale)','OUT TO_11000183','1 line, 1','-1 at cost 55, Branch-2') 'OK'
$st += StRow @('PR-TO_11000003 (2 x Air Filter 041, Each = 2 base units)','IN TO_11000039','1 line, 4','+4 at cost 50; batch cost 50.00 written') 'OK'
$st += StRow @('WO-TO_11000173 / 174 / 175 (services only)','OUT TO_11000184 / 185 / 186','0 lines','none') 'QUESTION'
$st += StRow @('WO-TO_11000176 / 177 (voided)','OUT TO_11000187 / 188','0 lines','none') 'QUESTION'
$st += StRow @('RTN-TO_11000019 (return of QA_SST Brake Check, a Service)','IN TO_11000038, RefDocument = INV-TO_11000132','1 line, 1','+1 at cost 0, DocumentID = INV-TO_11000132 (not the return)') 'ISSUE'
$st += "</table><p><b>Findings</b></p><ol><li><b>Bug (to be opened):</b> returning a service item adds stock. The sale of the service moved no stock (correct) but the return wrote +1. Six service rows now hold stock in the branch stores (Car Wash 4 + 1, RService 2 + 1, Service - R 1, QA_SST Brake Check 1).</li><li><b>Question:</b> the Sales Return stock movement and its Stock In point to the original invoice ID, not to the return document, so the movement cannot be traced to RTN-TO_11000019.</li><li><b>Question:</b> service-only and voided Work Orders each create an empty Stock Out header (0 lines). Is this expected?</li></ol>"
foreach ($im in @(@("$S\run8\ssms\st01_chain.png",'SSMS: stock documents of the day linked to their source documents'), @("$S\run8\ssms\st02_chain.png",'SSMS: store transactions of the day with item type'), @("$S\run8\ssms\st03_chain.png",'SSMS: service items holding stock (should be none)'), @("$S\run8\ssms\st04_chain.png",'SSMS: batch cost written by the purchase'))) {
  $script:fig++; $url = "IMG::" + $im[0]
  if ($Apply) { $bytes = [IO.File]::ReadAllBytes($im[0]); $a = Invoke-RestMethod -UseDefaultCredentials -Method Post -Uri "$base/_apis/wit/attachments?fileName=2179_fig$($script:fig)_$([IO.Path]::GetFileName($im[0]))&api-version=5.0" -ContentType "application/octet-stream" -Body $bytes; $url = $a.url }
  $st += "<p><b>Figure $($script:fig): $($im[1])</b><br><img src='$url' style='max-width:900px;width:100%;border:1px solid #ccc'></p>"
}
$st += "</div>"
$out = $out + $st
$sum = $sum.Replace("<b>5. Open questions</b>", "<b>4b. Stock tables</b><ol><li>Bug (to be opened): returning a service item adds stock (see Stock Tables Check at the end).</li></ol><b>5. Open questions</b>")
$out = $sum + $out
[IO.File]::WriteAllText("$S\task2179_r8.html", $out)
"figures $fig; length $($out.Length); counts: " + (($cnt.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ') + " total $total"
if ($Apply) {
  $body = ConvertTo-Json -Depth 5 @(@{ op = "test"; path = "/rev"; value = 13 }, @{ op = "replace"; path = "/fields/System.Description"; value = $out })
  $r = Invoke-RestMethod -UseDefaultCredentials -Method Patch -Uri "$base/_apis/wit/workitems/2179?api-version=5.0" -ContentType "application/json-patch+json" -Body ([Text.Encoding]::UTF8.GetBytes($body))
  "Task 2179 updated to rev $($r.rev)"
}



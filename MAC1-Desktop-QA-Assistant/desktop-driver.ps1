# Desktop driver for the native (MAUI / WinUI 3) MacOne app.
# Protocol: one JSON command per stdin line, one JSON reply per stdout line.
# The Node side (desktop-session.js) picks elements; this script only lists, clicks, types and captures.
# Keep this file ASCII only: Windows PowerShell 5.1 reads scripts as ANSI.
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Windows.Forms, System.Drawing, System.Web.Extensions
$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$json.MaxJsonLength = [int]::MaxValue
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public class QaWin {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(int f, int x, int y, int d, int e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, int f, int e);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
}
'@
[QaWin]::SetProcessDPIAware() | Out-Null
$AE = [System.Windows.Automation.AutomationElement]
$script:proc = $null

function Get-AppProcess {
  if ($script:proc) {
    $script:proc.Refresh()
    if (-not $script:proc.HasExited) { return $script:proc }
  }
  throw 'The desktop app is not running.'
}

function Foreground-Pid {
  $h = [QaWin]::GetForegroundWindow(); $fpid = 0
  [QaWin]::GetWindowThreadProcessId($h, [ref]$fpid) | Out-Null
  return [int]$fpid
}

function Focus-App {
  $p = Get-AppProcess
  $h = $p.MainWindowHandle
  if ($h -eq [IntPtr]::Zero) { throw 'The desktop app has no main window.' }
  [QaWin]::ShowWindow($h, 9) | Out-Null   # restore if minimized
  Start-Sleep -Milliseconds 200
  [QaWin]::ShowWindow($h, 3) | Out-Null   # maximize
  for ($i = 0; $i -lt 8; $i++) {
    [QaWin]::keybd_event(0x12, 0, 0, 0); [QaWin]::keybd_event(0x12, 0, 2, 0)   # tap Alt so focus can move
    if ($i -ge 2) {
      # Windows lets a thread give focus away; join the input of the window that has it now.
      $fg = [QaWin]::GetForegroundWindow(); $fgPid = 0
      $fgThread = [QaWin]::GetWindowThreadProcessId($fg, [ref]$fgPid)
      $me = [QaWin]::GetCurrentThreadId()
      [QaWin]::AttachThreadInput($me, $fgThread, $true) | Out-Null
      [QaWin]::BringWindowToTop($h) | Out-Null
      [QaWin]::SetForegroundWindow($h) | Out-Null
      [QaWin]::SetFocus($h) | Out-Null
      [QaWin]::AttachThreadInput($me, $fgThread, $false) | Out-Null
    }
    if ($i -eq 5) {
      [QaWin]::ShowWindow($h, 6) | Out-Null; Start-Sleep -Milliseconds 300   # minimize, then maximize again
      [QaWin]::ShowWindow($h, 3) | Out-Null
    }
    [QaWin]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 350
    if ((Foreground-Pid) -eq $p.Id) { return }
  }
  throw 'The desktop app could not be brought to the foreground. Keep the remote desktop window open and do not use the mouse while the agent works.'
}

function Assert-Foreground {
  $p = Get-AppProcess
  if ((Foreground-Pid) -ne $p.Id) { Focus-App }
  if ((Foreground-Pid) -ne $p.Id) { throw 'Stopped: another window is in the foreground.' }
}

function Cmd-Attach($c) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($c.exePath)
  $p = Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
  $launched = $false
  if (-not $p) {
    # A running instance can briefly report no main window (popup, redraw); wait for it instead of starting a second one.
    $running = Get-Process -Name $name -ErrorAction SilentlyContinue
    if (-not $running) {
      if (-not $c.launch) { throw "The desktop app ($name) is not running." }
      Start-Process -FilePath $c.exePath -WorkingDirectory ([System.IO.Path]::GetDirectoryName($c.exePath)) | Out-Null
      $launched = $true
    }
    $deadline = (Get-Date).AddSeconds([int]$c.launchTimeoutSec)
    while ((Get-Date) -lt $deadline -and -not $p) {
      Start-Sleep -Milliseconds 700
      $p = Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
    }
    if (-not $p) { throw "The desktop app ($name) did not open a window in time." }
  }
  $script:proc = $p
  Focus-App
  return @{ pid = $p.Id; launched = $launched }
}

function Cmd-Elements {
  $p = Get-AppProcess
  $cond = New-Object System.Windows.Automation.PropertyCondition ($AE::ProcessIdProperty), $p.Id
  $wins = $AE::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, $cond)
  $out = New-Object System.Collections.Generic.List[object]
  foreach ($w in $wins) {
    $all = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($e in $all) {
      try {
        $cur = $e.Current
        if ($cur.IsOffscreen) { continue }
        $r = $cur.BoundingRectangle
        if ($r.IsEmpty -or $r.Width -le 0 -or $r.Height -le 0) { continue }
        $value = $null
        if ($cur.ControlType -eq [System.Windows.Automation.ControlType]::Edit) {
          $vp = $null
          if ($e.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$vp)) { $value = [string]$vp.Current.Value }
        }
        $out.Add(@{
          value = $value
          name = [string]$cur.Name
          type = ($cur.ControlType.ProgrammaticName -replace '^ControlType\.', '')
          help = [string]$cur.HelpText
          id = [string]$cur.AutomationId
          x = [int]$r.X; y = [int]$r.Y; w = [int]$r.Width; h = [int]$r.Height
        })
      } catch { }   # element vanished while reading
    }
  }
  return ,$out.ToArray()
}

function Cmd-Click($c) {
  Assert-Foreground
  [QaWin]::SetCursorPos([int]$c.x, [int]$c.y) | Out-Null
  Start-Sleep -Milliseconds 120
  [QaWin]::mouse_event(0x0002, 0, 0, 0, 0); [QaWin]::mouse_event(0x0004, 0, 0, 0, 0)
  Start-Sleep -Milliseconds 700
  return @{}
}

function Cmd-Keys($c) {
  Assert-Foreground
  [System.Windows.Forms.SendKeys]::SendWait([string]$c.keys)
  Start-Sleep -Milliseconds 300
  return @{}
}

function Cmd-Screenshot($c) {
  Assert-Foreground   # never capture another window (for example an editor showing secrets)
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save([string]$c.path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  return @{ path = [string]$c.path }
}

# ---- OCR fallback (Windows.Media.Ocr) -------------------------------------------------------
# Some MAUI popups (print prompt, mileage prompt) are invisible to UI Automation. OCR reads the
# app window as an image and returns each text line with its screen rectangle.
$script:ocr = $null
function Init-Ocr {
  if ($script:ocr) { return }
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
  $null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime]
  $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
  $null = [Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime]
  $script:asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
      $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
  $lang = New-Object Windows.Globalization.Language 'en-US'
  if ([Windows.Media.Ocr.OcrEngine]::IsLanguageSupported($lang)) { $script:ocr = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang) }
  if (-not $script:ocr) { $script:ocr = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages() }
  if (-not $script:ocr) { throw 'Windows OCR is not available on this computer.' }
}
function Await-WinRt($operation, [type]$resultType) {
  $task = $script:asTask.MakeGenericMethod($resultType).Invoke($null, @($operation))
  $task.Wait(-1) | Out-Null
  return $task.Result
}
function Cmd-Ocr {
  Assert-Foreground
  Init-Ocr
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $file = Join-Path $env:TEMP ("qa-agent-ocr-{0}.png" -f $PID)
  $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
  try {
    $sf = Await-WinRt ([Windows.Storage.StorageFile]::GetFileFromPathAsync($file)) ([Windows.Storage.StorageFile])
    $stream = Await-WinRt ($sf.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
    $decoder = Await-WinRt ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
    $soft = Await-WinRt ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
    $result = Await-WinRt ($script:ocr.RecognizeAsync($soft)) ([Windows.Media.Ocr.OcrResult])
    $stream.Dispose()
  } finally { Remove-Item $file -ErrorAction SilentlyContinue }
  $lines = New-Object System.Collections.Generic.List[object]
  foreach ($line in $result.Lines) {
    $words = @()
    foreach ($w in $line.Words) {
      $r = $w.BoundingRect
      $words += @{ text = [string]$w.Text; x = [int]$r.X; y = [int]$r.Y; w = [int]$r.Width; h = [int]$r.Height }
    }
    $lines.Add(@{ text = [string]$line.Text; words = $words })
  }
  return ,$lines.ToArray()
}

while ($true) {
  $line = [Console]::In.ReadLine()
  if ($null -eq $line) { break }
  if (-not $line.Trim()) { continue }
  $reply = $null
  try {
    $c = $line | ConvertFrom-Json
    switch ($c.cmd) {
      'attach' { $data = Cmd-Attach $c }
      'focus' { Focus-App; $data = @{} }
      'elements' { $data = Cmd-Elements }
      'click' { $data = Cmd-Click $c }
      'keys' { $data = Cmd-Keys $c }
      'screenshot' { $data = Cmd-Screenshot $c }
      'ocr' { $data = Cmd-Ocr }
      'quit' { $data = @{} }
      default { throw "Unknown command: $($c.cmd)" }
    }
    $reply = @{ id = $c.id; ok = $true; data = $data }
  } catch {
    $reply = @{ id = $c.id; ok = $false; error = $_.Exception.Message }
  }
  [Console]::Out.WriteLine($json.Serialize($reply))
  [Console]::Out.Flush()
  if ($c.cmd -eq 'quit') { break }
}

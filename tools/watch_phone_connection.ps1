param(
    [string]$DeviceId,
    [string]$AdbPath = (Join-Path $env:LOCALAPPDATA 'Android/sdk/platform-tools/adb.exe'),
    [int]$IntervalSeconds = 15,
    [switch]$Stop
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path $PSScriptRoot -Parent
$statePath = Join-Path $workspace 'build/phone-connection.json'
$logPath = Join-Path $workspace 'build/phone-connection.log'
if ($Stop) {
    if (Test-Path -LiteralPath $statePath) {
        $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
        $watchProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$($state.pid)"
        if ($watchProcess -and $watchProcess.CommandLine.Replace('/', '\').IndexOf($PSCommandPath.Replace('/', '\'), [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Stop-Process -Id $state.pid
            Wait-Process -Id $state.pid -Timeout 5 -ErrorAction SilentlyContinue
            $state.connected = $false
            $state.serial = ''
            [IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
            Write-Output 'Phone connection watcher stopped.'
        }
    }
    exit
}
if ($DeviceId -notmatch '^[A-Za-z0-9_-]+$') { throw 'A paired device ID is required.' }
if (!(Test-Path -LiteralPath $AdbPath)) { throw 'ADB executable not found.' }
New-Item -ItemType Directory -Force -Path (Split-Path $statePath -Parent) | Out-Null
$created = $false
$mutex = [Threading.Mutex]::new($true, "Local\CevsenPhoneWatch-$DeviceId", [ref]$created)
if (!$created) { $mutex.Dispose(); exit }

function Invoke-Adb([string[]]$AdbArguments) {
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $AdbPath
    $info.Arguments = ($AdbArguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(6000)) {
            $process.Kill()
            return ''
        }
        return $outputTask.Result
    } finally { $process.Dispose() }
}

$escapedId = [regex]::Escape($DeviceId)
$previousStatus = ''
try {
    while ($true) {
        $serial = ''
        try {
            $devices = Invoke-Adb @('devices')
            $match = [regex]::Match($devices, "(?m)^(adb-$escapedId-.+?)\s+device(?:\s|$)")
            if ($match.Success) {
                $candidate = $match.Groups[1].Value.Trim()
                if ((Invoke-Adb @('-s', $candidate, 'shell', 'getprop', 'ro.serialno')).Trim() -eq $DeviceId) {
                    $serial = $candidate
                }
            }
            if (!$serial) {
                $services = Invoke-Adb @('mdns', 'services')
                $serviceMatches = [regex]::Matches($services, "(?m)^adb-$escapedId-.*_adb-tls-connect\._tcp\s+(\S+)\s*$")
                foreach ($service in $serviceMatches) {
                    $candidate = $service.Groups[1].Value
                    [void](Invoke-Adb @('connect', $candidate))
                    if ((Invoke-Adb @('-s', $candidate, 'shell', 'getprop', 'ro.serialno')).Trim() -eq $DeviceId) {
                        $serial = $candidate
                        break
                    }
                }
            }
        } catch { $serial = '' }
        $status = if ($serial) { 'connected' } else { 'waiting' }
        if ($status -ne $previousStatus) {
            Add-Content -LiteralPath $logPath -Value "$([DateTime]::UtcNow.ToString('o')) $status"
            $previousStatus = $status
        }
        $state = @{ pid = $PID; deviceId = $DeviceId; serial = $serial;
            connected = [bool]$serial; updatedUtc = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json
        [IO.File]::WriteAllText($statePath + '.tmp', $state, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath ($statePath + '.tmp') -Destination $statePath -Force
        Start-Sleep -Seconds ([Math]::Max(5, $IntervalSeconds))
    }
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }

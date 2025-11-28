#muti thread crawler v2
$ipRange    = "10.246.12."
$startIP    = 1
$endIP      = 254
$MaxThreads = 64         
$TimeoutMs  = 1000

$hostnames  = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
$logFile    = "$PSScriptRoot\PingSweep_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    if ($logFile) { Add-Content -Path $logFile -Value $line -Encoding UTF8 }
}

$sw = [Diagnostics.Stopwatch]::StartNew()
Write-Log "Scanning $ipRange$startIP - $ipRange$endIP (max $MaxThreads threads) → only real hostnames"

$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()
$Jobs = @()

$ScriptBlock = {
    param($ip, $TimeoutMs, $Bag)

    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $result = $ping.Send($ip, $TimeoutMs)
        if ($result.Status -eq 'Success') {
            try {
                $entry = [Net.Dns]::GetHostEntry($ip)
                $fqdn      = $entry.HostName
                $shortName = ($fqdn -split '\.')[0].Trim().ToUpper()  
                if ($shortName -and $shortName -notmatch '^\d+$') {  
                    $msg = "UP   $ip  →  $shortName"
                    [Console]::WriteLine("[$(Get-Date -Format HH:mm:ss)] $msg")
                    $Bag.Add($shortName)
                }
            } catch { }
        }
    } catch { }
}

for ($i = $startIP; $i -le $endIP; $i++) {
    $ip = "$ipRange$i"
    $ps = [PowerShell]::Create().AddScript($ScriptBlock)
    $ps.AddArgument($ip)       | Out-Null
    $ps.AddArgument($TimeoutMs)| Out-Null
    $ps.AddArgument($hostnames)| Out-Null
    $ps.RunspacePool = $RunspacePool
    $Jobs += [pscustomobject]@{ Pipe = $ps; Handle = $ps.BeginInvoke() }
}

while ($Jobs.Handle.IsCompleted -contains $false) { Start-Sleep -Milliseconds 100 }

$Jobs | ForEach-Object { $_.Pipe.Dispose() }
$RunspacePool.Close(); $RunspacePool.Dispose()

$finalList = $hostnames | Sort-Object -Unique

Write-Log "`n=== SCAN FINISHED ==="
Write-Log "Found $($finalList.Count) real hostnames:"
$finalList | ForEach-Object { Write-Log "  $_" }

$sw.Stop()
Write-Log "Time taken: $($sw.Elapsed.ToString('mm\:ss\.fff'))`n"

Write-Host "`nHOSTNAMES ONLY:`n" -ForegroundColor Yellow
$finalList -join "," | Write-Host -ForegroundColor Cyan

if ($logFile) {
    Write-Host "`nFull log: $logFile" -ForegroundColor Gray
}
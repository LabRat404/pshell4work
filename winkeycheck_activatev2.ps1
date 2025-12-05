#supports muti thread now
#$hosts = @("hosts")

$key = "KEY"

$MaxThreadsCheck = 50
$MaxThreadsApply = 30
$StartTime   = Get-Date
$Stopwatch   = [System.Diagnostics.Stopwatch]::StartNew()

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$time] $Message" -ForegroundColor $Color
}

Write-Log "=== WINDOWS ACTIVATION SCAN STARTED ===" "Cyan"
Write-Log "Hosts to check : $($hosts.Count)" "Cyan"

$results = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()

Write-Log "Phase 1: Checking activation status..." "Yellow"

$Pool = [RunspaceFactory]::CreateRunspacePool(1, $MaxThreadsCheck)
$Pool.Open()
$Jobs = @()

$CheckScriptBlock = {
    param($hostname)
    $obj = [pscustomobject]@{
        ComputerName      = $hostname
        ActivationStatus  = "Timeout"
        PartialProductKey = $null
        Timestamp         = Get-Date
    }
    try {
        $remote = Invoke-Command -ComputerName $hostname -ScriptBlock {
            $lic = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" |
                   Where-Object PartialProductKey
            if ($lic -is [array]) {
                $sel = $lic | Where-Object LicenseStatus -eq 1 | Select-Object -First 1
                if (-not $sel) { $sel = $lic[0] }
            } else { $sel = $lic }
            $status = switch ($sel.LicenseStatus) {
                0 {"Unlicensed"} 1 {"Licensed"} 2 {"OOBGrace"} 3 {"OOTGrace"}
                4 {"NonGenuineGrace"} 5 {"Not Activated"} 6 {"ExtendedGrace"}
                default {"Unknown"}
            }
            [pscustomobject]@{
                ComputerName      = $env:COMPUTERNAME
                ActivationStatus  = $status
                PartialProductKey = $sel.PartialProductKey
            }
        } -ErrorAction Stop -WarningAction SilentlyContinue

        $obj.ComputerName      = $remote.ComputerName
        $obj.ActivationStatus  = $remote.ActivationStatus
        $obj.PartialProductKey = $remote.PartialProductKey
    }
    catch {
        $obj.ActivationStatus = "Unreachable"
    }
    $obj
}

foreach ($h in $hosts) {
    $ps = [powershell]::Create().AddScript($CheckScriptBlock).AddArgument($h)
    $ps.RunspacePool = $Pool
    $Jobs += [pscustomobject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
}

while ($Jobs.Handle.IsCompleted -contains $false) {
    $done = ($Jobs.Handle.IsCompleted -eq $true).Count
    Write-Progress -Activity "Checking hosts" -Status "$done / $($hosts.Count)" -PercentComplete ($done/$hosts.Count*100)
    Start-Sleep -Milliseconds 200
}
Write-Progress -Activity "Checking hosts" -Completed

foreach ($j in $Jobs) { $results.Add($j.PS.EndInvoke($j.Handle)); $j.PS.Dispose() }
$Pool.Close(); $Pool.Dispose()

$all = $results | Sort-Object Timestamp

Write-Log "Phase 1 Complete → Results:" "Yellow"
foreach ($r in $all) {
    $ppk = if ($r.PartialProductKey) { $r.PartialProductKey } else { "N/A" }
    $color = if ($r.ActivationStatus -eq "Licensed") { "Green" }
             elseif ($r.ActivationStatus -eq "Unreachable") { "Gray" }
             else { "Red" }
    Write-Host ("  {0,-15} : {1} (Last5: {2})" -f $r.ActivationStatus, $r.ComputerName, $ppk) -ForegroundColor $color
}

$all | Group-Object ActivationStatus | Sort Name | ForEach-Object {
    $c = if ($_.Name -eq "Licensed") {"Green"} elseif ($_.Name -eq "Unreachable") {"Gray"} else {"Red"}
    Write-Host "    $($_.Name): $($_.Count)" -ForegroundColor $c
}


$needsFix = $all | Where-Object { $_.ActivationStatus -in "Unlicensed","Not Activated" }

if ($needsFix) {
    Write-Log "Phase 2: $($needsFix.Count) host(s) need activation!" "Red"

    $answer = Read-Host "  Apply key now? (Y/N)"
    if ($answer -match '^[Yy]') {
        Write-Log "Applying key using $MaxThreadsApply parallel threads..." "Yellow"

        $ApplyPool = [RunspaceFactory]::CreateRunspacePool(1, $MaxThreadsApply)
        $ApplyPool.Open()
        $ApplyJobs = @()

        $ApplyScriptBlock = {
            param($hostname, $key)
            try {
                Invoke-Command -ComputerName $hostname -ScriptBlock {
                    param($k) slmgr /ipk $k /quiet; Start-Sleep -Seconds 25; slmgr /ato /quiet
                } -ArgumentList $key -ErrorAction Stop | Out-Null
                "SUCCESS → $hostname"
            } catch {
                "FAILED  → $hostname : $($_.Exception.Message)"
            }
        }

        foreach ($h in $needsFix) {
            $ps = [powershell]::Create().AddScript($ApplyScriptBlock)
            $ps.AddArgument($h.ComputerName) | Out-Null
            $ps.AddArgument($key)           | Out-Null
            $ps.RunspacePool = $ApplyPool
            $ApplyJobs += [pscustomobject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
        }

        while ($ApplyJobs.Handle.IsCompleted -contains $false) { Start-Sleep -Milliseconds 500 }

        foreach ($j in $ApplyJobs) {
            $msg = $j.PS.EndInvoke($j.Handle)
            if ($msg -like "SUCCESS*") { Write-Host "  $msg" -ForegroundColor Green }
            else { Write-Host "  $msg" -ForegroundColor Red }
            $j.PS.Dispose()
        }
        $ApplyPool.Close(); $ApplyPool.Dispose()

        Write-Log "Key application completed!" "Green"
    } else {
        Write-Log "Key application skipped by user." "Cyan"
    }
} else {
    Write-Log "All hosts are already Licensed and activated!" "Green"
}

$Stopwatch.Stop()
$EndTime = Get-Date
$Elapsed = $Stopwatch.Elapsed.ToString("hh\:mm\:ss")

Write-Log "=== SCAN COMPLETED ===" "Cyan"
Write-Host "  Start Time   : " -NoNewline; Write-Host $StartTime.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor Gray
Write-Host "  End Time     : " -NoNewline; Write-Host $EndTime.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor Gray
Write-Host "  Elapsed Time : " -NoNewline; Write-Host $Elapsed -ForegroundColor Yellow
Write-Host "  Total Hosts  : $($hosts.Count) | Fixed: $($needsFix.Count)" -ForegroundColor Cyan
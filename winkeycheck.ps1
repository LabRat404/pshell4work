$hosts = @("hosts")
$key = "key" 

$results = @()

$total = $hosts.Count
$counter = 0

foreach ($hostname in $hosts) {
    $counter++
    $remaining = $total - $counter

    Write-Host "`nChecking computer: $hostname ($counter of $total). Remaining: $remaining" -ForegroundColor Cyan

    try {
        $status = Invoke-Command -ComputerName $hostname -ScriptBlock {
            $lic = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" |
                Where-Object { $_.PartialProductKey } |
                Select-Object LicenseStatus, PartialProductKey

            # If multiple entries, pick the one that is Licensed first; otherwise first entry
            if ($lic -is [System.Array]) {
                $selected = $lic | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
                if (-not $selected) { $selected = $lic | Select-Object -First 1 }
            } else {
                $selected = $lic
            }

            # Map LicenseStatus numeric -> friendly text
            $LicenseResult = switch ($selected.LicenseStatus) {
                0 { "Unlicensed" }
                1 { "Licensed" }
                2 { "OOBGrace" }
                3 { "OOTGrace" }
                4 { "NonGenuineGrace" }
                5 { "Not Activated" }
                6 { "ExtendedGrace" }
                default { "Unknown" }
            }

            # Return object
            [PSCustomObject]@{
                ComputerName      = $env:COMPUTERNAME
                ActivationStatus  = $LicenseResult
                PartialProductKey = $selected.PartialProductKey
            }
        } -ErrorAction Stop
    } catch {
        $status = [PSCustomObject]@{
            ComputerName      = $hostname
            ActivationStatus  = "Unreachable"
            PartialProductKey = $null
            Error             = $_.Exception.Message
        }
        Write-Host "Failed to query $hostname : $($_.Exception.Message)" -ForegroundColor Red
    }

    $results += $status
}

# Results
Write-Host "`nActivation Status Results:" -ForegroundColor Yellow
foreach ($result in $results) {
    $ppk = if ($result.PartialProductKey) { $result.PartialProductKey } else { "N/A" }
    Write-Host ("{0}: {1} (Last5: {2})" -f $result.ActivationStatus, $result.ComputerName, $ppk)
}

Write-Host "`n======================" -ForegroundColor Yellow
Write-Host "Summary by Status:" -ForegroundColor Yellow

$grouped = $results | Group-Object -Property ActivationStatus
foreach ($group in $grouped) {
    $color = switch ($group.Name) {
        "Licensed"         { "Green" }
        "Unlicensed"       { "Red" }
        "OOBGrace"         { "Red" }
        "OOTGrace"         { "Red" }
        "NonGenuineGrace"  { "Red" }
        "Not Activated"    { "Red" }
        "ExtendedGrace"    { "Blue" }
        "Unreachable"      { "Gray" }
        default            { "Gray" }
    }
    Write-Host "$($group.Name): $($group.Count)" -ForegroundColor $color
}

# Determine hosts needing activation or key re-apply:
#   - ActivationStatus in Unlicensed / Not Activated
#   - OR last 5 chars end with WTYPF 
$pendingHosts = $results | Where-Object {
    ($_?.ActivationStatus -in @("Unlicensed", "Not Activated")) -or
    ($_.PartialProductKey -match '(?i)WTYPF$')
}

if ($pendingHosts -and $pendingHosts.Count -gt 0) {
    Write-Host "`nThe following hosts need activation or re-application (Unlicensed/Not Activated or key ends with WTYPF):" -ForegroundColor Red
    $pendingHosts | ForEach-Object {
        $ppk = if ($_.PartialProductKey) { $_.PartialProductKey } else { "N/A" }
        Write-Host ("- {0} (Status: {1}, Last5: {2})" -f $_.ComputerName, $_.ActivationStatus, $ppk) -ForegroundColor Red
    }

    # Confirm before applying key
    $choice = Read-Host "`nDo you want to apply the new key to these hosts? (Y/N)"
    if ($choice -match '^[Yy]$') {
        foreach ($addhost in $pendingHosts) {
            Write-Host "Applying license key to $($addhost.ComputerName)..." -ForegroundColor Yellow
            try {
                Invoke-Command -ComputerName $addhost.ComputerName -ScriptBlock {
                    param($key)
                    slmgr /ipk $key /quiet
                    Start-Sleep -Seconds 30
                    slmgr /ato /quiet
                } -ArgumentList $key -ErrorAction Stop

                Write-Host "License key applied and activation attempted on $($addhost.ComputerName)." -ForegroundColor Green
            } catch {
                Write-Host "Failed to apply key on $($addhost.ComputerName): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No changes made." -ForegroundColor Cyan
    }
} else {
    Write-Host "`nNo hosts found that require activation or re-application." -ForegroundColor Green
}
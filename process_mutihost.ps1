$remoteComputers = @("HOSTNAME")
$softwareHosts = @{}

# Get credentials
$credential = Get-Credential testsuer_sym

foreach ($remoteComputer in $remoteComputers) {
    Write-Output "Checking $remoteComputer..."
    $pingResult = Test-Connection -ComputerName $remoteComputer -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
        $session = New-PSSession -ComputerName $remoteComputer -Credential $credential -ErrorAction Stop
        $runningApps = Invoke-Command -Session $session -ScriptBlock {
            Get-Process | Select-Object Name, Id, CPU, StartTime # | Where-Object { $_.Name -like "*Stagent*" }
        }
        if ($runningApps) {
            foreach ($app in $runningApps) {
                if ($app.Name) {
                    if ($softwareHosts.ContainsKey($app.Name)) {
                        $softwareHosts[$app.Name] += ", $remoteComputer"
                    } else {
                        $softwareHosts[$app.Name] = "$remoteComputer"
                    }
                }
            }
        } else {
            Write-Output "$remoteComputer : Not found"
        }
        Remove-PSSession -Session $session
    } else {
        Write-Output "$remoteComputer : Unreachable"
    }

    Write-Output ""
}

Write-Output "`nList of running applications process and their hosts:"
foreach ($software in $softwareHosts.Keys) {
    Write-Output "$software : $($softwareHosts[$software])"
}
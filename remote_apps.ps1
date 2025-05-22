$remoteComputers = @("HOSTNAME") 

foreach ($remoteComputer in $remoteComputers) {
    Write-Output "Checking $remoteComputer..."
     $pingResult = Test-Connection -ComputerName $remoteComputer -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
         $session = New-PSSession -ComputerName $remoteComputer -ErrorAction Stop
        $installedApps = Invoke-Command -Session $session -ScriptBlock {
            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate # | Where-Object { $_.DisplayName -like "*netskope*" }
        }
        if ($installedApps) {
            Write-Output "$remoteComputer : Applications"
            $installedApps | Format-Table -AutoSize
        } else {
            Write-Output "$remoteComputer : Not found"
        }
        Remove-PSSession -Session $session
    } else {
        Write-Output "$remoteComputer : Unreachable"
    }

    Write-Output "" 
}
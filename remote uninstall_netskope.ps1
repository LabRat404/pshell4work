# Define the remote computer names
$remoteComputers = @("HOSTNAME")
$appName = "netskope"
$psName = "STAgent"
foreach ($remoteComputer in $remoteComputers) {

 $pingResult = Test-Connection -ComputerName $remoteComputer -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
    # Check if the application is installed
    
 $installedApps = ""
 $installedApps = Get-WmiObject -Class Win32_Product -ComputerName $remoteComputer | Where-Object { $_.Name -like "*$appName*" }

if ($installedApps) {
    # Display the installed applications
    $installedApps | ForEach-Object {
        Write-Output "Name: $($_.Name)"
        Write-Output "Version: $($_.Version)"
        Write-Output "Vendor: $($_.Vendor)"
        Write-Output "Install Date: $($_.InstallDate)"
        Write-Output "Package ID: $($_.IdentifyingNumber)"
        Write-Output "-----------------------------------"
    }


        # Check for running processes and display them
        $pingResult = Test-Connection -ComputerName $remoteComputer -Count 1 -ErrorAction SilentlyContinue
        if ($pingResult) {
            $session = New-PSSession -ComputerName $remoteComputer -ErrorAction Stop
            $runningApps = Invoke-Command -Session $session -ScriptBlock {
                param ($psName)
                Get-Process | Select-Object Name, Id, CPU, StartTime | Where-Object { $_.Name -like "$psName*" }
            } -ArgumentList $psName
            if ($runningApps) {
                Write-Output "Running processes:"
                $runningApps | ForEach-Object {
                    Write-Output "Process Name: $($_.Name)"
                    Write-Output "Process ID: $($_.Id)"
                    Write-Output "CPU Usage: $($_.CPU)"
                    Write-Output "Start Time: $($_.StartTime)"
                    Write-Output "-----------------------------------"
                }
            } else {
                Write-Output "No running processes found with the name '$psName' on $remoteComputer."
            }
            Remove-PSSession -Session $session
        }

        # Ask for confirmation to uninstall
        $confirmation = Read-Host "Do you want to uninstall the above applications on $remoteComputer? (y/n)"
        if ($confirmation -eq "y" -or $confirmation -eq "Y") {
            # Stop the running processes
            $pingResult = Test-Connection -ComputerName $remoteComputer -Count 1 -ErrorAction SilentlyContinue
            if ($pingResult) {
                        
             
        Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
    param ($psName, $remoteComputer)
    Get-Process | Where-Object { $_.Name -like "$psName*" }# | ForEach-Object { $_.Kill() }
    Write-Host "Killed all processes containing '$psName' on $remoteComputer"
} -ArgumentList $psName, $remoteComputer

  # Continue with the rest of the script
                Write-Host "Wait for 2 second."
                Start-Sleep -Seconds 2

              
                
         Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
    param ($psName, $remoteComputer)
    Get-Process | Where-Object { $_.Name -like "$psName*" } #| ForEach-Object { $_.Kill() }
    Write-Host "Killed all processes containing '$psName' on $remoteComputer again."
} -ArgumentList $psName, $remoteComputer
            }

            # Uninstall the application and filter out unnecessary properties
            $installedApps | ForEach-Object {
            $productCode = $_.IdentifyingNumber
            $password = '"password"'
            Write-Output $productCode
            $cmd = "psexec \\$remoteComputer cmd /c 'msiexec /uninstall $productCode PASSWORD=$password /qn'"
            $cmd
            Invoke-Expression $cmd
         
            }
        } else {
            Write-Output "Uninstallation cancelled."
        }
    } else {
        Write-Output "No applications found with the name '$appName' on $remoteComputer."
    }
}else {
        Write-Output "$remoteComputer : Unreachable"
    }

}
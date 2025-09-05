$localMsiPath = "C:\netskopeInstall\SymphonyDesktopApplication-Win64-25.7.0.msi"
$remoteFolderPath = "C:\netskopeInstall"
#for kill app ps
$appName = "Symphony"
$symHosts = @()
$unreach = @()
$notFound = @()
$remoteComputerNames = @("hostname/s")
foreach ($remoteComputerName in $remoteComputerNames) {

    $startTime = [datetime]::Now
    Write-Host "Processing $remoteComputerName..."
    $pingResult = Test-Connection -ComputerName $remoteComputerName -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {

        $installedApps = ""
        $installedApps = Get-WmiObject -Class Win32_Product -ComputerName $remoteComputerName | Where-Object { $_.Name -eq "$appName" }

        #check ps
        if ($installedApps) {
            $installedApps | ForEach-Object {
                Write-Output "Name: $($_.Name)"
                Write-Output "Version: $($_.Version)"
                Write-Output "Vendor: $($_.Vendor)"
                Write-Output "Install Date: $($_.InstallDate)"
                Write-Output "Package ID: $($_.IdentifyingNumber)"
                Write-Output "-----------------------------------"
            }
            # kill ps
            Invoke-Command -ComputerName $remoteComputerName -ScriptBlock {
                Get-Process | Where-Object { $_.Name -eq "Symphony" }
                Get-Process | Where-Object { $_.Name -eq "Symphony" } | Stop-Process -Force
            }

            # Create the folder on the remote PC
            $folderStartTime = [datetime]::Now
            Invoke-Command -ComputerName $remoteComputerName -ScriptBlock {
                param ($folderPath)
                if (-Not (Test-Path -Path $folderPath)) {
                    New-Item -ItemType Directory -Path $folderPath
                    Write-Host "Folder created: $folderPath"
                }
                else {
                    Write-Host "Folder already exists: $folderPath"
                }
            } -ArgumentList $remoteFolderPath
            $folderEndTime = [datetime]::Now
            $folderElapsedTime = ($folderEndTime - $folderStartTime).TotalSeconds
            Write-Host "Folder creation done - took $folderElapsedTime seconds, total $([math]::Round(($folderEndTime - $startTime).TotalSeconds, 2)) seconds"

            # Test the creation of the folder
            $testStartTime = [datetime]::Now
            $folderExists = Invoke-Command -ComputerName $remoteComputerName -ScriptBlock {
                param ($folderPath)
                Test-Path -Path $folderPath
            } -ArgumentList $remoteFolderPath
            $testEndTime = [datetime]::Now
            $testElapsedTime = ($testEndTime - $testStartTime).TotalSeconds
            Write-Host "Folder verification done - took $testElapsedTime seconds, total $([math]::Round(($testEndTime - $startTime).TotalSeconds, 2)) seconds"

            if ($folderExists) {
                Write-Host "Folder creation verified on $remoteComputerName."

                # Copy the MSI file to the remote PC
                $copyStartTime = [datetime]::Now
                Copy-Item -Path $localMsiPath -Destination "\\$remoteComputerName\C$\netskopeInstall"
                $copyEndTime = [datetime]::Now
                $copyElapsedTime = ($copyEndTime - $copyStartTime).TotalSeconds
                Write-Host "MSI file copied - took $copyElapsedTime seconds, total $([math]::Round(($copyEndTime - $startTime).TotalSeconds, 2)) seconds"
            
                # Create the install command
                $installCmd = "/i C:\netskopeInstall\SymphonyDesktopApplication-Win64-25.7.0.msi pod_url=https://symmetry.symphony.com /quiet"


            
                # Execute the install command on the remote PC
                $installStartTime = [datetime]::Now
                Invoke-Command -ComputerName $remoteComputerName -ScriptBlock {
                    param ($cmd)
                    Start-Process -FilePath "msiexec.exe" -ArgumentList $cmd -Wait
                    Write-Host "Installation completed on $using:remoteComputerName."
                } -ArgumentList $installCmd
                $installEndTime = [datetime]::Now
                $installElapsedTime = ($installEndTime - $installStartTime).TotalSeconds


                Write-Host "Installation completed - took $installElapsedTime seconds, total $([math]::Round(($installEndTime - $startTime).TotalSeconds, 2)) seconds"

                $symHosts += $remoteComputerName


            }
            else {
                Write-Host "Failed to create the folder on $remoteComputerName."
                $unreach += $remoteComputerName
            }
        }
        else {
            Write-Output "$remoteComputerName : No Symphony found"
            $notFound += $remoteComputerName
        }
   
    }
    else {
        Write-Output "$remoteComputerName : Unreachable"
        $unreach += $remoteComputerName
    }

    $endTime = [datetime]::Now
    $elapsedTime = ($endTime - $startTime).TotalSeconds
    Write-Host "All procedures completed for $remoteComputerName - total $elapsedTime seconds"
}



Write-Host "Done install on:"
$symHosts | ForEach-Object { Write-Host $_ }
Write-Output "-----------------------------------"
Write-Host "Unreachable:"
$unreach | ForEach-Object { Write-Host $_ }
Write-Output "-----------------------------------"
Write-Host "App not found:"
$notFound | ForEach-Object { Write-Host $_ }
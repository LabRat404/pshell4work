# Define the parameters
$localMsiPath = "C:\netskopeInstall\NSClient.msi"
$remoteFolderPath = "C:\netskopeInstall"
$remoteMsiPath = "$remoteFolderPath\NSClient.msi"
$remoteComputerNames = @("hostname")

foreach ($remoteComputerName in $remoteComputerNames) {
    $startTime = [datetime]::Now
    Write-Host "Processing $remoteComputerName..."
    $pingResult = Test-Connection -ComputerName $remoteComputerName -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
        # Create the folder on the remote PC
        $folderStartTime = [datetime]::Now
        Invoke-Command -ComputerName $remoteComputerName -ScriptBlock {
            param ($folderPath)
            if (-Not (Test-Path -Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath
                Write-Host "Folder created: $folderPath"
            } else {
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
            $installCmd = "/i C:\netskopeInstall\NSClient.msi token=TOKEN host=addon-HOST.goskope.com enrollauthtoken=ENROLLTOKEN npavdimode=on autoupdate=on mode=peruserconfig"

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
        } else {
            Write-Host "Failed to create the folder on $remoteComputerName."
        }
    } else {
        Write-Output "$remoteComputerName : Unreachable"
    }
    $endTime = [datetime]::Now
    $elapsedTime = ($endTime - $startTime).TotalSeconds
    Write-Host "All procedures completed for $remoteComputerName - total $elapsedTime seconds"
}
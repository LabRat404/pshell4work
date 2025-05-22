# Define the parameters
$localMsiPath = "C:\tmp3\node-v23.10.0-x64.msi"
$remoteFolderPath = "C:\tmp3\node-v23.10.0-x64.msi"
$remoteMsiPath = "C:\tmp3\node-v23.10.0-x64.msi"
$remoteComputerNames = @("symhkdt116") # Add more remote computer names as needed

foreach ($remoteComputerName in $remoteComputerNames) {
  


        # Create the install command
        $installCmd = "/i C:\tmp3\node-v23.10.0-x64.msi /quiet /norestart "

        # Execute the install command on the remote PC
        Invoke-Command -ComputerName $remoteComputerName -ScriptBlock {
            param ($cmd)
            Start-Process -FilePath "msiexec.exe" -ArgumentList $cmd -Wait
            Write-Host "Installation completed on $using:remoteComputerName."
        } -ArgumentList $installCmd


}
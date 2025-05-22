# Define the list of PCs
$lines = @("PC1", "PC2", "PC3")

# Define the credentials
$creds = Get-Credential

# Initialize an array to store the results
$results = @()

# Loop through each PC in the list
foreach ($pc in $lines) {
    # Check if the PC is online using credentials
    if (Test-Connection -ComputerName $pc -Count 1 -Quiet) {
        # Get the active sessions on the PC
        $sessions = Get-WmiObject -Class Win32_LogonSession -ComputerName $pc -Credential $creds | 
                    Where-Object { $_.LogonType -eq 2 } | 
                    ForEach-Object {
                        $user = Get-WmiObject -Class Win32_LoggedOnUser -ComputerName $pc -Credential $creds | 
                                Where-Object { $_.Dependent -match $_.Antecedent } | 
                                Select-Object -ExpandProperty Antecedent
                        [PSCustomObject]@{
                            PCName = $pc
                            UserName = $user
                            SessionID = $_.LogonId
                        }
                    }
        $results += $sessions
    } else {
        $results += [PSCustomObject]@{
            PCName = $pc
            UserName = "Offline"
            SessionID = "N/A"
        }
    }
}

# Output the results
$results | Format-Table -AutoSize
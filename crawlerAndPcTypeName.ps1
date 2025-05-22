# Define the IP range
$ipRange = "10.246.12."
$startIP = 1
$endIP = 254
$hostnames = @()
$machineTypes = @{}

for ($i = $startIP; $i -le $endIP; $i++) {
    $ip = "$ipRange$i"
    Write-Output "Pinging $ip..."
    $pingResult = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
        try {
            $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            $hostname = $hostname -replace "\.options-it\.com$", "" # Remove .options-it.com
            Write-Output "IP Address: $ip, Hostname: $hostname is reachable."
            $hostnames += $hostname

            # Get the computer module name
            $computerModuleName = Invoke-Command -ComputerName $hostname -ScriptBlock {
                Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
            }

            # Add the computer module name to the machine types list
            if ($machineTypes.ContainsKey($computerModuleName)) {
                $machineTypes[$computerModuleName].Count += 1
                $machineTypes[$computerModuleName].Hostnames += $hostname
            } else {
                $machineTypes[$computerModuleName] = [PSCustomObject]@{
                    Count = 1
                    Hostnames = @($hostname)
                }
            }
        } catch {
            Write-Output "IP Address: $ip is reachable, but hostname could not be resolved."
        }
    } else {
        Write-Output "IP Address: $ip is not reachable."
    }
}

Write-Output "`nMachine types and their counts:"
foreach ($machineType in $machineTypes.Keys) {
    $hostnamesString = $machineTypes[$machineType].Hostnames -join ", "
    Write-Output "$machineType : $($machineTypes[$machineType].Count), $hostnamesString"
}
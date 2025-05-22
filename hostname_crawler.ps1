$ipRange = "10.246.12."
$startIP = 1
$endIP = 254
$hostnames = @()

for ($i = $startIP; $i -le $endIP; $i++) {
    $ip = "$ipRange$i"
    Write-Output "Pinging $ip..."
    $pingResult = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
        try {
            $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            Write-Output "IP Address: $ip, Hostname: $hostname is reachable."
            $hostnames += $hostname
        } catch {
            Write-Output "IP Address: $ip is reachable, but hostname could not be resolved."
        }
    } else {
        Write-Output "IP Address: $ip is not reachable."
    }
}

Write-Output "`nList of reachable hostnames:"
$hostnamesString = $hostnames -join ", "
Write-Output $hostnamesString
$hosts = @(
  ""
)

foreach ($hostname in $hosts) {
    Write-Host "Pinging $hostname..." -ForegroundColor Cyan
    for ($i = 1; $i -le 1; $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $pingResult = Test-Connection -ComputerName $hostname -Count 1 -Quiet
        if ($pingResult) {
            Write-Host "$timestamp - $hostname is reachable (Ping $i)" -ForegroundColor Green
        } else {
            Write-Host "$timestamp - $hostname is unreachable (Ping $i)" -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
    }
    Write-Host ""
}
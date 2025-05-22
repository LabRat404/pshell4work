# Define the drive to search
$drive = "C:\"

# Get the 20 largest files in the drive
$largestFiles = Get-ChildItem -Path $drive -Recurse -File | 
                Sort-Object -Property Length -Descending | 
                Select-Object -First 20

# Display the results in MB
$largestFiles | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Output "File: $($_.FullName) - Size: $sizeMB MB"
}
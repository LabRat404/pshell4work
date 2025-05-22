$string = "
abv
ad
cascc
"
$result = $string -replace "`n", ","
$sortedResult = ($result -split ",") | ForEach-Object { $_.Trim() } | Sort-Object
$finalResult = $sortedResult -join ","
$itemCount = $sortedResult.Count

Write-Output "Sorted Result: $finalResult"
Write-Output "Total Items: $itemCount"
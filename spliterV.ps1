$input = "a, asda, dasd"

# Split the input string into an array
$array = $input -split ','

# Add double quotes around each element
$quotedArray = $array | ForEach-Object { "`"$_`"" }

# Join the elements with commas
$output = [string]::Join(', ', $quotedArray)

# Output the result
$output
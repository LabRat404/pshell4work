
#.issues[6].fields.customfield_18722 = support

#.issues[6].fields.priority.name = major

#.issues[6].fields.key = projects 

# $recentTickets.issues[0].fields.resolution.name

# $recentTickets.issues[80].fields.customfield_11431.value

# 


# $recentTickets.issues[0].fields.resolution.name
# Completed

# MT - 2 types:
# $recentTickets.issues[80].fields.customfield_11431.value
# Support Visit = 7 or Full Time Onsite = 10

# Support 
# Blocker +3 or else = 1

# AutoSoc 
# Blocker +3 or else = 2


# Start the timer
$startTime = Get-Date

$env:jiraToken = "TOKEN"
$userName = "jiraUserName"


# Locate current call number
try {
    $recentTickets = Invoke-RestMethod -Uri "https://jira.options-it.com/rest/api/2/search?jql=assignee = $userName AND resolved >= 2025-03-01 and resolved < 2025-03-30&maxResults=1000" -Headers @{Authorization = "Bearer $env:jiraToken"}
} catch {
    Write-Error "Failed to retrieve recent tickets: $_"
    exit
}

# Initialize total marks
$totalMarks = 0

# Initialize an array to store the results
$results = [System.Collections.Generic.List[PSCustomObject]]::new()

# Loop through all the issues
foreach ($issue in $recentTickets.issues) {
    $key = $issue.key
    $resolution = $issue.fields.resolution.name
    $customFieldValue = $issue.fields.customfield_11431.value
    $supportType = $issue.fields.customfield_18722
    $priority = $issue.fields.priority.name
    $status = $issue.fields.status.name
    $type = $issue.fields.issuetype.name
    $marks = 0
    $criteria = ""

    # Calculate marks based on the criteria
    if ($resolution -eq "Completed") {
        # Check if the key contains "OTL" and set marks to 0
        if ($key -match "OTL") {
            $marks = 0
            $criteria += "Key contains OTL = 0; "
        } else {
            if ($customFieldValue -eq "Support Visit") {
                $marks += 7
                $criteria += "Support Visit = 7; "
            } elseif ($customFieldValue -eq "Full Time Onsite") {
                $marks += 10
                $criteria += "Full Time Onsite = 10; "
            }

            if ($supportType -eq "support") {
                if ($priority -eq "Blocker") {
                    $marks += 3
                    $criteria += "Support Blocker = 3; "
                } else {
                    $marks += 1
                    $criteria += "Support else = 1; "
                }
            } elseif ($supportType -eq "AutoSoc Task") {
                $marks += 2
                $criteria += "AutoSoc = 2; "
            }

            # Add marks for Inbound and Outbound types
            if ($type -eq "Inbound" -or $type -eq "Outbound") {
                $marks += 2
                $criteria += "$type = 2; "
            }
        }
    }

    # If criteria is empty, fill in the ticket status
    if ($criteria -eq "") {
        $criteria = "Status: $status"
    }

    # Add the marks to the total
    $totalMarks += $marks

    # Store the result
    $results.Add([PSCustomObject]@{
        Key      = $key
        Type     = $type
        Criteria = $criteria
        Marks    = $marks
    })
}

# Stop the timer
$endTime = Get-Date
$executionTime = $endTime - $startTime

# Output the results in a table-like view
Write-Output "Task List with Marks:"
$results | Format-Table -AutoSize

# Output the total marks
Write-Output "Total marks: $totalMarks"

# Output the execution time
Write-Output "Execution time: $executionTime"

# Export the results to a text file
$filePath = "C:\Users\tyeung_otl\OneDrive - Options Technology LTD\Desktop\$userName.txt"

# Check if the file exists
if (Test-Path $filePath) {
    # Remove the file
    Remove-Item $filePath -Force
    Write-Output "File removed successfully: $filePath"
} else {
    Write-Output "File not found: $filePath"
}

$results | ForEach-Object {
    "$($_.Key), $($_.Type), $($_.Criteria), $($_.Marks)" 
} | Out-File -FilePath $filePath -Append
Add-Content -Path $filePath -Value "`nTotal marks: $totalMarks"
Add-Content -Path $filePath -Value "`nExecution time: $executionTime"

Write-Output "Results have been exported to $filePath"
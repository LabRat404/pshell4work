$env:jiraToken = "TOKEN"
$userName = "jira_username"

try {
    $recentIssue = (Invoke-RestMethod -Uri "https://jira.options-it.com/rest/api/2/search?jql=Project=Call and assignee=$userName ORDER BY created DESC&maxResults=1" -Headers @{Authorization = "Bearer $env:jiraToken"}).issues[0]
    if ($recentIssue.fields.issuetype.name -ne "Inbound") {
        Write-Output "No ongoing call for this user/the call ticket is not yet created, or the last call was an out-bound call"
        return
    }
    $recentCallNumber = $recentIssue.fields.customfield_20417
} catch {
    Write-Error "Failed to retrieve recent call number: $_"
    return
}

try {
    $Response = Invoke-RestMethod -Uri "https://jira.options-it.com/rest/api/2/search?jql=Project=Call and text~'$recentCallNumber' ORDER BY created DESC&maxResults=10" -Method Get -Headers @{Authorization = "Bearer $env:jiraToken"}
    if ($Response.issues.Count -gt 0) {
        $userCounts = @{}
        $userEmails = @{}
        $totalCalls = $Response.issues.Count

        foreach ($issue in $Response.issues) {
            $CallerInfo = $issue.fields
            if ($CallerInfo.customfield_20203) {
                $clientUserName = $CallerInfo.customfield_20203.name
                $emailAddress = $CallerInfo.customfield_20203.emailAddress
                if ($userCounts.ContainsKey($clientUserName)) {
                    $userCounts[$clientUserName]++
                } else {
                    $userCounts[$clientUserName] = 1
                    $userEmails[$clientUserName] = $emailAddress
                }
            }
        }

        if ($userCounts.Count -gt 0) {
            $sortedUsers = $userCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 2
            $mostFrequentUser = $sortedUsers[0]
            $secondMostFrequentUser = $sortedUsers[1]

            $userName1 = $mostFrequentUser.Key
            $userCount1 = $mostFrequentUser.Value
            $percentage1 = [math]::Round(($userCount1 / $totalCalls) * 100, 2)
            $email1 = $userEmails[$userName1]
            $lastThreeChars1 = $userName1.Substring($userName1.Length - 3).ToUpper()

            $userName2 = $secondMostFrequentUser.Key
            $userCount2 = $secondMostFrequentUser.Value
            $percentage2 = [math]::Round(($userCount2 / $totalCalls) * 100, 2)
            $email2 = $userEmails[$userName2]
            $lastThreeChars2 = $userName2.Substring($userName2.Length - 3).ToUpper()

            # Function to get company details
            function Get-CompanyDetails($lastThreeChars) {
                $ticketDetailsUri = "https://jira.options-it.com/rest/api/2/project/$lastThreeChars"
                try {
                    $companyDetail = Invoke-RestMethod -Uri $ticketDetailsUri -Headers @{Authorization = "Bearer $env:jiraToken"}
                    return $companyDetail.name
                } catch {
                    Write-Error "Failed to retrieve company details for $lastThreeChars : $_"
                    return "Unknown Company"
                }
            }

            $companyName1 = Get-CompanyDetails $lastThreeChars1
            $companyName2 = Get-CompanyDetails $lastThreeChars2

            # Output the most frequent user information
            function Output-UserInfo($companyName, $lastThreeChars, $userName, $percentage, $userCount, $totalCalls, $email) {
                Write-Output "Company name: $companyName"
                Write-Output "Company code: $lastThreeChars"
                Write-Output "User name: $userName $percentage% ($userCount/$totalCalls calls)"
                Write-Output "User Email: $email"

                # Query for recent tickets reported by the user
                $recentTickets = Invoke-RestMethod -Uri "https://jira.options-it.com/rest/api/2/search?jql=reporter=$userName ORDER BY updated DESC&maxResults=3" -Headers @{Authorization = "Bearer $env:jiraToken"}
                if ($recentTickets.issues.Count -gt 0) {
                    Write-Output "Recent tickets:"
                    Write-Output "Summary | Key | URL | Updated"
                    Write-Output "----------------------------------------"
                    foreach ($ticket in $recentTickets.issues) {
                        $ticketSummary = $ticket.fields.summary
                        $ticketKey = $ticket.key
                        $ticketUrl = "https://jira.options-it.com/browse/$ticketKey"
                        $ticketUpdated = $ticket.fields.updated
                        Write-Output "$ticketSummary | $ticketKey | $ticketUrl | $ticketUpdated"
                    }
                } else {
                    Write-Output "No recent tickets found for this user."
                }
            }

            Output-UserInfo $companyName1 $lastThreeChars1 $userName1 $percentage1 $userCount1 $totalCalls $email1
            Write-Output ""
            Write-Output "----------------------------------------------------------------------------------------------------------------"
            Write-Output ""
            Output-UserInfo $companyName2 $lastThreeChars2 $userName2 $percentage2 $userCount2 $totalCalls $email2
        } else {
            Write-Output "No user information found in the issues."
        }
    } else {
        Write-Output "No results found or it's a call from a new number which is not in the database."
    }
} catch {
    Write-Error "Failed to retrieve caller information: $_"
}
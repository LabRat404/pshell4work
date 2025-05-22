#Create normal Jira ticket

#Close comments,request type

$env:jiraToken = "TOKEN"
$userName = "jira_username"


    try {
        # Create the ticket
        $createTicketUri = "https://jira.options-it.com/rest/api/2/issue"
        
        # Define the new ticket details
        $body = @{
            fields = @{
                
                project = @{
                    key = "SYM"  # Project Key
                }
                priority = @{
                   self = "https://jira.options-it.com/rest/api/2/priority/3"
                   icon = "iconUrl=https://jira.options-it.com/images/icons/priorities/major.svg"
                   name= "Major"
                   id = "3"
                }
                summary = "Remove SSD from SYMHKDT110 and move ou to disable "  # Summary


                description = "Remove SSD from SYMHKDT110 and move ou to disable "  # Description


                issuetype = @{
                    name = "Support"  # Issue Type
                }
      
                components = @(
                    @{
                        self = "https://jira.options-it.com/rest/api/2/component/11027"
                        id = "11027"
                        name = "Core"
                    }
                )
                   customfield_14102 = @{
                    self = "https://jira.options-it.com/rest/api/2/customFieldOption/15907"
                    value = "Desktop Mgmt"
                    id = "15907"
                }
                customfield_14905 = @{
                    self = "https://jira.options-it.com/rest/api/2/customFieldOption/16966"
                    value = "Face to Face"
                    id = "16966"
                }
                customfield_10201 = @(@{
                    self = "https://jira.options-it.com/rest/api/2/customFieldOption/11308"
                    value = "Asia"
                    id = "11308"
                    disabled = $false
                })
            
            }
        }

        # Convert the body to JSON
        $jsonBody = $body | ConvertTo-Json -Depth 3

        # Create the ticket
        $response = Invoke-RestMethod -Uri $createTicketUri -Method Post -Headers @{Authorization = "Bearer $env:jiraToken"} -Body $jsonBody -ContentType "application/json"
        
        Write-Output "Ticket created successfully: https://jira.options-it.com/browse/$($response.key)"

        # Close the ticket
        $ticketId = $response.key
        $closeTicketUri = "https://jira.options-it.com/rest/api/2/issue/$ticketId/transitions"
        
        $commentUri = "https://jira.options-it.com/rest/api/2/issue/$ticketId/comment"
        $commentBody = @{
            body = "Doen onsite."
        }

        #Invoke-RestMethod -Uri $commentUri -Method Post -Headers @{Authorization = "Bearer $env:jiraToken"} -Body ($commentBody | ConvertTo-Json) -ContentType "application/json"

        # Define the transition to close the ticket (assuming transition ID for closing is 31)
        $closeBody = @{
            transition = @{
                id = 2
            }
          
            fields = @{
                assignee = @{
                    self = "https://jira.options-it.com/rest/api/2/user?username=tyeung_otl"
                    name = "tyeung_otl"
                    key = "JIRAUSER61768"
                    emailAddress = "tan.yeung@options-it.com"
                    avatarUrls = @{}
                    displayName = "Tan Yeung"
                }
            }
        }

        # Close the ticket
        #Invoke-RestMethod -Uri $closeTicketUri -Method Post -Headers @{Authorization = "Bearer $env:jiraToken"} -Body ($closeBody | ConvertTo-Json) -ContentType "application/json"
        #Write-Output "Ticket $ticketId closed successfully."
    } catch {
        Write-Error "Failed to create or close the ticket for date $date : $_"
        Write-Output "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Output "Exception Message: $($_.Exception.Message)"
        Write-Output "Stack Trace: $($_.Exception.StackTrace)"
        Write-Output "Inner Exception: $($_.Exception.InnerException)"
    }
 
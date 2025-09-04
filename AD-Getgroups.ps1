#Import-Module "\CRED\CredModule.psm1"
#only once
if (!$securecredentials){
$securecredentials = Get-Credential
}

#target user
$username = "username"

$filename = "$username.txt"
$filepath = "C:\\temp2\\$filename"

$user = Get-ADUser -Identity $username -Credential $securecredentials -Properties MemberOf
$groupDNs = $user.MemberOf

foreach ($groupDN in $groupDNs) {
    try {
        $group = Get-ADGroup -Identity $groupDN -Credential $securecredentials -Properties Description
        $description = if ([string]::IsNullOrWhiteSpace($group.Description)) { "This group has no description" } else { $group.Description }
        $line = "`"$($group.Name)`",`"$description`""

        Add-Content -Path $filepath -Value $line
        write-host $line
    } catch {
        Write-Warning "Could not retrieve group: $groupDN"
    }
}

#change to csv
Rename-Item -Path "C:\\temp2\\$username.txt" -NewName "$username.csv"
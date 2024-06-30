# Specify the list of OUs
$ous = "MKT", "SALES", "TECH", "HR" 

# Loop through the list and create each OU
foreach ($ou in $ous) {
    New-ADOrganizationalUnit -Name $ou -Path "DC=paris,DC=local"
    Write-Host "OU '$ou' created."
}


# Specify the list of groups and their corresponding OUs
$groups = @{
    "MKT" = "OU=MKT,DC=paris,DC=local"
    "SALES" = "OU=SALES,DC=paris,DC=local"
    "TECH" = "OU=TECH,DC=paris,DC=local"
    "HR" = "OU=HR,DC=paris,DC=local"}

# Loop through the list and create each group
foreach ($group in $groups.GetEnumerator()) {
    New-ADGroup -Name $group.Key -GroupScope Global -GroupCategory Security -Path $group.Value
    Write-Host "Group '$($group.Key)' created in $($group.Value)."
}

$ouPath = "OU=MKT,DC=paris,DC=local";$prefix = "mkt"; $password = ConvertTo-SecureString -String "Twenty24!" -AsPlainText -Force; 1..999 | ForEach-Object { $username = $prefix + $_; if (-not (Get-ADUser -Filter { SamAccountName -eq $username })) { New-ADUser -Name $username -SamAccountName $username -Path $ouPath -UserPrincipalName ($username + "@paris.local") -AccountPassword $password -Enabled $true; Write-Host "User $username created." } else { Write-Host "User $username already exists." } }


$ouPath = "OU=MKT,DC=paris,DC=local";$prefix = "sales"; $password = ConvertTo-SecureString -String "Twenty24!" -AsPlainText -Force; 1..999 | ForEach-Object { $username = $prefix + $_; if (-not (Get-ADUser -Filter { SamAccountName -eq $username })) { New-ADUser -Name $username -SamAccountName $username -Path $ouPath -UserPrincipalName ($username + "@paris.local") -AccountPassword $password -Enabled $true; Write-Host "User $username created." } else { Write-Host "User $username already exists." } }

$ouPath = "OU=MKT,DC=paris,DC=local";$prefix = "tech"; $password = ConvertTo-SecureString -String "Twenty24!" -AsPlainText -Force; 1..999 | ForEach-Object { $username = $prefix + $_; if (-not (Get-ADUser -Filter { SamAccountName -eq $username })) { New-ADUser -Name $username -SamAccountName $username -Path $ouPath -UserPrincipalName ($username + "@paris.local") -AccountPassword $password -Enabled $true; Write-Host "User $username created." } else { Write-Host "User $username already exists." } }


$ouPath = "OU=MKT,DC=paris,DC=local";$prefix = "hr"; $password = ConvertTo-SecureString -String "Twenty24!" -AsPlainText -Force; 1..999 | ForEach-Object { $username = $prefix + $_; if (-not (Get-ADUser -Filter { SamAccountName -eq $username })) { New-ADUser -Name $username -SamAccountName $username -Path $ouPath -UserPrincipalName ($username + "@paris.local") -AccountPassword $password -Enabled $true; Write-Host "User $username created." } else { Write-Host "User $username already exists." } }

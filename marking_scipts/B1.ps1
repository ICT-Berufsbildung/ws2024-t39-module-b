# Import the Active Directory module
Import-Module ActiveDirectory

# Define the OUs and corresponding prefixes and groups
$ouPrefixMapping = @{
    "OU=MKT,DC=paris,DC=local"   = "mkt"
    "OU=SALES,DC=paris,DC=local" = "sales"
    "OU=TECH,DC=paris,DC=local"  = "tech"
    "OU=HR,DC=paris,DC=local"    = "hr"
}

$groupMapping = @{
    "mkt"   = "MKT"
    "sales" = "SALES"
    "tech"  = "TECH"
    "hr"    = "HR"
}

# Function to count users in a specific OU with a given prefix and group membership
function Get-UserCountInOU {
    param (
        [string]$ouDistinguishedName,
        [string]$userPrefix,
        [string]$groupName
    )

    # Retrieve all users in the specified OU
    $usersInOU = Get-ADUser -SearchBase $ouDistinguishedName -Filter * -SearchScope Subtree

    # Filter users whose SamAccountName starts with the specified prefix and are members of the specified group
    $filteredUsers = $usersInOU | Where-Object {
        $_.SamAccountName -like "$userPrefix*" -and
        (Get-ADUser $_.DistinguishedName -Property MemberOf).MemberOf -contains (Get-ADGroup -Identity $groupName).DistinguishedName
    }

    # Return the count of filtered users
    return $filteredUsers.Count
}

# Variable to track if all counts match 20
$allMatch = $true

# Iterate through each OU, prefix mapping, and group mapping, and count users
foreach ($ou in $ouPrefixMapping.Keys) {
    $prefix = $ouPrefixMapping[$ou]
    $group = $groupMapping[$prefix]
    $userCount = Get-UserCountInOU -ouDistinguishedName $ou -userPrefix $prefix -groupName $group
    Write-Output "The OU '$ou' contains $userCount users with the prefix '$prefix' and membership in group '$group'."
    
    if ($userCount -ne 20) {
        $allMatch = $false
    }
}

# Print result if all counts are 20
Write-Host "B1 component: "
if ($allMatch) {    
    Write-Host "passed" -ForegroundColor Green
} else {
    Write-Host "failed" -ForegroundColor Red
}

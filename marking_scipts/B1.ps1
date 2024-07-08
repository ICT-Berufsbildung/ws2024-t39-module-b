# Import the Active Directory module
Import-Module ActiveDirectory

# Define the OUs and corresponding prefixes
$ouPrefixMapping = @{
    "OU=MKT,DC=paris,DC=local"   = "mkt"
    "OU=SALES,DC=paris,DC=local" = "sales"
    "OU=TECH,DC=paris,DC=local"  = "tech"
    "OU=HR,DC=paris,DC=local"    = "hr"
}

# Function to count users in a specific OU with a given prefix
function Get-UserCountInOU {
    param (
        [string]$ouDistinguishedName,
        [string]$userPrefix
    )

    # Retrieve all users in the specified OU
    $usersInOU = Get-ADUser -SearchBase $ouDistinguishedName -Filter * -SearchScope Subtree

    # Filter users whose SamAccountName starts with the specified prefix
    $filteredUsers = $usersInOU | Where-Object { $_.SamAccountName -like "$userPrefix*" }

    # Return the count of filtered users
    return $filteredUsers.Count
}

# Variable to track if all counts match 999
$allMatch = $true

# Iterate through each OU and prefix mapping and count users
foreach ($ou in $ouPrefixMapping.Keys) {
    $prefix = $ouPrefixMapping[$ou]
    $userCount = Get-UserCountInOU -ouDistinguishedName $ou -userPrefix $prefix
    Write-Output "The OU '$ou' contains $userCount users with the prefix '$prefix'."
    
    if ($userCount -ne 999) {
        $allMatch = $false
    }
}
Write-Host "A1 component: "
# Print result if all counts are 999
if ($allMatch) {    
    Write-Host "passed" -ForegroundColor Green
} else {
    Write-Host "failed" -ForegroundColor Red
}

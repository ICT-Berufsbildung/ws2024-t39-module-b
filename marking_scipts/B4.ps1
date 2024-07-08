# Import the Active Directory module
Import-Module ActiveDirectory

# Define the domain and group name
$domain = "paris.local"
$groupName = "HR"

# Get the distinguished name of the group
$group = Get-ADGroup -Filter { Name -eq $groupName } -Server $domain

if ($null -eq $group) {
    Write-Output "Group $groupName not found in domain $domain."
    exit
}

$groupDN = $group.DistinguishedName

# Find all Password Settings Objects (PSOs) applied to the group
$passwordSettingsObjects = Get-ADFineGrainedPasswordPolicy -Filter * -Server $domain | Where-Object {
    $_.AppliesTo -contains $groupDN
}

if ($passwordSettingsObjects.Count -eq 0) {
    Write-Output "No fine-grained password policies applied to group $groupName in domain $domain."
    exit
}

$minPasswordAgeSet = $false

# Check the MinPasswordAge for the PSOs
foreach ($pso in $passwordSettingsObjects) {
    Write-Output "Checking PSO: $($pso.Name) with MinPasswordAge: $($pso.MinPasswordLength) days"
    if ($pso.MinPasswordLength -eq 8) {
        $minPasswordAgeSet = $true
        break
    }
}

# Output the result
if ($minPasswordAgeSet) {
    Write-Host "A4 component passed" -ForegroundColor Green
} else {
    Write-Host "A4 component failed" -ForegroundColor Red
}

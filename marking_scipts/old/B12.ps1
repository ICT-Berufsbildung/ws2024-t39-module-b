# Import Active Directory module
Import-Module ActiveDirectory

# Function to check if a domain controller belongs to a specific domain
function Test-IsDomainControllerInDomain {
    param (
        [string]$domainController,
        [string]$domainName
    )

    try {
        $domainInfo = Get-ADDomain -Server $domainController -ErrorAction Stop
        return $domainInfo.DNSRoot -like "$domainName"
    } catch {
        Write-Host "Failed to determine if $domainController is in $domainName domain: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check if an OU exists
function Test-OUExists {
    param (
        [string]$ouPath
    )

    try {
        $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq 'REMOTE'" -SearchBase $ouPath -ErrorAction SilentlyContinue
        return $ouExists -ne $null
    } catch {
        Write-Host "Failed to check OU existence: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check if a user exists
function Test-UserExists {
    param (
        [string]$userName,
        [string]$searchBase
    )

    try {
        $userExists = Get-ADUser -Filter { SamAccountName -eq $userName } -SearchBase $searchBase -ErrorAction SilentlyContinue
        return $userExists -ne $null
    } catch {
        Write-Host "Failed to check user existence: $_" -ForegroundColor Red
        return $false
    }
}

# Parameters
$domainController = "lyon-rodc.lyon.paris.local"
$domainName = "lyon.paris.local"
$ouPath = "OU=REMOTE,DC=lyon,DC=paris,DC=local"  # Adjust this path based on your domain structure

# Check if lyon-rodc.lyon.paris.local is in lyon.paris.local domain
$dcInDomain = Test-IsDomainControllerInDomain -domainController $domainController -domainName $domainName

if ($dcInDomain) {
    Write-Host "$domainController is part of $domainName domain." -ForegroundColor Green

    # Check if remote1 to remote20 users exist
    $remoteUsersExist = @(1..20 | ForEach-Object { Test-UserExists -userName "remote$_" -searchBase $ouPath })

    if ($remoteUsersExist -notcontains $false) {
        Write-Host "All users (remote1 to remote20) exist in OU REMOTE." -ForegroundColor Green
    } else {
        Write-Host "Some or all users (remote1 to remote20) do not exist in OU REMOTE." -ForegroundColor Red
    }

    # Check if all conditions passed
    if ($dcInDomain -and ($remoteUsersExist -notcontains $false)) {
        Write-Host "B12 Component passed." -ForegroundColor Green
    } else {
        Write-Host "B12 Failed." -ForegroundColor Red
    }

} else {
    Write-Host "$domainController is not part of $domainName domain." -ForegroundColor Red
}

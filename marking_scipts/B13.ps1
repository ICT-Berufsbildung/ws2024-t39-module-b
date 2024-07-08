# Import Active Directory module
Import-Module ActiveDirectory

# Function to check if a computer exists in Active Directory
function Test-ComputerInAD {
    param (
        [string]$computerName,
        [string]$domainController = $null
    )

    try {
        $computer = Get-ADComputer -Identity $computerName -Server $domainController -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

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
        return $false
    }
}

# Check computers in paris.local domain through dc1.paris.local
$parisDomainController = "dc1.paris.local"
$parisDomainName = "paris.local"

Write-Host "Checking computers in $parisDomainName domain through $parisDomainController..."

# Computers to check in paris.local
$parisComputers = @(
    "FILE-SRV",
    "NW-SRV",
    "PARIS-ROUTER",
    "WEB-SRV",
    "WIN-CLIENT1"
)

$parisAllPassed = $true

# Check each computer in paris.local domain
foreach ($computer in $parisComputers) {
    $exists = Test-ComputerInAD -computerName $computer -domainController $parisDomainController

    if ($exists) {
        Write-Host "$computer exists in $parisDomainName domain." -ForegroundColor Green
    } else {
        Write-Host "$computer does not exist in $parisDomainName domain." -ForegroundColor Red
        $parisAllPassed = $false
    }
}

# Check if LYON-RODC.lyon.paris.local is in lyon.paris.local domain
$lyonDomainController = "LYON-RODC.lyon.paris.local"
$lyonDomainName = "lyon.paris.local"

Write-Host "Checking domain controller $lyonDomainController in $lyonDomainName domain..."

$lyonDCInDomain = Test-IsDomainControllerInDomain -domainController $lyonDomainController -domainName $lyonDomainName

if ($lyonDCInDomain) {
    Write-Host "$lyonDomainController is part of $lyonDomainName domain." -ForegroundColor Green

    # Computers to check in lyon.paris.local
    $lyonComputers = @(
        "WIN-CLIENT2",
        "LYON-ROUTER"
    )

    $lyonAllPassed = $true

    # Check each computer in lyon.paris.local domain
    foreach ($computer in $lyonComputers) {
        $exists = Test-ComputerInAD -computerName $computer -domainController $lyonDomainController

        if ($exists) {
            Write-Host "$computer exists in $lyonDomainName domain." -ForegroundColor Green
        } else {
            Write-Host "$computer does not exist in $lyonDomainName domain." -ForegroundColor Red
            $lyonAllPassed = $false
        }
    }

    # Check if all checks passed for lyon.paris.local
    if ($lyonAllPassed) {
        Write-Host "A13 Component for lyon.paris.local passed." -ForegroundColor Green
    } else {
        Write-Host "A13 Component for lyon.paris.local failed." -ForegroundColor Red
    }

} else {
    Write-Host "$lyonDomainController is not part of $lyonDomainName domain." -ForegroundColor Red
    $lyonAllPassed = $false
}

# Check if all checks passed for paris.local
if ($parisAllPassed) {
    Write-Host "A13 Component for paris.local passed." -ForegroundColor Green
} else {
    Write-Host "A13 Component for paris.local failed." -ForegroundColor Red
}

# Check overall component status
if ($parisAllPassed -and $lyonAllPassed) {
    Write-Host "A13 Component passed." -ForegroundColor Green
} else {
    Write-Host "Failed." -ForegroundColor Red
}

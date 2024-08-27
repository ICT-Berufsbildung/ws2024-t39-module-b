# Parameters
$dhcpServer = "10.10.0.11"

# Function to format and compare IP address lists
function Compare-IpAddresses {
    param (
        [string[]]$expected,
        [string[]]$actual
    )
    
    $expectedSet = $expected | Sort-Object
    $actualSet = $actual | Sort-Object
    
    return ($expectedSet -join ",") -eq ($actualSet -join ",")
}

# Connect to the DHCP server
try {
    $scopes = Get-DhcpServerv4Scope -ComputerName $dhcpServer -ErrorAction Stop
} catch {
    Write-Host "Failed to connect to the DHCP server at $dhcpServer. Error: $_" -ForegroundColor Red
    exit
}

# Initialize check status
$allChecksPassed = $true

# Check each scope
foreach ($scope in $scopes) {
    $scopeId = $scope.ScopeId
    $scopeDetails = Get-DhcpServerv4Scope -ComputerName $dhcpServer -ScopeId $scopeId
    
    # Retrieve DHCP options for the scope
    $dhcpOptions = Get-DhcpServerv4OptionValue -ScopeId $scopeDetails.ScopeId -ComputerName $dhcpServer -ErrorAction Stop
    
    # Gateway
    $gateway = ($dhcpOptions | Where-Object { $_.OptionId -eq 3 }).Value
    if ($gateway -eq "10.30.0.1") {
        Write-Host "Gateway for scope $scopeId is correct: $gateway" -ForegroundColor Green
    } else {
        Write-Host "Gateway for scope $scopeId is incorrect: $gateway" -ForegroundColor Red
        $allChecksPassed = $false
    }
    
    # DNS Servers
    $dnsServers = ($dhcpOptions | Where-Object { $_.OptionId -eq 6 }).Value -split ','
    $expectedDnsServers = @("10.10.0.10", "10.10.0.11")
    if (Compare-IpAddresses -expected $expectedDnsServers -actual $dnsServers) {
        Write-Host "DNS servers for scope $scopeId are correct: $($dnsServers -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "DNS servers for scope $scopeId are incorrect: $($dnsServers -join ', ')" -ForegroundColor Red
        $allChecksPassed = $false
    }
    
    # Lease Range
    $leaseStart = $scopeDetails.StartRange
    $leaseEnd = $scopeDetails.EndRange
    if ($leaseStart -eq "10.30.0.100" -and $leaseEnd -eq "10.30.0.200") {
        Write-Host "Lease range for scope $scopeId is correct: $leaseStart - $leaseEnd" -ForegroundColor Green
    } else {
        Write-Host "Lease range for scope $scopeId is incorrect: $leaseStart - $leaseEnd" -ForegroundColor Red
        $allChecksPassed = $false
    }
    
    # Excluded IP Ranges
    $exclusions = Get-DhcpServerv4ExclusionRange -ComputerName $dhcpServer -ScopeId $scopeId | Sort-Object StartRange
    $expectedExclusions = @("10.30.0.100", "10.30.0.150")
    $exclusionStart = $exclusions[0].StartRange
    $exclusionEnd = $exclusions[0].EndRange
    if ($exclusionStart -eq $expectedExclusions[0] -and $exclusionEnd -eq $expectedExclusions[1]) {
        Write-Host "Exclusion range for scope $scopeId is correct: $exclusionStart - $exclusionEnd" -ForegroundColor Green
    } else {
        Write-Host "Exclusion range for scope $scopeId is incorrect: $exclusionStart - $exclusionEnd" -ForegroundColor Red
        $allChecksPassed = $false
    }
    
    # Lease Duration
    $leaseDuration = $scopeDetails.LeaseDuration
    $expectedLeaseDuration = [timespan]::Parse("13.13:13:00")
    if ($leaseDuration -eq $expectedLeaseDuration) {
        Write-Host "Lease duration for scope $scopeId is correct: $leaseDuration" -ForegroundColor Green
    } else {
        Write-Host "Lease duration for scope $scopeId is incorrect: $leaseDuration" -ForegroundColor Red
        $allChecksPassed = $false
    }
}

# Final result
if ($allChecksPassed) {
    Write-Host "B7 component passed." -ForegroundColor Green
} else {
    Write-Host "B7 component failed." -ForegroundColor Red
}

# Additional output for debugging purposes
Write-Host "Finished checking DHCP server settings on $dhcpServer."

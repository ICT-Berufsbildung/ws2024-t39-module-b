# Define the DNS records and their expected IP addresses
$dnsRecords = @{
    "www.paris.local"      = "10.20.0.11"
    "internal.paris.local" = "10.20.0.11"
    "external.paris.local" = "10.20.0.11"
    "help.paris.local"     = "10.20.0.11"
}

# Initialize a flag to check if all tests pass
$allPassed = $true

# DNS server to query
$dnsServer = "10.10.0.10"

# Function to check a DNS record
function Check-DNSRecord {
    param (
        [string]$RecordName,
        [string]$ExpectedIP
    )
    
    try {
        $dnsResult = Resolve-DnsName -Name $RecordName -Server $dnsServer -ErrorAction Stop
        $ipAddresses = $dnsResult | Where-Object { $_.QueryType -eq "A" } | Select-Object -ExpandProperty IPAddress
        
        if ($ipAddresses -contains $ExpectedIP) {
            Write-Host "$RecordName resolves to $ExpectedIP - Passed" -ForegroundColor Green
        } else {
            Write-Host "$RecordName does not resolve to $ExpectedIP - Failed" -ForegroundColor Red
            $global:allPassed = $false
        }
    } catch {
        Write-Host "Failed to resolve $RecordName" -ForegroundColor Red
        $global:allPassed = $false
    }
}

# Check each DNS record
foreach ($record in $dnsRecords.GetEnumerator()) {
    Check-DNSRecord -RecordName $record.Key -ExpectedIP $record.Value
}

# Output final result based on the flag
if ($allPassed) {
    Write-Host "A5 component passed" -ForegroundColor Green
} else {
    Write-Host "A5 component failed" -ForegroundColor Red
}

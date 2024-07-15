# Parameters
$primaryDnsServer = "10.10.0.10"    # Replace with the actual primary DNS server name or IP
$secondaryDnsServer = "10.10.0.11"  # Replace with the actual secondary DNS server name or IP
$zoneName = "paris.local"                # Replace with the actual DNS zone name

# Function to get the serial number of a DNS zone
function Get-DnsZoneSerial {
    param (
        [string]$dnsServer,
        [string]$zoneName
    )

    try {
        Write-Host "Querying $dnsServer for zone $zoneName SOA record..." -ForegroundColor Yellow
        $dnsZone = Get-DnsServerResourceRecord -ComputerName $dnsServer -ZoneName $zoneName -Name "@" -RRType SOA -ErrorAction Stop
        $serialNumber = $dnsZone.RecordData.SerialNumber
        Write-Host "Successfully retrieved serial number from $dnsServer : $serialNumber" -ForegroundColor Green
        return $serialNumber
    } catch {
        Write-Host "Failed to retrieve the zone serial number from $dnsServer for zone $zoneName. Error: $_" -ForegroundColor Red
        return $null
    }
}

# Get the serial numbers from the primary and secondary DNS servers
$primarySerial = Get-DnsZoneSerial -dnsServer $primaryDnsServer -zoneName $zoneName
$secondarySerial = Get-DnsZoneSerial -dnsServer $secondaryDnsServer -zoneName $zoneName

# Compare the serial numbers
if ($primarySerial -eq $null -or $secondarySerial -eq $null) {
    Write-Host "Failed to retrieve the serial numbers from one or both DNS servers" -ForegroundColor Red
} elseif ($primarySerial -eq $secondarySerial) {
    Write-Host "B6 component passed" -ForegroundColor Green
} else {
    Write-Host "B6 component failed" -ForegroundColor Red
}

# Additional output for debugging purposes
Write-Host "Primary DNS server ($primaryDnsServer) serial number: $primarySerial"
Write-Host "Secondary DNS server ($secondaryDnsServer) serial number: $secondarySerial"

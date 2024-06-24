# Function to check if Routing and Remote Access (RRAS) is installed
function Test-RRASInstallation {
    param (
        [string]$computerName = $env:COMPUTERNAME
    )

    try {
        # Check if RRAS Windows feature is installed
        $rrasInstalled = Get-WindowsFeature -ComputerName $computerName | Where-Object { $_.Name -eq "RemoteAccess" -and $_.Installed }
        
        return $rrasInstalled
    } catch {
        Write-Host "Failed to check RRAS installation on $computerName : $_" -ForegroundColor Red
        return $false
    }
}

# Example usage:
$computerName = "paris-router.paris.local"  # Replace with your target machine name if checking remotely
$rrasInstalled = Test-RRASInstallation -computerName $computerName

if ($rrasInstalled) {
    Write-Host "Routing and Remote Access (RRAS) is installed on $computerName." -ForegroundColor Green
    Write-Host "A11-1 passed." -ForegroundColor Green
} else {
    Write-Host "Routing and Remote Access (RRAS) is not installed on $computerName." -ForegroundColor Red
    Write-Host "A11-1 failed." -ForegroundColor Red
}

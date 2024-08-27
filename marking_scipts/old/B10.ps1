# Parameters
$webServer = "web-srv.paris.local"
$dcServer = "dc1.paris.local"
$websites = @{
    "www.paris.local" = "<html>This is internal WSC2024</html>"
    "help.paris.local" = "<html>This is internal WSC2024 Help</html>"
}
$httpsSite = "https://www.paris.local"

# Function to check if IIS is installed
function Test-IISInstallation {
    param (
        [string]$computerName
    )

    # Check if IIS Windows feature is installed
    $iisInstalled = Get-WindowsFeature -ComputerName $computerName | Where-Object { $_.Name -eq "Web-Server" -and $_.Installed }
    
    return $iisInstalled
}

# Function to check website content
function Check-WebsiteContent {
    param (
        [string]$url,
        [string]$expectedContent
    )

    try {
        $response = Invoke-WebRequest -Uri $url -ErrorAction Stop
        if ($response.Content -eq $expectedContent) {
            Write-Host "Website $url shows expected content." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Website $url does not show expected content." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Failed to access website $url : $_" -ForegroundColor Red
        return $false
    }
}

# Check if IIS is installed on $webServer
try {
    $isIISInstalled = Test-IISInstallation -computerName $webServer
    if ($isIISInstalled) {
        Write-Host "IIS is installed on $webServer." -ForegroundColor Green
    } else {
        Write-Host "IIS is not installed on $webServer." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "Failed to check IIS installation on $webServer : $_" -ForegroundColor Red
    exit
}

# Check each website content
$allChecksPassed = $true
foreach ($siteUrl in $websites.Keys) {
    $expectedText = $websites[$siteUrl]
    $checkPassed = Check-WebsiteContent -url "http://$siteUrl" -expectedContent $expectedText
    if (-not $checkPassed) {
        $allChecksPassed = $false
    }
}

# Check HTTPS site for certificate errors
try {
    $httpsResponse = Invoke-WebRequest -Uri $httpsSite -ErrorAction Stop
    Write-Host "HTTPS site $httpsSite accessed successfully." -ForegroundColor Green
} catch [System.Net.WebException] {
    if ($_.Exception.Message -like "*certificate*") {
        Write-Host "Certificate error encountered on HTTPS site $httpsSite." -ForegroundColor Red
        $allChecksPassed = $false
    } else {
        Write-Host "Failed to access HTTPS site $httpsSite : $_" -ForegroundColor Red
        $allChecksPassed = $false
    }
} catch {
    Write-Host "Failed to access HTTPS site $httpsSite : $_" -ForegroundColor Red
    $allChecksPassed = $false
}

# Final result
if ($allChecksPassed) {
    Write-Host "B10 Component passed." -ForegroundColor Green
} else {
    Write-Host "B10 Component failed." -ForegroundColor Red
}

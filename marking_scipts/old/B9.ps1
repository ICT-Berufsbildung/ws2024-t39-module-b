# Define the DFS namespace and shares to check
$dfsNamespace = "\\paris.local\CSDrive"
$sharesToCheck = @(
    "CommonShare",
    "MKT",
    "SALES",
    "HR",
    "TECH"
)

# Initialize check status
$allChecksPassed = $true

# Check if the DFS namespace exists
$dfsNamespaceExists = Test-Path -Path $dfsNamespace -PathType Container

if ($dfsNamespaceExists) {
    Write-Host "DFS namespace $dfsNamespace exists." -ForegroundColor Green
    
    # Check each share under the DFS namespace
    foreach ($share in $sharesToCheck) {
        $sharePath = Join-Path -Path $dfsNamespace -ChildPath $share
        $shareExists = Test-Path -Path $sharePath -PathType Container
        
        if ($shareExists) {
            Write-Host "Share $sharePath exists." -ForegroundColor Green
        } else {
            Write-Host "Share $sharePath does not exist." -ForegroundColor Red
            $allChecksPassed = $false
        }
    }
} else {
    Write-Host "DFS namespace $dfsNamespace does not exist." -ForegroundColor Red
    $allChecksPassed = $false
}

# Final result
if ($allChecksPassed) {
    Write-Host "B9 Component passed." -ForegroundColor Green
} else {
    Write-Host "B9 Component failed." -ForegroundColor Red
}

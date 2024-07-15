$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
Write-Host "B2 component"
if ($domain -eq "paris.local") {
  Write-Host "passed" -ForegroundColor Green
} else {
  Write-Host "failed" -ForegroundColor Red
}

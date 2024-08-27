# Define the name of the GPO to check
$gpoName = "TECH"
$domainName = "paris.local"

# Get all GPOs matching the specified name in the domain (case-insensitive search)
$gpos = Get-GPO -All -Domain $domainName | Where-Object { $_.DisplayName.Trim() -ieq $gpoName.Trim() }

if ($gpos.Count -eq 0) {
    Write-Host "No GPO named '$gpoName' found in the domain '$domainName'." -ForegroundColor Red
} elseif ($gpos.Count -gt 1) {
    Write-Host "Multiple GPOs named '$gpoName' found in the domain '$domainName'. Please refine your search." -ForegroundColor Red
} else {
    $gpo = $gpos[0]
    
    # Get the GPO report as XML
    $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    
    # Load XML content properly
    [xml]$gpoXml = $gpoReport
    
    $xml = [xml]$gpoReport
    if ($xml.GPO.Name -eq "TECH") {
        $extensionData = $xml.GPO.User.ExtensionData
        $q1Name = $extensionData.Extension.ScheduledTasks.TaskV2.Properties.Task.Triggers.LogonTrigger.Enabled
        $q1String = $extensionData.Extension.ScheduledTasks.TaskV2.Properties.Task.Actions.Exec.Command
        Write-Host $q1Name
        Write-Host $q1String
        # Check conditions
        if ($q1Name -eq "true" -and $q1String -like "*powershell.exe*") {
            Write-Host "B3-4 component passed" -ForegroundColor Green
        } else {
            Write-Host "B3-4 component failed" -ForegroundColor Red
        }
    } else {
        Write-Host "GPO with name 'TECH' not found." -ForegroundColor Red
    }
}

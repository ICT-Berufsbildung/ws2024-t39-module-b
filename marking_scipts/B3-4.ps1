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
    # Check if GPO Name is "TECH"
    # Check if GPO Name is "TECH"
    if ($xml.GPO.Name -eq "TECH") {
        # Retrieve q1:Name and q1:String from ExtensionData
        $extensionData = $xml.GPO.Computer.ExtensionData
        $q1Name = $extensionData.Extension.ScheduledTasks.Task.Properties.Triggers.Trigger.type
        $q1String = $extensionData.Extension.ScheduledTasks.Task.Properties.appName

        # Check conditions
        if ($q1Name -eq "LOGON" -and $q1String -like "*powershell.exe*") {
            Write-Host "B3-4 component passed" -ForegroundColor Green
        } else {
            Write-Host "B3-4 component failed" -ForegroundColor Red
        }
    } else {
        Write-Host "GPO with name 'TECH' not found." -ForegroundColor Red
    }
}

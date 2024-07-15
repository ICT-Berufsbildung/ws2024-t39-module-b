# Define the name of the GPO to check
$gpoName = "Updates"
$domainName = "paris.local"

# Get all GPOs matching the specified name in the domain (case-insensitive search)
$gpos = Get-GPO -All -Domain $domainName | Where-Object { $_.DisplayName.Trim() -ieq $gpoName.Trim() }
Write-Host "B3-2 component"
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

    if ($gpoXml) {
        # Define namespace manager to handle namespaces
        $ns = New-Object System.Xml.XmlNamespaceManager($gpoXml.NameTable)
        $ns.AddNamespace("q1", "http://www.microsoft.com/GroupPolicy/Settings/Registry")

        # Check conditions
        $condition2 = $gpoXml.SelectSingleNode("//q1:DropDownList[q1:Name='Scheduled install day: ']/q1:Value/q1:Name", $ns).'#text' -eq "6 - Every Friday"
        $condition3 = $gpoXml.SelectSingleNode("//q1:DropDownList[q1:Name='Scheduled install time:']/q1:Value/q1:Name", $ns).'#text' -eq "13:00"

        if ($condition2 -and $condition3) {
            Write-Host "passed" -ForegroundColor Green
        } else {
            Write-Host "failed" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to load GPO report XML for GPO '$gpoName'." -ForegroundColor Red
    }
}

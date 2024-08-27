# Define the name of the GPO to check
$gpoName = "MKT"
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

    if ($gpoXml) {
        # Define namespace manager to handle namespaces
        $ns = New-Object System.Xml.XmlNamespaceManager($gpoXml.NameTable)
        $ns.AddNamespace("q1", "http://www.microsoft.com/GroupPolicy/Settings/Registry")

        # Initialize the result flag
        $allConditionsMet = $true
        $failedPolicies = @()

        # Check and display "Don't run specified Windows applications" policy values
        $dontRunAppsPolicy = $gpoXml.GPO.User.ExtensionData.Extension.Policy | Where-Object { $_.Name -eq "Don't run specified Windows applications" }
        if ($dontRunAppsPolicy -ne $null) {
            $dontRunAppsListBox = $dontRunAppsPolicy.ListBox
            Write-Host $dontRunAppsListBox.Value.Element.Data
            if ($dontRunAppsListBox -ne $null -and $dontRunAppsListBox.Value -ne $null -and $dontRunAppsListBox.Value.Element.Data -eq "powershell.exe") {
                Write-Host "'Don't run specified Windows applications' is configured with the following values:" -ForegroundColor Yellow
                $dontRunAppsListBox.Value.Element.Data | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow }
            } else {
                Write-Host "'Don't run specified Windows applications' list is empty or not configured" -ForegroundColor Red
                $allConditionsMet = $false
                $failedPolicies += "'Don't run specified Windows applications'"
            }
        } else {
            Write-Host "'Don't run specified Windows applications' policy is not found" -ForegroundColor Red
            $allConditionsMet = $false
            $failedPolicies += "'Don't run specified Windows applications'"
        }

        # Check if "Prevent access to the command prompt" is enabled
        $preventCmdPolicy = $gpoXml.GPO.User.ExtensionData.Extension.Policy | Where-Object { $_.Name -eq "Prevent access to the command prompt" }
        if ($preventCmdPolicy -ne $null -and $preventCmdPolicy.State -eq "Enabled") {
            Write-Host "'Prevent access to the command prompt' is enabled" -ForegroundColor Yellow
        } else {
            Write-Host "'Prevent access to the command prompt' is not enabled" -ForegroundColor Red
            $allConditionsMet = $false
            $failedPolicies += "'Prevent access to the command prompt'"
        }

        # Check if "Remove Task Manager" is enabled
        $removeTaskManagerPolicy = $gpoXml.GPO.User.ExtensionData.Extension.Policy | Where-Object { $_.Name -eq "Remove Task Manager" }
        if ($removeTaskManagerPolicy -ne $null -and $removeTaskManagerPolicy.State -eq "Enabled") {
            Write-Host "'Remove Task Manager' is enabled" -ForegroundColor Yellow
        } else {
            Write-Host "'Remove Task Manager' is not enabled" -ForegroundColor Red
            $allConditionsMet = $false
            $failedPolicies += "'Remove Task Manager'"
        }

        # Final output based on all conditions
        if ($allConditionsMet) {
            Write-Host "B3-3 component passed" -ForegroundColor Green
        } else {
            Write-Host "B3-3 component failed" -ForegroundColor Red
            Write-Host "Failed policies:" -ForegroundColor Red
            $failedPolicies | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        }
    } else {
        Write-Host "Failed to load GPO report XML for GPO '$gpoName'." -ForegroundColor Red
    }
}
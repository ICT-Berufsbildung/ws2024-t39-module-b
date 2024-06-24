# Import the GroupPolicy module
Import-Module GroupPolicy

# Define the GPO name
$gpoName = "SALES"
$domainName = "paris.local"
$gpos = Get-GPO -All -Domain $domainName | Where-Object { $_.DisplayName.Trim() -ieq $gpoName.Trim() }
# Define the registry paths and values for the policies
$cmdPolicyPath = "HKCU\Software\Policies\Microsoft\Windows\System"
$cmdPolicyName = "DisableCMD"
$runMenuPolicyPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$runMenuPolicyName = "NoRun"

# Function to check a registry value in a GPO
function Check-GPOPolicy {
    param (
        [string]$GPOName,
        [string]$Path,
        [string]$Name
    )

    try {
        $value = Get-GPRegistryValue -Name $GPOName -Key $Path -ValueName $Name -Domain "paris.local" -ErrorAction Stop
        return $value
    } catch {
        return $null
    }
}

# Check the policies
#$cmdPolicyValue = Check-GPOPolicy -GPOName $gpoName -Path $cmdPolicyPath -Name $cmdPolicyName
$runMenuPolicyValue = Check-GPOPolicy -GPOName $gpoName -Path $runMenuPolicyPath -Name $runMenuPolicyName

# Output the results
#if ($cmdPolicyValue -ne $null -and $cmdPolicyValue.Value -eq 1) {
#    Write-Host "Prevent access to the command prompt policy is enabled in the SALES GPO" -ForegroundColor Green
#} else {
#    Write-Host "Prevent access to the command prompt policy is not enabled in the SALES GPO" -ForegroundColor Red
#}



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

        # Check if "Prevent access to the command prompt" is enabled
        $preventCmdPolicy = $gpoXml.GPO.User.ExtensionData.Extension.Policy | Where-Object { $_.Name -eq "Prevent access to the command prompt" }
        if ($preventCmdPolicy -ne $null -and $preventCmdPolicy.State -eq "Enabled") {
            Write-Host "'Prevent access to the command prompt' is enabled" -ForegroundColor Yellow
        } else {
            Write-Host "'Prevent access to the command prompt' is not enabled" -ForegroundColor Red
            $allConditionsMet = $false
            $failedPolicies += "'Prevent access to the command prompt'"
        }


        # Check run Menu
        if ($runMenuPolicyValue -ne $null -and $runMenuPolicyValue.Value -eq 1) {
            Write-Host "Remove Run menu from Start Menu policy is enabled in the SALES GPO" -ForegroundColor Yellow
        } else {
            Write-Host "Remove Run menu from Start Menu policy is not enabled in the SALES GPO" -ForegroundColor Red
            $allConditionsMet = $false
            $failedPolicies += "'Prevent access to the command prompt'"
        }

        # Final output based on all conditions
        if ($allConditionsMet) {
            Write-Host "A3-5 component passed" -ForegroundColor Green
        } else {
            Write-Host "A3-5 component failed" -ForegroundColor Red
            Write-Host "Failed policies:" -ForegroundColor Red
            $failedPolicies | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        }
    } else {
        Write-Host "Failed to load GPO report XML for GPO '$gpoName'." -ForegroundColor Red
    }
}
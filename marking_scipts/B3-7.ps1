# Define the GPO name and domain
$gpoName = "NOTECH"
$domainName = "paris.local"
$checkScope = $false
try {
    # Get the GPO
    $gpo = Get-GPO -Name $gpoName -Domain $domainName -ErrorAction Stop

    # Get all permissions for the GPO
    $gpoPermissions = Get-GPPermissions -Guid $gpo.Id -All -Domain $domainName -ErrorAction Stop

    # Initialize an array to store allowed groups
    $allowedGroups = @("MKT", "HR", "SALES")
    $allowedGroups += "Domain Admins"  # Add Domain Admins if required

    # Initialize an array to store actual groups
    $actualGroups = @()

    # Check each permission to see if it's a security group
    foreach ($permission in $gpoPermissions) {
        $groupName = $permission.Trustee.Name

        # Exclude special permissions and default settings
        if ($groupName -notin "Authenticated Users", "Domain Computers") {
            if ($permission.Permission -eq "GpoApply") {
                # Add the group to the actual groups array
                $actualGroups += $groupName
            }
        }
    }

    # Identify wrong groups (those not in allowedGroups)
    $wrongGroups = $actualGroups | Where-Object { $_ -notin $allowedGroups }

    # Check if 'Authenticated Users' is applied
    $authenticatedUsersApplied = $gpoPermissions | Where-Object { $_.Trustee.Name -eq "Authenticated Users" -and $_.Permission -eq "GpoApply" }

    # Output the results
    if ($wrongGroups.Count -eq 0 -and !$authenticatedUsersApplied) {
        $checkScope = $true
    } else {
        Write-Host "GPO '$gpoName' is incorrectly filtered. Groups other than MKT, HR, and SALES are applied or 'Authenticated Users' is incorrectly applied:" -ForegroundColor Red
        $wrongGroups | ForEach-Object {
            Write-Host "- $_" -ForegroundColor Red
        }
        if ($authenticatedUsersApplied) {
            Write-Host "- Authenticated Users (should not be applied)" -ForegroundColor Red
        }
        Write-Host "B3-7 component failed" -ForegroundColor Red
    }

} catch {
    Write-Host "Failed to retrieve or check GPO '$gpoName' in the domain '$domainName'. Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Define the GPO name and domain
$gpoName = "NOTECH"
$domainName = "paris.local"

$userNoRegistry = $false
$turnOffFileHistStatus = $false

try {
    # Get the GPO
    $gpo = Get-GPO -Name $gpoName -Domain $domainName -ErrorAction Stop

    # Get the GPO report as XML
    $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    [xml]$gpoXml = $gpoReport
    $xml = [xml]$gpoReport
    foreach ($policy in $gpoXml.GPO.User.ExtensionData.Extension.Policy) {
    $name = $policy.Name
    $state = $policy.State
    if($name -eq "Prevent access to registry editing tools" -and $state -eq "Enabled"){
        $userNoRegistry = $true
    }

    }
    
    $xml = [xml]$gpoReport
$nsManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)

# Add namespaces used in the XML
$nsManager.AddNamespace("q3", "http://www.microsoft.com/GroupPolicy/Settings/Registry")
$nsManager.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

# Loop through each <ExtensionData> element under <Computer>
foreach ($extensionData in $xml.GPO.Computer.ExtensionData) {
    $name = $extensionData.Name
    # Determine the type of ExtensionData and extract specific properties
    switch ($name) {
        "Registry" {
            $turnOffFileHistory = $extensionData.Extension.Policy | Where-Object { $_.Name -eq "Turn off File History" }
            $stateTurnOffFileHistory = $turnOffFileHistory.State
            if ($stateTurnOffFileHistory -eq "Enabled") {
                $turnOffFileHistStatus = $true
            }
           # Write-Output "State of Turn off File History: $stateTurnOffFileHistory"
        }
        default {
            Write-Output "Unknown ExtensionData: $name"
        }
        
    }

}

    Write-Output "1. No Registry: $userNoRegistry"
    Write-Output "2. Turn off file history: $turnOffFileHistStatus"

    if($checkScope -and $userNoRegistry -and $turnOffFileHistStatus){
        Write-Host "B3-7 component passed" -ForegroundColor Green
    } else {
        Write-Host "B3-7 Component Failed: " -ForegroundColor Red
    }

} catch {
    Write-Host "B3-7 Component Failed: " -ForegroundColor Red
}

# Define the GPO name and domain
$gpoName = "DOMSEC"
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
#        Write-Host "GPO '$gpoName' is correctly filtered to only MKT, HR, and SALES groups." -ForegroundColor Green
#        Write-Host "A3-3 component passed" -ForegroundColor Green
        $checkScope = $true
    } else {
        Write-Host "GPO '$gpoName' is incorrectly filtered. Groups other than MKT, HR, and SALES are applied or 'Authenticated Users' is incorrectly applied:" -ForegroundColor Red
        $wrongGroups | ForEach-Object {
            Write-Host "- $_" -ForegroundColor Red
        }
        if ($authenticatedUsersApplied) {
            Write-Host "- Authenticated Users (should not be applied)" -ForegroundColor Red
        }
        Write-Host "A3-6 component failed" -ForegroundColor Red
    }

} catch {
    Write-Host "Failed to retrieve or check GPO '$gpoName' in the domain '$domainName'. Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Define the GPO name and domain
$gpoName = "DOMSEC"
$domainName = "paris.local"

$userNoControlPanel = $false
$userNoRegistry = $false
$envVarStatus = $false
$passwordAgeStatus = $false
$lanManagerStatus = $false
$disableAdminStatus = $false
$turnOffFileHistStatus = $false

try {
    # Get the GPO
    $gpo = Get-GPO -Name $gpoName -Domain $domainName -ErrorAction Stop

    # Get the GPO report as XML
    $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    [xml]$gpoXml = $gpoReport
    $xml = [xml]$gpoReport
    #Write-Host $gpoXml.GPO.User.ExtensionData.Extension.Policy[0].Name
    #Write-Host $gpoXml.GPO.User.ExtensionData.Extension.Policy[0].State
    foreach ($policy in $gpoXml.GPO.User.ExtensionData.Extension.Policy) {
    $name = $policy.Name
    $state = $policy.State
    if($name -eq "Prohibit access to Control Panel and PC settings" -and $state -eq "Enabled"){
        $userNoControlPanel = $true
    }
    if($name -eq "Prevent access to registry editing tools" -and $state -eq "Enabled"){
        $userNoRegistry = $true
    }

    }
    #Write-Output $userNoControlPanel
    #Write-Output $userNoRegistry
    $xml = [xml]$gpoReport
$nsManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)

# Add namespaces used in the XML
$nsManager.AddNamespace("q1", "http://www.microsoft.com/GroupPolicy/Settings/Environment")
$nsManager.AddNamespace("q2", "http://www.microsoft.com/GroupPolicy/Settings/Security")
$nsManager.AddNamespace("q3", "http://www.microsoft.com/GroupPolicy/Settings/Registry")
$nsManager.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

# Loop through each <ExtensionData> element under <Computer>
foreach ($extensionData in $xml.GPO.Computer.ExtensionData) {
    $name = $extensionData.Name
   # Write-Output $name
    # Determine the type of ExtensionData and extract specific properties
    switch ($name) {
        "Environment Variables" {
            $properties = $extensionData.Extension.SelectSingleNode("q1:EnvironmentVariables/q1:EnvironmentVariable/q1:Properties", $nsManager)
            $propertyName = $properties.name
            $propertyValue = $properties.value
            if ($propertyName -eq "TheErasTour" -and $propertyValue -eq "2024") {
                $envVarStatus = $true
            }
           # Write-Output "Properties of Environment Variables:"
           # Write-Output "  Name: $propertyName"
           # Write-Output "  Value: $propertyValue"
        }
        "Security" {
            
            $maximumPasswordAge = $extensionData.Extension.Account | Where-Object {$_.Name -eq "MaximumPasswordAge"}
            $settingNumberMaxPasswordAge = $maximumPasswordAge.SettingNumber
            # Write-Output $settingNumberMaxPasswordAge
            if ($settingNumberMaxPasswordAge -eq 13) {
                $passwordAgeStatus = $true
            }
            # Write-Output $extensionData.Extension.SecurityOptions | Where-Object { $_.Display.Name -eq "Network security: Do not store LAN Manager hash value on next password change" }
            $enableLmHash = $extensionData.Extension.SecurityOptions | Where-Object { $_.Display.Name -eq "Network security: Do not store LAN Manager hash value on next password change" }
            $lmHashSetting = $enableLmHash.SettingNumber
            if ($lmHashSetting -eq 1) {
                $lanManagerStatus = $true
            }
            # Write-Output $extensionData.Extension.SecurityOptions | Where-Object { $_.SystemAccessPolicyName -eq "EnableAdminAccount" }
            $enableAdminAccount = $extensionData.Extension.SecurityOptions | Where-Object { $_.SystemAccessPolicyName -eq "EnableAdminAccount" }
            $settingNumberEnableAdmin = $enableAdminAccount.SettingNumber
            if ($settingNumberEnableAdmin -eq 0) {
                $disableAdminStatus = $true
            }
           # Write-Output "SettingNumber of MaximumPasswordAge: $settingNumberMaxPasswordAge"
           # Write-Output "Boolean value of Network security: Do not store LAN Manager hash value on next password change: $lmHashSetting"
           # Write-Output "SettingNumber of EnableAdminAccount: $settingNumberEnableAdmin"
        }
        "Registry" {
            #Write-Output $extensionData.Extension.Policy | Where-Object { $_.Name -eq "Turn off File History" }
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

    Write-Output "1. No control panel: $userNoControlPanel"
    Write-Output "2. No Registry: $userNoRegistry"
    Write-Output "3. env vars: $envVarStatus"
    Write-Output "4. Password age: $passwordAgeStatus"
    Write-Output "5. LM Managager: $lanManagerStatus"
    Write-Output "6. DisableAdmin: $disableAdminStatus"
    Write-Output "7. Turn off file history: $turnOffFileHistStatus"

    if($checkScope -and $userNoControlPanel -and $userNoRegistry -and $envVarStatus -and $passwordAgeStatus -and $lanManagerStatus -and $disableAdminStatus -and $turnOffFileHistStatus){
        Write-Host "A3-6 component passed" -ForegroundColor Green
    } else {
        Write-Host "A3-6 Component Failed: " -ForegroundColor Red
    }

} catch {
    Write-Host "A3-6 Component Failed: " -ForegroundColor Red
}

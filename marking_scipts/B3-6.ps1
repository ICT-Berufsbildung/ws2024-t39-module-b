# Define the GPO name and domain
$gpoName = "DOMSEC"
$domainName = "paris.local"
try {
    # Get the GPO
    $gpo = Get-GPO -Name $gpoName -Domain $domainName -ErrorAction Stop

    # Get all permissions for the GPO
    $gpoPermissions = Get-GPPermissions -Guid $gpo.Id -All -Domain $domainName -ErrorAction Stop

} catch {
    Write-Host "Failed to retrieve or check GPO '$gpoName' in the domain '$domainName'. Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Define the GPO name and domain
$gpoName = "DOMSEC"
$domainName = "paris.local"

$envVarStatus = $false
$passwordAgeStatus = $false
$lanManagerStatus = $false
$disableAdminStatus = $false

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

    }
    
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
    # Determine the type of ExtensionData and extract specific properties
    switch ($name) {
        "Environment Variables" {
            $properties = $extensionData.Extension.SelectSingleNode("q1:EnvironmentVariables/q1:EnvironmentVariable/q1:Properties", $nsManager)
            $propertyName = $properties.name
            $propertyValue = $properties.value
            if ($propertyName -eq "TheErasTour" -and $propertyValue -eq "2024") {
                $envVarStatus = $true
            }
        }
        "Security" {
            
            $maximumPasswordAge = $extensionData.Extension.Account | Where-Object {$_.Name -eq "MaximumPasswordAge"}
            $settingNumberMaxPasswordAge = $maximumPasswordAge.SettingNumber
            if ($settingNumberMaxPasswordAge -eq 13) {
                $passwordAgeStatus = $true
            }
            $enableLmHash = $extensionData.Extension.SecurityOptions | Where-Object { $_.Display.Name -eq "Network security: Do not store LAN Manager hash value on next password change" }
            $lmHashSetting = $enableLmHash.SettingNumber
            if ($lmHashSetting -eq 1) {
                $lanManagerStatus = $true
            }
            $enableAdminAccount = $extensionData.Extension.SecurityOptions | Where-Object { $_.SystemAccessPolicyName -eq "EnableAdminAccount" }
            $settingNumberEnableAdmin = $enableAdminAccount.SettingNumber
            if ($settingNumberEnableAdmin -eq 0) {
                $disableAdminStatus = $true
            }
        }
        default {
            Write-Output "Unknown ExtensionData: $name"
        }
        
    }

}

    Write-Output "1. env vars: $envVarStatus"
    Write-Output "2. Password age: $passwordAgeStatus"
    Write-Output "3. LM Managager: $lanManagerStatus"
    Write-Output "4. DisableAdmin: $disableAdminStatus"

    if($envVarStatus -and $passwordAgeStatus -and $lanManagerStatus -and $disableAdminStatus){
        Write-Host "B3-6 component passed" -ForegroundColor Green
    } else {
        Write-Host "B3-6 Component Failed: " -ForegroundColor Red
    }

} catch {
    Write-Host "B3-6 Component Failed: " -ForegroundColor Red
}

# Import the Group Policy module
Import-Module GroupPolicy

# Define the GPO name and the domain
$GPOName = "Desktop"
$Domain = "paris.local"

# Path to the temporary XML report file
$ReportPath = "$env:TEMP\GPOReport.xml"

# Generate a GPO report in XML format
try {
    Get-GPOReport -Name $GPOName -Domain $Domain -ReportType XML -Path $ReportPath
} catch {
    Write-Error "Failed to generate GPO report for '$GPOName' in domain '$Domain'. Error: $_"
    exit 1
}

# Load the XML report
[xml]$GPOReport = Get-Content -Path $ReportPath

# Add the namespace manager for proper XML parsing
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($GPOReport.NameTable)
$namespaceManager.AddNamespace("q1", "http://www.microsoft.com/GroupPolicy/Settings/Security")

# Define the XPath to locate the specific setting
$XPath = "//q1:SecurityOptions[q1:KeyName='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText']/q1:Display/q1:Name[text()='Interactive logon: Message text for users attempting to log on']/../q1:DisplayStrings/q1:Value"

# Check if the setting is present and retrieve its value
$Setting = $GPOReport.SelectSingleNode($XPath, $namespaceManager)



if ($Setting) {
    $Value = $Setting.InnerText
    $ExpectedMessage = "Welcome to Lyon! Only authorised personnel allowed to access. Should you try to break in, I knew you were trouble"
    
    if ($Value -eq $ExpectedMessage) {
        Write-Output "The 'Interactive logon: Message text for users attempting to log on' setting is configured with the expected message."
        Write-Host "A3-1 component"
        Write-Host "passed" -ForegroundColor Green
    } else {
        Write-Output "The 'Interactive logon: Message text for users attempting to log on' setting is configured, but the message does not match the expected message."
        Write-Host "A3-1 component"
        Write-Host "failed" -ForegroundColor Red
        Write-Output "Configured: " $Value
    }
} else {
    Write-Output "The 'Interactive logon: Message text for users attempting to log on' setting is not configured in the '$GPOName' GPO."
    Write-Host "A3-1 component"
    Write-Host "failed" -ForegroundColor Red
}

# Cleanup
Remove-Item -Path $ReportPath -Force



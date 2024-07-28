# Download IIS modules
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi', 'C:\Users\Administrator\Desktop\requestRouter_amd64.msi')
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi', 'C:\Users\Administrator\Desktop\rewrite_amd64_en-US.msi')
# Deploy web templates
New-Item -Path 'C:\Users\Administrator\Desktop\HTML' -ItemType Directory | Out-Null
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $Env:PACKER_HTTP_ADDR/external.html -OutFile "C:\Users\Administrator\Desktop\HTML\external.html"
Invoke-WebRequest -Uri $Env:PACKER_HTTP_ADDR/help.html -OutFile "C:\Users\Administrator\Desktop\HTML\help.html"
Invoke-WebRequest -Uri $Env:PACKER_HTTP_ADDR/internal.html -OutFile "C:\Users\Administrator\Desktop\HTML\internal.html"
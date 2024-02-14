# Retrieve secrets from environment variables
$TenantID = $env:EIDTENANT
$AppID = $env:EIDAPPID
$AppSecret = $env:EIDAPPSECRET

Set-ExecutionPolicy Unrestricted -Force

Install-PackageProvider NuGet -Force -ErrorAction SilentlyContinue
Install-Script Get-WindowsAutoPilotInfo -Force
Get-WindowsAutoPilotInfo -Online -TenantId $TenantID -AppID $AppID -AppSecret $AppSecret 

Set-ExecutionPolicy RemoteSigned -Force

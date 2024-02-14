Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Script -Name Get-WindowsAutoPilotInfo -Force | Out-Null
Install-Module -Name WindowsAutopilotIntune -Force | Out-Null

# Retrieve secrets from environment variables
$TenantId = $env:EIDTENANT
$AppId = $env:EIDAPPID
$AppSecret = $env:EIDAPPSECRET

$AutopilotParams = @{
    Online = $true
    TenantId = $TenantId
    AppId = $AppId
    AppSecret = $AppSecret
}

Get-WindowsAutoPilotInfo @AutopilotParams

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

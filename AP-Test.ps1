Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Script -Name Get-WindowsAutoPilotInfo -Force | Out-Null
Install-Module -Name WindowsAutopilotIntune -Force | Out-Null

# Retrieve secrets from environment variables
$TenantId = $env:EIDTENANT
$AppId = $env:EIDAPPID
$AppSecret = $env:EIDAPPSECRET

Write-Host "Debugging: Tenant ID: $TenantId"
Write-Host "Debugging: App ID: $AppId"
# Write out the AppSecret for debugging. It's not recommended to output secrets like this in a real environment.
Write-Host "Debugging: App Secret: $AppSecret"

$AutopilotParams = @{
    Online = $true
    TenantId = $TenantId
    AppId = $AppId
    AppSecret = $AppSecret
}

Write-Host "Debugging: Executing Get-WindowsAutoPilotInfo with parameters:"
Write-Host "Debugging: $AutopilotParams"

Get-WindowsAutoPilotInfo @AutopilotParams

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

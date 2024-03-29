Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Script -Name Get-WindowsAutoPilotInfo -Force | Out-Null
Install-Module -Name WindowsAutopilotIntune -Force | Out-Null

# Retrieve secrets from environment variables
#$TenantId = ${{secrets.EIDTENANT}}
#$AppId = ${{secrets.EIDAPPID}}
#$AppSecret = ${{secrets.EIDAPPSECRET}}

$AutopilotParams = @{
    Online = $true
    TenantId = $EIDTENANT
    AppId = $EIDAPPID
    AppSecret = $EIDAPPSECRET
}

Get-WindowsAutoPilotInfo @AutopilotParams

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

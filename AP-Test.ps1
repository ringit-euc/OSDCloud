Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Script -Name Get-WindowsAutoPilotInfo -Force | Out-Null
Install-Module -Name WindowsAutopilotIntune -Force | Out-Null

$AutopilotParams = @{
    Online = $true
    TenantId = "${{secrets.EIDTENANT}}"
    AppId = "${{secrets.EIDAPPID}}"
    AppSecret = "${{secrets.EIDAPPSECRET}}"
}

Get-WindowsAutoPilotInfo @AutopilotParams

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

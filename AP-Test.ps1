Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force:$true
Install-Script get-windowsautopilotinfo -Confirm:$false -Force:$true
get-windowsautopilotinfo -Online -TenantId $TenantId -AppId $AppId -AppSecret $AppSecret

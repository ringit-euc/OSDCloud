# Temporary fix for Workspace One not deploying applications after the enrollment
# https://kb.vmware.com/s/article/87801?lang=en_US&queryTerm=sfd%20agent

# Download the appdeploymentagent-x64.msi from Google Drive
$SaveFolder = "C:\Temp"
$InstallerFileName = "appdeploymentagent-x64.msi"
$Url = "https://drive.google.com/uc?export=download&id=16XPdOK8K_mzu6XPGSuyKJVi2ODEL8old&confirm=t"

$SavePath = Join-Path $SaveFolder $InstallerFileName
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($Url,$SavePath)

# Install the appdeploymentagent-x64.msi silently
msiexec /i "C:\Temp\appdeploymentagent-x64.msi" /qn /norestart

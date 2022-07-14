Write-Host  -ForegroundColor Cyan "Starting OSDCloud ..."
Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Setting Display Resolution to 1366x"
    Set-DisRes 1366
}
cls
Write-Host "===================== Main Menu =======================" -ForegroundColor Yellow
Write-Host "1: Install Windows 10 21H2 | en-us | Professional"-ForegroundColor Yellow
Write-Host "2: Exit" -ForegroundColor Yellow
$input = Read-Host "Please make a selection"
Write-Host  -ForegroundColor Yellow "Loading OSDCloud..."

#Make sure I have the latest OSD Content
Write-Host  -ForegroundColor Cyan "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Cyan "Importing PowerShell Modules"
Import-Module OSD -Force

switch ($input)
{
    '1' { Start-OSDCloud -OSLanguage en-us -OSVersion 'Windows 10' -OSBuild 21H2 -OSEdition Pro -OSLicense Retail -ZTI -Firmware -SkipAutopilot -SkipODT }
    '2' { Exit }  
}

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "Autopilot":  {
                      "IsPresent":  false
                  },
    "RemoveAppx":  [
                        "Microsoft.MicrosoftOfficeHub",
                        "Microsoft.MicrosoftSolitaireCollection",
                        "Microsoft.MixedReality.Portal",
                        "Microsoft.People",
                        "Microsoft.SkypeApp",
                        "Microsoft.Wallet",
                        "microsoft.windowscommunicationsapps",
                        "Microsoft.Xbox.TCUI",
                        "Microsoft.XboxApp",
                        "Microsoft.XboxGameOverlay",
                        "Microsoft.XboxGamingOverlay",
                        "Microsoft.XboxIdentityProvider",
                        "Microsoft.XboxSpeechToTextOverlay",
                        "Microsoft.YourPhone",
                        "Microsoft.ZuneMusic",
                        "Microsoft.ZuneVideo",
                        "Microsoft.3DBuilder",
                        "Microsoft.Office.OneNote"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
$AutopilotOOBEJson = @'
{
    "Assign":  {
                   "IsPresent":  true
               },
    "Hidden":  [
                   "AssignedComputerName",
                   "AssignedUser",
                   "PostAction",
                   "Assign",
                   "GroupTag",
                   "AddToGroup"
               ],
    "PostAction":  "Quit",
    "Run":  "NetworkingWireless",
    "Docs":  "https://docs.microsoft.com/en-us/mem/autopilot/troubleshooting",
    "Title":  "RCIT Autopilot Registration"
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBEAutopilot.cmd"
$OOBEAutopilotCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/andrewbelleza/OSDCloud/main/Scripts/Install-EmbeddedProductKey.ps1
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Start-AutopilotOOBE
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$OOBEAutopilotCMD | Out-File -FilePath 'C:\Windows\System32\OOBEAutopilot.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host -Foregroundcolor Yellow "*****  REMOVE THE USB DRIVE NOW *****"
Read-Host "The next step is to reboot the machine, connect to wifi/lan then press Shift + F10 to open a command prompt. 
Type-in OOBEAutopilot.cmd, then hit enter and wait to complete the autopilot and updates build. 
Press the ENTER key to continue...."
wpeutil reboot

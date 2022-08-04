cls
Write-Host "===================== OSDCloud Main Menu =======================" -ForegroundColor Cyan
Write-Host " "
Write-Host "1: Zero-Touch Windows 10 21H2 | en-us | Professional" -ForegroundColor Cyan
Write-Host "2: Zero-Touch Windows 11 21H2 | en-us | Professional (Not Certified Yet - For Testing)" -ForegroundColor Cyan
Write-Host "3: Start the Graphical OSDCloud (Manual Selection)" -ForegroundColor Cyan
Write-Host "4: Exit" -ForegroundColor Cyan
Write-Host " "
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "`n WARNING: Going further will erase all data on the disk!!! `n" -ForegroundColor Yellow -BackgroundColor Red

$input = Read-Host "Please make a selection"

switch ($input)
{
    '1' { Start-OSDCloud -OSLanguage en-us -OSName 'Windows 10 21H2 x64' -OSEdition Pro -OSLicense Retail -ZTI -Firmware -SkipAutopilot -SkipODT }
    '2' { Start-OSDCloud -OSLanguage en-us -OSName 'Windows 11 21H2 x64' -OSEdition Pro -OSLicense Retail -ZTI -Firmware -SkipAutopilot -SkipODT }
    '3' { Start-OSDCloudGUI } 
    '4' { Exit }  
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force -SkipPublisherCheck

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

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
                   "Docs",
                   "Run",
                   "GroupTag",
                   "AddToGroup",
                   "PostAction"
               ],
    "PostAction":  "Quit",
    "Title":  "Autopilot Registration",
    "Disabled": "Assign"
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
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/ringit-euc/OSDCloud/main/Install-EmbeddedProductKey.ps1
Start /Wait PowerShell -NoL -C Start-AutopilotOOBE
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$OOBEAutopilotCMD | Out-File -FilePath 'C:\Windows\System32\OOBEAutopilot.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
RD C:\OSDCloud\OS /S /Q
XCOPY C:\OSDCloud\ C:\Windows\Logs\OSD /E /H /C /I /Y
XCOPY C:\ProgramData\OSDeploy C:\Windows\Logs\OSD /E /H /C /I /Y
RD C:\OSDCloud /S /Q
RD C:\Drivers /S /Q
RD C:\Temp /S /Q
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host "*****  REMOVE THE USB DRIVE NOW *****" -ForegroundColor Yellow -BackgroundColor Red 
Read-Host "The next step is to reboot the machine, connect to wifi/lan then press Shift + F10 to open a command prompt. 
Type-in OOBEAutopilot.cmd, then hit enter and wait to complete the autopilot and updates build. 
Press the ENTER key to continue...."
wpeutil reboot

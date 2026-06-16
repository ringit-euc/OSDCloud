Remove-Item -Path "X:\Windows\System32\WindowsPowerShell\v1.0\Modules\OSD" -Recurse -Force -ErrorAction SilentlyContinue

cls
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Zero-Touch Install: Windows 11 25H2 | en-us | Professional" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "`n WARNING: Going further will erase all data on the disk!!! `n" -ForegroundColor Yellow -BackgroundColor Red

Write-Host "Waiting for network connectivity..." -ForegroundColor Cyan
while (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 5
}
Write-Host "Network is ready." -ForegroundColor Green

Try {
    Start-OSDCloud -OSLanguage en-us -OSName 'Windows 11 25H2 x64' -OSEdition Pro -OSLicense Retail -ZTI -SkipODT
} Catch {
    Write-Host "ERROR: Start-OSDCloud failed - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press ENTER to exit to X:\..." -ForegroundColor Yellow
    Read-Host
    exit 1
}


Write-Host -ForegroundColor Green "Create C:\Windows\Panther\Unattend.xml"
$Serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim() -replace '\s','' -replace '[^a-zA-Z0-9]', ''
$CombinedName = "LP$Serial"
$Hostname = $CombinedName.Substring(0, [math]::Min($CombinedName.Length, 15))
$UnattendXml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup"
                   processorArchitecture="amd64"
                   publicKeyToken="31bf3856ad364e35"
                   language="neutral"
                   versionScope="nonSxS"
                   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <ComputerName>$Hostname</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup"
                   processorArchitecture="amd64"
                   publicKeyToken="31bf3856ad364e35"
                   language="neutral"
                   versionScope="nonSxS"
                   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
</unattend>
"@
If (!(Test-Path "C:\Windows\Panther")) {
    New-Item "C:\Windows\Panther" -ItemType Directory -Force | Out-Null
}
[System.IO.File]::WriteAllText("C:\Windows\Panther\Unattend.xml", $UnattendXml, [System.Text.UTF8Encoding]::new($false))

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
                        "Microsoft.People",
                        "Microsoft.SkypeApp",
                        "microsoft.windowscommunicationsapps",
                        "Microsoft.Xbox.TCUI",
                        "Microsoft.XboxGameOverlay",
                        "Microsoft.XboxGamingOverlay",
                        "Microsoft.XboxIdentityProvider",
                        "Microsoft.XboxSpeechToTextOverlay",
                        "Microsoft.YourPhone",
                        "Microsoft.Office.OneNote",
                        "Microsoft.BingNews",
                        "Microsoft.BingWeather",
                        "Microsoft.GamingApp",
                        "Microsoft.Todos",
                        "Microsoft.PowerAutomateDesktop",
                        "Microsoft.Teams",
                        "MicrosoftCorporationII.MicrosoftFamily",
                        "Clipchamp.Clipchamp",
                        "Microsoft.WindowsFeedbackHub",
                        "Microsoft.549981C3F5F10"
                   ]
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force


#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBEAutopilot.cmd"
$OOBEAutopilotCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
SET PATH=%PATH%;C:\Program Files\WindowsPowerShell\Scripts

:WAITFORNETWORK
PowerShell -NoL -C "if (!(Test-NetConnection -ComputerName 'login.microsoftonline.com' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)) { exit 1 }"
if %ERRORLEVEL% NEQ 0 (
    echo [1/9] Waiting for network connectivity... Retrying in 15 seconds.
    timeout /t 15 /nobreak >nul
    goto WAITFORNETWORK
)
echo [1/9] Network is ready.

echo [2/9] Syncing clock...
w32tm /resync /force >nul 2>&1
echo [2/9] Done.

echo [3/9] Installing OSD PowerShell Module...
Start /Wait PowerShell -NoL -C "Write-Host 'Installing OSD module, please wait...' -ForegroundColor Cyan; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null; Install-Module OSD -Force | Out-Null; Write-Host 'Done.' -ForegroundColor Green"
echo [3/9] Done.

echo [4/9] Activating Windows product key...
Start /Wait PowerShell -NoL -C "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebPSScript https://raw.githubusercontent.com/ringit-euc/OSDCloud/main/Install-EmbeddedProductKey.ps1"
echo [4/9] Done.

echo [5/9] Setting Windows Update policies to block feature upgrades...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWUfBSafeguards" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /t REG_SZ /d "25H2" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 0 /f >nul
echo [5/9] Done.
echo [6/9] Registering Microsoft Update service for .NET and Security updates...
Start /Wait PowerShell -NoL -C "Write-Host 'Registering Microsoft Update service, please wait...' -ForegroundColor Cyan; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Install-Module PSWindowsUpdate -Force | Out-Null; Import-Module PSWindowsUpdate; Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null; Write-Host 'Done.' -ForegroundColor Green"
echo [6/9] Done.
echo [7/9] Running Windows and .NET Security Updates...
Start /Wait PowerShell -NoL -C "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Import-Module PSWindowsUpdate; Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot"
echo [7/9] Done.
echo [8/9] Running Driver Updates...
Start /Wait PowerShell -NoL -C "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Start-OOBEDeploy -UpdateDrivers -NoRestart"
echo [8/9] Done.

echo [9/9] Removing bloatware...
Start /Wait PowerShell -NoL -C "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Start-OOBEDeploy -RemoveAppx -NoRestart"
echo [9/9] Done.

echo Setup complete. Rebooting now...
shutdown /r /f /t 0
'@
$OOBEAutopilotCMD | Out-File -FilePath 'C:\Windows\System32\OOBEAutopilot.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
XCOPY C:\OSDCloud\ C:\Windows\Logs\OSD /E /H /C /I /Y
XCOPY C:\ProgramData\OSDeploy C:\Windows\Logs\OSD /E /H /C /I /Y
RD C:\OSDCloud\OS /S /Q
RD C:\OSDCloud /S /Q
RD C:\Drivers /S /Q
IF EXIST C:\Temp (RD C:\Temp /S /Q)
'@
If (!(Test-Path "C:\Windows\Setup\Scripts")) {
    New-Item "C:\Windows\Setup\Scripts" -ItemType Directory -Force | Out-Null
}
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host -ForegroundColor Green "Clearing TPM to remove stale enrollment data..."
$tpmTool = & tpmtool.exe getdeviceinformation 2>&1
if ($LASTEXITCODE -eq 0) {
    $clearResult = & tpmtool.exe clearTPM 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "TPM cleared successfully via tpmtool." -ForegroundColor Green
    } else {
        Write-Host "tpmtool clearTPM failed (code $LASTEXITCODE) - requesting physical presence clear on next boot..." -ForegroundColor Yellow
        $tpm = Get-CimInstance -Namespace "root\cimv2\security\microsofttpm" -Class Win32_Tpm
        if ($tpm) {
            $tpm | Invoke-CimMethod -MethodName "SetPhysicalPresenceRequest" -Arguments @{ RequestId = 14 } | Out-Null
            Write-Host "Physical presence TPM clear requested (takes effect on next boot)." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "TPM not found or not ready — skipping clear." -ForegroundColor Yellow
}

Write-Host "*****  REMOVE THE USB DRIVE NOW *****" -ForegroundColor Yellow -BackgroundColor Red
Read-Host "Press ENTER to reboot..."
wpeutil reboot

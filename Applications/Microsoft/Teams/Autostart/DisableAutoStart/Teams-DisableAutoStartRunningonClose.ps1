$ErrorActionPreference = "Stop"
$TeamsDesktopConfigJsonPath = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft', 'Teams', 'desktop-config.json')

# 0. Close Teams, if running
$teamsProc = Get-Process -name Teams -ErrorAction SilentlyContinue
if ($null -ne $teamsProc) {
    Write-Host  "Stopping Microsoft Teams..."
    Stop-Process -Name Teams -Force
    # wait some time
    Start-Sleep 5
} else {
    Write-Host  "No running Teams process found"
}

# 1. Check that Teams process isn't still running
$teamsProc = Get-Process -name Teams -ErrorAction SilentlyContinue

if($null -eq $teamsProc) {

    if (Test-Path -Path $TeamsDesktopConfigJsonPath) {
            Write-Host "Modifying appPreferenceSettings in desktop-config.json file"

            # open desktop-config.json file
            $desktopConfigFile = Get-Content -path $TeamsDesktopConfigJsonPath -Raw | ConvertFrom-Json
            #Disable running on close - e.g. prevent running in the background after clicking the red X to exit
            $desktopConfigFile.appPreferenceSettings.runningOnClose=$false
            #Prevent opening at sign in
            $desktopConfigFile.appPreferenceSettings.openAtLogin=$false
            $desktopConfigFile | ConvertTo-Json -Compress | Set-Content -Path $TeamsDesktopConfigJsonPath -Force
        }
} else {
    Write-Host  "Teams process is still running, aborting script execution"
}
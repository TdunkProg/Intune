<#
.SYNOPSIS
This script allows you to uninstall the Microsoft Teams app and remove Teams directory for a user.
.DESCRIPTION
Use this script to clear the installed Microsoft Teams application. Run this PowerShell script for each user profile for which the Teams App was installed on a machine. 
#>

function WriteLog($LogText){ 
    Add-Content -path $LogFile -value "$((Get-Date).ToString()) $LogText"
}
$Logfile = 'c:\windows\temp\RemoveTeams.txt'
$TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
$TeamsUpdateExePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams', 'Update.exe')

#Check if Teams is running, if so, stop it
$teamsProc = Get-Process -name Teams -ErrorAction SilentlyContinue
if ($null -ne $teamsProc) {
    WriteLog 'Teams process found, stopping'
    Stop-Process -Name Teams -Force
    # wait some time
    Start-Sleep 5
} else {
    WriteLog 'No running Teams process found'
}

try
{
    if (Test-Path -Path $TeamsUpdateExePath) {
        WriteLog 'Uninstalling Teams process'

        # Uninstall app
        $proc = Start-Process -FilePath $TeamsUpdateExePath -ArgumentList "-uninstall -s" -PassThru
        $proc.WaitForExit()
    }
    if (Test-Path -Path $TeamsPath) {
        WriteLog 'Deleting Teams directory'
        Remove-Item -Path $TeamsPath -Recurse
    }
}
catch
{
    WriteLog "Fatal error $_"
    exit /b 1
}
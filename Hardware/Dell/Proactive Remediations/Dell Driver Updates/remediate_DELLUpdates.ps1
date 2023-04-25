$DCU_folder = "C:\Program Files (x86)\Dell\CommandUpdate"
$DCU_report = "C:\Temp\Dell_report\update.log"
$DCU_exe = "$DCU_folder\dcu-cli.exe"
$DCU_category = "firmware,driver"  # bios,firmware,driver,application,others

try{
    Start-Process $DCU_exe -ArgumentList "/applyUpdates -silent -reboot=disable -updateType=$DCU_category -outputlog=$DCU_report /configure -silent -autoSuspendBitLocker=enable -userConsent=disable" -Wait
    Write-Output "Installation completed"
}catch{
    Write-Error $_.Exception
}

# Usermanual: https://www.dell.com/support/manuals/de-ch/command-update/dellcommandupdate_rg/dell-command-%7C-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us

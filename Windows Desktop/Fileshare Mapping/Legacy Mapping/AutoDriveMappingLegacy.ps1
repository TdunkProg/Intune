#If trying to map a home drive where you have users with a folder on a file share that uses their username, modify the following variable:
$path = "\\servername\students`$\`$env:USERNAME"
#If you have a folder with spaces in it, use the following format for the path variable
#$path = '''\\servername\test\student test'''
#Modify the driveletter variable to specify the drive letter to be mapped on the machine
$driveLetter = “’H'"


$ST_A = New-ScheduledTaskAction –Execute 'cmd' -Argument "/c start /b C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Minimized -NoLogo -NoProfile -NonInteractive -Command New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $Path -Persist"
$ST_T = New-ScheduledTaskTrigger -AtLogon
$ST_S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -Hidden
$ST_P = New-ScheduledTaskPrincipal -GroupId 'Builtin\Users'
Register-ScheduledTask –TaskName "Map Network Drive" -Action $ST_A –Trigger $ST_T -Settings $ST_S -Principal $ST_P -Force 

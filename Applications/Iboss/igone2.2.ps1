# Create file
$filePath = Join-Path -Path $env:ProgramFiles -ChildPath "Phantom\IBSA-Uninstalled.jb"
New-Item -ItemType File -Path $filePath -Force | Out-Null

Start-Process msiexec.exe -ArgumentList "/x `"$($env:ProgramFiles)\Phantom\IBSA\iboss-cloud-desktop-app.msi`" /quiet" -Wait

$softwareName = "IBSA"
$uninstallKey = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*$softwareName*"}
$guid = $uninstallKey.PSChildName

$uninstallString = $uninstallKey.UninstallString
$uninstallCommand = "$uninstallString /quiet"
Start-Process msiexec.exe -ArgumentList "/x $guid /passive" -Wait


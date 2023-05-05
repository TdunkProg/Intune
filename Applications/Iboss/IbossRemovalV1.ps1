@ECHO OFF

CLS

SET iboss_key="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\iBoss Security Agent"

SET proxy_key="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

WMIC product where name="ibsa" uninstall

REG add %proxy_key% /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1

REG delete %proxy_key% /v AutoConfigURL /f >nul 2>&1

REG delete %iboss_key% /f >nul 2>&1

exit
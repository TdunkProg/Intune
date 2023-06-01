# pre-requisite installs
# Install-Module MSonline
# Install-Module -Name WindowsAutoPilotIntune

# Get user creds and connect to MSonline
$UserCredential = Get-Credential
#$path = "$PSScriptRoot\DeviceList.txt"
#Connect-MsolService -Credential $UserCredential
Connect-MSGraph
# Get device info for all devices named in $FILE$

ForEach ($deviceName in (Get-Content .\DeviceList.txt)) {

get-autopilotdevice | where {$_.serialNumber -eq $deviceName} | Out-File -FilePath .\DeviceInfo.txt -append

} 


# Filter out the device ids
Get-Content .\DeviceInfo.txt | Where { $_ -match "id                                        " } | Set-Content .\DeviceIDs.txt

#clean up device ids file
get-content .\DeviceIDs.txt | % {$_ -replace "id                                        : ",""} | Out-File .\FinalIDs.txt
$Group = 11120
Connect-Msgraph

# update groupings for all devices associated with device ids

ForEach ($ID in (Get-Content .\FinalIDs.txt)) 
{

Set-AutoPilotDevice -id $ID -groupTag 11120

}  

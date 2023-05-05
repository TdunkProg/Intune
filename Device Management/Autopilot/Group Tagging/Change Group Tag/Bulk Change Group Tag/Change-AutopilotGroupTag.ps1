Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
Connect-MSGraph -Quiet

# Get all autopilot devices (even if more than 1000)
$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

# Display gridview to show devices
$selectedAutopilotDevices =  $autopilotDevices | Out-GridView -OutputMode Multiple -Title "Select Windows Autopilot entities to update"

$selectedAutopilotDevices | ForEach-Object {

    $autopilotDevice = $PSItem

    # Change names according to your environment
    $autopilotDevice.groupTag = "MOSD"
    #$autopilotDevice.orderIdentifier = "ORDER1234" | updating orderidentifier is currently not supported

    $requestBody=
@"
    {
        groupTag: `"$($autopilotDevice.groupTag)`",
    }
"@
    Write-Output "Updating entity: $($autopilotDevice.id) | groupTag: $($autopilotDevice.groupTag) | orderIdentifier: $($autopilotDevice.orderIdentifier)"
    Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody -Url "deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotDevice.id)/UpdateDeviceProperties" 
}

# Invoke an autopilot service sync
Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/windowsAutopilotSettings/sync"
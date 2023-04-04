
try {
    #If you need to add additional apps to this list, get the Provisioned App Display name by running (Get-AppXProvisionedPackage -Online).DisplayName via Powershell
    #Minecraft requires the XboxGame(ing)overlay apps in order to take screenshots. If removed, you will get an error when opening Minecraft. Minecraft still works, but the error might be annoying for end users.
    $ProvisionedAppPackageNames = @( 
        #MS Stuff
        "Microsoft.YourPhone"
        "Microsoft.SkypeApp"
        "Microsoft.Messaging"
        "Microsoft.People"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.BingWeather"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.MixedReality.Portal"
        "microsoft.windowscommunicationsapps"
        "Microsoft.XboxApp"
        "MicrosoftTeams"
        "Microsoft.BingNews"
        "Microsoft.MicrosoftSolitaireCollection"
        #"Microsoft.WindowsStore"
        "Microsoft.SurfaceHub"
        "Microsoft.GamingApp"
        #Remove these if using Take a Test and need a faster logon - only remove these if the device is going to be used only for testing
        "Clipchamp.Clipchamp"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.MicrosoftStickyNotes"
        "Microsoft.RawImageExtension"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.ZuneMusic"
        "Microsoft.ZuneVideo"
        "MicrosoftCorporationII.QuickAssist"
        )

    $ProvisionedStoreApps = (Get-AppXProvisionedPackage -Online).DisplayName
    
    foreach ($ProvisionedAppName in $ProvisionedAppPackageNames) {
        If($ProvisionedAppName -in $ProvisionedStoreApps) {
            Get-AppxPackage -Name $ProvisionedAppName -AllUsers | Remove-AppxPackage
            Get-AppXProvisionedPackage -Online | where DisplayName -EQ $ProvisionedAppName | Remove-AppxProvisionedPackage -Online -AllUsers
            "$ProvisionedAppName removed" | out-file c:\windows\temp\AppsRemoved.txt -Append
        }
    }

    #Checks for Teams Machine Wide Installer and removes it. 
    #This is best used for provisioning new devices.
    #Once a user signs in and Teams is installed for that user, it must be uninstalled from that user's profile. 
    #if(Test-Path 'C:\Program Files (x86)\Teams Installer'){
    #    Start-Process -FilePath MsiExec.exe -ArgumentList "/X `{731F6BAA-A986-45A4-8936-7C3AAAAA760B`} /qn /norestart /log c:\windows\temp\TeamsUninstall.log" -Wait
    #}
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
# Variables
[System.Int32]$waitBatchSeconds = 5
[System.Int32]$maxWaitSeconds = 300

# Applocker policy
[string]$SidecarMiPolicy = 
@"
<?xml version="1.0"?>
<AppLockerPolicy Version="1">
    <RuleCollection Type="Appx" EnforcementMode="NotConfigured" />

    <RuleCollection Type="Dll" EnforcementMode="AuditOnly">
        <FilePathRule Id="86f235ad-3f7b-4121-bc95-ea8bde3a5db5" Name="Dummy Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
            <Conditions>
                <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.dll" />
            </Conditions>
        </FilePathRule>
        <RuleCollectionExtensions>
            <ThresholdExtensions>
                <Services EnforcementMode="Enabled" />
            </ThresholdExtensions>
            <RedstoneExtensions>
                <SystemApps Allow="Enabled" />
            </RedstoneExtensions>
        </RuleCollectionExtensions>
    </RuleCollection>

    <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
        <FilePathRule Id="9420c496-046d-45ab-bd0e-455b2649e41e" Name="Dummy Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
            <Conditions>
                <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.exe" />
            </Conditions>
        </FilePathRule>
        <RuleCollectionExtensions>
            <ThresholdExtensions>
                <Services EnforcementMode="Enabled" />
            </ThresholdExtensions>
            <RedstoneExtensions>
                <SystemApps Allow="Enabled" />
            </RedstoneExtensions>
        </RuleCollectionExtensions>
    </RuleCollection>

    <RuleCollection Type="ManagedInstaller" EnforcementMode="AuditOnly">
        <FilePublisherRule Id="3cf97403-1b4a-4492-8e70-98436cf78983" Name="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE version 1.37.200.8 exactly in MICROSOFT INTUNE from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="1" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE">
                    <BinaryVersionRange LowSection="1.37.200.8" HighSection="*" />
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>
    </RuleCollection>

    <RuleCollection Type="Msi" EnforcementMode="NotConfigured" />

    <RuleCollection Type="Script" EnforcementMode="NotConfigured" />
</AppLockerPolicy>
"@


function MergeAppLockerPolicy([string]$policyXml)
{
    $policyFile = '.\AppLockerPolicy.xml'
    $policyXml | Out-File $policyFile

    Write-Host "Merging and setting AppLocker policy"

    Set-AppLockerPolicy -XmlPolicy $policyFile -Merge -ErrorAction SilentlyContinue

    Remove-Item $policyFile
}

#Start AppID Driver service
start-service "AppID"

#Start Application Identity service
start-service "AppIDSvc"

# Start Smartlocker and set it to auto start
$sevName = "applockerfltr"
start-service $sevName 
set-service -name $sevName -StartupType Automatic

# Restart the Sidecar service
Restart-Service "IntuneManagementExtension" -Force

# Check service state, wait up to 5 minute
[System.Int32]$waitedSeconds = 0
while($waitedSeconds -lt $maxWaitSeconds)
{
    Start-Sleep -Seconds $waitBatchSeconds
    $waitedSeconds += $waitBatchSeconds

    if(-not ((Get-Service AppIDSvc).Status -eq 'Running'))
    {
        Write-Host 'AppID Service is not fully started yet.'
        continue
    }

    if(-not ((Get-Service AppID).Status -eq 'Running'))
    {
        Write-Host 'AppId Driver Service is not fully started yet.'
        continue
    }

    if(-not ((Get-Service applockerfltr).Status -eq 'Running'))
    {
        Write-Host 'AppLocker Filter Driver Service is not fully started yet.'
        continue
    }

    if(-not ((Get-Service IntuneManagementExtension).Status -eq 'Running'))
    {
        Write-Host 'Sidecar service is not fully started yet.'
        continue
    }

    break
}

if (-not ($waitedSeconds -lt $maxWaitSeconds))
{
    Write-Error 'Time-out on waiting for services to start.'
    exit 1
}

# Set the policy
try
{
    MergeAppLockerPolicy($SidecarMiPolicy)
}
catch
{
    $e = $_.Exception
    Write-Error('Failed to merge AppLocker policy. ' + $e.Message.ToString())
    if(-not($e.Message.Contains("already exists")))
    {
        exit 1
    }
}

# Set ManagedInstallerEnabled to 1
Set-ItemProperty -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies" -Name "ManagedInstallerEnabled" -Value 1

Write-Host ('Sidecar is set as the managed Installer.')

exit 0
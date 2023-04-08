#Variables
[System.Int32]$policyBinaryTimeoutSeconds = 300
[System.Int32]$waitBatchSeconds = 5
[System.Int32]$maxWaitSeconds = 300
[System.Int32]$waitedSeconds = 0

[string]$miPolicyBinaryPathRoot = "$env:windir\System32"

if(-not ([Environment]::Is64BitProcess))
{
    $miPolicyBinaryPathRoot = "$env:windir\Sysnative"
}

[string]$miPolicyBinaryPath = Join-Path -Path $miPolicyBinaryPathRoot -ChildPath "AppLocker\ManagedInstaller.AppLocker"

[string]$miPolicy = 
@"
<AppLockerPolicy Version="1">
	<RuleCollection Type="ManagedInstaller" EnforcementMode="NotConfigured">
		<FilePublisherRule Id="ef33930e-c6b2-484b-8ef1-a9b00bb52501" Name="OMADMCLIENT.EXE version 10.0.22000.469 exactly in MICROSOFT WINDOWS OPERATING SYSTEM from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
			<Conditions>
				<FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="OMADMCLIENT.EXE">
					<BinaryVersionRange LowSection="*" HighSection="*" />
				</FilePublisherCondition>
			</Conditions>
		</FilePublisherRule>
		<FilePublisherRule Id="ac59cf7b-cab2-4267-9555-fda31a1b7a9b" Name="GOOGLEUPDATE.EXE version 1.3.36.111 exactly in GOOGLE UPDATE from O=GOOGLE LLC, L=MOUNTAIN VIEW, S=CALIFORNIA, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
			<Conditions>
				<FilePublisherCondition PublisherName="O=GOOGLE LLC, L=MOUNTAIN VIEW, S=CALIFORNIA, C=US" ProductName="GOOGLE UPDATE" BinaryName="GOOGLEUPDATE.EXE">
					<BinaryVersionRange LowSection="*" HighSection="*" />
				</FilePublisherCondition>
			</Conditions>
		</FilePublisherRule>
		<FilePublisherRule Id="2807E34F-4165-4470-BB1B-74AE1B46C088" Name="Pearson Test Nav version 1.11.0.0 exactly in TESTNAV from O=PEARSON PLC, L=LONDON, S=LONDON, C=GB" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
			<Conditions>
				<FilePublisherCondition PublisherName="O=PEARSON PLC, L=LONDON, S=LONDON, C=GB" ProductName="TESTNAV" BinaryName="TESTNAV.EXE">
					<BinaryVersionRange LowSection="*" HighSection="*" />
				</FilePublisherCondition>
			</Conditions>
		</FilePublisherRule>
		<FilePublisherRule Id="647cb1c9-3661-4b53-af1e-9b658ae201f6" Name="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE version 1.53.202.0 exactly in MICROSOFT INTUNE from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
			<Conditions>
				<FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE">
					<BinaryVersionRange LowSection="*" HighSection="*" />
				</FilePublisherCondition>
			</Conditions>
		</FilePublisherRule>
	</RuleCollection>
	<RuleCollection Type="Dll" EnforcementMode="AuditOnly" >
    <FilePathRule Id="86f235ad-3f7b-4121-bc95-ea8bde3a5db5" Name="Benign DENY Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
      <Conditions>
        <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.dll" />
      </Conditions>
    </FilePathRule>
    <RuleCollectionExtensions>
      <ThresholdExtensions>
        <Services EnforcementMode="Enabled" />
      </ThresholdExtensions>
      <RedstoneExtensions>
        <SystemApps Allow="Enabled"/>
      </RedstoneExtensions>
    </RuleCollectionExtensions>
  </RuleCollection>
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePathRule Id="9420c496-046d-45ab-bd0e-455b2649e41e" Name="Benign DENY Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
      <Conditions>
        <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.exe" />
      </Conditions>
    </FilePathRule>
    <RuleCollectionExtensions>
      <ThresholdExtensions>
        <Services EnforcementMode="Enabled" />
      </ThresholdExtensions>
      <RedstoneExtensions>
        <SystemApps Allow="Enabled"/>
      </RedstoneExtensions>
    </RuleCollectionExtensions>
  </RuleCollection>
</AppLockerPolicy>
"@

#Create log file
$LogFileName = 'ApplyManagedInstaller.txt'
New-item -Path $env:TEMP -Name $LogFileName -ItemType "file" -Force | Out-Null
$LogFile = "$env:TEMP\" + $LogFilename
WriteLog 'Begin Logging'

function WriteLog($LogText){ 
  Add-Content -path $LogFile -value "$((Get-Date).ToString()) $LogText"
}
function MergeAppLockerPolicy([string]$policyXml)
{
    $policyFile = '.\AppLockerPolicy.xml'
    $policyXml | Out-File $policyFile

    WriteLog "Merging and setting AppLocker policy"

    Set-AppLockerPolicy -XmlPolicy $policyFile -Merge -ErrorAction SilentlyContinue

    Remove-Item $policyFile
}

# Start services
WriteLog 'Starting services'

# sc start gpsvc
appidtel.exe start -mionly

# Check service state, wait up to 1 minute
while($waitedSeconds -lt $maxWaitSeconds)
{
    Start-Sleep -Seconds $waitBatchSeconds
    $waitedSeconds += $waitBatchSeconds

    if(-not ((Get-Service AppIDSvc).Status -eq 'Running'))
    {
        WriteLog 'AppID Service is not fully started yet.'
        continue
    }

    if(-not ((Get-Service appid).Status -eq 'Running'))
    {
        WriteLog 'AppId Driver Service is not fully started yet.'
        continue
    }

    if(-not ((Get-Service applockerfltr).Status -eq 'Running'))
    {
        WriteLog 'AppLocker Filter Driver Service is not fully started yet.'
        continue
    }

    break
}

if (-not ($waitedSeconds -lt $maxWaitSeconds))
{
    WriteLog 'Time-out on waiting for services to start.'
    exit 1
}

# Set the policy
try
{
    MergeAppLockerPolicy($miPolicy)
}
catch
{
    WriteLog 'Failed to merge AppLocker policy. ' + $_.Exception.Message
    exit 1
}

# Wait for policy update
if(test-path $miPolicyBinaryPath)
{
	$previousPolicyBinaryTimeStamp = (Get-ChildItem $miPolicyBinaryPath).LastWriteTime
	WriteLog 'There is an existing ManagedInstaller policy binary (LastWriteTime: {0})' -f $previousPolicyBinaryTimeStamp.ToString('yyyy-MM-dd 
HH:mm')
}

if($previousPolicyBinaryTimeStamp)
{
	$action = 'updated'
	$condition = "$previousPolicyBinaryTimeStamp -lt (Get-ChildItem $miPolicyBinaryPath).LastWriteTime"
}
else
{
	$action = 'created'
	$condition = "test-path $miPolicyBinaryPath"
}

WriteLog "Waiting for policy binary to be $action"

$startTime = get-date

while(-not (Invoke-Expression $condition))
{
	Start-Sleep -Seconds $waitBatchSeconds

	if((new-timespan $startTime $(get-date)).TotalSeconds -ge $policyBinaryTimeoutSeconds)
	{ 
		WriteLog "Policy binary has not been $action within $policyBinaryTimeoutSeconds seconds"
	    exit 1
	}
}

WriteLog 'Policy binary was created after {0:mm} minutes {0:ss} seconds' -f (new-timespan $startTime $(get-date))
WriteLog 'AppLocker with Managed Installer for Intune successfully enabled'
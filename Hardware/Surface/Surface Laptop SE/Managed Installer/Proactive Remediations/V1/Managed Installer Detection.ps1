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

function VerifyNode($miNode, [string]$ruleId, [string]$PublisherName, [string]$BinaryName)
{
    Write-Debug ("Checking node $ruleId and $PublisherName")
    $ruleNode = $miNode.ChildNodes | Where-Object{($_.LocalName -eq 'FilePublisherRule') -and ($_.Id -eq $ruleId)}

    if(-not $ruleNode) 
    {
        return $false
    }

    $conditionNode = $ruleNode.ChildNodes | ForEach-Object { $_.ChildNodes } | Where-Object { ($_.LocalName -eq 'FilePublisherCondition') -and ($_.PublisherName -eq $PublisherName) -and ($_.BinaryName -eq $BinaryName) }

    if(-not $conditionNode)
    {
        return $false
    }

    return $true
}

function VerifyCompliance([xml]$policy)
{
    $miNode = $policy.AppLockerPolicy.ChildNodes | Where-Object{$_.Type -eq 'ManagedInstaller'}

    if(-not $miNode)
    {
        Write-Host('Policy does not contain a managed installer')
        return $false
    }

    [xml]$desiredPolicy = $SidecarMiPolicy
    $desiredMiNode = $desiredPolicy.AppLockerPolicy.ChildNodes | Where-Object{$_.Type -eq 'ManagedInstaller'}

    $desiredRules = $desiredMiNode.ChildNodes | Where-Object{ ($_.LocalName -eq 'FilePublisherRule') }
    $currentdRules = $miNode.ChildNodes | Where-Object{ ($_.LocalName -eq 'FilePublisherRule') }

    $versionNew = $desiredRules.Attributes["Description"].Value
    $versionCurrent = $currentdRules.Attributes["Description"].Value

    if($versionNew -ne $versionCurrent)
    {
        Write-Host('Upgrade from version ' + $versionCurrent + ' to ' + $versionNew)
        return $false
    }

    foreach($rule in $desiredRules)
    {
        $conditionNode = $rule.ChildNodes | ForEach-Object {$_.ChildNodes } | Where-Object { ($_.LocalName -eq 'FilePublisherCondition') }

        if(-not (VerifyNode -miNode $miNode -ruleId $rule.Id -PublisherName $conditionNode.PublisherName -BinaryName $conditionNode.BinaryName))
        {
            Write-Host('Policy does not contain file publisher rule with id: ' + $id)

            return $false
        }
    }

    return $true
}


# Execution flow starts here

# Load the current effective AppLocker policy
try
{
    [xml]$effectivePolicyXml = Get-AppLockerPolicy -Effective -Xml -ErrorVariable ev -ErrorAction SilentlyContinue
}
catch
{
    Write-Error('Get-AppLockerPolicy failed. ' + $_.Exception.Message)
    exit 1
}

# Check if it contains MI policy and if the MI policy has rules for sidecar
try
{
    $compliant = VerifyCompliance($effectivePolicyXml)
}
catch
{
    Write-Error('Failed to verify AppLocker policy compliance. ' + $_.Exception.Message)
    exit 1
}


if($compliant)
{
   # sidecar is set as the managed installer
   Write-Host("Sidecar is set as the managed installer.")

   # Check if the registry value is there and set it if it is not
   if(!(Get-ItemProperty -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies" -Name "ManagedInstallerEnabled" -ErrorAction Ignore))
   {
      Write-Host("ManagedInstallerEnabled in registry is missing")
      Set-ItemProperty -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies" -Name "ManagedInstallerEnabled" -Value 1
   }

   exit 0
}
else
{
   # sidecar is not set as the managed insatller
   Write-Host("Sidecar is not set as a managed installer.")

   # Check if the registry value is there and remove it if it is there
   if(Get-ItemProperty -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies" -Name "ManagedInstallerEnabled" -ErrorAction Ignore)
   {
      Write-Host("ManagedInstallerEnabled should not be present")
      Remove-ItemProperty -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies" -Name "ManagedInstallerEnabled"
   }

   exit 1
}
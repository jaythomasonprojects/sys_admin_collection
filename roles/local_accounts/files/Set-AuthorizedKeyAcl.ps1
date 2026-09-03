[CmdletBinding(DefaultParameterSetName = 'StandardUser')]
param (
    [Parameter(Mandatory, ParameterSetName = 'Administrator')]
    [Switch] $Administrator,

    [Parameter(Mandatory, ParameterSetName = 'StandardUser')]
    [String] $UserName
)

$Ansible.Changed = $false
$administratorSid = [System.Security.Principal.SecurityIdentifier]::new(
    'S-1-5-32-544')
$systemSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18')

if ($Administrator) {
    $ownerSid = $administratorSid
    $expectedSids = @($administratorSid, $systemSid)
    $paths = @('C:\ProgramData\ssh\administrators_authorized_keys')
}
else {
    $account = [System.Security.Principal.NTAccount]::new(
        $env:COMPUTERNAME, $UserName)
    $ownerSid = $account.Translate(
        [System.Security.Principal.SecurityIdentifier])
    $expectedSids = @($ownerSid, $administratorSid, $systemSid)
    $paths = @(
        "C:\Users\$UserName\.ssh",
        "C:\Users\$UserName\.ssh\authorized_keys"
    )
}

$fullControl = [System.Security.AccessControl.FileSystemRights]::FullControl
foreach ($path in $paths) {
    $acl = Get-Acl -LiteralPath $path
    $rules = @($acl.GetAccessRules(
        $true,
        $true,
        [System.Security.Principal.SecurityIdentifier]
    ))
    $actualOwner = $acl.GetOwner(
        [System.Security.Principal.SecurityIdentifier])
    $aclMatches = $acl.AreAccessRulesProtected -and
        $actualOwner.Value -eq $ownerSid.Value -and
        $rules.Count -eq $expectedSids.Count

    foreach ($sid in $expectedSids) {
        $matchingRules = @($rules | Where-Object {
            $_.IdentityReference.Value -eq $sid.Value -and
            -not $_.IsInherited -and
            $_.AccessControlType -eq 'Allow' -and
            [int] $_.FileSystemRights -eq [int] $fullControl -and
            $_.InheritanceFlags -eq 'None' -and
            $_.PropagationFlags -eq 'None'
        })
        $aclMatches = $aclMatches -and ($matchingRules.Count -eq 1)
    }

    if (-not $aclMatches) {
        $acl.SetOwner($ownerSid)
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($rule in @($acl.Access)) {
            [void] $acl.RemoveAccessRuleSpecific($rule)
        }
        foreach ($sid in $expectedSids) {
            $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
                $sid,
                'FullControl',
                'Allow'
            )
            [void] $acl.AddAccessRule($rule)
        }
        Set-Acl -LiteralPath $path -AclObject $acl
        $Ansible.Changed = $true
    }
}

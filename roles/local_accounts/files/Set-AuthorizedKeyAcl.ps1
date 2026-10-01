[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String] $AccountSid,

    [Parameter(Mandatory)]
    [String] $ProfilePath
)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$administratorSid = [System.Security.Principal.SecurityIdentifier]::new(
    'S-1-5-32-544')
$systemSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18')

$ownerSid = [System.Security.Principal.SecurityIdentifier]::new($AccountSid)
$expectedSids = @($ownerSid, $administratorSid, $systemSid)
$paths = @(
    (Join-Path $ProfilePath '.ssh'),
    (Join-Path $ProfilePath '.ssh\authorized_keys')
)

$fullControl = [System.Security.AccessControl.FileSystemRights]::FullControl
function Test-AuthorisedKeyAcl {
    param (
        [Parameter(Mandatory)] $Acl
    )

    $rules = @($Acl.GetAccessRules(
        $true,
        $true,
        [System.Security.Principal.SecurityIdentifier]
    ))
    $actualOwner = $Acl.GetOwner(
        [System.Security.Principal.SecurityIdentifier])
    $aclMatches = $Acl.AreAccessRulesProtected -and
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

    return $aclMatches
}

foreach ($path in $paths) {
    $acl = Get-Acl -LiteralPath $path -ErrorAction Stop
    if (-not (Test-AuthorisedKeyAcl -Acl $acl)) {
        $acl.SetOwner($ownerSid)
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($rule in @($acl.Access)) {
            [void] $acl.RemoveAccessRuleSpecific($rule)
        }
        foreach ($sid in $expectedSids) {
            $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
                $sid.Translate([System.Security.Principal.NTAccount]),
                'FullControl',
                'Allow'
            )
            [void] $acl.AddAccessRule($rule)
        }
        Set-Acl -LiteralPath $path -AclObject $acl -ErrorAction Stop
        $verified = Get-Acl -LiteralPath $path -ErrorAction Stop
        if (-not (Test-AuthorisedKeyAcl -Acl $verified)) {
            throw "Authorised-key ACL verification failed for $path"
        }
        $Ansible.Changed = $true
    }
}

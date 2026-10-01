[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String] $ExpectedJson
)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$profileRoot = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
foreach ($account in (ConvertFrom-Json $ExpectedJson)) {
    $sid = (Get-LocalUser -Name $account.name -ErrorAction Stop).SID.Value
    $profile = (Get-ItemProperty -LiteralPath (Join-Path $profileRoot $sid)).ProfileImagePath
    if ($account.name -eq 'sa_key_standard' -and
        (Split-Path $profile -Leaf) -ne 'sa_key_alternate') {
        throw 'Existing native profile was not retained'
    }
    $keyFile = Join-Path $profile '.ssh\authorized_keys'
    $keys = $account.keys
    if ($null -eq $keys) {
        $keys = $account.ssh_authorized_keys
    }
    $expected = @($keys) -join "`n"
    if ([IO.File]::ReadAllText($keyFile).Trim() -ne $expected.Trim()) {
        throw "Key contents differ for $($account.name)"
    }
    foreach ($path in @((Join-Path $profile '.ssh'), $keyFile)) {
        $acl = Get-Acl -LiteralPath $path -ErrorAction Stop
        $owner = $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
        $rules = @($acl.GetAccessRules($true, $true,
            [Security.Principal.SecurityIdentifier]))
        $expectedSids = @($sid, 'S-1-5-32-544', 'S-1-5-18')
        if (-not $acl.AreAccessRulesProtected -or $owner -ne $sid -or
            $rules.Count -ne $expectedSids.Count) {
            throw "Key ACL ownership or protection differs for $path"
        }
        foreach ($expectedSid in $expectedSids) {
            $matching = @($rules | Where-Object {
                $_.IdentityReference.Value -eq $expectedSid -and
                -not $_.IsInherited -and
                $_.AccessControlType -eq 'Allow' -and
                $_.FileSystemRights -eq 'FullControl' -and
                $_.InheritanceFlags -eq 'None' -and
                $_.PropagationFlags -eq 'None'
            })
            if ($matching.Count -ne 1) {
                throw "Key ACL rights differ for $path"
            }
        }
    }
}
if (Test-Path -LiteralPath 'C:\Users\sa_key_standard\.ssh') {
    throw 'A guessed account-name profile was used'
}

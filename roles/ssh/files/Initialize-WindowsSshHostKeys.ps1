$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$directory = 'C:\ProgramData\ssh'
$before = @(Get-ChildItem -LiteralPath $directory |
    Where-Object { $_.Name -like 'ssh_host_*_key' } |
    ForEach-Object { $_.FullName })
$keygen = 'C:\Windows\System32\OpenSSH\ssh-keygen.exe'
& $keygen -A
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to establish Windows SSH host keys'
}

$systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
$administratorSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
foreach ($key in @(Get-ChildItem -LiteralPath $directory |
        Where-Object { $_.Name -like 'ssh_host_*_key' })) {
    if ($key.FullName -in $before) {
        continue
    }

    # Windows sshd refuses private host keys inherited by the WinRM caller.
    $acl = Get-Acl -LiteralPath $key.FullName -ErrorAction Stop
    $acl.SetOwner($systemSid)
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) {
        [void] $acl.RemoveAccessRuleSpecific($rule)
    }
    foreach ($sid in @($systemSid, $administratorSid)) {
        $account = $sid.Translate([Security.Principal.NTAccount])
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            $account, 'FullControl', 'Allow')
        [void] $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $key.FullName -AclObject $acl -ErrorAction Stop
    $Ansible.Changed = $true
}

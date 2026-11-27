$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$path = 'Software\Microsoft\WindowsUpdate\UX\Settings'
$taskName = 'JayThomasonProjects-SysAdmin-PauseUpdates'
# The provider ACL lookup can miss this existing key; select its native view.
$base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
    'LocalMachine', 'Registry64')
$rights = [System.Security.AccessControl.RegistryRights]'ReadKey,ChangePermissions'
$key = $base.OpenSubKey($path, 'ReadWriteSubTree', $rights)
if ($null -eq $key) { throw 'The effective Windows Update settings key is missing.' }
$sections = [System.Security.AccessControl.AccessControlSections]::Access
$originalSddl = $key.GetAccessControl().GetSecurityDescriptorSddlForm($sections)
try {
    $restricted = $key.GetAccessControl()
    $sid = [System.Security.Principal.SecurityIdentifier]'S-1-5-19'
    $deny = [System.Security.AccessControl.RegistryAccessRule]::new(
        $sid, 'SetValue', 'Deny')
    $restricted.AddAccessRule($deny)
    $key.SetAccessControl($restricted)
    $before = (Get-ScheduledTaskInfo -TaskName $taskName).LastRunTime
    Start-ScheduledTask -TaskName $taskName
    $deadline = [datetime]::UtcNow.AddSeconds(45)
    do {
        Start-Sleep -Milliseconds 250
        $info = Get-ScheduledTaskInfo -TaskName $taskName
        $state = (Get-ScheduledTask -TaskName $taskName).State
    } while (($info.LastRunTime -le $before -or $state -eq 'Running') -and
        [datetime]::UtcNow -lt $deadline)
    if ($info.LastRunTime -le $before -or $state -eq 'Running' -or
        $info.LastTaskResult -eq 0) {
        throw 'A denied renewal did not terminate with a failing task result.'
    }
    $Ansible.Result = @{ denied_write_result = $info.LastTaskResult }
} finally {
    # SetAccessControl persists modified sections, not an unmodified snapshot.
    $restored = [System.Security.AccessControl.RegistrySecurity]::new()
    $restored.SetSecurityDescriptorSddlForm($originalSddl, $sections)
    $key.SetAccessControl($restored)
    $key.Dispose()
    $base.Dispose()
}

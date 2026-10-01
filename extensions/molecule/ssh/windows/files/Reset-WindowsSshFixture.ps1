$ErrorActionPreference = 'Stop'
$directory = 'C:\ProgramData\ssh'
if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    throw 'Prepared template is missing its native Windows SSH directory'
}

# Preserve the native directory ACL from the template, as the original fresh
# baseline did. Removing the directory also removes that security context.
$before = (Get-Acl -LiteralPath $directory).Sddl
$children = @(Get-ChildItem -LiteralPath $directory -Force)
$Ansible.Changed = $children.Count -gt 0
foreach ($child in $children) {
    Remove-Item -LiteralPath $child.FullName -Force -Recurse
}
if ((Get-Acl -LiteralPath $directory).Sddl -ne $before) {
    throw 'Resetting Windows SSH files changed the native directory ACL'
}
if (@(Get-ChildItem -LiteralPath $directory -Force).Count -ne 0) {
    throw 'Windows SSH fixture files were not completely removed'
}

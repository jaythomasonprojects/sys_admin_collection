[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String] $UserName
)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$account = Get-LocalUser -Name $UserName -ErrorAction Stop
$Ansible.Result = @{
    Name = $account.Name
    Sid = $account.SID.Value
}

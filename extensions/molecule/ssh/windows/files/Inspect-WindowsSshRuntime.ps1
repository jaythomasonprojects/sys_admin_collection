[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [Int] $Port,

    [Parameter(Mandatory)]
    [String] $PasswordAuthentication,

    [Parameter(Mandatory)]
    [String[]] $AllowedUsers
)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$capability = @(Get-WindowsCapability -Online |
    Where-Object { $_.Name -like 'OpenSSH.Server*' })
if ($capability.Count -ne 1 -or
    $capability[0].State.ToString() -ne 'Installed') {
    throw 'OpenSSH Server capability is not installed'
}
$service = Get-Service -Name sshd
if ($service.Status.ToString() -ne 'Running' -or
    $service.StartType.ToString() -ne 'Automatic') {
    throw 'OpenSSH service is not running and automatic'
}
$config = Get-Content 'C:\ProgramData\ssh\sshd_config' -Raw
$lines = @($config -split '\r?\n')
foreach ($line in @("Port $Port", "PasswordAuthentication $PasswordAuthentication",
    "AllowUsers $($AllowedUsers -join ' ')")) {
    if ($line -notin $lines) {
        throw "Missing requested SSH policy: $line"
    }
}
$rule = Get-NetFirewallRule -DisplayName 'OpenSSH Server (sshd)'
$filter = $rule | Get-NetFirewallPortFilter
if ($rule.Enabled.ToString() -ne 'True' -or
    $rule.Direction.ToString() -ne 'Inbound' -or
    $rule.Action.ToString() -ne 'Allow' -or
    $filter.LocalPort.ToString() -ne $Port.ToString() -or
    $filter.Protocol.ToString() -ne 'TCP') {
    throw 'SSH firewall rule does not allow the requested TCP port'
}
if (@(Get-NetTCPConnection -LocalPort $Port -State Listen).Count -lt 1) {
    throw 'SSH service is not listening on the requested port'
}
$shell = (Get-ItemProperty 'HKLM:\SOFTWARE\OpenSSH').DefaultShell
$expectedShell = Join-Path 'C:\Windows\System32' `
    'WindowsPowerShell\v1.0\powershell.exe'
if ($shell -ne $expectedShell) {
    throw 'Default SSH shell does not match the requested policy'
}
'Windows SSH runtime policy verified'

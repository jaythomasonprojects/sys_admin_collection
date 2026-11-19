$ErrorActionPreference = 'Stop'
$configuration = & "$env:WINDIR\System32\OpenSSH\sshd.exe" -T -e `
    -f 'C:\ProgramData\ssh\sshd_config'
if ($LASTEXITCODE -ne 0) {
    throw 'Native SSH validation failed before activation'
}
$ports = @($configuration | Where-Object { $_ -match '^port \d+$' } |
    ForEach-Object { ($_ -split ' ', 2)[1] })
if ($ports.Count -ne 1) {
    throw 'Expected one validated SSH listener port'
}

# Narrowing before restart would cut off the SSH request that activates policy.
Restart-Service -Name sshd -Force
Get-NetFirewallRule -DisplayName 'OpenSSH Server (sshd)' |
    Get-NetFirewallPortFilter |
    Set-NetFirewallPortFilter -LocalPort $ports[0]

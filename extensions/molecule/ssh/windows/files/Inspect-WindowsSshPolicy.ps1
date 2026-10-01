[CmdletBinding()]
param (
    [Int] $ExpectedPort = 0
)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$path = 'C:\ProgramData\ssh\sshd_config'
$service = Get-CimInstance Win32_Service -Filter "Name='sshd'"
$Ansible.Result = @{
    Hash = (Get-FileHash -LiteralPath $path).Hash
    Keys = @(
        Get-ChildItem C:\ProgramData\ssh -Filter 'ssh_host_*_key' |
            ForEach-Object { (Get-FileHash $_.FullName).Hash }
    )
    Pid = $service.ProcessId
}
if ($ExpectedPort -ne 0) {
    $policy = @(& 'C:\Windows\System32\OpenSSH\sshd.exe' -T -f $path)
    if ($LASTEXITCODE -ne 0) {
        throw 'Transitioned SSH policy is not valid'
    }
    $Ansible.Result.Port = @(
        $policy | Where-Object { $_ -eq "port $ExpectedPort" }
    ).Count
}

[CmdletBinding()]
param ([Parameter(Mandatory)] [UInt32] $Expected)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PowerPolicyProbe {
    [DllImport("powrprof.dll")]
    public static extern uint PowerReadACValueIndex(IntPtr root,
        ref Guid scheme, ref Guid subgroup, ref Guid setting, out uint value);
    [DllImport("powrprof.dll")]
    public static extern uint PowerReadDCValueIndex(IntPtr root,
        ref Guid scheme, ref Guid subgroup, ref Guid setting, out uint value);
}
'@
$scheme = [Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
$power = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'
$active = (Get-ItemProperty "$power\User\PowerSchemes").ActivePowerScheme
if ([Guid]$active -ne $scheme) { throw 'Expected balanced power plan' }
$settings = @(
    @('7516b95f-f776-4464-8c53-06167f40cc99',
      '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e'),
    @('238c9fa8-0aad-41ed-83f4-97be242c8f20',
      '29f6c1db-86da-48c5-9fdb-f2b67b1f44da')
)
$values = @()
foreach ($setting in $settings) {
    $subgroup = [Guid]$setting[0]
    $index = [Guid]$setting[1]
    [UInt32]$ac = 0
    [UInt32]$dc = 0
    $acStatus = [PowerPolicyProbe]::PowerReadACValueIndex(
        [IntPtr]::Zero, [ref]$scheme, [ref]$subgroup, [ref]$index, [ref]$ac)
    $dcStatus = [PowerPolicyProbe]::PowerReadDCValueIndex(
        [IntPtr]::Zero, [ref]$scheme, [ref]$subgroup, [ref]$index, [ref]$dc)
    if ($acStatus -ne 0 -or $dcStatus -ne 0) {
        throw 'Native power timeout query failed'
    }
    if ($ac -ne $Expected -or $dc -ne $Expected) {
        throw "Unexpected AC/DC timeout: $ac/$dc, expected $Expected"
    }
    $values += @($ac, $dc)
}
$Ansible.Result = @{
    Timeouts = $values
    HibernateEnabled = (Get-ItemProperty $power).HibernateEnabled
}

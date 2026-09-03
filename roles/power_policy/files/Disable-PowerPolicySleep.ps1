[CmdletBinding()]
param ()

$Ansible.Changed = $false
$settings = @(
    @{
        Change = 'monitor-timeout-ac'
        PowerSource = 'AC'
        Setting = 'VIDEOIDLE'
        Subgroup = 'SUB_VIDEO'
    },
    @{
        Change = 'standby-timeout-ac'
        PowerSource = 'AC'
        Setting = 'STANDBYIDLE'
        Subgroup = 'SUB_SLEEP'
    },
    @{
        Change = 'monitor-timeout-dc'
        PowerSource = 'DC'
        Setting = 'VIDEOIDLE'
        Subgroup = 'SUB_VIDEO'
    },
    @{
        Change = 'standby-timeout-dc'
        PowerSource = 'DC'
        Setting = 'STANDBYIDLE'
        Subgroup = 'SUB_SLEEP'
    }
)

foreach ($setting in $settings) {
    $pattern = 'Current ' + $setting.PowerSource +
        ' Power Setting Index: 0x([0-9a-f]+)'
    $query = powercfg /query SCHEME_CURRENT $setting.Subgroup $setting.Setting
    if ($LASTEXITCODE -ne 0) {
        throw "Could not query $($setting.PowerSource) timeout for " +
            "$($setting.Subgroup)/$($setting.Setting)."
    }
    $matches = @($query | Select-String $pattern)
    if ($matches.Count -ne 1) {
        throw "Could not read $($setting.PowerSource) timeout for " +
            "$($setting.Subgroup)/$($setting.Setting)."
    }
    $value = [Convert]::ToInt32(
        $matches[0].Matches[0].Groups[1].Value, 16)
    if ($value -ne 0) {
        powercfg /change $setting.Change 0
        if ($LASTEXITCODE -ne 0) {
            throw "Could not set $($setting.Change) to never."
        }
        $Ansible.Changed = $true
    }
}

param([string[]]$UpdateIds)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$key = Get-Item 'HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings'
$pause = @{}
foreach ($name in @(
    'PauseFeatureUpdatesStartTime', 'PauseQualityUpdatesStartTime',
    'PauseUpdatesStartTime', 'PauseFeatureUpdatesEndTime',
    'PauseQualityUpdatesEndTime', 'PauseUpdatesExpiryTime'
)) {
    $pause[$name] = $key.GetValue($name, $null)
    if ($null -eq $pause[$name]) { throw "Missing effective pause value: $name" }
}
$searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
$count = $searcher.GetTotalHistoryCount()
$history = @()
if ($count -gt 0) {
    $history = @($searcher.QueryHistory(0, [Math]::Min($count, 500)) |
        Where-Object {
            $_.Operation -eq 1 -and $_.ResultCode -eq 2 -and
            $_.UpdateIdentity.UpdateID -in $UpdateIds
        } |
        ForEach-Object {
            '{0}/{1}/{2}' -f $_.UpdateIdentity.UpdateID,
                $_.UpdateIdentity.RevisionNumber, $_.Date.Ticks
        })
}
$Ansible.Result = @{ pause = $pause; history = $history }

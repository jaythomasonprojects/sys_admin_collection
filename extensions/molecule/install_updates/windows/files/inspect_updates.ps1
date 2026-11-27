$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$baseline = Get-Content 'C:\ProgramData\install-updates-baseline.json' -Raw |
    ConvertFrom-Json
$ids = @($baseline.PSObject.Properties.Name)
$session = New-Object -ComObject Microsoft.Update.Session
$searcher = $session.CreateUpdateSearcher()
$count = $searcher.GetTotalHistoryCount()
$history = @()
if ($count -gt 0) {
    $history = @($searcher.QueryHistory(0, [Math]::Min($count, 500)) |
        Where-Object {
            $_.Operation -eq 1 -and $_.ResultCode -eq 2 -and
            $_.UpdateIdentity.UpdateID -in $ids
        } |
        ForEach-Object {
            @{
                id = $_.UpdateIdentity.UpdateID
                title = $_.Title
                date = $_.Date.ToString('o')
                signature = '{0}/{1}/{2}' -f $_.UpdateIdentity.UpdateID,
                    $_.UpdateIdentity.RevisionNumber, $_.Date.Ticks
            }
        })
}
$systemInfo = New-Object -ComObject Microsoft.Update.SystemInfo
$Ansible.Result = @{
    baseline_ids = $ids
    boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString('o')
    evidence_exists = Test-Path 'C:\ProgramData\install-updates-no-reboot.json'
    pending_reboot = $systemInfo.RebootRequired
    history = $history
    installed_baseline_ids = @($history | Where-Object { $_.id -in $ids } |
        ForEach-Object { $_.id })
}

param(
    [bool]$UpdatesEnabled,
    [bool]$AutoReboot,
    [bool]$NativeHours = $false,
    [bool]$RunTasks = $false
)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$settings = 'HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings'
$au = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
$pauseNames = @(
    'PauseFeatureUpdatesStartTime', 'PauseQualityUpdatesStartTime',
    'PauseUpdatesStartTime', 'PauseFeatureUpdatesEndTime',
    'PauseQualityUpdatesEndTime', 'PauseUpdatesExpiryTime'
)
$hoursNames = @('ActiveHoursStart', 'ActiveHoursEnd', 'SmartActiveHoursState')
$tasks = @(
    @{
        Name = 'JayThomasonProjects-SysAdmin-PauseUpdates'
        Active = -not $UpdatesEnabled
        Interval = 'P1D'
        Triggers = 2
    },
    @{
        Name = 'JayThomasonProjects-SysAdmin-MoveActiveHours'
        Active = -not $AutoReboot
        Interval = 'PT4H'
        Triggers = 2
    }
)
foreach ($expected in $tasks) {
    $task = Get-ScheduledTask | Where-Object TaskName -eq $expected.Name
    if (-not $expected.Active) {
        if ($task) { throw "Removed task remains: $($expected.Name)" }
        continue
    }
    if (-not $task) { throw "Renewal task is missing: $($expected.Name)" }
    $user = $task.Principal.UserId
    if ($user -notmatch '^S-1-') {
        $user = ([System.Security.Principal.NTAccount]$user).Translate(
            [System.Security.Principal.SecurityIdentifier]).Value
    }
    if ($user -ne 'S-1-5-19' -or -not $task.Settings.Enabled) {
        throw 'Renewal must run as enabled Local Service.'
    }
    [xml]$xml = Export-ScheduledTask -TaskName $expected.Name
    $triggers = @($xml.Task.Triggers.ChildNodes)
    if ($triggers.Count -ne $expected.Triggers -or
        $triggers[0].LocalName -ne 'BootTrigger') {
        throw 'Renewal trigger types differ from the contract.'
    }
    foreach ($trigger in $triggers) {
        if ($trigger.Repetition.Interval -ne $expected.Interval) {
            throw 'Renewal interval differs from the contract.'
        }
    }
    if ($expected.Triggers -eq 2 -and
        $triggers[1].LocalName -ne 'RegistrationTrigger') {
        throw 'Renewal on an already-running host requires a registration trigger.'
    }
    if ($RunTasks) {
        $before = (Get-ScheduledTaskInfo -TaskName $expected.Name).LastRunTime
        Start-ScheduledTask -TaskName $expected.Name
        $deadline = [datetime]::UtcNow.AddSeconds(45)
        do {
            Start-Sleep -Milliseconds 250
            $info = Get-ScheduledTaskInfo -TaskName $expected.Name
            $state = (Get-ScheduledTask -TaskName $expected.Name).State
        } while (($info.LastRunTime -le $before -or $state -eq 'Running') -and
            [datetime]::UtcNow -lt $deadline)
        if ($info.LastRunTime -le $before -or $state -eq 'Running' -or
            $info.LastTaskResult -ne 0) {
            throw "Local Service renewal did not complete: $($expected.Name)"
        }
    }
}
$key = Get-Item -LiteralPath $settings
if ($UpdatesEnabled) {
    foreach ($name in $pauseNames) {
        if ($null -ne $key.GetValue($name, $null)) {
            throw "Residual pause value remains: $name"
        }
    }
} else {
    $values = @($pauseNames | ForEach-Object {
        [datetime]::Parse($key.GetValue($_),
            [cultureinfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
    })
    for ($i = 0; $i -lt 3; $i++) {
        if ($values[$i] -gt [datetime]::UtcNow -or
            $values[$i + 3] -le [datetime]::UtcNow -or
            ($values[$i + 3] - $values[$i]).TotalDays -ne 7) {
            throw 'The six pause timestamps do not form an effective seven-day pause.'
        }
    }
}
if ($AutoReboot) {
    if ($NativeHours) {
        if ($key.GetValue('ActiveHoursStart') -ne 8 -or
            $key.GetValue('ActiveHoursEnd') -ne 17 -or
            $key.GetValue('SmartActiveHoursState') -ne 1) {
            throw 'Unchanged allowed-reboot policy removed normal Windows preferences.'
        }
    } else {
        foreach ($name in $hoursNames) {
            if ($null -ne $key.GetValue($name, $null)) {
                throw "Residual active-hours value remains: $name"
            }
        }
    }
    if (Test-Path $au) {
        $policy = Get-Item $au
        foreach ($name in @('AUOptions', 'NoAutoRebootWithLoggedOnUsers')) {
            if ($null -ne $policy.GetValue($name, $null)) {
                throw "Residual AU suppression value remains: $name"
            }
        }
    }
} else {
    $start = $key.GetValue('ActiveHoursStart')
    $end = $key.GetValue('ActiveHoursEnd')
    if ($null -eq $start -or $null -eq $end -or
        (($end - $start + 24) % 24) -ne 12 -or
        (([datetime]::Now.Hour - $start + 24) % 24) -gt 5 -or
        $key.GetValue('SmartActiveHoursState') -ne 0) {
        throw 'Moving local active hours are not effective.'
    }
    if ($RunTasks -and
        ($start -ne (([datetime]::Now.Hour + 23) % 24) -or
         $end -ne (([datetime]::Now.Hour + 11) % 24))) {
        throw 'Renewal did not use the generator local-hour calculations.'
    }
    $policy = Get-Item $au
    if ($policy.GetValue('AUOptions') -ne 4 -or
        $policy.GetValue('NoAutoRebootWithLoggedOnUsers') -ne 1) {
        throw 'The accompanying AU reboot policy is missing.'
    }
}
$policy = Get-Item $au
if ($policy.GetValue('NoAutoUpdate') -ne 1) {
    throw 'The foreign fixture policy was not preserved.'
}
$Ansible.Result = @{
    updates_enabled = $UpdatesEnabled
    auto_reboot = $AutoReboot
    native_tasks_exercised = $RunTasks
}

param([Parameter(Mandatory)][string]$TaskName)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$task = Get-ScheduledTask -TaskName $TaskName -TaskPath '\'
if ($task.State -eq 'Running') {
    $task | Stop-ScheduledTask
    $Ansible.Changed = $true
}
# Disable precedes stop, so no new boot/renewal writer can race value removal.
$deadline = [datetime]::UtcNow.AddSeconds(30)
while ((Get-ScheduledTask -TaskName $TaskName -TaskPath '\').State -eq 'Running') {
    if ([datetime]::UtcNow -ge $deadline) {
        throw "The owned task writer did not stop: $TaskName"
    }
    Start-Sleep -Milliseconds 100
}

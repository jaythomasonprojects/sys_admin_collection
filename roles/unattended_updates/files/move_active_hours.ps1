# Adapted from cschneegans/unattend-generator resource/MoveActiveHours.xml,
# commit c112aa81e5d35fe06b5c57f7fa09aeb112a9d456.
# Copyright (c) 2024-2025 Christoph Schneegans
# SPDX-License-Identifier: MIT
# Licence: LICENSE.unattend-generator.txt, distributed alongside this action.
param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
$path = 'Registry::HKLM\Software\Microsoft\WindowsUpdate\UX\Settings'
$hour = [datetime]::Now.Hour
if ($CheckOnly) {
    $valid = Test-Path -LiteralPath $path
    if ($valid) {
        $key = Get-Item -LiteralPath $path
        $start = $key.GetValue('ActiveHoursStart', $null)
        $end = $key.GetValue('ActiveHoursEnd', $null)
        $smart = $key.GetValue('SmartActiveHoursState', $null)
        $valid = $null -ne $start -and $null -ne $end -and
            $null -ne $smart -and $smart -eq 0 -and
            $start -ge 0 -and $start -le 23 -and
            $end -ge 0 -and $end -le 23 -and
            (($end - $start + 24) % 24) -eq 12 -and
            (($hour - $start + 24) % 24) -le 5
    }
    Write-Output ([bool]$valid)
    return
}
$parameters = @{ LiteralPath = $path; Type = 'DWord'; Force = $true }
Set-ItemProperty @parameters -Name 'ActiveHoursStart' -Value (($hour + 23) % 24)
Set-ItemProperty @parameters -Name 'ActiveHoursEnd' -Value (($hour + 11) % 24)
Set-ItemProperty @parameters -Name 'SmartActiveHoursState' -Value 0

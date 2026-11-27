# Adapted from cschneegans/unattend-generator resource/PauseWindowsUpdate.xml,
# commit c112aa81e5d35fe06b5c57f7fa09aeb112a9d456.
# Copyright (c) 2024-2025 Christoph Schneegans
# SPDX-License-Identifier: MIT
# Licence: LICENSE.unattend-generator.txt, distributed alongside this action.
param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
$path = 'Registry::HKLM\Software\Microsoft\WindowsUpdate\UX\Settings'
$startNames = @(
    'PauseFeatureUpdatesStartTime', 'PauseQualityUpdatesStartTime',
    'PauseUpdatesStartTime'
)
$endNames = @(
    'PauseFeatureUpdatesEndTime', 'PauseQualityUpdatesEndTime',
    'PauseUpdatesExpiryTime'
)
$now = [datetime]::UtcNow
$culture = [cultureinfo]::InvariantCulture
if ($CheckOnly) {
    $valid = Test-Path -LiteralPath $path
    if ($valid) {
        $key = Get-Item -LiteralPath $path
        for ($i = 0; $i -lt $startNames.Count; $i++) {
            $start = [datetime]::MinValue
            $end = [datetime]::MinValue
            $style = [System.Globalization.DateTimeStyles]::RoundtripKind
            $parsedStart = [datetime]::TryParse(
                $key.GetValue($startNames[$i]), $culture, $style, [ref]$start)
            $parsedEnd = [datetime]::TryParse(
                $key.GetValue($endNames[$i]), $culture, $style, [ref]$end)
            if (-not $parsedStart -or -not $parsedEnd -or
                $start.ToUniversalTime() -gt $now -or
                $end.ToUniversalTime() -le $now -or
                ($end - $start).TotalDays -ne 7) {
                $valid = $false
            }
        }
    }
    Write-Output ([bool]$valid)
    return
}
$format = 'yyyy-MM-ddTHH\:mm\:ssK'
$parameters = @{ LiteralPath = $path; Type = 'String'; Force = $true }
foreach ($name in $startNames) {
    Set-ItemProperty @parameters -Name $name -Value $now.ToString($format, $culture)
}
foreach ($name in $endNames) {
    Set-ItemProperty @parameters -Name $name `
        -Value $now.AddDays(7).ToString($format, $culture)
}

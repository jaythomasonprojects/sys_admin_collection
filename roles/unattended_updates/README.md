# unattended_updates

Manages persistent update policy on Ubuntu 24.04/26.04 and Windows. Applying
policy does not itself install updates or reboot the host. Use `install_updates`
for explicit maintenance.

## Inputs

- `unattended_updates_apt_auto_reboot`: allow required unattended Ubuntu
  reboots, default `false`.
- `unattended_updates_apt_auto_reboot_time`: Ubuntu reboot time, default `'02:00'`.
- `unattended_updates_apt_origins`: allowed APT origin patterns, default `[]`
  selects Ubuntu release and security origins.
- `unattended_updates_apt_package_blacklist`: excluded Ubuntu packages, default `[]`.
- `unattended_updates_enabled`: desired automatic-update policy, default `true`.
  False disables the owned APT schedule or establishes a rolling Windows pause;
  it does not skip the role.
- `unattended_updates_win_auto_reboot`: permit Windows to determine automatic
  reboot timing, default `false`, independently of the update toggle.

Types and defaults are declared in `meta/argument_specs.yml`. APT inputs affect
Ubuntu only; the Windows reboot input affects Windows only.

## Ubuntu ownership

The role installs `unattended-upgrades`, owns
`/etc/apt/apt.conf.d/20auto-upgrades` and
`/etc/apt/apt.conf.d/52sys-admin-auto-updates`, and restores enabled/running,
unmasked APT timers when policy is enabled on systemd.

Disabled policy zeros its three periodic counters. It preserves installed tools,
shared timer state and foreign policy, and does not cancel an upgrade in progress.
Re-enabling restores the schedule and timers. The role clears package-provided
origin allow-lists before setting its patterns. Later foreign APT files can
override them. Native non-systemd scheduling remains package-owned.

## Windows ownership and reversal

Disabling updates immediately applies a seven-day UTC pause and registers a
Local Service task to renew it at boot, registration and daily. Registration
starts renewal on an already-running host. It owns only these values in
`HKLM\Software\Microsoft\WindowsUpdate\UX\Settings`:
`PauseFeatureUpdatesStartTime`, `PauseQualityUpdatesStartTime`,
`PauseUpdatesStartTime`, `PauseFeatureUpdatesEndTime`,
`PauseQualityUpdatesEndTime` and `PauseUpdatesExpiryTime`.

**Pause also hides affected updates from explicit Ansible installation.**
Successful zero-install maintenance while paused does not prove update currency.
The role does not automatically unpause around maintenance.

With automatic reboots disallowed, a separate Local Service task moves active
hours around local time at boot, registration and every four hours. It owns
`ActiveHoursStart`, `ActiveHoursEnd`, `SmartActiveHoursState` in the same UX key,
plus `AUOptions` and `NoAutoRebootWithLoggedOnUsers` in
`HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU`.

This is active-hours suppression, not a universal reboot prohibition. Windows
deadlines, external policy and missed renewals can defeat suppression. Explicitly
requested reboots and Windows Update services remain available.

Re-enabling updates removes the pause task and all six timestamps. Allowing
automatic reboots removes the independent moving-hours task and its owned values.
Task removal stops the writer before deleting registry values. Shared registry
keys and unrelated values remain intact; Windows regenerates normal active-hours
preferences rather than restoring an arbitrary historical snapshot. Unused owned
scripts are removed. Allowed-reboot repeats preserve normal preferences when no
owned task or AU suppression remains. Scheduled renewal can advance timestamps without making an
unchanged, effective Ansible policy report changes.

Actions are adapted from the MIT-licensed
[unattend generator](https://github.com/cschneegans/unattend-generator/tree/c112aa81e5d35fe06b5c57f7fa09aeb112a9d456).
The static files retain upstream attribution.

## Migration

Replace `auto_updates` imports with `unattended_updates` and rename Ubuntu policy
input prefixes directly. Both owned APT paths remain stable. There are no aliases.
Move immediate Windows installation to `install_updates`, migrating
`auto_updates_win_reboot` to `install_updates_reboot`, whose default is false.
Configure background Windows reboot permission independently.

Before reverting to an older collection, remove Windows suppression through this
role. An older role cannot remove scheduled tasks it never owned.

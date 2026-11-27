# install_updates

Runs explicit maintenance on Ubuntu 24.04/26.04 or Windows. Invoke or tag the
role when maintenance is wanted; it has no enable input or recurring schedule.
Unsupported platforms fail before mutation.

## Inputs and scope

- `install_updates_reboot`: permit required host reboots, default `false`.
  Permission does not force a reboot when none is needed.

Types and defaults are declared in `meta/argument_specs.yml`.

Ubuntu refreshes APT metadata and upgrades installed native packages with the
generic package module. Native holds and configured sources remain effective.
This is not an operating-system release upgrade.

It then updates installed system-wide Flatpak deployments and global npm
packages, in that order. Absent optional executables and empty global npm sets
are skipped. The role does not install package managers, add remotes, update
per-user stores or update project dependencies. Flatpak uses configured remotes
and native masks; npm follows native global-update version selection, not a
promise of the latest major version. An installation pin is not a maintenance
hold. A later pinned `install_app` run can restore its requested version.

After all Ubuntu channels, `/var/run/reboot-required` determines whether a host
reboot is needed. Without permission, the requirement is reported and retained.
Package-script service restarts are native package behaviour and are distinct
from a role-initiated host reboot.

Windows uses `ansible.windows.win_updates` with critical, security and
update-rollup categories from the configured Windows Update source. With reboot
permission, the native module owns required reboot, reconnect and continuation
cycles. Otherwise the pending-reboot result is reported, not declared complete.
Chocolatey maintenance is outside this role.

## Pause policy and failure boundaries

The role preserves Windows pause state. Paused updates can be hidden from an
explicit installation request, producing a successful zero-install result even
when applicable updates exist. That result does not prove the host is current.
Use `unattended_updates_enabled: true` to remove this collection's pause before
maintenance when installation is intended.

Package-manager and connection errors fail the run. Repetition against unchanged
sources with no eligible updates should report no package changes or unnecessary
reboots. Package updates are not reversed by rolling back this collection.

## Migration

Move immediate Windows calls from `auto_updates` to this role. Replace
`auto_updates_win_reboot` with `install_updates_reboot` and explicitly opt in
where reboots are permitted. Background policy belongs to `unattended_updates`,
whose independent Windows automatic-reboot permission defaults to false.

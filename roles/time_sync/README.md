# time_sync

Manages chrony time synchronisation policy on Debian, Ubuntu, and Fedora hosts.

## Guarantee

The role installs chrony, configures its sole upstream pool, and enables and
starts its service.

## Ownership

- Package: `chrony`.
- Debian and Ubuntu: `/etc/chrony/chrony.conf` pool entries and the `chrony`
  service.
- Fedora: `/etc/chrony.conf` pool entries and the `chronyd` service.

## Supported platforms

Linux hosts running Debian, Ubuntu, or Fedora.

## Implementation

- `tasks/main.yml` owns the complete supported-platform gate and conditionally
  dispatches to `tasks/linux/main.yml`.
- The Linux task file loads distribution data with `first_found`, then changes
  package, configuration, and service state.
- `vars/Debian.yml`, `vars/Ubuntu.yml`, and `vars/Fedora.yml` define the
  package, configuration path, and service data for their supported
  distributions.

## Interface

- `time_sync_enabled`: whether this host should have managed time
  synchronisation. Defaults to `true`. `false` skips the role and does not
  remove chrony or restore pool entries an earlier run commented out.
- `time_sync_server`: upstream NTP server. Defaults to `''` and is required only
  when `time_sync_enabled` is `true`.

## Invariants

- When enabled, `time_sync_server` must be a non-empty string.
- The configured upstream pool is the only active `pool` entry managed by the
  role.
- Configuration changes restart chrony.

## Migration

`time_sync_manage_package` and `time_sync_manage_service` have been removed.
Package installation and chrony service management are mandatory role-owned
behaviour. Upgrades no longer use the old `/etc/ntpsec/ntp.conf` artefact.

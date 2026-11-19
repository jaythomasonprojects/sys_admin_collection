# time_sync

Manages chrony time synchronisation policy on Ubuntu hosts.

## Guarantee

The role installs chrony, configures one upstream pool in its main file, and
enables and starts its service.

## Ownership

- Package: `chrony`.
- Ubuntu: `/etc/chrony/chrony.conf` pool entries and the `chrony`
  service.

## Supported platforms

Ubuntu 24.04/26.04 only. Windows is not supported by this role.

Ubuntu 26.04's packaged chrony service excludes ordinary containers through
native systemd conditions. Use a VM or bare-metal host for service acceptance;
the role does not override those conditions or disable clock discipline to make
container checks pass.

## Interface

- `time_sync_enabled`: whether this host should have managed time
  synchronisation. Defaults to `true`. `false` skips the role and does not
  remove chrony or restore pool entries an earlier run commented out.
- `time_sync_server`: upstream Network Time Protocol (NTP) pool hostname.
  Defaults to `''` and is required only
  when `time_sync_enabled` is `true`.

## Invariants

- When enabled, `time_sync_server` must be a non-empty string.
- The configured upstream pool is the only active `pool` entry managed by the
  role.
- Configuration changes restart chrony.

The role comments out other `pool` entries in the named main file. It does not
remove `server` entries or reconcile configuration included from other files.

## Implementation

- `tasks/main.yml` checks the platform and dispatches enabled hosts.
- `tasks/linux/main.yml` loads distribution data and manages package,
  configuration, and service state.
- `vars/Debian.yml` and `vars/Ubuntu.yml` define Ubuntu package,
  configuration-path, and service data.
- `handlers/main.yml` restarts chrony after changed pool configuration.

## Migration

`time_sync_manage_package` and `time_sync_manage_service` have been removed.
Package installation and chrony service management are mandatory role-owned
behaviour. Upgrades no longer use the old `/etc/ntpsec/ntp.conf` artefact.

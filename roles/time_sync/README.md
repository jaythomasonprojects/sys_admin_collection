# time_sync

Manages ntpsec time synchronisation policy on Debian and Ubuntu hosts.

## Guarantee

The role installs `ntpsec`, configures its sole upstream pool, and enables and
starts the `ntpsec` service.

## Ownership

- Package: `ntpsec`.
- Configuration: `/etc/ntpsec/ntp.conf` pool entries.
- Service: `ntpsec` enablement and running state.

## Supported platforms

Linux hosts running Debian or Ubuntu.

## Implementation

- `tasks/main.yml` validates Linux before conditionally dispatching to
  `tasks/linux/main.yml`.
- The Linux task file validates the Debian/Ubuntu contract, loads distribution
  data with `first_found`, then changes package, configuration, and service
  state.
- `vars/Debian.yml` and `vars/Ubuntu.yml` define the package, configuration
  path, and service data for their supported distributions.

## Interface

- `time_sync_enabled`: whether this host should have managed time
  synchronisation. Defaults to `true`. `false` skips the role and does not
  remove ntpsec or restore pool entries an earlier run commented out.
- `time_sync_server`: upstream NTP server. Defaults to `''` and is required only
  when `time_sync_enabled` is `true`.

## Invariants

- When enabled, `time_sync_server` must be a non-empty string.
- The configured upstream pool is the only active `pool` entry managed by the
  role.
- Configuration changes restart `ntpsec`.

## Migration

`time_sync_manage_package` and `time_sync_manage_service` have been removed.
Package installation and `ntpsec` service management are mandatory role-owned
behaviour.

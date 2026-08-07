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

`tasks/main.yml` validates Linux before dispatching to `tasks/linux/main.yml`.
The Linux task file validates the Debian/Ubuntu APT contract before changing
package, configuration, or service state.

## Interface

- `time_sync_server`: required upstream NTP server.

## Invariants

- `time_sync_server` must be a non-empty string.
- The configured upstream pool is the only active `pool` entry managed by the
  role.
- Configuration changes restart `ntpsec`.

## Migration

`time_sync_manage_package` and `time_sync_manage_service` have been removed.
Package installation and `ntpsec` service management are mandatory role-owned
behaviour.

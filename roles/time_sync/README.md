# time_sync

Manages chrony on Ubuntu 24.04/26.04 and the Windows Time client on Windows.

## Guarantee

Ubuntu receives chrony, one upstream pool in its main file, startup restoration
policy and an enabled/running service. Windows receives an explicit NTP client
source and an automatic/running W32Time service.

## Ownership

- Package: `chrony`.
- Ubuntu: `/etc/chrony/chrony.conf` pool entries and the `chrony`
  service, standalone `-s` in packaged `/etc/default/chrony` `DAEMON_OPTS`, and a
  persistent drift setting when none is configured.
- Windows: local W32Time `Parameters\NtpServer` with client flag `,0x8`,
  `Parameters\Type=NTP`, and `TimeProviders\NtpClient\Enabled=1`.

## Supported platforms

Ubuntu 24.04/26.04 and Windows.

Ubuntu 26.04's packaged chrony service excludes ordinary containers through
native systemd conditions. Use a VM or bare-metal host for service acceptance;
the role does not override those conditions or disable clock discipline to make
container checks pass.

## Interface

- `time_sync_enabled`: whether this host should have managed time
  synchronisation. Defaults to `true`. `false` skips the role and does not
  remove prior configuration, stop services or undo startup options. The
  platform gate still applies.
- `time_sync_restore_time`: enable chrony's native startup restoration, default
  `true`. Ubuntu only. False removes the standalone `-s` option without removing
  drift data, other startup options or normal synchronisation.
- `time_sync_server`: explicit upstream Network Time Protocol (NTP) hostname or address.
  Defaults to `''` and is required only
  when `time_sync_enabled` is `true`.

## Invariants

- When enabled, `time_sync_server` must be a non-empty string.
- The configured upstream pool is the only active `pool` entry managed by the
  role.
- Configuration changes restart chrony.
- Changed Windows registry configuration restarts W32Time. Unchanged runs do not
  restart the service.

The role comments out other `pool` entries in the named main file. It does not
remove `server` entries or reconcile configuration included from other files.

Startup restoration can step the Ubuntu clock from the RTC or a later persistent
drift-file timestamp. It supplies approximate startup time, not elapsed powered-off
time or proof of network synchronisation. The packaged unit, security options and
native container conditions remain intact.

Windows domain members deliberately use the supplied local source, not automatic
domain hierarchy selection. Organisational Group Policy can override local
settings. The role configures a client, not a domain controller or an NTP server.
Configured registry/service state does not establish successful upstream
synchronisation.

## Implementation

- `tasks/main.yml` checks the platform and dispatches enabled hosts.
- `tasks/linux/main.yml` loads distribution data and manages package,
  configuration, and service state.
- `tasks/linux/restore_time.yml` manages packaged startup options and persistent drift.
- `tasks/windows/main.yml` configures the native client and service.
- `vars/Debian.yml` and `vars/Ubuntu.yml` define Ubuntu package,
  configuration-path, and service data.
- `handlers/main.yml` applies changed configuration through native services.

## Migration

For 0.17.0, Windows callers must supply the explicit `time_sync_server` when
enabled. Ubuntu startup restoration defaults on. Set
`time_sync_restore_time: false` to retain startup without the managed `-s` option.

`time_sync_manage_package` and `time_sync_manage_service` have been removed.
Package installation and chrony service management are mandatory role-owned
behaviour. Upgrades no longer use the old `/etc/ntpsec/ntp.conf` artefact.

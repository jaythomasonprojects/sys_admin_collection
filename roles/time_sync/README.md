# time_sync

Minimal time synchronisation role based on the original `config_ntp` role.

## Variables

- `time_sync_server`: upstream NTP server to configure.
- `time_sync_manage_package`: install `ntpsec`. Default: `true`.
- `time_sync_manage_service`: allow the role to restart `ntp` when it changes
  `ntp.conf`. Default: `true`.

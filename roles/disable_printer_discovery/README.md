# disable_printer_discovery

Stops and disables Avahi and CUPS printer-discovery services on Linux hosts
using systemd. Genuinely missing units are already compliant; failed service
inspection is not.

## Guarantee

When enabled, the role stops and disables present `avahi-daemon.service`,
`avahi-daemon.socket`, and `cups-browsed.service` units without removing an
existing mask. It rejects failed or unusable service-manager inspection.
It owns only those unit states, not their packages or unrelated service policy.

## Interface

```yaml
disable_printer_discovery_enabled: true
```

This is the role's only public variable.

## Enable behaviour

`disable_printer_discovery_enabled: false` skips the policy rather than
converging services to another state. It does not restart services that an
earlier enabled run stopped.
The Linux and systemd prerequisites still apply when disabled.

## Supported platforms

Linux hosts using systemd only. Other hosts fail with
`disable_printer_discovery supports Linux hosts only.` A Linux host without
systemd fails with
`disable_printer_discovery requires a host using systemd as its service manager.`

## Implementation

- `tasks/main.yml` rejects unsupported platforms and dispatches Linux hosts.
- `tasks/linux/main.yml` validates systemd, inspects the fixed service list, and
  validates each query before stopping and disabling loaded or masked units.
- `vars/main.yml` holds the internal printer-discovery service list.

## Migration

`disable_printer_discovery` replaces `config_systemd_units`. Rename
`config_systemd_units_disable_printer_services` to
`disable_printer_discovery_enabled`. The old
`config_systemd_units_printer_services` variable has no replacement because the
service list is internal to this role.

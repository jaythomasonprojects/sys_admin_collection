# config_systemd_units

Suppresses printer-discovery services on Linux hosts using systemd.

## Guarantee

When enabled, the role stops and disables loaded `avahi-daemon.service`,
`avahi-daemon.socket`, and `cups-browsed.service`. Missing units are compliant.

## Supported platforms

Linux hosts using systemd only. Unsupported platforms and service managers fail
explicitly.

## Implementation

- `tasks/main.yml` rejects unsupported platforms and dispatches Linux hosts.
- `tasks/linux/main.yml` validates systemd, inspects the fixed service list, and
  stops and disables loaded units.
- `vars/main.yml` holds the internal printer-discovery service list.

## Interface

```yaml
config_systemd_units_disable_printer_services: true
```

## Enable behaviour

`config_systemd_units_disable_printer_services: false` skips the policy rather
than converging services to another state. It does not restart services that a
previous enabled run stopped.

## Invariants

The printer-discovery service list is internal to the role. Callers select only
whether printer-service suppression applies.

## Migration

The role now provides only fixed printer-service suppression.

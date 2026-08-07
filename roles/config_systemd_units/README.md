# config_systemd_units

Configures the role-owned custom systemd services and, by default, disables
loaded printer-discovery services. The role supports Linux hosts running
systemd only.

## Guarantee

The role stops and disables loaded `cups-browsed.service`,
`avahi-daemon.service`, and `avahi-daemon.socket` when
`config_systemd_units_disable_printer_services` is `true`. Missing printer
units are compliant.

It writes custom units to `/etc/systemd/system` with `root:root`, mode `0644`,
and the exact ownership marker:

```text
# Ansible managed: config_systemd_units custom service.
```

Only a file beginning with that marker can be stopped, disabled, and removed
by a `unit_file_state: 'absent'` declaration. The role does not manage
arbitrary existing or vendor-provided units.

## Implementation

- `tasks/main.yml` rejects unsupported platforms and dispatches Linux hosts.
- `tasks/linux/printer_services.yml` implements the fixed printer policy.
- `tasks/linux/custom_services.yml` validates and manages role-owned units.

## Variables

```yaml
config_systemd_units_disable_printer_services: true
config_systemd_units_custom_services: []
```

Each `config_systemd_units_custom_services` item accepts only `enabled`,
`name`, `state`, `unit_content`, and `unit_file_state`.

- `name` is required and must end in `.service`.
- `unit_content` is required and non-empty.
- `unit_file_state` is `present` (default) or `absent`.
- `state`, when provided, is `started` or `stopped`.
- `enabled`, when provided, is a boolean.
- An absent unit must use `state: 'stopped'` if it declares state, and
  `enabled: false` if it declares enablement.
- Names must be unique and cannot overlap with the printer-policy units.

## Examples

Create and enable a role-owned service:

```yaml
config_systemd_units_custom_services:
  - name: 'example.service'
    enabled: true
    state: 'started'
    unit_content: |
      [Unit]
      Description=Example service

      [Service]
      ExecStart=/usr/local/bin/example

      [Install]
      WantedBy=multi-user.target
```

Remove a service previously created by this role:

```yaml
config_systemd_units_custom_services:
  - name: 'example.service'
    unit_file_state: 'absent'
    unit_content: |
      [Service]
      ExecStart=/usr/local/bin/example
```

## Migration

The former `config_systemd_units` arbitrary existing-unit policy is removed.
Use `config_systemd_units_disable_printer_services` for the fixed printer
policy, or define a complete unit with `config_systemd_units_custom_services`.

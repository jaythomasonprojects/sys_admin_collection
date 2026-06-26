# config_print_services

Disable printer discovery services that can automatically add network printers
to workstations.

The role is intentionally narrow. It does not install CUPS, create print queues,
or manage printer drivers.

## Variables

- `config_print_services_disable_discovery_services`: apply the managed printer
  discovery service policy. Defaults to `false` so the role is a no-op unless a
  caller opts in.
- `config_print_services_discovery_services`: service policy list. Each item has
  `name`, `state`, and optional `enabled` keys.

## Example

```yaml
- name: Disable automatic printer discovery
  ansible.builtin.import_role:
    name: jaythomasonprojects.sys_admin.config_print_services
  vars:
    config_print_services_disable_discovery_services: true
```

## Tags

- `print_services`

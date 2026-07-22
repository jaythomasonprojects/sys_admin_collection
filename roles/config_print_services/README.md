# config_print_services

Disable printer discovery services that can automatically add network printers
to workstations.

The role is intentionally narrow. It does not install CUPS, create print queues,
or manage printer drivers.

## Variables

- `config_print_services_discovery_services`: service policy list applied when
  the role is invoked. Each item has `name`, `state`, and optional `enabled`
  keys.

## Example

```yaml
- name: Disable automatic printer discovery
  ansible.builtin.import_role:
    name: jaythomasonprojects.sys_admin.config_print_services
```

## Tags

- `print_services`

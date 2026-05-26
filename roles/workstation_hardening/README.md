# workstation_hardening

Minimal workstation hardening for USB-storage module blacklisting and optional
service stop or disable policy.

## Variables

- `workstation_hardening_blacklisted_modules`: module names to blacklist.
- `workstation_hardening_services`: service names or mappings with `name`, and
  optional `state` and `enabled` values.
- `workstation_hardening_apply_runtime_changes`: apply service stops and module
  unloads. Set `false` in container tests.

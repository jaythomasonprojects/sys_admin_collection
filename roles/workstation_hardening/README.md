# workstation_hardening

Manage workstation kernel-module blacklist policy and optional runtime module
unloading.

## Variables

- `workstation_hardening_apply_runtime_changes`: unload configured modules at
  runtime. Set `false` when the environment cannot unload host modules.
- `workstation_hardening_blacklisted_modules`: module names to blacklist.

Manage systemd units separately through `config_systemd_units`.

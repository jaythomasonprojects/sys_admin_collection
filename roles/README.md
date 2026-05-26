# Roles

Extracted collection roles for `jaythomasonprojects.sys_admin` now live in this directory.

## Available roles

- `create_user`
- `config_git`
- `config_ssh`
- `config_desktop`
- `install_app`
- `mount_network_share`
- `workstation_hardening`
- `time_sync`
- `auto_updates`

These roles were extracted from the playbook-local roles and are now consumed
from the installed collection via FQCNs such as `jaythomasonprojects.sys_admin.create_user`.

## Validation coverage

- Supported scenarios: `extensions/molecule/create_user`,
  `extensions/molecule/config_git`, `extensions/molecule/config_ssh`,
  `extensions/molecule/config_desktop`, `extensions/molecule/install_app`,
  `extensions/molecule/auto_updates`,
  `extensions/molecule/mount_network_share`,
  `extensions/molecule/workstation_hardening`,
  `extensions/molecule/time_sync`

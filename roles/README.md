# Roles

Extracted collection roles for `jaythomason.infra_management` now live in this directory.

## Available roles

- `create_users`
- `config_git`
- `config_ssh`
- `install_apps`
- `update_apps`

These roles were extracted from the playbook-local roles and are now consumed from the installed collection via FQCNs.

## Validation coverage

- `extensions/molecule/create_users`
- `extensions/molecule/config_git/README.md` placeholder for future git coverage
- `extensions/molecule/install_apps/README.md` placeholder for future package coverage
- `extensions/molecule/update_apps/README.md` placeholder for future package coverage
- `extensions/molecule/config_ssh/README.md` placeholder for future SSH coverage

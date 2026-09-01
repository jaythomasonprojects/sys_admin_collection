# config_ssh

Guarantee SSH reachability on Debian, Ubuntu, and Windows. The role owns SSH
packages and client/server configuration, the SSH service, and the Windows SSH
firewall rule. It does not create or manage authorised keys.

## Supported platforms

- Debian and Ubuntu: installs `openssh-client` and `openssh-server`, removes
  conflicting cloud-init server drop-ins, validates `sshd -t`, and enables and
  starts the selected SSH service.
- Windows: installs OpenSSH Server, configures `sshd`, owns the exact
  `OpenSSH Server (sshd)` TCP firewall rule, enables and starts `sshd`, and
  sets PowerShell as the default SSH shell.

Linux firewall policy is intentionally outside this role's ownership.

## Implementation map

- `tasks/linux/client.yml`: SSH client drop-in configuration.
- `tasks/linux/server.yml`: server package configuration, cloud-init cleanup,
  syntax validation, and service state.
- `tasks/windows/server.yml`: OpenSSH Server capability, configuration,
  firewall, service, and shell policy.

## Variables

The role accepts the normalized `config_ssh_*` variables already used by
inventory. `config_ssh_sshd_permit_root_login` defaults to `'no'`; the legacy
unprefixed root-login variable is not supported.

- `config_ssh_service_name`: override the SSH service name when the host does
   not use the role's auto-detected default (`ssh` on Debian-style systems,
   otherwise `sshd`).

## Invariants and migration

- A rendered Linux server configuration must pass `sshd -t`; invalid policy is
  left in place and fails the run rather than being silently removed.
- Authorised-key contents and Windows ACLs belong to `create_user`, including
  `administrators_authorized_keys`.
- Migrate legacy unprefixed root-login assignments to
  `config_ssh_sshd_permit_root_login`.

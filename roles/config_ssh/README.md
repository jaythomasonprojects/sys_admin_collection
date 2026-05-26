# config_ssh

Manage SSH client and SSHD drop-in configuration under `/etc/ssh`, including removal of conflicting cloud-init SSHD snippets.

## Variables

The role accepts the normalized `config_ssh_*` variables already used by
inventory, including `config_ssh_sshd_permit_root_login`.

- `config_ssh_service_name`: override the SSH service name when the host does
  not use the role's auto-detected default (`ssh` on Debian-style systems,
  otherwise `sshd`).

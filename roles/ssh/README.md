# ssh

Installs OpenSSH and owns client policy, server policy, Windows firewall access,
and service state.

## Ownership

The role owns OpenSSH packages, Linux client and server drop-ins, cloud-init
server drop-in cleanup, the SSH service, and the Windows `OpenSSH Server
(sshd)` TCP firewall rule keyed to `ssh_server_port`. Linux firewall policy is
outside this role's ownership. Authorised keys belong to `local_accounts`.

## Supported platforms

- Debian and Ubuntu: install `openssh-client` and `openssh-server`, remove
  conflicting cloud-init server drop-ins, validate `sshd -t`, and enable and
  start the service.
- Fedora: install `openssh-clients` and `openssh-server`, remove conflicting
  cloud-init server drop-ins, validate `sshd -t`, and enable and start `sshd`.
  Fedora hosts only support `ssh_server_port: 22`.
- Windows: install OpenSSH Server, configure `sshd`, manage the firewall rule
  and service, and set PowerShell as the default SSH shell.

Other platforms fail with `ssh supports Linux and Windows hosts only.`

## Implementation map

- `tasks/main.yml`: validates the platform and dispatches supported hosts.
- `tasks/linux/main.yml`: loads first-found distribution variables, installs
  packages, and dispatches client and server policy.
- `tasks/linux/client.yml`: manages the SSH client drop-in.
- `tasks/linux/server.yml`: removes cloud-init drop-ins, manages server policy,
  validates it, and manages the service.
- `tasks/windows/server.yml`: manages the OpenSSH capability, server policy,
  firewall rule, service, and shell policy.
- `vars/Debian.yml`, `vars/Fedora.yml`, and `vars/Ubuntu.yml`: provide package
  and service names.

## Interface

`ssh_enabled` defaults to `true`. The full `ssh_server_*` and `ssh_client_*`
interface, including defaults and validation, is defined in
`meta/argument_specs.yml`. `ssh_service_name` is an internal distribution value,
not a public option.

## Enable behaviour

When `ssh_enabled` is `false`, the role skips rather than converges or removes
previously managed OpenSSH packages, configuration, firewall rules, or service
state. Restoring prior SSH policy is not safe or unambiguous.

## Invariants

- A rendered Linux server configuration must pass `sshd -t`.
- The Windows firewall rule always uses `ssh_server_port`.
- Authorised keys and Windows authorised-key ACLs are owned by `local_accounts`.
- The Linux service name comes from first-found `vars/` data, not runtime
  detection.
- Fedora hosts require `ssh_server_port` to be `22` before the role loads
  variables, installs packages, or configures OpenSSH.

## Migration

`ssh` replaces `config_ssh`. Rename every setting below. No compatibility
aliases are provided.

| Old variable | New variable |
| --- | --- |
| `config_ssh_sshd_allow_agent_forwarding` | `ssh_server_allow_agent_forwarding` |
| `config_ssh_sshd_allow_groups` | `ssh_server_allow_groups` |
| `config_ssh_sshd_allow_tcp_forwarding` | `ssh_server_allow_tcp_forwarding` |
| `config_ssh_sshd_allow_users` | `ssh_server_allow_users` |
| `config_ssh_sshd_client_alive_count_max` | `ssh_server_client_alive_count_max` |
| `config_ssh_sshd_client_alive_interval` | `ssh_server_client_alive_interval` |
| `config_ssh_sshd_deny_groups` | `ssh_server_deny_groups` |
| `config_ssh_sshd_deny_users` | `ssh_server_deny_users` |
| `config_ssh_sshd_listen_address` | `ssh_server_listen_address` |
| `config_ssh_sshd_login_grace_time` | `ssh_server_login_grace_time` |
| `config_ssh_sshd_max_auth_tries` | `ssh_server_max_auth_tries` |
| `config_ssh_sshd_password_authentication` | `ssh_server_password_authentication` |
| `config_ssh_sshd_permit_empty_passwords` | `ssh_server_permit_empty_passwords` |
| `config_ssh_sshd_permit_root_login` | `ssh_server_permit_root_login` |
| `config_ssh_sshd_port` | `ssh_server_port` |
| `config_ssh_sshd_pubkey_authentication` | `ssh_server_pubkey_authentication` |
| `config_ssh_sshd_use_dns` | `ssh_server_use_dns` |
| `config_ssh_sshd_x11_forwarding` | `ssh_server_x11_forwarding` |
| `config_ssh_ssh_compression` | `ssh_client_compression` |
| `config_ssh_ssh_connect_timeout` | `ssh_client_connect_timeout` |
| `config_ssh_ssh_forward_agent` | `ssh_client_forward_agent` |
| `config_ssh_ssh_forward_x11` | `ssh_client_forward_x11` |
| `config_ssh_ssh_host_overrides` | `ssh_client_host_overrides` |
| `config_ssh_ssh_password_authentication` | `ssh_client_password_authentication` |
| `config_ssh_ssh_port` | `ssh_client_port` |
| `config_ssh_ssh_pubkey_authentication` | `ssh_client_pubkey_authentication` |
| `config_ssh_ssh_server_alive_count_max` | `ssh_client_server_alive_count_max` |
| `config_ssh_ssh_server_alive_interval` | `ssh_client_server_alive_interval` |
| `config_ssh_ssh_strict_host_key_checking` | `ssh_client_strict_host_key_checking` |
| `config_ssh_service_name` | Removed, now an internal `vars/` value |

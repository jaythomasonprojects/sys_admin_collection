# ssh

Installs and configures OpenSSH, starts its server, and manages Windows firewall
access. Authorised keys belong to [`local_accounts`](../local_accounts/README.md).

## Guarantee and ownership

The role owns OpenSSH packages, Linux client policy, the complete server
configuration, and service state. Server paths are `/etc/ssh/sshd_config` and
`C:\ProgramData\ssh\sshd_config`. Windows also owns the `OpenSSH Server (sshd)`
TCP firewall rule and PowerShell as the default SSH shell. Linux firewall policy
is outside this role.

The role replaces the entire server main file, including custom settings and
includes. Its Linux file does not include the general server drop-in directory.
On Fedora it includes only the system crypto-policy file
`/etc/crypto-policies/back-ends/opensshserver.config`, which supplies ciphers,
MACs and key exchange.
Foreign files remain on disk but are not merged or deleted.

## Supported platforms and prerequisites

- Debian and Ubuntu use `openssh-client`, `openssh-server`, and the native service.
- Fedora uses `openssh-clients`, `openssh-server`, and `sshd`. Server port must be
  `22`; this role does not manage alternate-port SELinux labels.
- Windows uses the native OpenSSH Server capability and `sshd`.

Other platforms fail explicitly. Windows requires `ansible.windows >=3.6.0`
and its `win_capability` prerequisites. The installing account needs
administrative access and the batch logon right. The role does not grant that
right or provide a missing capability source. Installation may need an
operator-managed reboot.

## Interface

`ssh_enabled` defaults to `true`. Setting it to `false` skips management without
removing packages, configuration, firewall access, or service state from earlier
runs. It does not restore previous policy. Unsupported-platform validation
still applies.

Boolean-like OpenSSH settings below use quoted strings `'yes'` and `'no'`, not
YAML Booleans. Types and choices are declared in
[`meta/argument_specs.yml`](meta/argument_specs.yml).

### Server options

These configure both platforms. OpenSSH interprets patterns and values, and
native validation reports invalid settings.

| Variable | Default | Meaning |
| --- | --- | --- |
| `ssh_server_allow_agent_forwarding` | `'yes'` | Allow SSH agent forwarding |
| `ssh_server_allow_groups` | `null` | List of allowed group patterns |
| `ssh_server_allow_tcp_forwarding` | `'yes'` | Allow TCP forwarding |
| `ssh_server_allow_users` | `null` | List of allowed user patterns |
| `ssh_server_client_alive_count_max` | `3` | Unanswered server keepalives before disconnect |
| `ssh_server_client_alive_interval` | `0` | Server keepalive interval in seconds; zero disables it |
| `ssh_server_deny_groups` | `null` | List of denied group patterns |
| `ssh_server_deny_users` | `null` | List of denied user patterns |
| `ssh_server_listen_address` | `'0.0.0.0'` | Listener address |
| `ssh_server_login_grace_time` | `'1m'` | Time allowed to authenticate |
| `ssh_server_max_auth_tries` | `3` | Maximum authentication attempts per connection |
| `ssh_server_password_authentication` | `'yes'` | Permit password authentication |
| `ssh_server_permit_empty_passwords` | `'no'` | Permit empty passwords |
| `ssh_server_permit_root_login` | `'no'` | `yes`, `no`, or `prohibit-password` |
| `ssh_server_port` | `22` | Server port; Fedora supports only `22` |
| `ssh_server_pubkey_authentication` | `'yes'` | Permit public-key authentication |
| `ssh_server_use_dns` | `'no'` | Request reverse DNS lookup |
| `ssh_server_x11_forwarding` | `'yes'` | Permit X11 forwarding |

`null` or empty access lists omit the corresponding directive. Windows uses
`.ssh/authorized_keys` in each account's native profile for administrators and
standard accounts alike. There is no shared administrator-key override.

### Linux client options

Windows does not manage SSH client policy through this role.

| Variable | Default | Meaning |
| --- | --- | --- |
| `ssh_client_compression` | `'no'` | Enable compression |
| `ssh_client_connect_timeout` | `0` | Connection timeout in seconds |
| `ssh_client_forward_agent` | `'no'` | Forward the local SSH agent |
| `ssh_client_forward_x11` | `'no'` | Forward X11 |
| `ssh_client_host_overrides` | `[]` | Ordered host patterns and native settings |
| `ssh_client_password_authentication` | `'yes'` | Permit password authentication |
| `ssh_client_port` | `22` | Default destination port |
| `ssh_client_pubkey_authentication` | `'yes'` | Permit public-key authentication |
| `ssh_client_server_alive_count_max` | `3` | Unanswered client keepalives before disconnect |
| `ssh_client_server_alive_interval` | `0` | Client keepalive interval in seconds |
| `ssh_client_strict_host_key_checking` | `'ask'` | `yes`, `no`, or `ask` |

Each override requires `host` and a `settings` mapping of native OpenSSH keys:

```yaml
ssh_client_host_overrides:
  - host: '*.example.invalid'
    settings:
      Port: 4022
      User: 'example_user'
```

Host overrides appear before general defaults, in caller order. OpenSSH uses the
first obtained value. The owned client file is
`/etc/ssh/ssh_config.d/00-sys-admin-ssh.conf`; the packaged system include must
load it. Custom system and per-user client configuration remains your responsibility.

## Validation and invariants

Native `sshd -t -f` checks the complete candidate before replacement. Rejection
preserves the installed server file and does not restart the service. A valid
changed file notifies a restart; an unchanged repeat does not. Syntax validation
does not prove every effective setting.

Linux establishes missing host keys before validation. Windows generates missing
keys and restricts newly created private-key access control lists (ACLs).
Existing host keys are untouched. Windows validates and promotes its candidate
outside check mode; check mode is not equivalent to runtime acceptance.

The Windows firewall rule uses `ssh_server_port`. Linux service names come from
distribution data; `ssh_service_name` is internal, not a public option.
The [Windows scenario](../../extensions/molecule/ssh/windows/README.md) uses
independent Windows Remote Management (WinRM) access while checking installation
and policy transitions.
Setup and commands are in the [Molecule guide](../../extensions/molecule/README.md).

## Implementation map

- `tasks/main.yml` checks the platform and dispatches enabled hosts.
- `tasks/linux/main.yml` checks Fedora's port and installs distribution packages.
- `tasks/linux/client.yml` manages and validates the client drop-in.
- `tasks/linux/server.yml` establishes prerequisites and validates server policy.
- `tasks/windows/server.yml` manages the capability, candidate, firewall, and service.
- `files/Initialize-WindowsSshHostKeys.ps1` generates and protects new host keys.
- `handlers/main.yml` restarts services after changed server policy.
- `vars/Debian.yml`, `vars/Fedora.yml`, and `vars/Ubuntu.yml` provide package and service
  data; Fedora also names its crypto-policy include.

## Migration

`ssh` replaces `config_ssh`, without aliases. Replace the variable prefixes
`config_ssh_sshd_` with `ssh_server_` and `config_ssh_ssh_` with `ssh_client_`,
keeping the suffix. Remove `config_ssh_service_name`; service names are internal.

Beta configuration-layout upgrades are unsupported. Adopt the complete server
policy on a standard supported host; it does not merge custom policy. Apply
`local_accounts` alongside this role to provide each Windows account's keys.
Keys in the former shared administrator file no longer authorise logins under
the role's policy. That legacy file remains untouched.

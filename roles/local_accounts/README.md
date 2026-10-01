# local_accounts

Creates and updates local accounts, authorised keys, Windows key access control
lists (ACLs), and Windows password policy. The
name distinguishes local accounts from domain accounts. The role does not
install or configure OpenSSH.

## Guarantee

Creates and updates the declared local accounts on Linux and Windows. Account
names and the standard account set are site policy: define
`local_accounts_users` in the consuming repository's `group_vars`.

## Ownership

The role owns declared account fields, Linux authorised-key entries, Windows
authoritative key-file contents and ACLs, and Windows password policy. Apply
`ssh` separately to install and configure OpenSSH itself, including its service
and Windows firewall rule.

## Supported platforms

Linux and Windows hosts only.

## Interface

- `local_accounts_enabled`: whether the host should have managed local
  accounts, defaulting to `true`.
- `local_accounts_users`: list of account mappings, defaulting to `[]`.

Each mapping in `local_accounts_users` accepts:

| Field | Default | Meaning |
| --- | --- | --- |
| `append` | `false` | Add supplied groups instead of replacing membership |
| `comment` | Omitted | Account description |
| `create_home` | `true` | Create a Linux home directory |
| `groups` | Omitted | List of Linux groups or Windows local groups |
| `name` | Required | Local account name |
| `password` | Omitted | Linux password hash or Windows plain password |
| `password_never_expires` | Omitted | Windows password expiry policy |
| `shell` | Omitted | Linux login shell |
| `ssh_authorized_keys` | Omitted | List of public keys, with platform-specific semantics below |
| `update_password` | `'always'` | Windows final password policy: `always` or `on_create` |

Omit `password` for a key-only account; the role does not pass it to the account
module. Store supplied passwords through your external secret source.
The role does not delete accounts omitted from the list.

## Enable behaviour

Setting `local_accounts_enabled: false` skips the role. It does not remove
accounts an earlier run created.

## Key semantics

Linux keys are additive through `ansible.posix.authorized_key`. Windows treats
each declared `ssh_authorized_keys` list as the complete content of that
account's native profile `.ssh/authorized_keys`, including administrators.
An empty list clears that account's file; an omitted list leaves it unmanaged.

Windows disables inheritance. Per-user `.ssh` directories and key files are owned by the
managed account's security identifier (SID). Full control is limited to that
account, Administrators, and SYSTEM.

Windows resolves the SID of each account with declared keys after applying
account changes. Membership does not select a different key destination.
Windows creates or reuses that SID's native user profile without relocating an
existing profile. Key files and ACLs use the returned profile path, never a
guessed `C:\Users\<name>` directory. Missing identity, inaccessible profile or
failed ACL writes fail the role; an unchanged correct ACL reports no change.
An empty account declaration or disabled role leaves key files untouched.
The role does not manage `C:\ProgramData\ssh` or its former shared key file.

## Invariants

Windows creates accounts before key files, then applies final password policy.
A bootstrap-password rotation requires reconnecting with the vaulted
credentials before subsequent tasks. Key-only accounts skip the Windows
password-policy task.

The [Windows scenario](../../extensions/molecule/local_accounts/windows/README.md)
checks identity-specific logins over disposable clones. Setup and commands live
in the [Molecule guide](../../extensions/molecule/README.md).

## Implementation map

- `tasks/main.yml` checks the platform and dispatches enabled hosts.
- `tasks/linux/main.yml` and `tasks/windows/main.yml` order platform tasks.
- `tasks/linux/accounts.yml` manages local Linux account fields.
- `tasks/linux/authorized_keys.yml` adds Linux key entries.
- `tasks/windows/accounts.yml` creates accounts with `update_password: on_create`.
- `tasks/windows/authorized_keys.yml` uses `files/Resolve-LocalAccount.ps1` and
  `files/Set-AuthorizedKeyAcl.ps1` for native profiles and protected key ACLs.
- `tasks/windows/passwords.yml` applies final password policy.

## Migration

Apply the updated `ssh` role with this role to remove the administrator-group
key-file override. Declare each account's keys explicitly. Keys in the former
shared administrator file no longer authorise logins; remove that legacy file
manually if required. The account role leaves it untouched.

Upgrades from beta configurations are not supported. Supply the current
`local_accounts_users` interface directly; no old-role or variable aliases
are provided.

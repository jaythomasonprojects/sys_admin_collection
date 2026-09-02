# local_accounts

Manage the full lifecycle of a set of local accounts: their account fields,
authorised-key contents, Windows key ACLs, and Windows password policy. The
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

## Implementation map

- `tasks/linux/accounts.yml`: local Linux account fields.
- `tasks/linux/authorized_keys.yml`: additive Linux authorised-key entries.
- `tasks/windows/accounts.yml`: Windows account creation with
  `update_password: on_create`.
- `tasks/windows/authorized_keys.yml`: Windows authoritative key files and
  ACLs.
- `tasks/windows/passwords.yml`: final Windows password policy.

## Interface

- `local_accounts_enabled`: whether the host should have managed local
  accounts, defaulting to `true`.
- `local_accounts_users`: list of account mappings, defaulting to `[]`.
- `name`: required account name.
- `password`: optional hashed password on Linux or plain password on Windows.
  Omit it for a key-only account; it is not sent to either account module.
- `append`: add supplied groups instead of replacing them, defaulting to
  `false`.
- `comment`: account description or Linux GECOS field.
- `create_home`: Linux home-directory policy, defaulting to `true`.
- `groups`: Linux groups or Windows local groups.
- `password_never_expires`: Windows account policy.
- `shell`: Linux login shell.
- `ssh_authorized_keys`: list of public keys.
- `update_password`: Windows final password-policy setting, defaulting to
  `always`.

## Enable behaviour

Setting `local_accounts_enabled: false` skips the role. It does not remove
accounts an earlier run created.

## Key semantics

Linux keys are additive through `ansible.posix.authorized_key`. Windows treats
each declared `ssh_authorized_keys` list as the complete content of that
account's key file. Administrator accounts contribute to the complete
`C:\ProgramData\ssh\administrators_authorized_keys` aggregate, so an empty
declared list removes stale managed administrator keys.

Windows disables inheritance. The administrator aggregate is owned by
`S-1-5-32-544` and grants full control only to that SID and `S-1-5-18`
(SYSTEM). Standard-user `.ssh` directories and key files are owned by the
managed account SID and grant full control only to that account, Administrators,
and SYSTEM.

## Invariants

Windows creates accounts before key files, then applies final password policy.
A bootstrap-password rotation requires reconnecting with the vaulted
credentials before subsequent tasks. Key-only accounts skip the Windows
password-policy task.

## Migration

Replace the `jaythomasonprojects.sys_admin.create_user` role with
`jaythomasonprojects.sys_admin.local_accounts`, and rename
`create_user_accounts` to `local_accounts_users`. There are no aliases for the
old role or variable. `password` is now optional.

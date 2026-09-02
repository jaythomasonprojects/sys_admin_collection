# create_user

Create local users from `create_user_accounts` and manage their SSH
authorised keys. The role owns account fields, key contents, and Windows key
ACLs. It does not install or configure OpenSSH.

## Variables

`create_user_accounts` is a list of mappings. Each item requires `name` and
`password`, and supports:

- `append`: add supplied groups instead of replacing them.
- `comment`: account description or GECOS field.
- `create_home`: Linux home-directory policy, defaulting to `true`.
- `groups`: Linux groups or Windows local groups.
- `password_never_expires`: Windows account policy.
- `shell`: Linux login shell.
- `ssh_authorized_keys`: list of public keys.
- `update_password`: Windows final password-policy setting, defaulting to
  `always`.

## Implementation map

- `tasks/linux/accounts.yml`: local Linux account fields.
- `tasks/linux/authorized_keys.yml`: additive Linux authorised-key entries.
- `tasks/windows/accounts.yml`: Windows account creation with
  `update_password: on_create`.
- `tasks/windows/authorized_keys.yml`: Windows authoritative key files and
  ACLs.
- `tasks/windows/passwords.yml`: final Windows password policy.

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

## Invariants and migration

- Windows creates accounts before key files, then applies final password policy.
  A bootstrap-password rotation requires reconnecting with the vaulted
  credentials before subsequent tasks.
- Configure `ssh` separately to install OpenSSH, configure its service,
  and open the Windows SSH firewall rule.

# create_user

Create local users from `create_user_accounts` and manage their `ssh_authorized_keys` entries.

## Variables

- `create_user_accounts`: list of user definitions consumed by the role. On
  Windows, set `password_never_expires: true` on an individual user to disable
  password expiration for that account.

# create_users

Create local users from `create_users_users` and manage their `ssh_authorized_keys` entries.

## Variables

- `create_users_users`: list of user definitions consumed by the role
- `users`: compatibility fallback used when `create_users_users` is unset

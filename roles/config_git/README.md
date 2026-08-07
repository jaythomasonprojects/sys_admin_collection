# config_git

Install Git and configure global identity settings for the effective Ansible
execution user on Debian and Ubuntu hosts.

## Guarantee

This role owns the `git` package and global `user.name` and `user.email`
configuration when their values are non-empty. The global configuration uses the
effective execution user's `HOME`; callers must set `HOME` explicitly when that
user's home cannot be inferred.

It does not manage repositories, credentials, signing, or multi-user
orchestration.

## Support

- Debian
- Ubuntu

## Implementation

- `tasks/main.yml` rejects non-Linux hosts and dispatches to Linux tasks.
- `tasks/linux/main.yml` rejects unsupported Linux distributions, installs the
  `git` package, and configures the requested global identity keys.

## Variables

- `config_git_user_name`: global Git user name. An empty value leaves the key
  unmanaged.
- `config_git_user_email`: global Git user email. An empty value leaves the key
  unmanaged.

## Migration from pre-0.7

Before 0.7, callers had to ensure Git was installed before applying this role.
The role now owns the `git` package, so remove that duplicate package-management
step. The identity variables and effective-user global configuration semantics
are unchanged.

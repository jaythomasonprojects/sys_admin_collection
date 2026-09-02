# git

Install Git and configure global identity for the account the play runs as on
Debian and Ubuntu hosts.

## Guarantee

This role owns the `git` package and, when configured, the global `user.name`
and `user.email` settings for the execution user. The global configuration uses
that user's `HOME`; callers must set `HOME` explicitly when it cannot be
inferred. It does not manage repositories, credentials, signing, or identities
for multiple accounts.

## Support

- Debian
- Ubuntu

## Implementation

- `tasks/main.yml` rejects non-Linux hosts and conditionally dispatches to the
  Linux implementation.
- `tasks/linux/main.yml` rejects unsupported distributions, loads package data
  with `first_found`, installs Git, and configures the requested identity keys.
- `vars/Debian.yml` and `vars/Ubuntu.yml` define their distribution package
  data. Fedora is not yet supported because it has no declared support contract
  or distribution data file.

## Variables

- `git_enabled`: whether this host should have managed Git configuration.
  Defaults to `true`. `false` skips the role and does not remove Git or an
  identity configured by an earlier run.
- `git_user_name`: global Git user name. Defaults to `''`; an empty value leaves
  the existing value unchanged.
- `git_user_email`: global Git user email. Defaults to `''`; an empty value
  leaves the existing value unchanged.

## Migration from config_git

Replace `jaythomasonprojects.sys_admin.config_git` with
`jaythomasonprojects.sys_admin.git`. Rename `config_git_user_name` to
`git_user_name` and `config_git_user_email` to `git_user_email`. The execution
user semantics are unchanged.

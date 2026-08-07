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

## Variables

- `config_git_user_name`: global Git user name. An empty value leaves the key
  unmanaged.
- `config_git_user_email`: global Git user email. An empty value leaves the key
  unmanaged.

# mount_network_share

Manage SMB/CIFS fstab entries, mount point directories, and optional
credential files from `mount_network_share_shares`.

## Variables

- `mount_network_share_manage_packages`: install `cifs-utils`. Default: `true`.
- `mount_network_share_reload_remote_fs`: restart `remote-fs.target` after
  share changes. Default: `false`.
- `mount_network_share_shares`: list of share definitions. Defaults to `[]`.
  Each item supports:
  - `name`: label used for the credential filename and task output.
  - `server`: SMB server hostname or address.
  - `share`: remote share name.
  - `mount_point`: local mount path.
  - `state`: mount state for `ansible.posix.mount`. Defaults to `present`.
  - `owner`, `group`, `mode`: mount point ownership and mode.
  - `fstab_options`: option list or comma-separated string. Defaults to
    `_netdev,nofail,iocharset=utf8`.
  - `username`, `password`: optional SMB credentials; define both or neither.
  - `credentials_path`: optional path for workstation `.smbcredentials` files
    or system paths such as `/etc/samba/credentials/<name>`.
  - `credentials_owner`, `credentials_group`, `credentials_mode`: optional
    ownership and mode for the credential file.

Passwords should come from Ansible Vault or another secret source. Set
`credentials_path` per share for workstation `.smbcredentials` files or
system-wide paths such as `/etc/samba/credentials/<name>`.

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
   - `mount_point`: local mount path on Linux, or a bare drive letter such as
     `Z` on Windows.
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

## Windows credentials

For a Windows share with `username` and `password`, the role saves a local
Credential Manager `domain_password` entry for `server` in the configured
user's profile before mapping the drive. Windows then uses that saved SMB
credential for the mapping, so the drive can continue to connect after the
local Windows account password changes.

Removing a drive with `state: absent` does not remove its saved server
credential, because another share on that server may use it. Credential
Manager permits one `domain_password` credential per server for each user. If
multiple share definitions use the same server with different credentials, the
last share processed replaces the credential and is used by all shares on that
server.

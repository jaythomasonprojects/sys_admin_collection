# mount_network_share

Manages SMB/CIFS network-share policy on Linux and Windows hosts. The role owns
the Linux `cifs-utils` prerequisite, Linux mount points and `/etc/fstab`
entries, credential files, and Windows mapped drives and Credential Manager
entries.

## Supported platforms

- Linux: mounts SMB/CIFS shares at filesystem paths.
- Windows: maps SMB shares to bare drive letters such as `Z`.

The role fails on other platforms.

## Implementation map

- `tasks/main.yml`: asserts the supported platform, validates enabled share
  invariants and credentials, and dispatches once to the supported platform flow.
- `tasks/linux/main.yml`: installs `cifs-utils`, calculates scoped values, and
  passes them to each Linux share include.
- `tasks/linux/share.yml`: manages mount points, credentials, and fstab.
- `tasks/windows/main.yml`: processes each Windows share.
- `tasks/windows/share.yml`: persists SMB credentials and maps drive letters.

## Variables

```yaml
mount_network_share_enabled: true
mount_network_share_reload_remote_fs: false
mount_network_share_shares:
  - name: 'workstation_data'
    server: 'files.example.invalid'
    share: 'Data'
    mount_point: '/mnt/workstation-data'
    owner: 'molecule'
    group: 'molecule'
    mode: '0750'
    fstab_options:
      - '_netdev'
      - 'nofail'
    credentials_path: '/home/molecule/.smbcredentials'
    credentials_owner: 'molecule'
    credentials_group: 'molecule'
    credentials_mode: '0600'
    username: 'molecule'
    password: '{{ vault_mount_network_share_password }}'
```

`mount_network_share_enabled` defaults to `true`. Set it to `false` to skip
credential validation and share management. Disabling the role does not remove
shares managed by an earlier run.

`mount_network_share_shares` defaults to `[]`. Every entry, including an entry
provided while the role is disabled, must define `name`, `server`, `share`, and
`mount_point`. The role argument specification validates supplied field types,
defaults, and `state` choices.
Define `username` and `password` together as non-empty strings, or omit both.

On Linux, `mount_point` is a filesystem path. `state` is passed to
`ansible.posix.mount` and defaults to `present`; `absent` and
`absent_from_fstab` remove the managed credential file when credentials were
declared. `owner`, `group`, and `mode` configure present mount-point
directories. The role also adds `uid=<owner>` and `gid=<group>` CIFS options
unless `fstab_options` already provides them. This makes the mounted files
locally accessible to the configured owner and group. SMB server permissions
still apply to the configured SMB account.

With credentials, Linux writes a file at `credentials_path`, defaulting to
`/etc/samba/credentials/<name>`. `credentials_owner`, `credentials_group`, and
`credentials_mode` default to `root`, `root`, and `0600`. Keep passwords in
Ansible Vault or another secret source. A credential path must be suitable for
the configured account and should not be shared by shares requiring different
credentials. Set `fstab_options` as a YAML list only; it defaults to
`['_netdev', 'nofail', 'iocharset=utf8']`.

On Windows, `mount_point` must be a bare mapped-drive letter. The role maps
`\\server\share`; Linux-only fstab and credential-path settings do not apply.

## Activation policy

`mount_network_share_reload_remote_fs` defaults to `false`. Set it to `true`
to restart `remote-fs.target` after a Linux credential, fstab, or mount change.
The role does not mount a remote filesystem merely to validate connectivity.

## Invariants and migration

Linux package installation is mandatory. The
`mount_network_share_manage_packages` opt-out has been removed, so remove it
from inventories and playbooks.

Windows SMB authentication is coupled to the configured local user. The role
uses interactive `runas` so that user's Credential Manager profile receives a
local `domain_password` entry before drive mapping. Windows permits one such
credential per server per user, so every share for a given server and user must
use the same credentials. Removing a mapped drive intentionally retains the
server credential because another share can still use it. The credential secret
refreshes on every run so inventory password changes take effect; Windows does
not expose stored secrets for comparison, so this refresh is reported as a
change even when the mapped drives are already compliant.

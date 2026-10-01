# mount_network_share

Manages Server Message Block (SMB) network shares on Linux and Windows.
Linux uses the Common Internet File System (CIFS) client; Windows uses mapped drive letters.
Other platforms fail explicitly.

## Guarantee and ownership

Linux owns `cifs-utils`, declared mount-point directories, `/etc/fstab` entries,
and per-share root-owned credential files, `/etc/samba/credentials/<share-name>`, with
mode `0600`. The default `present` state writes mount policy without requiring
an immediate mount. Existing credential-directory ownership and modes are
preserved; legacy credential files are not discovered or deleted.

Windows owns declared drive mappings and the configured user's Credential
Manager entries. Each share declares its own authentication.
The role does not manage the SMB server or its share permissions.

## Interface

| Variable | Default | Meaning |
| --- | --- | --- |
| `mount_network_share_enabled` | `true` | Manage declared credentials and shares |
| `mount_network_share_reload_remote_fs` | `false` | Restart Linux `remote-fs.target` after changes |
| `mount_network_share_shares` | `[]` | List of share mappings |

Each share requires `name`, `server`, `share`, and `mount_point`. The name labels
task output and identifies its Linux credential file. Linux names must be distinct
single filenames, not `.` or `..`, and contain no path separators or whitespace.
The server and share form `\\server\share`. Argument validation
still checks declared fields when the role is disabled.

Linux example, using an existing local owner and group:

```yaml
mount_network_share_shares:
  - fstab_options:
      - '_netdev'
      - 'nofail'
    group: 'example_user'
    mode: '0750'
    mount_point: '/mnt/example-data'
    name: 'example_data'
    owner: 'example_user'
    password: '{{ vault_mount_network_share_password }}'
    server: 'files.example.invalid'
    share: 'Data'
    username: 'example_user'
```

Keep passwords in Ansible Vault or another secret source. Enabled, non-empty
share input requires non-empty `username` and `password` on every share,
including removal requests.
Empty share input makes no changes.

### Linux share fields

| Field | Default | Meaning |
| --- | --- | --- |
| `fstab_options` | `['_netdev', 'nofail', 'iocharset=utf8']` | List of mount options, not a comma-separated string |
| `group` | `'root'` | Mount-point group and default CIFS file group |
| `mode` | `'0755'` | Mount-point directory mode |
| `mount_point` | Required | Filesystem path |
| `owner` | `'root'` | Mount-point owner and default CIFS file owner |
| `state` | `'present'` | Native mount state |

State accepts `present`, `absent`, `mounted`, `unmounted`, or
`absent_from_fstab`, passed to `ansible.posix.mount`. The role adds `uid=<owner>`
and `gid=<group>` options unless supplied explicitly. Those values control local
ownership; SMB server permissions still apply to the SMB credential account.
The owned credential path is always added to mount options.

### Windows share fields and prerequisites

Use a bare `mount_point` letter such as `Z`, not `Z:`. Use `state: present`
or `state: absent`; Linux-only mount options, ownership, and modes do not apply.
The credential username must also identify the local user whose drive is mapped,
and its password must permit that user's interactive logon.

The role uses interactive `runas` with the user's profile to persist a local
`domain_password` credential before mapping the drive. Windows allows one such
credential per server per user. Native password refresh reports a change on
every run, even when the drive mapping is already correct. Shares on the same
server under the same user must use consistent credentials.

## Enable behaviour and invariants

`mount_network_share_enabled: false` skips credential validation and share work.
It does not remove shares from an earlier run. Remove a share with an explicit
`state: absent` declaration while the role is enabled.

Share removal retains Linux's per-share files and Windows's server credentials.
The role does not discover or delete legacy files, including `sys-admin`.
Remove a retained credential manually
only after confirming no mapping or mount depends on it.

`mount_network_share_reload_remote_fs: true` restarts `remote-fs.target` after
Linux credential, mount, or fstab changes. The role does not mount a remote
filesystem merely to validate connectivity.

## Implementation map

- `tasks/main.yml` checks the platform and enabled credential requirements.
- `tasks/linux/main.yml` installs the client and prepares the credential directory.
- `tasks/linux/shares.yml` calculates native mount state and options.
- `tasks/linux/share.yml` writes protected credentials and manages mounts.
- `tasks/windows/main.yml` iterates Windows shares.
- `tasks/windows/share.yml` persists credentials and maps drive letters.
- `handlers/main.yml` conditionally restarts `remote-fs.target`.

## Migration

Move the existing host-level `mount_network_share_credential.username` and
`.password` values into `username` and `password` on each share, then remove
the host mapping. Keep existing Vault expressions rather than copying secrets.
Remove per-share `credentials_path`, `credentials_owner`, `credentials_group`,
and `credentials_mode` if present. Paths and permissions are fixed, and there
is no host-credential fallback.
Remove `mount_network_share_manage_packages`; client installation is mandatory.
The role does not remove old credential files during this migration.

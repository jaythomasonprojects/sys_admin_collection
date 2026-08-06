# config_systemd_units

Manage system-scope unit files and lifecycle policy on hosts that use systemd.
The role fails when assigned to a host whose service manager is not systemd.

## Variables

- `config_systemd_units`: unit policy mappings. Each item requires `name` and
  at least one desired property:
  - `state`: `started` or `stopped`
  - `enabled`: whether the unit starts through its install target
  - `masked`: whether systemd must prevent all activation
  - `unit_content`: complete inline unit-file content written under
    `/etc/systemd/system`
  - `unit_file_state`: `present` or `absent`; explicit removal also requires
    `state: 'stopped'` and `enabled: false`

Omitted runtime properties remain unmanaged. Existing units must already be
installed; a missing unit is treated as a policy error.

## Example

```yaml
config_systemd_units:
  - name: 'cups-browsed.service'
    state: 'stopped'
    enabled: false
  - name: 'avahi-daemon.socket'
    state: 'stopped'
  - name: 'avahi-daemon.service'
    state: 'stopped'
    enabled: false
  - name: 'example.service'
    unit_content: |
      [Unit]
      Description=Example service

      [Service]
      ExecStart=/usr/local/bin/example

      [Install]
      WantedBy=multi-user.target
    state: 'started'
    enabled: true
```

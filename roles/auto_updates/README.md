# auto_updates

Configures persistent automatic updates on Linux and immediately installs
available updates on Windows. Linux support is Ubuntu 24.04/26.04 with APT.
Other platforms fail explicitly.

## Guarantee and ownership

- APT hosts receive `unattended-upgrades`, owned schedule file
  `/etc/apt/apt.conf.d/20auto-upgrades`, and owned policy file
  `/etc/apt/apt.conf.d/52sys-admin-auto-updates`. Enabled policy also unmasks,
  enables, and starts `apt-daily.timer` and `apt-daily-upgrade.timer` on systemd.
- Windows installs available updates through `ansible.windows.win_updates`.
  The role does not configure a Windows update schedule.

## Interface

| Variable | Default | Meaning |
| --- | --- | --- |
| `auto_updates_enabled` | `true` | Manage the Linux automatic-update schedule; ignored on Windows |
| `auto_updates_apt_auto_reboot` | `false` | Permit a required unattended reboot |
| `auto_updates_apt_auto_reboot_time` | `'02:00'` | APT reboot time |
| `auto_updates_apt_origins` | `[]` | Explicit allowed origins; empty selects release and security patterns |
| `auto_updates_apt_package_blacklist` | `[]` | Packages excluded from unattended upgrades |
| `auto_updates_win_reboot` | `true` | Permit Windows update installation to reboot |

APT options apply only to Ubuntu.
Windows uses only `auto_updates_win_reboot`. Types and choices are declared in
[`meta/argument_specs.yml`](meta/argument_specs.yml).

## Enable behaviour and invariants

On Linux, `auto_updates_enabled: false` disables the schedule instead of
skipping the role. APT writes zero for its three managed periodic counters;
it preserves shared timer state and does not cancel an upgrade already running.
Required packages and
configuration remain installed. Re-enabling restores policy and timer state.

Windows ignores `auto_updates_enabled` and always requests immediate update
installation with `state: installed`. It may reboot by default. Omitting the
role, not setting its Linux enable flag, is how you avoid that Windows action.

APT policy clears the package-supplied origin allow-lists before adding the
requested patterns. An explicit origins list replaces those defaults; an empty
list selects Ubuntu release and security patterns. Package policy
and foreign files remain on disk. APT merges files in filename order, so later
foreign policy can override the role's settings. The role does not inspect it.
On non-systemd APT hosts, the package's native scheduling mechanism remains in use.

## Implementation map

- `tasks/main.yml` checks the complete Ubuntu/Windows platform gate.
- `tasks/linux/main.yml` selects the Ubuntu APT procedure.
- `tasks/linux/apt.yml` installs the package, renders policy, and manages timers.
- `tasks/windows/main.yml` requests immediate updates and optional reboot.
- `templates/` holds the owned APT configuration sources.

## Migration

The current APT policy path is `52sys-admin-auto-updates`. The role does not
reconcile foreign or historical policy files. When adopting its origin policy,
check that no later file overrides your intended configuration. Disabling the
role does not remove the installed update tools or foreign policy.

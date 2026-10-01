# auto_updates

Configures persistent automatic updates on Linux and immediately installs
available updates on Windows. Linux supports package managers `apt`, `dnf`,
and `dnf5`. Other platforms and Linux package managers fail explicitly.

## Guarantee and ownership

- APT hosts receive `unattended-upgrades`, owned schedule file
  `/etc/apt/apt.conf.d/20auto-upgrades`, and owned policy file
  `/etc/apt/apt.conf.d/52sys-admin-auto-updates`. Enabled policy also unmasks,
  enables, and starts `apt-daily.timer` and `apt-daily-upgrade.timer` on systemd.
- DNF4 hosts receive `dnf-automatic`, `/etc/dnf/automatic.conf`, and
  `dnf-automatic.timer`. DNF5 uses `dnf5-plugin-automatic` and
  `dnf5-automatic.timer` with the same configuration path.
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
| `auto_updates_dnf_apply_updates` | `true` | Install downloaded updates |
| `auto_updates_dnf_download_updates` | `true` | Download updates |
| `auto_updates_dnf_emit_via` | `'stdio'` | Notification transport |
| `auto_updates_dnf_random_sleep` | `0` | Maximum random delay before DNF starts |
| `auto_updates_dnf_reboot` | `'never'` | `never`, `when-changed`, or `when-needed` |
| `auto_updates_dnf_upgrade_type` | `'default'` | `default` or `security` |
| `auto_updates_win_reboot` | `true` | Permit Windows update installation to reboot |

APT and DNF options apply only to their respective Linux package managers.
Windows uses only `auto_updates_win_reboot`. Types and choices are declared in
[`meta/argument_specs.yml`](meta/argument_specs.yml).

## Enable behaviour and invariants

On Linux, `auto_updates_enabled: false` disables the schedule instead of
skipping the role. APT writes zero for its three managed periodic counters;
it preserves shared timer state and does not cancel an upgrade already running.
DNF stops and disables its automatic-update timer. Required packages and
configuration remain installed. Re-enabling restores policy and timer state.

Windows ignores `auto_updates_enabled` and always requests immediate update
installation with `state: installed`. It may reboot by default. Omitting the
role, not setting its Linux enable flag, is how you avoid that Windows action.

APT policy clears the package-supplied origin allow-lists before adding the
requested patterns. An explicit origins list replaces those defaults; an empty
list selects Ubuntu or Debian release and security patterns. Package policy
and foreign files remain on disk. APT merges files in filename order, so later
foreign policy can override the role's settings. The role does not inspect it.
On non-systemd APT hosts, the package's native scheduling mechanism remains in use.

## Implementation map

- `tasks/main.yml` checks the complete platform and package-manager gate.
- `tasks/linux/main.yml` selects `apt.yml` or `dnf.yml` and DNF version data.
- `tasks/linux/apt.yml` installs the package, renders policy, and manages timers.
- `tasks/linux/dnf.yml` manages the selected package, configuration, and timer.
- `tasks/windows/main.yml` requests immediate updates and optional reboot.
- `templates/` holds the owned APT and DNF configuration sources.

## Migration

The current APT policy path is `52sys-admin-auto-updates`. The role does not
reconcile foreign or historical policy files. When adopting its origin policy,
check that no later file overrides your intended configuration. Disabling the
role does not remove the installed update tools or foreign policy.

# auto_updates

Configures persistent native automatic updates on Linux and immediately installs
available updates on Windows.

## Guarantee

On Linux, the role owns the supported package manager's persistent automatic
update configuration. `auto_updates_enabled` is the collection's reference
converging flag: disabling it writes zeroed APT periodic counters and stops the
`dnf-automatic` timer instead of skipping. On Windows, the role immediately
installs available updates with `ansible.windows.win_updates`; Windows has no
scheduled configuration and ignores `auto_updates_enabled`.

## Ownership

- APT: the `unattended-upgrades` package plus
  `/etc/apt/apt.conf.d/20auto-upgrades` and
  `/etc/apt/apt.conf.d/52jtprojects-unattended-upgrades`.
- DNF: the `dnf-automatic` package, `/etc/dnf/automatic.conf`, and
  `dnf-automatic.timer` state.
- Windows: the immediate update installation requested through
  `ansible.windows.win_updates`.

## Supported platforms

- Linux with `apt`, `dnf`, or `dnf5`.
- Windows.

Unsupported operating systems and Linux package managers fail explicitly.

## Implementation

`tasks/main.yml` validates the operating system, then dispatches Linux hosts to
`tasks/linux/main.yml` and Windows hosts to `tasks/windows/main.yml`. The Linux
dispatcher validates the package manager before selecting APT or DNF tasks.

### APT (Debian/Ubuntu)

Installs `unattended-upgrades` and manages two files in `/etc/apt/apt.conf.d/`:

- **`20auto-upgrades`** is the schedule. It tells APT's periodic daemon to refresh package lists, download, and install upgrades daily. This is the canonical filename the `unattended-upgrades` package ships; we overwrite it with our own values.
- **`52jtprojects-unattended-upgrades`** is the policy. It controls which repos are trusted for upgrades, which packages are excluded, and whether the system may reboot. The `52` prefix ensures it loads after the package's own default policy file (`50unattended-upgrades`), so our settings win.

APT reads `/etc/apt/apt.conf.d/` in filename order. The numbering convention: packages own the low range (≤ 50), admins own the high range (≥ 50). Later files override earlier ones.

### DNF (RHEL/Fedora/CentOS)

Installs `dnf-automatic` and writes `/etc/dnf/automatic.conf`. A systemd timer (`dnf-automatic.timer`) triggers it on schedule. The config controls whether updates are downloaded only or also applied, and how results are reported.

## Interface

- `auto_updates_enabled`: the collection's reference converging flag. On Linux,
  `false` writes zeroed APT periodic counters and stops the `dnf-automatic`
  timer instead of skipping; Windows ignores this setting.
- `auto_updates_apt_origins`: explicit APT origins pattern override.
- `auto_updates_apt_package_blacklist`: packages to exclude from unattended
  upgrades.
- `auto_updates_apt_auto_reboot`: allow unattended-upgrades to reboot when
  needed.
- `auto_updates_apt_auto_reboot_time`: reboot window for unattended-upgrades.
- `auto_updates_dnf_download_updates`: download package updates with
  `dnf-automatic`.
- `auto_updates_dnf_apply_updates`: install downloaded updates with
  `dnf-automatic`.
- `auto_updates_dnf_random_sleep`: maximum random delay before DNF starts.
- `auto_updates_dnf_upgrade_type`: DNF upgrade type.
- `auto_updates_dnf_reboot`: DNF reboot policy (`never`, `when-needed`, etc.).
- `auto_updates_dnf_emit_via`: DNF update notification transport.
- `auto_updates_win_reboot`: allow the immediate Windows update installation to
  reboot the host when required.

## Invariants

- Linux configures persistent package-manager automatic updates.
- Windows always performs an immediate installation, independently of
  `auto_updates_enabled`.
- Windows update installation uses `state: installed`.

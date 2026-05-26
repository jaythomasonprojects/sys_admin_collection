# auto_updates

Configures native package-manager auto-update mechanisms instead of performing
imperative "upgrade everything now" runs during every play.

## How It Works

### APT (Debian/Ubuntu)

Installs `unattended-upgrades` and manages two files in `/etc/apt/apt.conf.d/`:

- **`20auto-upgrades`** — the schedule: tells APT's periodic daemon to refresh package lists, download, and install upgrades daily. This is the canonical filename the `unattended-upgrades` package ships; we overwrite it with our own values.
- **`52jtprojects-unattended-upgrades`** — the policy: controls which repos are trusted for upgrades, which packages are excluded, and whether the system may reboot. The `52` prefix ensures it loads after the package's own default policy file (`50unattended-upgrades`), so our settings win.

APT reads `/etc/apt/apt.conf.d/` in filename order. The numbering convention: packages own the low range (≤ 50), admins own the high range (≥ 50). Later files override earlier ones.

### DNF (RHEL/Fedora/CentOS)

Installs `dnf-automatic` and writes `/etc/dnf/automatic.conf`. A systemd timer (`dnf-automatic.timer`) triggers it on schedule. The config controls whether updates are downloaded only or also applied, and how results are reported.

## Variables

- `auto_updates_enabled`: enable or disable native auto-update scheduling.
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
- `auto_updates_dnf_reboot`: DNF reboot policy (`never`, `when-needed`, etc.).

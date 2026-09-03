# Fedora Support and Role Cleanup Design

## Status

Approved for the unreleased collection version `0.9.0`. This design extends the uncommitted
`desktop_layout` and `power_policy` work already present in the worktree.

## Purpose

Remove the obsolete `git` role, support current Fedora Workstation where each Linux capability has
a meaningful implementation, add Ubuntu 26.04 to the GNOME compatibility matrix, and remove
distribution-specific task branches where data or an existing Ansible module is the only thing that
varies.

The role interface remains outcome-oriented. Distribution package names, service names, and paths
are internal implementation data, not new public options.

## Release boundary

This work joins the unreleased `0.9.0` release. `galaxy.yml` remains at `0.9.0`, and the existing
`CHANGELOG.rst` section is expanded in the same change.

Removing `git` and replacing ntpsec with chrony are intentional pre-1.0 breaking changes. No
compatibility aliases or deprecated role stubs are added.

Historical changelog entries, designs, and implementation plans remain unchanged. They describe
previous releases and decisions. Live role documentation and the shared Molecule guide must not
advertise the removed `git` capability.

## Supported platform policy

- Ubuntu GNOME release-specific capabilities support Ubuntu 22.04, 24.04, and 26.04.
- Current Fedora means Fedora 44 for the `0.9.0` test matrix. Fedora role gates remain distribution
  based unless behaviour is known to depend on a Fedora release.
- Existing Debian support remains intact. This change does not add a complete Debian Molecule
  matrix.
- `desktop_layout` remains Ubuntu-only because stock Fedora GNOME does not include Ubuntu Dock or
  dash-to-dock.
- `allow_ping` remains Windows-only.
- Windows behaviour remains unchanged except where shared documentation names supported systems.

## Architecture

Every role keeps a single operating-system dispatch at `tasks/main.yml`. Linux procedure remains in
`tasks/linux/`. A distribution file under `vars/` is added only when package names, service names,
or paths differ. A distribution-specific task file is justified only when the procedure differs.

The review found no need for `tasks/linux/fedora.yml`. Fedora differences are data in `auto_login`,
`power_policy`, `ssh`, and `time_sync`. `auto_updates` retains its existing package-manager seam
because APT and DNF are genuinely different implementations. DNF4 and DNF5 use the same DNF
implementation with different internal package and timer names.

Molecule validates a representative distribution matrix rather than multiplying every
package-manager-neutral scenario across every Ubuntu release. GNOME schema-sensitive roles test all
three supported Ubuntu releases. Fedora-capable roles test Fedora 44. Existing Ubuntu coverage
continues to establish the Debian-family implementation.

## Role decisions

### Remove `git`

Delete `roles/git/` and `extensions/molecule/git/`. Dotfile management now owns Git configuration,
and no replacement role is introduced. `community.general` remains a dependency because other
roles use its dconf, modprobe, npm, and Flatpak modules.

### `auto_login`

Continue to detect existing display-manager configuration rather than installing a display manager.
Load the GDM configuration path from distribution data:

- Debian and Ubuntu: `/etc/gdm3/custom.conf`
- Fedora: `/etc/gdm/custom.conf`

LightDM remains at `/etc/lightdm/lightdm.conf.d`. GDM settings are written inside the `[daemon]`
section. The role continues to manage `AutomaticLoginEnable`, `AutomaticLogin`, and the existing
Wayland-disable dependency. Privileged file changes use task-level `become: true`.

### `auto_updates`

APT continues to own `unattended-upgrades`, `20auto-upgrades`, and one collection policy file. Rename
that policy file and template to `52sys-admin-auto-updates`. Every APT convergence removes the old
`52jtprojects-unattended-upgrades` path so an upgraded host cannot retain duplicate policy.

DNF4 owns `dnf-automatic` and `dnf-automatic.timer`. DNF5 owns `dnf5-plugin-automatic` and
`dnf5-automatic.timer`. Both write `/etc/dnf/automatic.conf`; the common template places
`random_sleep` in the documented `[commands]` section. Package, template, and timer tasks use
task-level privilege escalation.

### `desktop_layout`

Remain Ubuntu-only. Extend the supported releases and Molecule schema checks from Ubuntu 22.04 and
24.04 to 22.04, 24.04, and 26.04. Fedora must continue to fail explicitly rather than silently
persisting dash-to-dock keys that stock Fedora GNOME will not consume.

### `power_policy`

Support Ubuntu 22.04, 24.04, 26.04, and Fedora. The GNOME schemas, dconf keys, user resolution, and
execution procedure remain shared. Add Fedora package data for DBus, dconf, GLib utilities,
PyGObject, and psutil. Windows-only hibernation and plan settings remain ignored on Linux.

### `time_sync`

Replace ntpsec with chrony on Debian, Ubuntu, and Fedora while keeping the public interface:

```yaml
time_sync_enabled: true
time_sync_server: ''
```

Distribution data is:

| Distribution | Package | Configuration | Service |
| --- | --- | --- | --- |
| Debian | `chrony` | `/etc/chrony/chrony.conf` | `chrony` |
| Ubuntu | `chrony` | `/etc/chrony/chrony.conf` | `chrony` |
| Fedora | `chrony` | `/etc/chrony.conf` | `chronyd` |

All three use chrony's `pool` syntax, so configuration and service tasks remain shared. Installing
chrony resolves package conflicts with ntpsec through the native package manager. The role does not
delete the old `/etc/ntpsec/ntp.conf`; the README records it as a migration artefact that no longer
affects the active service.

### `ssh`

Add Fedora package data:

```yaml
ssh_packages:
  - 'openssh-clients'
  - 'openssh-server'
ssh_service_name: 'sshd'
```

Client and server drop-in tasks remain shared. Fedora support is restricted to
`ssh_server_port: 22`; another value fails before package or configuration changes. This avoids
claiming SELinux and firewalld ownership in `0.9.0`. Linux firewall policy remains external.

### Module-driven Linux roles

`disable_printer_discovery`, `disable_usb_storage`, `local_accounts`, and `mount_network_share`
retain one shared Linux implementation. Add or refresh Fedora 44 Molecule coverage and align Galaxy
metadata. Do not add Fedora task files.

`install_app` retains channel-oriented Linux task files. Native package, npm, Flatpak, and Debian
installer tasks are not distribution implementations. Move the npm prerequisite into
`vars/Debian.yml` (`npm`) and `vars/RedHat.yml` (`nodejs-npm`), loaded through `first_found`. Update
its Fedora image to Fedora 44 and add missing Ubuntu metadata. Privileged system package, system
Flatpak, and Debian installer operations use task-level `become: true`.

`mount_network_share` and its handler also gain task-level `become: true` because package, system
directory, credential, fstab, mount, and daemon-reload operations must work for a normal remote
user, not only a root-based test container.

## Stable failures

Existing stable failure strings remain unchanged unless their supported-platform list changes. New
or revised exact strings are:

```text
desktop_layout supports Ubuntu 22.04, 24.04, and 26.04 hosts only.
power_policy supports Windows, Ubuntu 22.04, 24.04, and 26.04, and Fedora hosts only.
ssh supports Debian, Ubuntu, Fedora, and Windows hosts only.
ssh_server_port must be 22 on Fedora hosts.
time_sync supports Debian, Ubuntu, and Fedora hosts only.
```

Molecule assertions change in the same task as each role contract.

## Testing

- Use `docker.io/geerlingguy/docker-ubuntu2604-ansible:latest` for Ubuntu 26.04.
- Use `docker.io/geerlingguy/docker-fedora44-ansible:latest` for current Fedora.
- GNOME containers verify installed schemas and persisted dconf values, not a running GNOME Shell.
- Service scenarios use privileged systemd containers with the existing cgroup settings.
- Network-share tests verify package, credentials, directories, and fstab state without contacting a
  real SMB server.
- Fedora DNF5 verification asserts `dnf5-plugin-automatic`, `/etc/dnf/automatic.conf`, and
  `dnf5-automatic.timer`.
- APT migration verification seeds the old `52jtprojects-unattended-upgrades` file, converges, then
  asserts the old path is absent and `52sys-admin-auto-updates` has exact expected content.
- Each changed scenario passes its complete Molecule sequence, including idempotence.
- Final validation runs `ansible-lint .`, `yamllint .`, and all Molecule scenarios with
  `ANSIBLE_CONFIG=ansible.cfg`.

## Documentation

Each affected role README records its guarantee, owned artefacts, supported platforms,
implementation map, enable behaviour, invariants, and migration notes. `extensions/molecule/README.md`
removes the obsolete Git example and records Ubuntu 26.04/Fedora 44 coverage boundaries.

The root README retains the `0.9.0` warning and updates only test-runtime details that are no longer
accurate. `CHANGELOG.rst` gains concise `0.9.0` entries for role removal, Fedora support, chrony,
Ubuntu 26.04, DNF5, and the APT filename migration. `galaxy.yml` remains `0.9.0`.

## Non-goals

- Fedora `desktop_layout` support or GNOME extension lifecycle management
- Non-default Fedora SSH ports, SELinux port labels, or Linux firewall management
- A full Debian release matrix
- A live GNOME Shell integration test
- Successful live SMB mounting in Docker
- Changing public role options other than removing the complete `git` interface
- Rewriting historical changelog entries, designs, or plans

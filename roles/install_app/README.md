# install_app

Installs applications through native package, Debian installer, npm, Flatpak,
and Chocolatey channels. It supports Ubuntu 24.04/26.04 and Windows hosts.

## Guarantee and ownership

On Linux, the role processes channels in this order: native packages, Debian
package references, npm applications, then Flatpak applications. Native package
installation owns required npm and Flatpak tools. Its first-found distribution
data selects `npm` for Ubuntu; Flatpak requests receive `flatpak`.

The role validates the npm and Flatpak executables after it installs their
prerequisites. It configures Flathub before installing requested Flatpak refs
unless `install_app_manage_flatpak_remote` is `false`. Windows owns Chocolatey
package installation through `install_app_choco_packages`.

Each managed application belongs to one requested channel. The role does not
install Node.js versions, manage other Flatpak remotes, or apply Linux-only
channels to Windows.

Application package lists are site data supplied from `group_vars` in the
consuming playbook repository, not from this collection.

## Variables

- `install_app_enabled`: whether this host should have its requested
  applications installed. Defaults to `true`. Setting it to `false` skips the
  role and does not remove applications installed by an earlier run.
- `install_app_native_packages`: native repository package names on Ubuntu.
  Defaults to `[]`. Windows ignores this list.
- `install_app_choco_packages`: Windows Chocolatey package names to install.
  Defaults to `[]`. Ubuntu ignores this list.
- `install_app_deb_packages`: list of HTTP(S) Debian package URLs. Absolute package
  paths on the managed APT host are also accepted. Defaults to `[]`. For example:

  ```yaml
  install_app_deb_packages:
    - '/usr/local/src/example.deb'
    - 'https://packages.example.invalid/example_1.2.3_all.deb'
  ```

  The role installs the referenced package with APT's native package/version
  idempotence. It does not copy controller files, stage downloads, verify
  checksums or remove packages. A caller requiring those guarantees must copy
  or download and verify the package before the role runs, then supply its
  managed-host path. Construct the list conditionally to skip an application;
  there is no per-item enable or state switch. Use versioned URLs or verified
  local files when mutable URL content is not acceptable. The input type is
  declared in `meta/argument_specs.yml`.
- `install_app_flatpaks`: Flatpak refs to install. Defaults to `[]`.
- `install_app_manage_flatpak_remote`: ensure Flathub is configured before
  installing Flatpak refs. Defaults to `true`.
- `install_app_npm_packages`: npm package names to install globally on Linux
  hosts. Defaults to `[]`. Entries pass unchanged to `community.general.npm`,
  including version suffixes:

  ```yaml
  install_app_npm_packages:
    - 'is-number'
    - 'is-odd@3.0.1'
    - '@colors/colors@1.6.0'
  ```

  The role does not parse or validate package syntax. The npm module owns
  installation and errors. Bare names and matching exact versions report no
  changes on repeat runs. Partial versions and ranges use native module
  behaviour and can report changes on every run.

## Invariants

- Requested native packages and channel prerequisites use `state: present`.
- Missing active APT references fail installation instead of silently skipping.
- npm requests require a working executable after prerequisite installation.
- Global npm installation uses task-level escalation. Already installed bare
  packages and matching exact pins report no changes on repeat runs.

## Implementation map

- `tasks/main.yml` checks the platform and dispatches enabled hosts.
- `tasks/linux/main.yml` loads distribution data and selects package channels.
- `tasks/linux/native_packages.yml` installs native packages and prerequisites.
- `tasks/linux/debian_packages.yml` uses native APT for package paths or URLs.
- `tasks/linux/npm.yml` checks npm and installs the supplied entries globally
  with system-wide escalation.
- `tasks/linux/flatpaks.yml` checks Flatpak and manages Flathub and requested refs.
- `tasks/windows/main.yml` installs Chocolatey packages, bootstrapping Chocolatey
  through its native module if necessary.

## Migration

For 0.17.0, replace `install_app_apt_packages` with
`install_app_native_packages`, preserving the list of strings. No compatibility
alias is provided. The generic package module and other channels are unchanged.

For 0.16.0, replace `deb_package_urls` with `install_app_deb_packages`. The
string-list format, URLs and managed-host paths are unchanged. No compatibility
alias is provided.

For 0.15.0, replace `install_app_debs` with `deb_package_urls`; the string-list
format and support for managed-host paths are unchanged.

For 0.14.0, replace `install_app_packages` with `install_app_apt_packages`
on Ubuntu or `install_app_choco_packages` on Windows. Mixed-platform groups
can set both lists directly.

Beta dictionary-valued `install_app_debs` entries and beta configuration
upgrades are unsupported. Supply string package references on fresh hosts.

Versioned npm entries are accepted from `0.10.1`. Existing bare-name inputs and
defaults are unchanged. Older releases reject versioned entries. Disabling the
role does not remove installed packages.

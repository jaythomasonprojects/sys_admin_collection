# install_app

Installs applications through native package, Debian installer, npm, Flatpak,
and Chocolatey channels. It supports Debian, EL, Fedora, and Windows hosts.

## Guarantee and ownership

On Linux, the role processes channels in this order: native packages, Debian
package installers, npm applications, then Flatpak applications. Native package
installation owns required npm and Flatpak tools: APT hosts receive `npm`, DNF
hosts receive `nodejs-npm`, and Flatpak requests receive `flatpak`.

The role validates the npm and Flatpak executables after it installs their
prerequisites. It configures Flathub before installing requested Flatpak refs
unless `install_app_manage_flatpak_remote` is `false`. Windows owns Chocolatey
package installation through `install_app_packages`.

Each managed application belongs to one requested channel. The role does not
install Node.js versions, manage other Flatpak remotes, or apply Linux-only
channels to Windows.

## Implementation map

- `tasks/main.yml`: validates the supported platform and dispatches to the
  platform implementation.
- `tasks/linux/main.yml`: processes Linux channels in their required order.
- `tasks/linux/native_packages.yml`: installs requested native packages and
  channel prerequisites.
- `tasks/linux/debian_packages.yml`: skips non-APT hosts or dispatches enabled
  Debian installer definitions.
- `tasks/linux/deb_package.yml`: validates, prepares, and installs each Debian
  installer definition.
- `tasks/linux/npm.yml`: validates bare names, checks npm, and installs global
  packages.
- `tasks/linux/flatpaks.yml`: checks Flatpak, optionally configures Flathub,
  and installs refs.
- `tasks/windows/main.yml`: installs Chocolatey packages.

## Variables

- `install_app_packages`: native Linux package names or Windows Chocolatey
  package names to install. Defaults to `[]`.
- `install_app_debs`: Debian package installers to apply on APT hosts. Defaults
  to `[]`. Each item supports:
  - `name`: human-readable label used in task output.
  - `enabled`: set to `false` to skip an item. Defaults to `true`.
  - `src`: package file on the controller to copy to the managed host.
  - `url`: package URL to download to the managed host.
  - `dest`: managed-host path used with `src` or `url`.
  - `deb`: managed-host package path or URL passed directly to `apt`.
  - `state`: package state passed to `apt`. Defaults to `present`.
  - `mode`: copied/downloaded file mode. Defaults to `0644`.
  - `checksum`: checksum for downloaded packages.
  - `creates`: managed-host path that skips the installer when it already
    exists.
- `install_app_flatpaks`: Flatpak refs to install. Defaults to `[]`.
- `install_app_manage_flatpak_remote`: ensure Flathub is configured before
  installing Flatpak refs. Defaults to `true`.
- `install_app_npm_packages`: npm package names to install globally on Linux
  hosts. Defaults to `[]`. Entries must be bare package names, such as `eslint`
  or `@scope/tool`.

## Invariants

- All requested native packages and channel prerequisites are installed once,
  with `state: present`.
- `install_app_debs` retains its item schema. Non-APT hosts skip it with a
  debug message without accessing installer paths.
- Invalid Debian installer definitions fail before any installer action.
- npm package requests reject versioned names and require a working executable
  after prerequisite installation.

## Migration

No variables or item schemas changed. Remove caller-managed `npm`,
`nodejs-npm`, and `flatpak` entries from `install_app_packages` when they were
only prerequisites for the corresponding channels; keeping them is harmless.

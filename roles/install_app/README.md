# install_app

Installs native OS packages, optional local or remote `.deb` files, and Flatpak
applications.

## Variables

- `install_app_packages`: package names to install. Defaults to `[]`.
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

Non-APT hosts skip `install_app_debs` with a debug message instead of failing.

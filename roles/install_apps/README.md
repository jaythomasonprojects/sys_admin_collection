# install_apps

Installs OS packages and Flatpak applications with the normalized role interface.

## Variables

- `install_apps_packages`: package names to install. Defaults to `[]` and falls back to `packages` for compatibility.
- `install_apps_flatpaks`: Flatpak refs to install. Defaults to `[]` and falls back to `flatpaks` for compatibility.

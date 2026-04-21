# update_apps

Updates system packages and Flatpak applications with the normalized role interface.

## Variables

- `update_apps_packages`: reserved for interface parity with the source role. Defaults to `[]` and falls back to `packages` for compatibility.
- `update_apps_flatpaks`: Flatpak refs to update. Defaults to `[]` and falls back to `flatpaks` for compatibility.

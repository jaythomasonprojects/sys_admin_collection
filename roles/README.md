# Role reference

Use installed roles by their fully qualified names, such as
`jaythomasonprojects.sys_admin.local_accounts`. Each role's README is its
current contract: supported platforms, prerequisites, inputs, ownership,
disable behaviour, implementation, invariants, and migration notes.

- [allow_ping](allow_ping/README.md)
- [auto_login](auto_login/README.md)
- [auto_updates](auto_updates/README.md)
- [desktop_layout](desktop_layout/README.md)
- [disable_printer_discovery](disable_printer_discovery/README.md)
- [disable_usb_storage](disable_usb_storage/README.md)
- [install_app](install_app/README.md)
- [local_accounts](local_accounts/README.md)
- [mount_network_share](mount_network_share/README.md)
- [power_policy](power_policy/README.md)
- [ssh](ssh/README.md)
- [time_sync](time_sync/README.md)

Most roles use `<role>_enabled` to express host policy. Disabling a role either
removes its safely reversible owned policy or skips work without undoing an
earlier run. `auto_login` instead uses empty user values to remove automatic
login. Windows `auto_updates` always requests immediate updates and ignores
its Linux enable flag. Check the individual role before assuming disable means
rollback or removal.

Tests live under `extensions/molecule/<role>/linux/` and `windows/`.
The [Molecule guide](../extensions/molecule/README.md) explains their lifecycle,
setup, commands, and limits.

# Role reference

Use installed roles by their fully qualified names, such as
`jaythomasonprojects.sys_admin.ssh`. Each role's README is its
current contract: supported platforms, prerequisites, inputs, ownership,
disable behaviour, implementation, invariants, and migration notes.

- [auto_updates](auto_updates/README.md)
- [install_app](install_app/README.md)
- [ssh](ssh/README.md)
- [time_sync](time_sync/README.md)

Most roles use `<role>_enabled` to express host policy. Disabling a role either
removes its safely reversible owned policy or skips work without undoing an
earlier run. Windows `auto_updates` always requests immediate updates and ignores
its Linux enable flag. Check the individual role before assuming disable means
rollback or removal.

Only Ubuntu 24.04/26.04 and Windows are supported. `time_sync` is Ubuntu-only. Consumers
prepare accounts before `ssh` key management and own account password and share policy.
See [CHANGELOG.rst](../CHANGELOG.rst) for removed roles and upgrade guidance.

Tests live under `extensions/molecule/<role>/linux/` and `windows/`.
The [Molecule guide](../extensions/molecule/README.md) explains their lifecycle,
setup, commands, and limits.

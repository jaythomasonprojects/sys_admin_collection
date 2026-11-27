# Role reference

Use installed roles by their fully qualified names, such as
`jaythomasonprojects.sys_admin.ssh`. Each role's README is its
current contract: supported platforms, prerequisites, inputs, ownership,
disable behaviour, implementation, invariants, and migration notes.

- [install_app](install_app/README.md)
- [install_updates](install_updates/README.md)
- [ssh](ssh/README.md)
- [time_sync](time_sync/README.md)
- [unattended_updates](unattended_updates/README.md)

Most roles use `<role>_enabled` to express host policy. Disabling a role either
removes its safely reversible owned policy or skips work without undoing an
earlier run. `unattended_updates` controls persistent policy, while invoking
`install_updates` requests immediate maintenance with required reboots opt-in.
Windows pause policy can hide applicable updates from explicit maintenance.
Check the individual role before assuming disable means rollback or removal.

Only Ubuntu 24.04/26.04 and Windows are supported. Consumers
prepare accounts before `ssh` key management and own account password and share policy.
See [CHANGELOG.rst](../CHANGELOG.rst) for removed roles and upgrade guidance.

Tests live under `extensions/molecule/<role>/linux/` and `windows/`.
The [Molecule guide](../extensions/molecule/README.md) explains their lifecycle,
setup, commands, and limits.

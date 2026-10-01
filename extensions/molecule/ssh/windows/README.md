# ssh Windows scenario

This scenario starts without the native OpenSSH Server capability and checks
installation, service state, listener, and effective per-user key policy.
It checks ordinary idempotence. Invalid candidates must preserve the installed
configuration and running service. Valid transitions must change effective
policy without an unnecessary restart on repeat.

`prepare.yml` removes the capability and checks that the disabled role does
not install it. `verify.yml` checks runtime policy, validation and transitions.
Static inspection and reset scripts live in `files/`.
Management stays on independent WinRM while SSH changes.
Follow the [Molecule guide](../../README.md#set-up-windows-testing) and use
selector `ssh/windows`.

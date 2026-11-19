# ssh Windows scenario

This scenario uses prepared native OpenSSH over key-only SSH and checks
service state, listener and effective per-user key policy.
It checks ordinary idempotence. Invalid candidates must preserve the installed
configuration and running service. Valid transitions must change effective
policy without an unnecessary restart on repeat.

`prepare.yml` uses the disposable clone's existing administrative SSH key,
without altering its source or reinstalling its control transport.
`verify.yml` checks runtime policy, validation and port transitions.
Static inspection scripts live in `files/`. Restart activation is asynchronous;
fresh connections must work on the declared port. No WinRM endpoint is created.
Native fixture accounts and distinct generated keys retain administrator and
standard-user logins, cross-account/shared-key rejection, alternate-profile
placement, protected ACLs, replacement, clearing and omission checks. Ordinary
idempotence covers unchanged key declarations. Administrative key-only SSH also
reapplies configuration without account passwords, then reconnects
after a deliberate fixture-password change without the replacement password.
The cleanup phase removes the generated controller keys. Account lifecycle
acceptance belongs to the consumer, not this scenario.
Follow the [Molecule guide](../../README.md#set-up-windows-testing) and use
selector `ssh/windows`.

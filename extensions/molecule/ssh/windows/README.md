# ssh Windows scenario

This scenario uses prepared native OpenSSH over key-only SSH and checks
service state, listener and effective per-user key policy.
The native idempotence pass checks both reported changes and an independently
read service process ID: unchanged policy and firewall ports must not restart
SSH. Invalid candidates must preserve the installed configuration and running
service. Valid port transitions must activate the requested policy.

`prepare.yml` uses the disposable clone's existing administrative SSH key,
without altering its source or reinstalling its control transport.
`verify.yml` checks runtime policy, validation and port transitions.
Static inspection scripts live in `files/`. Restart activation is asynchronous;
fresh connections must work on the declared port. No WinRM endpoint is created.
Native fixture accounts and distinct generated keys retain administrator and
standard-user logins, cross-account/shared-key rejection, alternate-profile
placement, protected ACLs, replacement, clearing and omission checks. Ordinary
idempotence covers unchanged key declarations. After a deliberate fixture
password change, a fresh key-only administrative connection applies the port
transition without the replacement password. That run supplies an empty
top-level key list; inspections before and after require both accounts' keys,
profiles and permissions to remain intact. Key replacement and clearing use
the separate management connection so they cannot revoke their own access.
These combined checks retain named observations, but an early failure can
prevent later checks from running.
The cleanup phase restores the prepared management port and account, checks a
fresh connection, then removes the generated controller keys. Shared destroy
releases DHCP over the restored connection before deleting the clone.
Account lifecycle acceptance belongs to the consumer, not this scenario.
Follow the [Molecule guide](../../README.md#set-up-windows-testing) and use
selector `ssh/windows`.

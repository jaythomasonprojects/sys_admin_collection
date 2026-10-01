# power_policy Windows scenario

This scenario seeds non-zero power timeouts, then checks native AC and DC
values and disabled hibernation after convergence. Ordinary idempotence and
an explicit repeat of timeout enforcement must report no changes.
Local `files/Inspect-PowerPolicy.ps1` supplies native value inspection for
preparation and verification.

The clone uses SSH. Follow the [Molecule guide](../../README.md#set-up-windows-testing) and use
selector `power_policy/windows`.

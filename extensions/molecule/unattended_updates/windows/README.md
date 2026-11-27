# Windows unattended-update policy acceptance

Uses the public role and shared disposable Windows 11 lifecycle over SSH.
Checks immediate rolling pause, six UTC timestamps, Local Service identity,
boot/daily renewal, task execution, unchanged convergence and effective removal.
Registration must also start the daily renewal cycle on an already-running host;
an immediate registry write alone must not defer recurring renewal until a boot.
The same seam checks moving local active hours, AU policy, all four update/reboot
combinations and independence of the controls.
Preparation sets foreign `NoAutoUpdate` policy on the disposable guest to avoid
background installation racing the known-baseline check. The role must preserve
that foreign value while changing its own controls. This tests local owned
policy, not automatic installation under external policy.
After effective reversal, the scenario supplies ordinary Windows active-hours
preferences and repeats allowed-reboot policy. Those native preferences must
remain intact when no owned writer or AU suppression remains.

Native task actions are triggered for observations rather than moving the clock
or waiting days. These checks prove configuration and execution, not universal
background reboot blocking. Deadlines and missed renewals remain limitations.

Explicit maintenance while paused must preserve the six timestamps and report its
actual zero-install outcome against a separately observed applicable baseline.
An empty result alone does not establish update currency.

Use `molecule test -s unattended_updates/windows` after the
[shared setup](../../README.md#set-up-windows-testing).

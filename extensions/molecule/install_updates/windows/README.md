# Windows explicit-update acceptance

Runs the public role through SSH on a disposable Windows 11 clone. Preparation
removes this collection's pause and suppresses background reboots, then requires
real applicable critical/security/rollup updates. No source template is changed.
The disposable fixture sets the native foreign `NoAutoUpdate` policy to prevent
background installation competing with explicit maintenance. It does not pause
manual updates or disable services.

Convergence requests maintenance without reboot permission, independently checks
boot identity, and saves that first outcome. It then permits required reboots,
reconnects and saves the completed outcome. Idempotence repeats the same sequence.
Verification reads native Windows Update history and pending-reboot state and
requires an installed baseline update plus an observed reboot-requiring first
run and a completed reboot.

Reboot observations use native WUA `SystemInfo` through task-scoped SYSTEM
`runas`; the ordinary SSH token cannot activate it. A residual CBS registry key
alone is not authoritative: it can remain after WUA and native package state
report completion.

No applicable baseline, no required reboot or missing native history leaves
acceptance incomplete. A successful empty scan is not installation evidence.
The paused no-op interaction is checked in `unattended_updates/windows`.

Use `molecule test -s install_updates/windows` after the
[shared setup](../../README.md#set-up-windows-testing).

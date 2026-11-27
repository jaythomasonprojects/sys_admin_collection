# Windows Time acceptance

Runs the public `time_sync` role on a disposable Windows 11 clone through SSH.
Checks local and effective W32Time configuration for the explicit test upstream,
client enablement, automatic/running service state, unchanged repeat behaviour
and disabled-role preservation. Repetition must preserve the service process.

The scenario reports the observed source separately. Configured policy does not
prove successful upstream synchronisation. External domain policy is outside
this local client configuration test.

Use `molecule test -s time_sync/windows` after the
[shared setup](../../README.md#set-up-windows-testing).

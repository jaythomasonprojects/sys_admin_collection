# unattended_updates Linux acceptance

This scenario verifies rendered native APT policy and timer state for
`jaythomasonprojects.sys_admin.unattended_updates` on Ubuntu 24.04/26.04 VMs. It also
verifies rejection of unsupported operating systems and excluded distributions
through rescued role inclusions with synthetic facts.

It checks ordinary idempotence, string `'false'` inputs (as an INI inventory
or `-e` gives them), and native origin policy on APT hosts. Preparation stops,
disables and masks both native APT timers; enabled policy must recover them.
Disabled policy must preserve their enabled/running state and package policy.
Use selector `unattended_updates/linux` with the
[shared test procedure](../../README.md#run-the-affected-scenario).

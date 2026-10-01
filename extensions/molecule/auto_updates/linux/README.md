# auto_updates Molecule scenario

This scenario verifies rendered native auto-update configuration and DNF timer
state for `jaythomasonprojects.sys_admin.auto_updates` on Ubuntu and Fedora. It
also verifies explicit rejection of unsupported operating systems and Linux
package managers through rescued role inclusions with synthetic facts.

It checks ordinary idempotence, string `'false'` inputs (as an INI inventory
or `-e` gives them), and native origin policy on APT hosts. Use selector `auto_updates/linux` with the
[shared test procedure](../../README.md#run-the-affected-scenario).

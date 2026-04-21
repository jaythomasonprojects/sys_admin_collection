# config_ssh Molecule placeholder

This role does not have an enabled Molecule scenario yet.

## Why it is deferred

`config_ssh` writes SSH and SSHD drop-ins under `/etc/ssh`, validates server
config with `sshd -t`, and notifies an `sshd` service restart. A reliable
Molecule scenario needs a container image that ships a predictable `sshd`
package layout and an executable service baseline for the restart handler.

The current collection scaffold uses lightweight Docker containers for user and
package validation, which is not a stable fit for those SSHD-specific checks.

## Next step

Add a dedicated SSH-capable test image or alternate container harness, then wire
an `extensions/molecule/config_ssh/` scenario around that image.

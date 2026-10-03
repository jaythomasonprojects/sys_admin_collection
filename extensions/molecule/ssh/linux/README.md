# ssh Molecule scenario

This scenario uses Debian 12, Ubuntu 22.04, and Fedora 44 systemd containers.
Preparation restores packaged main files, preserves vendor drop-ins, and seeds
a neutral cloud-init banner setting. Convergence uses a non-root caller with
passwordless sudo rather than play-wide escalation.

## Acceptance checks

- The root-owned, mode `0640` managed server file is
  `/etc/ssh/sshd_config.d/99-sys-admin-sshd.conf`. Main, vendor, and unrelated files
  retain contents, ownership, and modes.
- Native effective output checks representative authentication, access, and
  session settings on the conflict-free packaged layout.
- Invalid updates restore previous managed contents and metadata. A rejected
  first write leaves no managed file. Invalid foreign includes remain untouched.
  Rejections preserve the running PID and leave no managed backup files.
- A valid changed policy changes effective output and the service PID. An
  identical repeat preserves the PID; Molecule idempotence reports zero changes.
- An isolated earlier authentication directive wins by native first-value
  precedence and remains unchanged. The role does not reconcile that conflict.
- Fedora native debug parsing loads `50-redhat.conf` and the system crypto-policy
  file. Effective crypto settings match the packaged baseline; vendor files are
  not deleted to make tests pass. Fedora still rejects non-22 server ports.
- Disabled management, host-key preservation, check-mode non-mutation, supported
  platform rejection, and Linux client host-override ordering remain covered.

Fixtures are restored in `always` blocks. The full test sequence destroys all
three disposable instances.

## Why these checks remain

Verification runs the whole role with shared inputs in `molecule.yml`. Native
effective policy replaces rendered-line and package checks. Non-default session
values show that managed policy takes effect, not just that package defaults work.
One baseline checks file and host-key preservation across the workflow.

The three rejection cases cover existing-file rollback, first-write removal,
and invalid foreign policy. File checks run before fixture recovery can hide a
role edit. One service PID spans all rejection cases, and a handler flush exposes
queued restarts. The delayed-restart case covers a foreign edit after deployment
validation. Check mode and disabled runs come last so
normal deployment cannot hide their writes. Molecule idempotence checks reported
changes. PID checks also detect restarts that Ansible did not report.

## Coverage limits

The scenario assumes the packaged main file loads drop-ins. The role does not
check or repair custom include layouts. The scenario does not cover arbitrary
include graphs, universal effective-policy enforcement, concurrent edits, or
independent reloads during deployment. Containers do not prove real SSH login
access, alternate Fedora SELinux port management, or recovery of an overwritten
main file. Native validation checks syntax, not access for every `Match` context.

Recovery requires independent operator restoration of the main file and lost
site policy. Adding an include or deploying the drop-in does not recover lost
configuration. See the [operator recovery procedure](../../../../roles/ssh/README.md#recover-an-overwritten-linux-main-file).
Windows runtime acceptance and the full publication gate are separate checks.

Use selector `ssh/linux` with the
[shared test procedure](../../README.md#run-the-affected-scenario).

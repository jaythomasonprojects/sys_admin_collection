# Task 7 Report

## Scope

- Made `time_sync` a Linux-only Debian/Ubuntu ntpsec capability.
- Removed package and service opt-outs, making package, configuration, and
  service lifecycle role-owned.
- Converted the Molecule scenario to a privileged systemd runtime contract.
- Documented the narrowed interface and migration.

## Test-first Evidence

The scenario first removed the package and service opt-outs and added an
unsupported Linux distribution assertion. It failed against the prior role
because it configured the simulated Fedora host instead of rejecting it.

## Final Verification

The scoped Molecule invocation used
`ANSIBLE_COLLECTIONS_PATH=/tmp/opencode/time-sync-collection`, whose collection
entry is a symlink to this checkout.

| Command | Result | Evidence |
| --- | --- | --- |
| `ansible-lint .` | Pass | `0 failure(s), 0 warning(s)` at production profile. |
| `yamllint .` | Pass | Exit status 0 with no output. |
| `ANSIBLE_CONFIG=ansible.cfg ANSIBLE_COLLECTIONS_PATH=/tmp/opencode/time-sync-collection molecule test -s time_sync` | Pass | Converge installed `ntpsec`, configured the requested pool, enabled and started `ntpsec`, and rejected the simulated Fedora distribution. Idempotence reported zero changes and verify passed. |

Ubuntu's `ntpsec` package provides `ntpsec.service`, not `ntp.service`; the role
and runtime assertions therefore own the package-provided `ntpsec` unit.

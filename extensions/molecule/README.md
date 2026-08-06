# Molecule harness guide

`extensions/molecule/create_user/` is the reference harness for this
collection.

## Shared pattern

- `extensions/molecule/config.yml` holds the shared dependency, provisioner,
  verifier, test sequence, and shared state for every scenario in this
  collection.
- Keep each scenario's `molecule.yml` limited to scenario-specific runtime
  details such as the driver, image, and any scenario-only overrides.
- Keep only genuinely shared explanation here. What an individual scenario
  proves lives in that scenario's own directory. A per-scenario catalogue in
  this guide drifts from `extensions/molecule/` as scenarios are added and
  removed.

## What the reference harness proves

The `create_user` scenario is the baseline example for roles that can be
validated in a lightweight Docker container:

- repo-local tooling from `.venv`
- Docker driver
- converge + idempotence + verify flow
- explicit prepare and cleanup playbooks
- verify assertions that inspect the runtime state directly

## Runtime assumptions for future scenarios

Future scenarios should satisfy these assumptions before they copy the
`create_user` pattern:

1. The image is stable under Molecule's Docker driver and can stay alive with a
   long-running command such as `sleep infinity`.
2. The image already includes the runtime Ansible needs for remote execution
   (for example Python and a usable privilege-escalation path).
3. The role can be validated without a full init system unless the scenario
   intentionally introduces one.
4. Any role that depends on package-manager behavior, service management, or
   SSHD layout needs an image that makes those behaviors deterministic; if not,
   keep the scenario deferred and document the missing capability in shared
   docs.
5. If a lightweight role only needs one missing package (for example `git` for
   `community.general.git_config`), install it during `prepare` instead of
   building a scenario-local image.

## Deferred coverage gaps

### `install_app` Flatpak coverage

The first supported `install_app` scenario intentionally proves only native OS
package installation. Promote Flatpak coverage only after the harness has all of
the following:

1. an image with a working `flatpak` binary under Docker
2. a predictable Flatpak remote that can be seeded during the scenario
3. fixture refs that are stable enough to verify without relying on flaky
   external state

## Release gate

Before publishing, lint, build, then run every scenario:

```bash
ansible-lint .
yamllint .
ansible-galaxy collection build --force
ANSIBLE_CONFIG=ansible.cfg molecule test --all
```

`--all` discovers whatever scenarios exist under `extensions/molecule/`, so it
stays correct as roles are added or removed. While iterating, run a single
scenario with `ANSIBLE_CONFIG=ansible.cfg molecule test -s <scenario>`.

A scenario that cannot pass under Docker belongs in Deferred coverage gaps
above, with its missing capability named. Do not skip it silently.

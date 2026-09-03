# Molecule harness guide

`extensions/molecule/local_accounts/` is the reference harness for this
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

The `local_accounts` scenario is the baseline example for roles that can be
validated in a lightweight Docker container:

- repo-local tooling from `.venv`
- Docker driver
- converge + idempotence + verify flow
- explicit prepare and cleanup playbooks
- verify assertions that inspect the runtime state directly

## Scenario conventions

Scenarios must test supported behaviour, idempotence, and explicit
unsupported-platform rejection. Test runtime state rather than parsing the
static task tree. Do not add test-only package or service opt-outs: scenarios
must exercise the role's supported behaviour.

Scenarios assert platform `fail_msg` strings verbatim. A role rename therefore changes the role
and its scenario assertion in the same commit, along with the scenario directory name and
`scenario.name`.

## Runtime assumptions for future scenarios

Future scenarios should satisfy these assumptions before they copy the
`local_accounts` pattern:

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

## Deferred coverage gaps

### `install_app` Flatpak coverage

The first supported `install_app` scenario proves native package installation,
npm prerequisite ownership, and Debian installer validation and skipping.
Promote Flatpak coverage only after the harness has all of the following:

1. an image with a working `flatpak` binary under Docker
2. a predictable Flatpak remote that can be seeded during the scenario
3. fixture refs that are stable enough to verify without relying on flaky
   external state

## Release gate

Before publishing, lint, run every scenario, complete Windows integration
testing, then build:

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg MOLECULE_GLOB='extensions/molecule/**/molecule.yml' molecule test --all
ansible-galaxy collection build --force
```

`MOLECULE_GLOB` makes `--all` discover whatever scenarios exist under
`extensions/molecule/`, so it stays correct as roles are added or removed.
While iterating, run a single scenario with
`ANSIBLE_CONFIG=ansible.cfg molecule test -s <scenario>`.

Complete Windows integration testing as described in `AGENTS.md` before the
collection build.

A scenario that cannot pass under Docker belongs in Deferred coverage gaps
above, with its missing capability named. Do not skip it silently.

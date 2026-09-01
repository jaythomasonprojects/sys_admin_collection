# sys_admin

## Project Overview

Reusable Ansible Galaxy collection (`jaythomasonprojects.sys_admin`) of system-administration roles.
For Ansible guidance use the `ansible-expert` skill.

## Stack

- Ansible >=2.18 (`ansible <14` pinned for molecule-plugins compatibility)
- Molecule (Docker driver), ansible-lint, yamllint
- Python 3 venv for tooling (no uv/package build)

## Layout

- `roles/`: role directories, each with tasks/, handlers/, defaults/, meta/, and a `README.md`
  (required by Galaxy import)
- `extensions/molecule/`: per-role Molecule test scenarios
- `meta/runtime.yml`: collection metadata and Ansible version requirement
- `galaxy.yml`: collection manifest (version source of truth)
- `CHANGELOG.rst`: versioned release notes

## Commands

```bash
. .venv/bin/activate
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s <scenario>   # per-change gate
ANSIBLE_CONFIG=ansible.cfg MOLECULE_GLOB='extensions/molecule/**/molecule.yml' molecule test --all  # pre-publish gate only
ansible-galaxy collection build --force --output-path dist
ansible-galaxy collection publish dist/jaythomasonprojects-sys_admin-*.tar.gz \
  --token "$(tr -d '\n' < ~/.ansible/galaxy_token)"
```

## Test gate

Molecule invocations carry `ANSIBLE_CONFIG=ansible.cfg`, as the release gate in
`extensions/molecule/README.md` does. `ansible.cfg` sets `collections_path` relative to the repo
root, so without it the collection under test can resolve to an installed copy instead of this
checkout. Read `extensions/molecule/README.md` before debugging the harness: it holds the shared
scenario pattern, the reference harness, the runtime assumptions for new scenarios, and the
deferred coverage gaps.

- The gate for a change is `ansible-lint .`, `yamllint .`, and the scenario covering the change.
  `molecule test --all` is the pre-publish gate, not a per-change one.
- A scenario failing for reasons unrelated to your change is a report, not a block. Name it, say why
  it is unrelated, and continue.
- No scenarios are currently known-failing. Record one here if it recurs, and remove it once fixed.

## Windows Integration Testing

Molecule uses Docker and cannot execute Windows role tasks. Validate Windows
changes against Proxmox VM `101` at `192.168.41.103`: restore snapshot
`fresh`, test via WinRM, inspect the resulting configured-user registry
mapping, then restore `fresh` again. The first user-configuration pass rotates
the bootstrap account to its vaulted password, so reconnect before later tasks.

## Project conventions

- FQCN always: `ansible.builtin.apt`, not `apt`
- Single quotes; double only when nested in single quotes or escaping characters
- Explicit `state: present` / `state: absent` on every module where it is optional
- Multi-line map syntax always, even single-pair maps; sort variables alphabetically
- `become: true` at task level unless every task in the play requires it
- Task names: action verb, capitalised, no trailing period, no role prefix
- Secrets: `group_vars/<group>/vars` (all vars; sensitive ones reference `vault_` equivalents via
  Jinja2) + `group_vars/<group>/vault` (vault-prefixed vars, encrypted)

Play key order: `hosts` → host options (alphabetical) → `pre_tasks` → `roles` → `tasks`

Task key order: `name` → module → parameters → `loop` → task options (alphabetical) → `tags`

## Role design

- `tasks/main.yml` validates the supported platform and dispatches to `tasks/linux/main.yml` or `tasks/windows/main.yml`.
- Add focused task files only for substantial responsibilities, independently selectable capabilities, or multi-subsystem workflows.
- Capability roles own required packages or features, configuration, validation, firewall access, and service state.
- Booleans express desired policy or optional capabilities, never suppression of required implementation steps.
- Structured variables represent repeated policy such as users, applications, shares, and role-owned custom services.
- Unsupported platforms fail explicitly. Each managed artefact has one owning role.
- Every role README records the role guarantee, ownership, supported platforms, implementation map, interface, invariants, and migration notes.

## Release and versioning

`galaxy.yml` `version` is the source of truth for the collection version. `CHANGELOG.rst` is
newest-on-top, one section per release. The two must never drift: every version bump ships with a
matching changelog entry, and both live in the same commit as the change they release.

Bump rules (semver, `0.x.y`):

- New role or plugin, or a breaking change to a role's public interface (renaming/removing a default
  variable, changing default behaviour) → minor bump, `0.x.0` → `0.(x+1).0`.
- Bug fix or backward-compatible role tweak → patch bump, `0.x.y` → `0.x.(y+1)`.
- Test-only, dev-infra, editor config, docs, or CI changes → no bump and no changelog entry. These
  do not change shipped collection behaviour.

Do not push a version bump separately from its change. Before publishing, run the full validation in
`README.md` (lint plus every Molecule scenario), then follow its Publish section; the committed
`galaxy.yml` version is what gets packaged.

## Tooling

`requirements-test.txt` pins `ansible <14`: ansible-core 2.21 drops `invocation` from registered
results, which breaks the molecule-plugins docker create playbook.

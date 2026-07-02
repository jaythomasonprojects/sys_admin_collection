# AGENTS.md

Reusable Ansible Galaxy collection (`jaythomasonprojects.sys_admin`) of system-administration roles. For Ansible guidance use the `ansible-expert` skill.

## Project conventions

- FQCN always: `ansible.builtin.apt`, not `apt`
- Single quotes; double only when nested in single quotes or escaping characters
- Explicit `state: present` / `state: absent` on every module where it is optional
- Multi-line map syntax always, even single-pair maps; sort variables alphabetically
- `become: true` at task level unless every task in the play requires it
- Task names: action verb, capitalised, no trailing period, no role prefix
- Secrets: `group_vars/<group>/vars` (all vars; sensitive ones reference `vault_` equivalents via Jinja2) + `group_vars/<group>/vault` (vault-prefixed vars, encrypted)

Play key order: `hosts` → host options (alphabetical) → `pre_tasks` → `roles` → `tasks`

Task key order: `name` → module → parameters → `loop` → task options (alphabetical) → `tags`

## Release and versioning

`galaxy.yml` `version` is the source of truth for the collection version. `CHANGELOG.rst` is newest-on-top, one section per release. The two must never drift: every version bump ships with a matching changelog entry, and both live in the same commit as the change they release.

Bump rules (semver, `0.x.y`):

- New role or plugin, or a breaking change to a role's public interface (renaming/removing a default variable, changing default behaviour) → minor bump, `0.x.0` → `0.(x+1).0`.
- Bug fix or backward-compatible role tweak → patch bump, `0.x.y` → `0.x.(y+1)`.
- Test-only, dev-infra, editor config, docs, or CI changes → no bump and no changelog entry. These do not change shipped collection behaviour.

Do not push a version bump separately from its change. Before publishing, run the full validation in `README.md` (lint plus every Molecule scenario), then follow its Publish section; the committed `galaxy.yml` version is what gets packaged.

## Tooling

`requirements-test.txt` pins `ansible <14`: ansible-core 2.21 drops `invocation` from registered results, which breaks the molecule-plugins docker create playbook.

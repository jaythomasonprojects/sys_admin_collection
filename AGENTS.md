# AGENTS.md

Reusable Ansible Galaxy collection (`jaythomasonprojects.sys_admin`) of system-administration roles. See `README.md` for setup, Molecule, lint, build, and publish commands, and `.github/instructions/ansible.instructions.md` for Ansible coding conventions.

## Release and versioning

`galaxy.yml` `version` is the source of truth for the collection version. `CHANGELOG.rst` is newest-on-top, one section per release. The two must never drift: every version bump ships with a matching changelog entry, and both live in the same commit as the change they release.

Bump rules (semver, `0.x.y`):

- New role or plugin, or a breaking change to a role's public interface (renaming/removing a default variable, changing default behaviour) → minor bump, `0.x.0` → `0.(x+1).0`.
- Bug fix or backward-compatible role tweak → patch bump, `0.x.y` → `0.x.(y+1)`.
- Test-only, dev-infra, editor config, docs, or CI changes → no bump and no changelog entry. These do not change shipped collection behaviour.

Do not push a version bump separately from its change. Before publishing, run the full validation in `README.md` (lint plus every Molecule scenario), then follow its Publish section; the committed `galaxy.yml` version is what gets packaged.

## Tooling

Install with `pip install -r requirements-test.txt`, which pins the supported Ansible, Molecule, and linter versions. Note the `ansible <14` constraint documented inline in that file: ansible-core 2.21 drops `invocation` from registered results, which breaks the molecule-plugins docker create playbook.

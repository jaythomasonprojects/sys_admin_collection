# Final Fix Report

## Commit

- Fix commit: `ef2dbd1 fix: enforce role policy contracts`

## Changed Files

- `CHANGELOG.rst`
- `extensions/molecule/config_systemd_units/converge.yml`
- `extensions/molecule/config_systemd_units/prepare.yml`
- `extensions/molecule/install_app/converge.yml`
- `roles/config_systemd_units/tasks/main.yml`
- `roles/install_app/README.md`
- `roles/install_app/tasks/npm.yml`

## RED Evidence

- `. .venv/bin/activate && molecule test -s install_app` failed before the
  npm validation was added. The versioned `is-number@7.0.0` specification was
  installed on Ubuntu and Fedora, and the rejection assertion failed because
  no rescue fact was set.
- `. .venv/bin/activate && molecule test -s config_systemd_units` failed
  before the unit preflight was added. A missing
  `molecule-missing-mask.service` was masked successfully, and its rejection
  assertion failed.

## GREEN Evidence

- `. .venv/bin/activate && molecule test -s install_app` passed. The scenario
  rejects the versioned specification through the public role interface,
  retains the global Linux installation check for `is-number`, and passes
  idempotence and verification on Ubuntu and Fedora.
- `. .venv/bin/activate && molecule test -s config_systemd_units` passed. The
  scenario rejects missing standard, masked, and removal policies through the
  public role interface, and passes idempotence and verification. Its removal
  fixture includes a vendor fallback unit so the managed `/etc` file can be
  removed while the declared unit remains present on the idempotence rerun.

## Validation Outcomes

- `. .venv/bin/activate && ansible-lint roles/install_app roles/config_systemd_units extensions/molecule/install_app extensions/molecule/config_systemd_units`: passed, 0 failures and 0 warnings in 22 processed files.
- `. .venv/bin/activate && yamllint roles/install_app roles/config_systemd_units extensions/molecule/install_app extensions/molecule/config_systemd_units`: passed with no output.
- `. .venv/bin/activate && ansible-lint .`: passed, 0 failures and 0 warnings in 135 processed files.
- `. .venv/bin/activate && yamllint .`: passed with no output.
- `. .venv/bin/activate && molecule test --all`: passed, 12 scenarios with 0 failures.
- `. .venv/bin/activate && ansible-galaxy collection build --force --output-path dist`: passed, created `dist/jaythomasonprojects-sys_admin-0.6.0.tar.gz`.
- `git diff --check`: passed with no output.

## Notes

- Molecule reported existing missing scenario dependency, prepare, or cleanup
  playbooks, but all scenario failure counts were zero.
- Molecule and ansible-lint reported pre-existing collection-version and custom
  yamllint-configuration warnings. Neither command reported validation
  failures.

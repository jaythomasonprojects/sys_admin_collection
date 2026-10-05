# sys_admin

## Scope and contracts

- `jaythomasonprojects.sys_admin` ships capabilities; consuming playbooks supply environment policy.
  Keep account names, package selections, and shares out of collection defaults.
- Keep public documentation and examples generic, without site-specific hosts or repository assumptions.
- Ubuntu and Windows are primary; platform support varies by role. Read the affected role's
  README for its contract and its scenario README for acceptance limits.
- Planning policy lives in `openspec/config.yaml`.

## Local tools and worktrees

- Use `python3 -m venv .venv`, then `. .venv/bin/activate` and
  `pip install -r requirements.txt`. This is not a uv package project.
- Keep `ansible <14`: ansible-core 2.21 removes registered `invocation` data used by the
  Molecule Docker driver's create playbook. The collection itself requires ansible-core >=2.18.
- Keep `molecule-proxmox==1.2.1`. Test dependency constraints live in `requirements.txt`.
- Run `uv run --no-project scripts/setup_worktree.py` in a new worktree, or the VS Code
  `Setup: worktree` task. It refuses tracked paths and existing conflicting destinations.
- The helper shares `.venv`, `.env`, `openspec`, the Proxmox secrets file, CA bundle, and
  Windows public identity file. Dependency and OpenSpec edits affect all linked worktrees.
  `.ansible/` and Molecule lifecycle state must remain worktree-local.
- Export test variables explicitly; `.env` is not loaded automatically. Before Windows setup,
  read `extensions/molecule/README.md#set-up-windows-testing` for credentials and prerequisites.

## Verify the installed checkout

Run from the repository root with `.venv` active. Tests resolve FQCNs through the installed
collection in `.ansible/collections`, not directly through the edited role files.
After role changes, build and install before testing:

```bash
ansible-galaxy collection install -r requirements.yml -p ./.ansible/collections --force
ansible-galaxy collection build --force --output-path dist
version=$(sed -n "s/^version: '\(.*\)'/\1/p" galaxy.yml)
ansible-galaxy collection install "dist/jaythomasonprojects-sys_admin-${version}.tar.gz" -p ./.ansible/collections --force
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts/linux
```

- Substitute `<role>/linux` or `<role>/windows` for the focused scenario selector.
  Always set `ANSIBLE_CONFIG=ansible.cfg`; it selects the local collection but does not refresh it.
- Run scenarios sequentially, including across worktrees: Linux scenarios reuse container names,
  and Windows scenarios reserve VMIDs. Read `extensions/molecule/README.md` before test setup or recovery.
- Before publishing, run the full gate, not just the affected scenario:
  `ANSIBLE_CONFIG=ansible.cfg MOLECULE_GLOB='extensions/molecule/**/molecule.yml' molecule test --all`.
- Documentation-only changes need factual, link, example, lint, and archive checks, not infrastructure runs.
  Report unrelated failures with their cause; do not claim an incomplete release gate passed.

## Molecule pitfalls

- Shared configuration is `extensions/molecule/config.yml`. Linux needs Docker access;
  service tests need privileged containers and cgroup support.
- Before scenario edits, follow `extensions/molecule/README.md#maintain-scenarios`.
  Use `local_accounts/linux` as the lightweight reference. Assert supported-platform `fail_msg`
  verbatim; role renames also change the scenario path, `scenario.name`, and assertions.
- Windows uses Proxmox linked clones of the configured template. Run fixture-mutating helpers
  only against identified disposable clones, never the template or an arbitrary workstation.
- Do not replay create against an existing Windows clone: the driver can return the source VMID.
  Local state deletion does not dispose of API resources. Confirm clone and disk disposal through
  the API, following `extensions/molecule/README.md#troubleshoot-and-recover`.
- The driver can discover APIPA before DHCP settles. Confirm the clone identity and API-observed
  DHCP address before correcting only its disposable connection record.
- SSH and account-key scenarios use WinRM so SSH edits do not break management access.
  Reset the connection after credential rotation. Keep API TLS verification enabled.
- Generated inventory and lifecycle records can contain secrets; do not print them in full or commit them.
- Windows SMB refreshes stored passwords and reports changes honestly; its functional repeat
  replaces zero-change idempotence. Verify mappings under the configured user's SID and profile.

## Role design and YAML conventions

- Keep the full platform gate in `tasks/main.yml`, then dispatch to OS implementations.
  `meta/argument_specs.yml` owns types, required options, and choices; assertions cover platform
  and cross-field rules that specifications cannot express.
- Put distribution data in `vars/`; use `ansible.builtin.first_found` with distribution then
  OS-family filenames. Split task files only for different procedures, not different data.
- Capabilities own packages, configuration, validation, firewall access, and service state.
  Give each artefact one owner. Public inputs describe policy, not module-call parameters.
- Name roles for outcomes, without prefixes. Support one input shape unless a real consumer needs another.
- `<role>_enabled: false` reverts safely owned policy where possible; otherwise it skips without undoing.
  Document that distinction. Exposure-increasing capabilities default to `false`.
  `auto_login` uses empty user values instead; Windows `auto_updates` ignores the Linux enable flag.
- Put cohesive shell and PowerShell algorithms in static role files with parameters.
  Use templates only when source must vary; use scoped variables instead of temporary `set_fact` aliases.
- Use FQCNs, single-quoted YAML strings, multiline maps, and alphabetically sorted variables.
  Set optional module state explicitly. Put `become: true` on tasks unless the whole play needs it.
- Task names use a capitalised action verb, no trailing full stop, and no role prefix.
  Task order: `name`, module and parameters, `loop`, alphabetised options, `tags`.
  Play order: `hosts`, alphabetised host options, `pre_tasks`, `roles`, `tasks`.
- Each role README is the published variable reference on Galaxy. Keep its purpose, platforms,
  full variable reference matching `meta/argument_specs.yml`, enable behaviour (including what
  `false` undoes), and caveats current. Put migration notes in `CHANGELOG.rst`.

## Release and versioning

- `galaxy.yml` owns the version. Keep its bump and a matching newest-first `CHANGELOG.rst` entry
  in the same commit as the released change.
- For `0.x.y`: new roles or plugins and breaking interfaces or defaults require `0.(x+1).0`.
  Backward-compatible role fixes require `0.x.(y+1)`.
  Tests, tooling, editor configuration, docs, and CI alone require no bump or changelog entry.
- Publish only the exact versioned archive installed for the successful full release gate.
  Do not rebuild changed source and publish it as the tested archive.

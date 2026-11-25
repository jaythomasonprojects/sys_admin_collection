# sys_admin

## Scope and contracts

- `jaythomasonprojects.sys_admin` publishes only `ssh`, `time_sync`, `auto_updates` and
  `install_app`. Consumers own account lifecycle, shares and workstation policy. Keep public
  examples and collection defaults free of site-specific policy.
- Supported targets are Ubuntu 24.04/26.04 and Windows, within each role's contract. `time_sync` is
  Ubuntu-only. Read the affected role's README and scenario README before edits.
- SSH configures installed OpenSSH and existing-account keys, including Windows profiles and key
  ACLs. Callers own installation, host-key initialisation and initial access.
- Windows `auto_updates` installs updates immediately and may reboot. Its Linux enable flag does not
  suppress Windows execution; omit the role to avoid that action.
- Read `openspec/config.yaml` for planning policy. OpenSpec is globally Git-ignored and shared
  across linked worktrees; historical specs and reports can describe retired interfaces.

## Local tools and worktrees

- This is not a uv package project. Use `python3 -m venv .venv` and
  `pip install -r requirements.txt` after activation. Preserve the tested controller constraints in
  that file; the collection's ansible-core minimum is a separate contract.
- Complete [tool setup](extensions/molecule/README.md#set-up-the-tools), then run `source .envrc`
  from the repository root once per shell. Activation sets the native driver's module path, local
  development collection link, dependency path and worktree-local Ansible home.
- Molecule loads `.env.yml`; `.envrc` does not load it into arbitrary commands. Keep API credentials
  in `.config/molecule/proxmox.yml`, separate from ordinary settings.
- In a new worktree, run `uv run --no-project scripts/setup_worktree.py`. Its `SHARED_PATHS` defines
  shared settings, credentials and tools. Tool installs and OpenSpec edits affect linked worktrees;
  collection links, installed collections and Molecule lifecycle state stay worktree-local.
- Editor commands live in `.vscode/tasks.json`. `Lint: format` runs `yamllint`, not a formatter.
  Python helper checks are `uvx ruff check scripts`, `uvx ruff format --check scripts` and
  `uvx pyright`; they do not replace Ansible lint or Molecule acceptance.

## Verify the active checkout

Activation links `.ansible/development/ansible_collections/jaythomasonprojects/sys_admin` to this
checkout. Focused tests resolve FQCNs through that link before installed dependencies in
`.ansible/collections`. Uncommitted edits are immediately visible; no build or reinstall is needed.
Molecule's implicit local installation is disabled.

Molecule creates and deletes real Proxmox VMs. Agree a test window and run sequentially across
worktrees and consuming repositories. Coordinate shared tool and collection installs too.

```bash
source .envrc
ansible-lint --offline .
yamllint .
molecule test -s time_sync/linux
```

- Substitute `<role>/linux` or `<role>/windows` for the focused selector. Linux acceptance needs
  native VM kernels and service conditions, not Docker targets.
- Before running, editing or recovering scenarios, read the relevant setup,
  [maintenance](extensions/molecule/README.md#maintain-scenarios) or
  [recovery](extensions/molecule/README.md#troubleshoot-and-recover) section. Use `time_sync/linux`
  as the lightweight reference; assert platform `fail_msg` verbatim.
- Documentation and scaffolding checks use local lint, links, examples and archive inspection, not
  VM runs. Report unavailable checks and unrelated failures without claiming acceptance.

## Molecule pitfalls

- `extensions/molecule/config.yml` owns shared configuration; `create.yml` and `destroy.yml` wrap
  the native driver. Trust prepared templates during routine tests: no approved-settings audit or
  before/after fingerprints. Check source eligibility and disposable clone ownership automatically;
  inspect a private approved record manually only when diagnosing a relevant failure. Tests leave
  sources stopped and unchanged, but do not certify full configuration equality. Source preparation
  needs separate authorisation; escalate clone-start failures without changing source settings.
- Proxmox selects clone IDs. Never replay creation against an existing clone: the driver can return
  the source VMID. Independently verify VMID, name, node, pool and owned disks before preparation,
  clearing inherited clone protection or deletion. API access needs `Pool.Audit`. Local state
  deletion is not resource disposal; confirm clone and disk absence through the API.
- Preserve verified API TLS, independently pinned SSH host keys, the initial SSH socket probe and
  API-observed DHCP addresses. APIPA is not a usable lease. Correct addresses only in verified
  disposable connection records, not templates. Generated inventories can contain secrets; keep
  complete records out of logs and Git.
- Keep DHCP release before clone disposal and the SSH scenarios' management-access cleanup. The
  shared network has limited leases; SSH disconnect is evidence of the release attempt, not a
  receipt from the DHCP server.
- Ubuntu 26.04 inventory uses installed `/usr/bin/sudo.ws` for sudo-rs prompt compatibility. Keep
  system alternatives and bootstrap permissions unchanged.
- Windows SSH tests use SSH, detached service activation and fresh reconnects, not WinRM. Reset
  connections after credential rotation. In `roles/ssh/tasks/windows/server.yml`, retain the
  validators' task-scoped POSIX descriptor environment clearing and timeout: inherited OpenSSH
  grandparent handles can hang fatal exits; stderr redirection is insufficient.

## Role design and YAML conventions

- Keep the full platform gate in `tasks/main.yml`, before OS dispatch, even when disabled.
  `meta/argument_specs.yml` owns types, required inputs and choices; assertions cover platform and
  cross-field rules. Keep the role README's published variable reference in sync.
- Put distribution data in `vars/`, selected by `ansible.builtin.first_found`, distribution before
  OS family. Split procedures, not data. Keep cohesive shell/PowerShell algorithms in static
  parameterised files; template only varying source. Prefer scoped vars to `set_fact`.
- Name roles for outcomes without prefixes. Inputs describe policy, not module-call parameters. Use
  one input shape unless a real consumer needs another. Document whether disabling removes safely
  owned policy or skips without undoing; exposure-increasing capabilities default off.
- Use FQCNs, single-quoted YAML strings, multiline maps and alphabetically sorted variables. Set
  optional module state explicitly. Put `become: true` on tasks unless the whole play needs it.
- Task names start with a capitalised action verb, without a role prefix or trailing full stop. Task
  order: `name`, module/parameters, `loop`, alphabetised options, `tags`. Play order: `hosts`,
  alphabetised host options, `pre_tasks`, `roles`, `tasks`.

## Release and versioning

- `galaxy.yml` owns the version. For `0.x.y`, new roles/plugins and breaking interfaces/defaults
  require `0.(x+1).0`; compatible role fixes require `0.x.(y+1)`. Keep a newest-first
  `CHANGELOG.rst` entry and version bump with the released change. Tooling/tests/docs alone need
  neither. Put consumer migration notes in the changelog.
- Before publication, complete the [release gate](extensions/molecule/README.md#release-gate),
  including the full sequential `molecule test --all` with only the installed archive path selected.
  `Test: all` uses that release selection, not the development link. Verify installed contents
  against the chosen archive and record actual task paths. Publish only that exact successful
  archive. Rebuilding changed source invalidates its acceptance evidence.

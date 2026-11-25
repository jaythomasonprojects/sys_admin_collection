# sys_admin

## Scope and contracts

- `jaythomasonprojects.sys_admin` publishes only `ssh`, `time_sync`, `auto_updates` and
  `install_app`. Consumers own account lifecycle, shares and workstation policy. Keep public
  examples and collection defaults free of site-specific policy.
- Supported targets are Ubuntu 24.04/26.04 and Windows, within each role's contract. `time_sync` is
  Ubuntu-only. Before edits, read `roles/<role>/README.md` and the affected
  `extensions/molecule/<role>/<platform>/README.md`.
- SSH configures installed OpenSSH and existing-account keys, including Windows profiles and key
  ACLs. Callers own installation, host-key initialisation and initial access.
- Windows `auto_updates` installs updates immediately and may reboot. Its Linux enable flag does not
  suppress Windows execution; omit the role to avoid that action.
- Before planning or extending test coverage, read `openspec/config.yaml`: it defines agreed test
  seams and approval boundaries. OpenSpec is globally Git-ignored and shared across worktrees;
  historical specs and reports can describe retired interfaces.

## Local tools and worktrees

- `pyproject.toml` configures Ruff, not a uv package. Follow
  [tool setup](extensions/molecule/README.md#set-up-the-tools) using `python3 -m venv .venv` and
  `pip install -r requirements.txt`. Preserve its controller constraints; `meta/runtime.yml` defines
  the separate consumer ansible-core minimum.
- Run commands from the repository root in Bash and `source .envrc` once per shell. Activation
  selects the native driver's module path, collection paths and worktree-local Ansible home.
  Molecule loads `.env.yml`; arbitrary commands do not. API credentials belong separately in
  `.config/molecule/proxmox.yml`.
- In a new worktree, run `uv run --no-project scripts/setup_worktree.py`. Its `SHARED_PATHS` shares
  settings, credentials, tools and OpenSpec, so installs and planning edits affect other worktrees.
  Development links, installed collections and Molecule lifecycle state remain worktree-local.
- `.vscode/tasks.json` owns editor shortcuts. `Lint: format` checks YAML; it does not format it.
  For Python helpers use `uvx ruff check scripts`, `uvx ruff format --check scripts` and `uvx pyright`.

## Verify the active checkout

Activation links this checkout under `.ansible/development`, searched before `.ansible/collections`.
Focused tests see uncommitted edits without a build or reinstall; Molecule's implicit local
installation is disabled. Use `molecule -vv` task paths to diagnose selection of another copy.

Molecule creates and deletes real Proxmox VMs. Agree a test window and run sequentially across
worktrees and consuming repositories; coordinate shared tool and collection installs too.

```bash
source .envrc
ansible-lint --offline .
yamllint .
molecule test -s time_sync/linux
```

- Use `<role>/linux` or `<role>/windows` for focused verification. Documentation/scaffolding changes
  use local lint, links, examples and archive inspection, not VM runs. Reserve the full suite for
  publication.
- Before VM runs, read the [setup](extensions/molecule/README.md#set-up-the-tools) and platform
  prerequisites. Before scenario edits, read
  [maintenance](extensions/molecule/README.md#maintain-scenarios); use `time_sync/linux` as the
  reference and assert platform `fail_msg` verbatim. Before retries or manual cleanup, read
  [recovery](extensions/molecule/README.md#troubleshoot-and-recover).
- `extensions/molecule/config.yml` owns shared configuration; `create.yml` and `destroy.yml` wrap
  the native driver. Trust prepared templates during routine tests, without full-settings audits.
  Source preparation needs separate authorisation; leave templates stopped and unchanged.
- Proxmox selects clone IDs. Replaying creation against an existing clone can return the source
  VMID. Independently verify ID, name, node, pool and owned disks before preparation or deletion.
  Local state deletion is not disposal: confirm clone and disk absence through the API.
- Preserve verified API TLS, independently pinned SSH host keys, the initial SSH socket probe,
  API-observed DHCP addresses, DHCP release before disposal and SSH management-access cleanup.
  Generated inventories can contain secrets; keep complete records out of logs and Git.
- Linux acceptance requires native VM kernels/service conditions. Ubuntu 26.04 inventory selects
  installed `/usr/bin/sudo.ws` for controller prompt compatibility, without changing alternatives or
  bootstrap permissions. Windows acceptance uses SSH and fresh reconnects, not WinRM.
- In `roles/ssh/tasks/windows/server.yml`, retain the validators' task-scoped POSIX descriptor
  environment clearing and timeout: inherited OpenSSH handles can hang fatal exits; stderr
  redirection is insufficient.

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

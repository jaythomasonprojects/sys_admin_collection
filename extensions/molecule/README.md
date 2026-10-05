# Test the collection with Molecule

Molecule runs Ansible roles against disposable machines and checks the result.
This collection uses Docker containers for Linux and Proxmox linked clones for
Windows. Tests do not run against your workstation inventory.

## Contents

- [How testing works](#how-testing-works)
- [Set up the tools](#set-up-the-tools)
- [Run your first Linux test](#run-your-first-linux-test)
- [Run the affected scenario](#run-the-affected-scenario)
- [Commands and files](#commands-and-files)
- [Set up Windows testing](#set-up-windows-testing)
- [Run Windows tests](#run-windows-tests)
- [Troubleshoot and recover](#troubleshoot-and-recover)
- [Maintain scenarios](#maintain-scenarios)
- [Release gate](#release-gate)

## How testing works

A **scenario** is a test case with its own configuration and playbooks. For
example, `local_accounts/linux` creates Ubuntu and Fedora containers, applies
the account role, and checks the account and SSH key files.

An **instance** is one container or VM used by a scenario. The **driver** creates
and destroys instances. Ansible configures them and checks their state.
A **fixture** is test data or a starting condition, such as an account or an
intentionally invalid configuration.

The shared `test` sequence is:

```text
dependency --> create --> prepare --> converge --> idempotence
                                                       |
                                                       v
destroy <-------- cleanup <-------- verify <------------+
```

| Phase | Purpose |
| --- | --- |
| `dependency` | Install the required Ansible collections |
| `create` | Create disposable instances with the selected driver |
| `prepare` | Set up fixtures or starting conditions, when needed |
| `converge` | Apply the role through `converge.yml` |
| `idempotence` | Repeat convergence and fail if Ansible reports changes |
| `verify` | Inspect the resulting state and assert the expected outcomes |
| `cleanup` | Remove fixtures that need explicit cleanup, when needed |
| `destroy` | Delete the test instances |

Idempotence means applying the same configuration again reports no changes.
It does not prove the configuration is correct. Verification checks the actual
outcome, such as account ownership, effective SSH policy, or service state.
Some verification playbooks also change inputs to check transitions and failures.

Windows SMB is the exception to zero-change idempotence. Windows cannot compare
stored credential secrets, so the role refreshes the password on each run.
Its scenario checks that repeated mapping works under the configured user's
security identifier (SID) and profile. It also checks failure behaviour and
scans captured logs for the synthetic test password. Those refresh changes are
not hidden.

## Set up the tools

Run commands from the collection root. Use Python 3 and the pinned test
dependencies; Ansible stays below version 14 for Docker driver compatibility.

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml -p ./.ansible/collections --force
export ANSIBLE_CONFIG=ansible.cfg
```

Activate `.venv` in each new shell. Keep `ANSIBLE_CONFIG=ansible.cfg` set for
Molecule commands. The scenario playbooks use fully qualified collection names
(FQCNs), such as `jaythomasonprojects.sys_admin.local_accounts`.

For Linux tests, install and start Docker, and allow your account to use it.
Package downloads require network access. Scenarios that check systemd services
use privileged containers and mount `/sys/fs/cgroup`. Other scenarios, including
`local_accounts/linux`, use a long-running container without a full init system.

For Windows prerequisites, see [Set up Windows testing](#set-up-windows-testing).

## Run your first Linux test

This example creates and deletes disposable Ubuntu and Fedora containers.
Do not run another scenario at the same time; Linux scenarios reuse container
names such as `ubuntu` and `fedora`.

First, build and install this checkout into the repo-local collection path:

```bash
ansible-galaxy collection build --force --output-path dist
version=$(sed -n "s/^version: '\(.*\)'/\1/p" galaxy.yml)
ansible-galaxy collection install "dist/jaythomasonprojects-sys_admin-${version}.tar.gz" \
  -p ./.ansible/collections --force
```

`ANSIBLE_CONFIG` selects that installed path. It does not copy changed role
files into it. Repeat the build and installation after editing role code,
or you may test an older copy.

Run the scenario:

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts/linux
```

Expect phase headings, Ansible task output, and play recaps for both containers.
Initial convergence normally reports changes. The idempotence phase must report
none. Verification checks the account's home, shell, keys, ownership, and modes.
The final destroy phase removes the containers. A successful command exits zero.

`prepare.yml` and `cleanup.yml` are optional. This scenario does not need them,
so "Missing playbook" notices for those hooks are expected. Do not add empty
playbooks just to silence the notices. A failure in an assertion, connection,
or driver operation is not an optional-hook notice.

## Run the affected scenario

For a role change, refresh the installed checkout as above, then run lint and
the scenario that covers the change:

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s ssh/linux
```

Use `<role>/linux` or `<role>/windows` as the selector. Run affected scenarios
sequentially. Use the [release gate](#release-gate) only before publication,
not for every change. Documentation-only changes need factual, link, example,
lint, and package checks rather than another infrastructure run.

## Commands and files

All commands below use `-s <role>/<platform>`. Set `ANSIBLE_CONFIG=ansible.cfg`
and activate `.venv` first.

| Command | What it does |
| --- | --- |
| `molecule test` | Run the scenario's complete test sequence, including destruction |
| `molecule converge` | Run dependency, create, prepare, and converge; leave instances for inspection |
| `molecule idempotence` | Repeat convergence against existing instances and reject reported changes |
| `molecule verify` | Run assertions against existing instances; do not create them first |
| `molecule destroy` | Run dependency, optional cleanup, and native driver destruction |
| `molecule matrix test` | Show one scenario's phase sequence without running it |

Use `molecule list` to list instance status across discovered scenarios. It is
not an outcome test. Use `molecule --help` or a command's `--help` for options.
The collection's recursive discovery finds `extensions/molecule/**/molecule.yml`.

For a Linux debugging session:

```bash
ANSIBLE_CONFIG=ansible.cfg molecule converge -s local_accounts/linux
ANSIBLE_CONFIG=ansible.cfg molecule verify -s local_accounts/linux
ANSIBLE_CONFIG=ansible.cfg molecule destroy -s local_accounts/linux
```

`converge` is not only a role rerun; its sequence includes creation. Do not use
it to debug an existing Windows clone without checking driver state. In
particular, do not replay Windows `create` against a clone that already exists.

| File | Responsibility |
| --- | --- |
| `extensions/molecule/config.yml` | Shared dependencies, collection path, verifier, and test sequence |
| `<role>/<platform>/molecule.yml` | Driver, instance definitions, connection settings, and sequence overrides |
| `<role>/<platform>/converge.yml` | Role invocation and test inputs |
| `<role>/<platform>/verify.yml` | Outcome assertions |
| `<role>/<platform>/prepare.yml` | Optional starting conditions |
| `<role>/<platform>/cleanup.yml` | Optional fixture cleanup, distinct from instance deletion |
| `<role>/<platform>/README.md` | The scenario's assertions and coverage limits |
| `<role>/<platform>/files/` | Static scripts that the scenario's tasks run |

The role/platform paths in this table are relative to `extensions/molecule/`.
See [Maintain scenarios](#maintain-scenarios) for the layout rules.
Molecule also writes temporary inventory and lifecycle records beneath the
project cache. These can contain connection secrets. Do not print complete
generated inventories or commit cached state.

## Set up Windows testing

Windows scenarios use the released Proxmox driver. A linked clone is a
disposable VM backed by a template disk. The template is the source, not a
test target. Routine lifecycle operations use the HTTPS API, not root SSH to
the hypervisor.

### Template and reserved identities

Use one standalone, stopped Windows template with disks that support linked
cloning. Enable the QEMU guest agent in Proxmox and Windows. Use DHCP on one
controller-reachable Ethernet interface. The driver selects the first
non-loopback IPv4 address; it does not filter automatic private IP addressing
(APIPA) addresses or choose among interfaces.

The template needs an administrator management account independent of fixture
accounts, native OpenSSH Server, key authentication, and PowerShell as the SSH
default shell. Enable Windows Remote Management (WinRM) over HTTPS with NTLM
authentication on port 5986. Before converting a
prepared guest to a template, check `ansible.windows.win_ping` over both SSH
and WinRM. Prepare management access, not the policies under test.

The current environment uses Proxmox 9.1.1, node `proxmox02`, ZFS storage
`data`, bridge `vmbr0`, pool `molecule`, and Windows 11 Pro template 100,
`win11-molecule-template`. SSH listens on port 4022. VM 101 and its former
`fresh` snapshot do not exist. Do not use the retired snapshot procedure or
alter template 100 during tests.

The reserved allocations are:

| Scenario | VMID | Clone name | Guest connection |
| --- | --- | --- | --- |
| `power_policy/windows` | 9101 | `power-policy-windows` | SSH |
| `ssh/windows` | 9102 | `ssh-windows` | WinRM |
| `local_accounts/windows` | 9103 | `local-accounts-windows` | WinRM |
| `allow_ping/windows` | 9104 | `allow-ping-windows` | SSH |
| `mount_network_share/windows` | 9105 | `mount-network-share-windows` | SSH |

Confirm each reserved VM identifier (VMID) is unused before creating a clone.
Run Windows scenarios sequentially. Never delete a VM based only on its number.

### API credentials and permissions

Keep Proxmox API credentials separate from guest credentials. If you do not
already have a secrets file, copy the [placeholder example](../../.config/molecule/proxmox.example.yaml):

```bash
umask 077
cp -n .config/molecule/proxmox.example.yaml .config/molecule/proxmox.yml
chmod 600 .config/molecule/proxmox.yml
```

Replace the placeholders in the private copy. The driver's `proxmox_secrets`
option reads `api_host`, `api_user`, `api_token_id`, and `api_token_secret`.
Git ignores `.config/molecule/proxmox.yml`, and Galaxy excludes `.config/`. Never commit
tokens, guest passwords, or private keys.

The environment uses these access control list (ACL) grants for both the
privilege-separated user and token. They are not a minimal-permissions claim:

| ACL path | Role | Propagate |
| --- | --- | --- |
| `/vms/100` | `PVETemplateUser` | No |
| `/pool/molecule` | `PVEVMAdmin` | Yes |
| `/storage/data` | `PVEDatastoreUser` | No |
| `/sdn/zones/localnetwork/vmbr0` | `PVESDNUser` | No |

These allow template inspection and cloning, allocation, power operations,
guest-agent discovery, and deletion of test VMs and disks. Provision grants
through the operator's Proxmox administration workflow.

Keep API `validate_certs: true`. If the endpoint needs a custom trust bundle,
set `REQUESTS_CA_BUNDLE`. The local `.cache/proxmox-api-ca.pem` combines trusted
roots and an independently verified missing issuer chain. Refresh it when the
endpoint chain changes; do not disable API TLS verification.

### Guest authentication and environment

The following values describe the current environment, not Molecule defaults:

```bash
export ANSIBLE_CONFIG=ansible.cfg
export REQUESTS_CA_BUNDLE="$PWD/.cache/proxmox-api-ca.pem"
export MOLECULE_PROXMOX_NODE=proxmox02
export MOLECULE_PROXMOX_POOL=molecule
export MOLECULE_PROXMOX_SECRETS="$PWD/.config/molecule/proxmox.yml"
export MOLECULE_WINDOWS_TEMPLATE_VMID=100
export MOLECULE_WINDOWS_USER=Admin
export MOLECULE_WINDOWS_SSH_PORT=4022
export MOLECULE_WINDOWS_IDENTITY_FILE="$PWD/.cache/windows-admin.pub"
export MOLECULE_POWER_POLICY_WINDOWS_VMID=9101
export MOLECULE_SSH_WINDOWS_VMID=9102
export MOLECULE_LOCAL_ACCOUNTS_WINDOWS_VMID=9103
export MOLECULE_ALLOW_PING_WINDOWS_VMID=9104
export MOLECULE_MOUNT_NETWORK_SHARE_WINDOWS_VMID=9105
```

For WinRM, load `MOLECULE_WINDOWS_PASSWORD` from an external secret source into
the test process environment. Do not put the value in committed configuration,
print it, or pass it as an Ansible command-line extra variable. For SSH, use an
agent-held key selected by a public identity file, or an external private-key
file. Its public key must be authorised in the template.

SSH and account-key scenarios use WinRM so changing SSH does not break their
management connection. If a case rotates management credentials, reset the
connection with the new credentials before later tasks.

The driver disables SSH host-key checking for disposable clones. WinRM uses
NTLM and the existing self-signed-listener exception
`ansible_winrm_server_cert_validation: ignore`. Confine both exceptions to tests;
neither permits disabling Proxmox API certificate validation. Windows scenarios
set guest connection options separately from API lifecycle operations.

## Run Windows tests

Refresh the installed checkout, configure authentication, then run each
scenario sequentially:

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s power_policy/windows
ANSIBLE_CONFIG=ansible.cfg molecule test -s ssh/windows
ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts/windows
ANSIBLE_CONFIG=ansible.cfg molecule test -s allow_ping/windows
ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share/windows
```

Each scenario README states what its assertions prove. Windows helpers require
the driver's generated inventory and instance record. Do not run fixture-mutating
helpers against the template, an old fixed IP, or an arbitrary workstation.
Past successful trials do not replace current acceptance or the release gate.

## Troubleshoot and recover

### Check the failed phase

Read the first failing task and its native error. A create or connection failure
before convergence is not evidence of a role defect. A wrong effective value
or failed verification is not a successful test just because idempotence passed.

If changes appear to have no effect, check that you rebuilt and installed the
checkout. If Docker service tests fail, check privileged-container and cgroup
support.

For Windows address discovery, inspect the clone through the API or Proxmox UI.
An address beginning with `169.254.` is APIPA, not a usable DHCP lease. Confirm
the guest-agent-observed DHCP address and the clone's identity before correcting
only its disposable connection record. Do not change the template or guess an
address. If state is incomplete, use the recovery procedure below.

### Recover a Windows clone

If creation fails before the driver writes instance state, `destroy` may have no
VMID to remove. Deleting local state does not delete the clone or its disks.

1. Inspect the reserved VMID through the authenticated API or Proxmox UI.
   Confirm the clone name, test-pool membership, and owned clone disks.
2. Stop and delete that exact test clone and its owned disks through the API or
   UI. Do not delete template disks or unrelated VMs.
3. Inspect API inventory and storage to confirm both the clone and its disks
   are absent. Confirm the template remains.
4. Run `ANSIBLE_CONFIG=ansible.cfg molecule destroy -s <role>/windows` to clear
   remaining local lifecycle state. Then rerun the scenario.

Do not replay driver create against an existing clone. The evaluated driver
can return the source VMID when the destination already exists. A successful
local destroy alone does not prove API resource disposal.

The manual orphan procedure is a documented recovery path, not a separately
verified test case.

## Maintain scenarios

Use `local_accounts/linux` as the reference for lightweight Docker tests.
Keep scenario configuration under `<role>/linux/` or `<role>/windows/` and name
the scenario to match its path. Include only platforms needed for supported
outcomes or deliberate rejection checks; `allow_ping/linux` is rejection-only.

Keep common configuration in `config.yml`. A scenario contains `molecule.yml`,
its phase playbooks, its `README.md`, and optionally `files/`:

- Each phase playbook does only its own phase job. `prepare.yml` sets starting
  conditions, `converge.yml` applies the role, and `verify.yml` checks results.
  Do not share one playbook between phases through a stage variable.
- Put tasks directly in the phase playbook. Use `block` with `when` for
  platform-specific checks. Add a task file only when two or more places include
  it, or when a loop includes it.
- Put test input variables in the phase playbook, or in `molecule.yml` under
  `provisioner.inventory` when several phases need them. Do not add `fixtures/`.
- Put static scripts that tasks run in `files/`.
- Do not add guards that only check Molecule's own driver output, or helpers
  that scan Ansible output.

Add `prepare.yml` or `cleanup.yml` only when the scenario needs them. Images must provide Ansible's remote runtime and
stay alive; service tests need an intentional init-system setup. Test native
outcomes and consequential failures, not task counts or historical input
permutations. Do not add test-only package or service opt-outs.

Assert supported-platform `fail_msg` text verbatim. A role rename updates the
role, scenario assertions, directory, and `scenario.name` together. Record what
each scenario checks in its own README, including limits.

GNOME scenarios inspect persisted dconf state and schemas, not a live desktop.
They do not prove visual layout or physical suspend. Flatpak acceptance remains
deferred until a container provides a working runtime, predictable remote, and
stable fixture refs. A test that cannot run in its environment needs a named
coverage limitation, not a silently skipped result.

## Release gate

Before publishing, build and install the checkout, configure both Docker and
Proxmox, then run lint and every scenario sequentially:

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg MOLECULE_GLOB='extensions/molecule/**/molecule.yml' molecule test --all
```

The full run includes Windows acceptance; do not repeat a separate Windows
suite for the same gate. Report unrelated failures with their reason rather
than claiming they passed. Do not publish with an incomplete release gate.

Publish only the exact versioned archive installed for that successful run.
Do not rebuild from changed source and call it the tested archive:

```bash
version=$(sed -n "s/^version: '\(.*\)'/\1/p" galaxy.yml)
ansible-galaxy collection publish "dist/jaythomasonprojects-sys_admin-${version}.tar.gz" \
  --token "$(tr -d '\n' < ~/.ansible/galaxy_token)"
```

A later role change requires a fresh build, installation, and test. Release
versioning rules are in [AGENTS.md](../../AGENTS.md#release-and-versioning).

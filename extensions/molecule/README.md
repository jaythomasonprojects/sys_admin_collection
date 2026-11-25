# Test the collection with Molecule

Molecule runs Ansible roles against disposable machines and checks the result.
This collection uses disposable Proxmox VM clones for Linux and Windows.
Tests do not run against your workstation inventory or source templates.

## Contents

- [How testing works](#how-testing-works)
- [Set up the tools](#set-up-the-tools)
- [Run your first Linux test](#run-your-first-linux-test)
- [Run the affected scenario](#run-the-affected-scenario)
- [Commands and files](#commands-and-files)
- [Set up Linux testing](#set-up-linux-testing)
- [Set up Windows testing](#set-up-windows-testing)
- [Run Windows tests](#run-windows-tests)
- [Troubleshoot and recover](#troubleshoot-and-recover)
- [Maintain scenarios](#maintain-scenarios)
- [Release gate](#release-gate)

## How testing works

A **scenario** is a test case with its own configuration and playbooks. For
example, `time_sync/linux` creates Ubuntu VM clones, applies
time synchronisation policy, and checks chrony configuration and service state.

An **instance** is one disposable VM used by a scenario. The **driver** creates
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

## Set up the tools

Run commands from the collection root. Use Python 3 and the pinned test
dependencies; the controller remains below Ansible 14 during the VM migration.

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
cp .env.yml.example .env.yml
```

Edit `.env.yml` for this controller. Use the stopped source template IDs,
Proxmox location, management accounts and public identity paths from your setup.
Keep API credentials in the separate private Proxmox secrets file.

Activate this checkout's test environment once in each shell, then install
collections when first setting up or changing requirements:

```bash
source .envrc
ansible-galaxy collection install -r requirements.yml -p .ansible/collections --force
```

`.envrc` selects this checkout's `.venv`, Ansible configuration and native module
path. Its private Ansible home is `.cache/molecule`, local to each worktree.
It links `.ansible/development/ansible_collections/jaythomasonprojects/sys_admin`
to this checkout and searches it before dependencies in `.ansible/collections`.
Edits are visible without rebuilding or reinstalling. Molecule's implicit local
installation (`prerun`) and Python-path collection discovery are disabled so
they cannot silently select another copy.
Molecule reads `.env.yml` automatically. No environment loader or test runner
is required. The scenario playbooks use fully qualified collection names
(FQCNs), such as `jaythomasonprojects.sys_admin.ssh`.

Both platforms need Proxmox API access with verified TLS and guest SSH keys.
Package downloads require network access. The API and guest credentials are
separate. Ordinary Linux scenarios use linked clones. Windows uses full clones
when its TPM-backed prepared source requires them.

For Windows prerequisites, see [Set up Windows testing](#set-up-windows-testing).

## Run your first Linux test

This example creates and deletes disposable Ubuntu 24.04 and 26.04 VM clones.
Configure [Linux testing](#set-up-linux-testing) first. Run scenarios sequentially
across repositories within an approved shared test window. Proxmox selects
the next available clone ID. Confirm that each requested clone name is absent
before creation.

After shell activation, run the scenario directly against the checkout:

```bash
molecule test -s time_sync/linux
```

Expect phase headings, Ansible task output, and play recaps for both VMs.
Initial convergence normally reports changes. The idempotence phase must report
none. Verification checks chrony policy, service state and disabled behaviour.
The final destroy phase removes the clones. Confirm through the API that their
owned disks are also absent and source templates remain. A successful command
exits zero.

`prepare.yml` and `cleanup.yml` are optional. This scenario needs preparation but
not explicit fixture cleanup, so a missing cleanup hook is expected. Do not add empty
playbooks just to silence the notices. A failure in an assertion, connection,
or driver operation is not an optional-hook notice.

## Run the affected scenario

For a role change, use the activated shell to run lint and the scenario that
covers the change:

```bash
ansible-lint --offline .
yamllint .
molecule test -s ssh/linux
```

Use `<role>/linux` or `<role>/windows` as the selector. Run affected scenarios
sequentially. Use the [release gate](#release-gate) only before publication,
not for every change. Documentation-only changes need factual, link, example,
lint, and package checks rather than another infrastructure run.

## Commands and files

All commands below use `-s <role>/<platform>`. Source `.envrc` in this checkout
first. Use current setup instructions for reruns; retained reports record
historical commands and results.

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
molecule converge -s time_sync/linux
molecule verify -s time_sync/linux
molecule destroy -s time_sync/linux
```

`converge` is not only a role rerun; its sequence includes creation. Do not use
it to debug an existing clone without checking driver state. In particular,
do not replay `create` against a clone allocation that already exists. The create
sequence stops before preparation so API identity and DHCP can be checked first.

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

## Set up Linux testing

Provide stopped Ubuntu 24.04 and 26.04 templates with native systemd, Python,
OpenSSH, the QEMU guest agent, DHCP and a controller-reachable network. Prepare
management access, not the role policy under test. The administrative account
must support sudo with a protected credential, passwordless sudo or root access.
Do not convert or modify source
VMs as part of a scenario.

Use the [API configuration](#api-credentials-and-permissions) and trust settings
below for both platforms. Set Linux source IDs, management access and public
identity paths in `.env.yml`. `.env.yml.example` defines the required fields.

The example's template IDs are placeholders, not site defaults. Inspect actual
API inventory before creation. Omit `newid` from platforms so Proxmox selects
clone IDs. Keep source templates stopped and unchanged.

`MOLECULE_LINUX_IDENTITY_FILE` is a public identity file selecting an agent-held
key already authorised in each source. Preparation authorises that public key
for the disposable `molecule` account where an unprivileged caller is tested.
Do not put a private key into this input.

If the administrative account requires a sudo password, supply it through
Ansible's protected `ANSIBLE_BECOME_PASSWORD_FILE` input for Linux test commands.
Keep that file outside the repository and never log its contents. Preparation
does not grant the bootstrap account passwordless sudo through the guest agent.
The test inventory selects the already-installed `/usr/bin/sudo.ws` on Ubuntu
26.04 because the tested controller's sudo plugin cannot recognise sudo-rs custom
prompts (Ansible issue [86849](https://github.com/ansible/ansible/issues/86849)).
This leaves system alternatives, packages and sudo permissions unchanged.

Shared `create.yml` and `destroy.yml` wrap the installed native driver's
playbooks. They reject existing clone names, verify native creation receipts
and recorded IDs, inspect API identities before preparation, pin guest host
keys read through the verified API, and check clone/disk disposal and stopped
source eligibility. Routine tests trust the prepared template. They do not read
an approved-settings record or compare full source configurations. Source
templates must remain unchanged, but a passing run does not certify full settings
equality. Inspect the private approved record manually when a failure gives
reason to suspect source settings.
The configured datastore must contain every clone-owned disk; inspect API
storage after failed lifecycle operations rather than deleting local state.
Socket-activated SSH may generate host keys only after a first TCP connection.
The wrapper probes that socket before independently reading and pinning its
public key; it does not alter source key-generation policy.

Before deletion, shared destroy asks each running verified guest to release
DHCP over SSH. Ubuntu fixtures use NetworkManager; Windows uses `ipconfig`.
Create installs `udhcpc` in disposable Ubuntu 24.04 guests because their
NetworkManager lacks release-on-disconnect control. That client requests the
current address with the same MAC client identity and releases it on exit.
Its no-op configuration hook leaves network settings with NetworkManager.
Ubuntu 24.04 fixtures must use NetworkManager's default MAC-based DHCP client ID.
The release is the last guest operation. A bounded controller check waits for
SSH to disconnect, but does not prove the DHCP server received the release.
Unreachable guests produce a warning and still proceed to native disposal.
SSH scenarios restore prepared management access in their own cleanup phase.

Native chrony service checks run on independent guest kernels without changing
packaged container conditions. Missing fixtures or failed service checks leave
acceptance incomplete. Ubuntu 22.04 is unsupported, not an optional third target.
USB policy and its guest-kernel acceptance remain consumer-owned.

## Set up Windows testing

Windows scenarios use the released Proxmox driver. A full clone is a
disposable VM with its own disks. The prepared source is not a
test target. Routine lifecycle operations use the HTTPS API, not root SSH to
the hypervisor.

### Template and clone identities

Use one stopped, deletion-protected Windows template prepared from the current
canonical unattended installation and its basic access bootstrap. Record the
input identity and any approved Windows Setup edition, disk or driver choices.
Verify completed setup and basic connectivity through a disposable full clone
before accepting the baseline. Source preparation and conversion require separate
authorisation; ordinary tests leave the template stopped and unchanged.
Enable the QEMU guest agent in Proxmox and Windows. Use DHCP on one
controller-reachable Ethernet interface. The driver selects the first
non-loopback IPv4 address; it does not filter automatic private IP addressing
(APIPA) addresses or choose among interfaces.

The source needs an administrator management account independent of fixture
accounts, native OpenSSH Server, key authentication, and PowerShell as the SSH
default shell. Verify `ansible.windows.win_ping` and native SFTP over pinned
key-only SSH. Prepare management access, not the policies under test.
The SSH scenario does not provision WinRM or reinstall OpenSSH.

Select a test node, full-clone-capable storage, bridge, pool and Windows 11
source in your own environment. The source's SSH port must match
`MOLECULE_WINDOWS_SSH_PORT`. Never alter the source template during tests.

The `ssh/windows` scenario uses clone name `ssh-windows` and SSH.
Proxmox selects its VM identifier (VMID). Keep that name absent before creation.
The native driver records the returned ID for cleanup.

Run both repositories sequentially within the approved test window.
Share acceptance belongs to the consuming project.
Never delete a VM based only on its number.
Full clones inherit deletion protection. The shared destroy playbook clears it
only after API checks confirm the recorded ID, name, node, pool and owned
disks. Source protection is never cleared. Source shutdown/restart wrappers are
not part of normal tests.

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

For example, these access control list (ACL) grants can permit linked-clone tests
for both the privilege-separated user and token. Substitute your template, pool,
storage and bridge. They are not a minimal-permissions claim:

| ACL path | Role | Propagate |
| --- | --- | --- |
| `/vms/<template-vmid>` | `PVETemplateUser` | No |
| `/pool/molecule` | `PVEVMAdmin` | Yes |
| `/pool/molecule` | `PVEPoolUser` | No |
| `/storage/<storage>` | `PVEDatastoreUser` | No |
| `/sdn/zones/localnetwork/<bridge>` | `PVESDNUser` | No |

Independent pool ownership checks also require `Pool.Audit` on the test pool for
both the privilege-separated user and token. Without it, Proxmox omits pool
membership from VM discovery; creation stops before allocating a clone.

These allow source inspection and cloning, allocation, power operations,
guest-agent discovery, and deletion of test VMs and disks. Provision grants
through the operator's Proxmox administration workflow.

Keep API `validate_certs: true`. If the endpoint needs a custom trust bundle,
set `REQUESTS_CA_BUNDLE` in `.env.yml`. An empty value uses system trust.
The local `.cache/proxmox-api-ca.pem` combines trusted
roots and an independently verified missing issuer chain. Refresh it when the
endpoint chain changes; do not disable API TLS verification.

### Guest authentication and environment

Set the Windows source ID, management user, port and public identity path in
`.env.yml`. Use `.env.yml.example` as the field reference.

The retained SSH scenario manages an already prepared clone through the source's
administrative SSH key. It requires no external Windows guest password and does
not change the source. For SSH, use an
agent-held key selected by a public identity file, or an external private-key
file. Its public key must be authorised in the template.

The SSH scenario uses actual SSH connections for fixture control, policy work
and fresh-session checks. If a case rotates fixture credentials, reset the
connection with the new credentials before later tasks.

SSH host keys are independently read through the verified Proxmox guest-agent
API after clone identity validation and pinned in the scenario's private
`known_hosts`. Windows SSH transition ports use the same pinned key.
Management SSH trust and Proxmox API certificate validation remain enabled.
The Linux SSH scenario's explicit loopback/client-policy test settings do not
change the controller's pinned management transport.

## Run Windows tests

Activate the checkout, configure authentication, then run each
scenario sequentially:

```bash
molecule test -s ssh/windows
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

If changes appear to have no effect, check the task path with `molecule -vv`
and confirm it resolves through this checkout's `.ansible/development` link.
An archive-selected shell intentionally ignores checkout edits. If VM service
tests fail, inspect the native unit, journal and guest prerequisites rather than
overriding service conditions.

For Windows address discovery, inspect the clone through the API or Proxmox UI.
An address beginning with `169.254.` is APIPA, not a usable DHCP lease. Confirm
the guest-agent-observed DHCP address and the clone's identity before correcting
only its disposable connection record. Do not change the template or guess an
address. If state is incomplete, use the recovery procedure below.

### Recover a disposable clone

If creation fails before the driver writes instance state, `destroy` may have no
VMID to remove. Deleting local state does not delete the clone or its disks.

1. Inspect the recorded VMID through the authenticated API or Proxmox UI.
   If no record exists, find the scenario's clone name in the test pool.
   Confirm its ID, name, node, pool and owned clone disks. Never guess the ID.
2. Stop and delete that exact test clone and its owned disks through the API or
   UI. Do not delete template disks or unrelated VMs.
3. Inspect API inventory and storage to confirm both the clone and its disks
   are absent. Confirm the template remains.
4. Run `molecule destroy -s <role>/<platform>` to clear
   remaining local lifecycle state. Then rerun the scenario.

Do not replay driver create against an existing clone. The evaluated driver
can return the source VMID when the destination already exists. A successful
local destroy alone does not prove API resource disposal.

The manual orphan procedure is a documented recovery path, not a separately
verified test case.

### Distinguish VM start failure from driver waiting

The pinned driver's start waiter returns early only for a successful Proxmox
task. A failed task can therefore leave Molecule waiting until its configured
timeout. Inspect that exact `qmstart` task and the host log before retrying;
increasing Molecule's timeout does not extend Proxmox's native start timeout.

Check concurrent backups and host memory/I/O pressure when starts fail
intermittently. Healthy storage pools or available memory do not rule out stalls.
Retry the existing scenario during a quiet window before changing the driver,
source VM or host settings. Timing correlation alone does not establish a cause.

## Maintain scenarios

Use `time_sync/linux` as the reference for Linux VM tests.
Keep scenario configuration under `<role>/linux/` or `<role>/windows/` and name
the scenario to match its path. Include only platforms needed for supported
outcomes or deliberate rejection checks. Retained Linux scenarios cover Ubuntu
24.04 and 26.04. Unsupported distributions/releases are not provisioned.

The Ubuntu 26.04 chrony unit intentionally refuses ordinary containers. Test
its native service on the VM without changing those conditions. Keep both
supported matrix targets and substantive assertions; missing prerequisites are
an incomplete gate, not a skipped success or a service opt-out.

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

Add `prepare.yml` or `cleanup.yml` only when the scenario needs them. Source VMs
must provide Ansible's remote runtime and native systemd. Test native
outcomes and consequential failures, not task counts or historical input
permutations. Do not add test-only package or service opt-outs.

Assert supported-platform `fail_msg` text verbatim. A role rename updates the
role, scenario assertions, directory, and `scenario.name` together. Record what
each scenario checks in its own README, including limits.

Account lifecycle and workstation-policy acceptance belong to the consuming
project. SSH key/profile/ACL acceptance belongs to this collection. Flatpak acceptance remains
deferred until the test environment provides a working runtime, predictable remote, and
stable fixture refs. A test that cannot run in its environment needs a named
coverage limitation, not a silently skipped result.

## Release gate

Development tests, including an ordinary `molecule test --all`, use the checkout.
They are not release acceptance. Before publishing, configure both platform
fixtures and agree an exclusive window. Build once, record the archive's digest,
and install those exact bytes in the worktree-local candidate path:

```bash
source .envrc
ansible-galaxy collection build --force --output-path dist
version=$(sed -n "s/^version: '\(.*\)'/\1/p" galaxy.yml)
candidate="$PWD/dist/jaythomasonprojects-sys_admin-${version}.tar.gz"
sha256sum "$candidate"
ansible-galaxy collection install "$candidate" -p .ansible/collections --force
ansible-lint .
yamllint .
(
  export ANSIBLE_COLLECTIONS_PATH="$PWD/.ansible/collections"
  cmp <(tar -xOf "$candidate" FILES.json) \
    .ansible/collections/ansible_collections/jaythomasonprojects/sys_admin/FILES.json &&
  ansible-galaxy collection verify jaythomasonprojects.sys_admin --offline &&
  molecule -vv test --all
)
```

The subshell excludes the development link and keeps the activated shell ready
for subsequent development. Dependencies must be installed in the same selected
collection root. The manifest comparison and offline integrity check establish
that the installed files match the selected archive; a missing candidate stops
the gate. Keep the verbose task paths as evidence that role execution used that
installation, not the source or a global copy. `Test: all` makes the same explicit
selection and integrity checks against the existing versioned archive.

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

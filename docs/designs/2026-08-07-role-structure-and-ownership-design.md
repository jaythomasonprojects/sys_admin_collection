# Role Structure and Ownership Design

## Purpose

Refactor the collection so that every role presents a predictable platform structure and owns a
complete system-administration capability. Inventory declares intent through role inclusion and
small, meaningful interfaces; roles hide platform-specific packages, configuration, firewall rules,
and service management.

The refactor is a clean pre-1.0 breaking release. It does not preserve aliases for removed or renamed
variables and roles.

## Scope

This work restructures the twelve existing capabilities. It may simplify their interfaces and move
existing responsibilities to their proper owners, but it does not introduce new capabilities. In
particular, it does not add Linux firewall support, Windows SSH client policy, real Windows automatic
update scheduling, or broader workstation hardening.

The work includes role tasks, defaults, metadata, handlers, templates, Molecule scenarios, role
READMEs, collection documentation, `AGENTS.md`, the changelog, and the collection version.

## Collection ethos

Each role is a module whose interface describes an operational capability rather than the Ansible
modules used to implement it.

- Including a role applies its primary capability with useful defaults.
- Variables express desired policy, not implementation choreography.
- Boolean variables select optional sub-capabilities or desired states. They do not disable required
  packages, firewall rules, validation, or service management.
- Structured variables remain appropriate for repeated policy such as users, applications, shares,
  and arbitrary systemd units.
- A capability role owns all prerequisites required to deliver its promise: package or Windows
  feature installation, configuration, validation, firewall access, and service state.
- A generic policy role remains valid when generic policy is itself the capability. `install_app`
  therefore remains a first-class role, but other roles do not require callers to compose it to
  become functional.
- No two roles manage the same artefact for the same purpose.
- Unsupported platforms fail explicitly with a useful message rather than silently skipping work.

The practical test is: after including a capability role, the capability works without requiring the
caller to understand or invoke another implementation role.

## Universal task structure

Every role uses `tasks/main.yml` as a small platform validator and dispatcher:

```text
roles/<role>/tasks/
├── main.yml
├── linux/
│   ├── main.yml
│   └── <focused-responsibility>.yml
└── windows/
    ├── main.yml
    └── <focused-responsibility>.yml
```

A Linux-only role contains only `tasks/linux/`; a Windows-only role contains only
`tasks/windows/`; a cross-platform role contains both. Package-manager-specific implementations,
such as APT and DNF, remain beneath `tasks/linux/`.

Platform `main.yml` files provide the shortest complete reading path through that platform's
implementation. Additional task files are created only when they:

- isolate a substantial responsibility;
- separate independently selectable sub-capabilities; or
- make an otherwise long or multi-subsystem workflow easier to understand.

Small, cohesive implementations remain in the platform `main.yml`. Files are not split merely to
make platform trees identical. Where Linux and Windows implement the same conceptual responsibility,
such as SSH client or server policy, their filenames and reading order are mirrored.

Shared cross-platform task files remain directly under `tasks/` only when the implementation is
genuinely identical and extracting it improves locality. Platform locality is preferred over trivial
deduplication.

## Ownership rules

### Firewall

The role that owns a capability owns the firewall access required by that capability. For example,
`config_ssh` owns its SSH firewall rule.

`config_firewall` owns host-wide firewall posture and firewall openings without a dedicated
capability owner. Its platform directories contain one file per selectable exposure, such as
`windows/ping.yml` or `windows/rdp.yml`, and each file may manage one or more related rules. Only
existing ping behaviour is implemented by this refactor; RDP illustrates the future ownership rule.

When a dedicated capability role is introduced later, its firewall rule moves out of
`config_firewall`. Two roles must never manage the same named firewall rule. Callers never need to
coordinate a capability flag with a second firewall flag.

### Packages and services

Capability roles always ensure their required packages or Windows features are present and their
services are in the state needed to apply the configuration. Existing prerequisite opt-outs such as
`time_sync_manage_package`, `time_sync_manage_service`, and
`mount_network_share_manage_packages` are removed.

Idempotent package installation remains compatible with centrally pre-installed packages because
`state: present` makes no change when the prerequisite already exists. Partial configuration for
maintenance windows, immutable-image builds, and restricted package pipelines is outside this
collection's current interface.

### Users and SSH keys

`config_ssh` owns OpenSSH installation, client and server policy, SSH firewall access, service state,
and SSH-owned filesystem prerequisites. `create_user` owns local accounts and the contents and access
control of their authorised-key files, including Windows administrator keys. Each managed file has
one owner.

### Defaults

Primary capabilities use useful defaults. Optional capabilities that increase network exposure use
conservative defaults. A Boolean that represents a meaningful desired state may remain even when it
can disable the role's effect, such as automatic updates being enabled or disabled as policy. A
Boolean that merely suppresses a required implementation step is removed.

## Target role designs

### `auto_updates`

- Supports Linux and Windows through platform directories.
- Linux dispatches to focused APT and DNF implementations.
- Windows retains its existing immediate update installation behaviour; changing it to persistent
  scheduling would add a new capability and is outside scope.
- Owns required packages, configuration, timers, and update execution.
- Retains policy variables that describe update behaviour, including whether automatic updates are
  enabled and whether a platform may reboot.

### `config_desktop`

- Is Linux-only and fails explicitly elsewhere.
- Keeps separate GDM, LightDM, and Qt policy files because they are independently selected settings.
- Configures detected desktop software but does not install an entire desktop environment. The
  capability is policy for an existing desktop, not desktop provisioning.

### `config_firewall`

- Is Windows-only because Linux firewall behaviour does not currently exist.
- Dispatches from `windows/main.yml` to one file per independently selectable, unowned exposure.
- Replaces separate ICMPv4 and ICMPv6 switches with the platform-agnostic
  `config_firewall_allow_ping`; enabling it manages both existing Windows echo-request rules.
- Does not duplicate the SSH rule owned by `config_ssh`.

### `config_git`

- Is Linux-only according to its current supported-platform contract and fails explicitly elsewhere.
- Ensures Git is installed before configuring global identity.
- Preserves the existing execution-user semantics and documents them. Adding a multi-user interface
  would be a new capability.
- Remains cohesive in `linux/main.yml` unless the final task list needs a package/configuration split
  for readability.

### `config_power`

- Is Windows-only and fails explicitly elsewhere.
- Keeps its cohesive power plan, timeout, and hibernation policy in `windows/main.yml`.
- Retains Booleans that represent desired power policy rather than implementation opt-outs.

### `config_ssh`

- Supports Linux and Windows and owns complete, reachable SSH server configuration.
- Organises each platform around client and server responsibilities when that responsibility exists.
- Linux uses `client.yml` and `server.yml`; cloud-init SSHD cleanup belongs to the Linux server flow.
- Windows uses `server.yml`. It does not create an empty `client.yml` or add Windows client policy
  solely for structural symmetry.
- Windows server policy owns OpenSSH Server installation, server configuration, firewall access,
  service state, and default-shell registration.
- Authorised-key contents and ACLs move to `create_user` so that only one role owns those files.
- Removes the compatibility fallback to unprefixed `sshd_permit_root_login`.

### `config_systemd_units`

- Is Linux-only and ceases to be a generic lifecycle wrapper for arbitrary existing units.
- Uses `tasks/linux/printer_services.yml` for the opinionated printer-discovery policy. When
  `config_systemd_units_disable_printer_services` is true, the task stops and disables
  `cups-browsed.service`, `avahi-daemon.service`, and `avahi-daemon.socket` when they exist. Missing
  printer services are already compliant rather than errors.
- Uses `tasks/linux/custom_services.yml` to create explicitly defined, role-owned systemd services.
  `config_systemd_units_custom_services` is a list of definitions requiring `name` and
  `unit_content`; definitions may select `state`, `enabled`, and `unit_file_state`. The role writes
  files beneath `/etc/systemd/system`, reloads systemd when files change, and applies their desired
  lifecycle. It prefixes each managed unit with a fixed ownership marker. Removal is permitted only
  when the target file carries that marker.
- Removes the existing `config_systemd_units` pass-through list and its support for starting,
  stopping, enabling, disabling, or masking arbitrary externally owned units.
- Defaults printer-service disabling to enabled, preserving the collection's opinionated workstation
  policy. The custom-service list defaults to empty.

### `create_user`

- Supports Linux and Windows.
- Mirrors account and authorised-key responsibilities across platform directories where both exist.
- Owns account creation and authorised-key contents, paths, and permissions or ACLs.
- Retains the structured account list because repeated account data is a suitable interface.
- Documents the complete supported account-item schema and platform-specific password semantics.

### `install_app`

- Supports Linux and Windows and remains a generic application-installation capability.
- Linux separates native packages, Debian packages, npm packages, and Flatpak applications because
  they are independently selectable package channels with different validation.
- Windows keeps its cohesive Chocolatey implementation in the platform main file unless complexity
  justifies a focused file.
- Retains structured lists for applications and package metadata.

### `mount_network_share`

- Supports Linux and Windows and owns all prerequisites needed to establish its managed shares.
- Removes `mount_network_share_manage_packages`; Linux always ensures `cifs-utils` is present.
- Retains a platform orchestration file and focused per-share implementation where that keeps
  credential and mount logic readable.
- Retains structured share policy and its current local-user and remote-credential semantics.
- Retains `mount_network_share_reload_remote_fs` because it represents desired activation policy,
  not prerequisite ownership.

### `time_sync`

- Is Linux-only and remains specifically an `ntpsec` capability.
- Always installs `ntpsec`, validates and writes its configuration, and applies it through the
  `ntpsec.service` service.
- Removes `time_sync_manage_package` and `time_sync_manage_service`.
- Remains in `linux/main.yml` while cohesive; file count is not a goal.

### `blacklist_kernel_modules`

- Replaces the misleading `workstation_hardening` role name. The existing implementation manages
  kernel-module blacklist policy, not general workstation hardening.
- Is Linux-only and exposes supported module policies as explicit Boolean capabilities rather than
  accepting arbitrary module names.
- Initially supports only `blacklist_kernel_modules_disable_usb_storage`, enabled by default.
- Uses `tasks/linux/usb_storage.yml` to persistently blacklist the `usb-storage` and `uas` kernel
  modules and unload either when already loaded. This disables USB mass-storage devices without
  disabling USB input devices or the wider USB controller stack.
- Removes `workstation_hardening_blacklisted_modules` and
  `workstation_hardening_apply_runtime_changes` without aliases. The role does not offer a switch
  that leaves a selected module policy unapplied until reboot.
- Future module policies receive their own Boolean and focused task file because their enforcement
  steps may differ; an unrestricted module-name list is not reintroduced.

No other roles are renamed. Cosmetic pluralisation does not justify additional migration cost.

## Platform validation

Every `tasks/main.yml` asserts its supported `ansible_facts.system` or
`ansible_facts.os_family` values before dispatch. Assertions name the role and supported platforms.
Distribution- or package-manager-specific Linux paths validate their narrower requirements before
executing. Role metadata and README platform claims match these runtime contracts.

## Documentation

`AGENTS.md` gains concise project conventions for:

- the universal platform-directory structure;
- the file-splitting heuristic;
- complete capability ownership;
- Boolean and structured-variable interfaces;
- explicit unsupported-platform failures; and
- single ownership of managed artefacts.

The collection `README.md` explains the opinionated capability model and links to role READMEs for
interfaces. It also warns that releases before `1.0.0` may contain breaking changes and directs
readers to the changelog for migrations.

Each role README is the local design record for users, agents, and maintainers. It describes what
including the role guarantees, what the role owns and deliberately does not own, supported
platforms, its platform-directory structure, why focused task files exist, required inputs, optional
policy, useful defaults, invariants, and breaking migrations. It names the relevant task files so a
maintainer can locate each responsibility without reverse-engineering the dispatcher. Executable
variable values remain sourced from defaults rather than being duplicated into a second reference
catalogue.

`extensions/molecule/README.md` records the expected assertions for platform dispatch and the rule
that test-only package or service opt-outs must not be added to weaken a role interface.

## Compatibility and release

This is a clean breaking release from `0.6.0` to `0.7.0`. Removed role names and variables have no
compatibility aliases. `CHANGELOG.rst` receives a newest-first `0.7.0` section that identifies:

- the `workstation_hardening` to `blacklist_kernel_modules` rename;
- all removed or renamed public variables;
- the combined platform-agnostic ping flag;
- removal of arbitrary existing-unit lifecycle policy from `config_systemd_units`;
- the new printer-service, custom-service, and USB-storage capability interfaces;
- prerequisite ownership changes;
- explicit unsupported-platform failures; and
- the new task-layout convention.

The version bump, changelog, behavioural changes, tests, and documentation ship together.

## Testing and acceptance

Tests exercise observable role contracts rather than task-file shape.

- Each same-named Molecule scenario is updated for moved paths and changed interfaces.
- Each role scenario verifies successful supported-platform behaviour, idempotence, and explicit
  unsupported-platform rejection where Docker can exercise the contract.
- Scenarios for roles that now own prerequisites stop preparing or suppressing those prerequisites
  when the role itself should provide them.
- The `config_systemd_units` scenario verifies printer services are stopped and disabled when
  present, missing printer services are accepted, custom unit creation and removal are idempotent,
  and arbitrary externally owned units remain untouched.
- The renamed `blacklist_kernel_modules` scenario verifies the `usb-storage` modprobe policy and
  exercises runtime unloading only where the container can safely provide a fixture module state.
- Static tests that parse internal YAML structure are removed or replaced with observable behaviour.
- Windows behaviour is validated against the documented Proxmox VM workflow because Docker cannot
  execute Windows tasks. The Windows checks cover SSH reachability and firewall ownership, user key
  paths and ACLs, power policy, ping rules, shares, and any other Windows implementation touched by
  more than a path-only move.
- The per-change gate is `ansible-lint .`, `yamllint .`, and every affected scenario. Because this
  refactor affects every role, the final branch gate includes
  `ANSIBLE_CONFIG=ansible.cfg molecule test --all` plus the Windows integration workflow.
- The collection artefact is built after validation to confirm Galaxy packaging includes every
  nested task file and renamed role.

## Non-goals

- Adding capabilities not present in `0.6.0`.
- Preserving pre-`0.7.0` aliases or compatibility wrappers.
- Creating a general dependency framework between roles.
- Centralising all firewall, package, or service operations in technical wrapper roles.
- Splitting every implementation step into a separate file.
- Making Linux and Windows directory trees superficially identical through empty files.
- Expanding Windows Docker coverage beyond what the platform supports.

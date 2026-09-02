# Capability Role Naming and Interfaces Design

## Status

Supersedes `2026-08-07-role-structure-and-ownership-design.md`. That document remains the record of
the `0.7.0` refactor and is not edited. Where the two disagree, this document wins. The
supersession is itemised in [Relationship to the 0.7.0 design](#relationship-to-the-070-design).

## Purpose

`0.7.0` gave every role a predictable platform layout and complete capability ownership. It did not
fix what the roles are *named after*. Several roles still take their name from the Ansible mechanism
they use rather than the policy they deliver, and one role is a thin wrapper around
`ansible.builtin.copy` plus `ansible.builtin.systemd_service`.

This refactor renames every role after its outcome, deletes the two interfaces that only restate
module arguments, replaces hand-written validation with native role argument validation, and gives
policy roles a single documented switch so a fleet-wide playbook can vary policy by group.

It is a clean pre-1.0 breaking release. No compatibility aliases are retained.

## Scope

Twelve existing roles. Eight are renamed, two interfaces are deleted, and every role gains argument
validation and a documented enable interface. Three roles gain a `vars/` structure that separates
distribution data from task logic.

The work covers role tasks, defaults, vars, metadata, argument specifications, handlers, templates,
Molecule scenarios, role READMEs, `roles/README.md`, `extensions/molecule/README.md`, `AGENTS.md`,
`CHANGELOG.rst`, and `galaxy.yml`.

## Naming rule

A role is named after the outcome it produces, never after the Ansible module, subsystem, or
technique it uses to produce it. No fixed prefix: `config_` carried no information because every
role configures something.

Two shapes, chosen by what the role does:

- **Subsystem noun** where the role configures an existing subsystem to a desired state:
  `ssh`, `git`, `time_sync`, `auto_updates`, `power_policy`, `local_accounts`, `auto_login`.
- **Verb phrase** where the role applies one discrete policy: `disable_usb_storage`,
  `disable_printer_discovery`, `allow_ping`, `install_app`, `mount_network_share`.

The test for whether an interface belongs in this collection at all: **does the variable describe
the environment, or does it describe the module call?** `install_app_packages: ['vim']` describes
the environment. `config_systemd_units_custom_services: [{name, unit_content, unit_file_state,
state, enabled}]` is a `systemd_service` invocation typed into YAML. The first is legitimate generic
policy; the second is a wrapper and is removed.

Generic policy remains a valid capability when generic policy is itself the capability.
`install_app`, `local_accounts`, and `mount_network_share` keep structured list interfaces for that
reason.

## Role map

| `0.7.1` name | `0.8.0` name | Change beyond the rename |
| --- | --- | --- |
| `config_systemd_units` | `disable_printer_discovery` | `custom_services` interface deleted |
| `blacklist_kernel_modules` | `disable_usb_storage` | mechanism name replaced by policy name |
| `config_desktop` | `auto_login` | Qt platform-theme policy deleted |
| `config_firewall` | `allow_ping` | `false` now removes the rules instead of skipping |
| `config_power` | `power_policy` | none |
| `config_ssh` | `ssh` | `vars/` structure for distribution data |
| `config_git` | `git` | `vars/` structure for distribution data |
| `create_user` | `local_accounts` | `password` becomes optional |
| `auto_updates` | `auto_updates` | argument specification only |
| `install_app` | `install_app` | argument specification and enable flag |
| `mount_network_share` | `mount_network_share` | argument specification and enable flag |
| `time_sync` | `time_sync` | `vars/` structure, argument specification, enable flag |

Every public variable is renamed to match its role prefix. `config_ssh_sshd_port` becomes
`ssh_server_port`, `create_user_accounts` becomes `local_accounts_users`, and so on. There are no
aliases.

## Deletions

### `config_systemd_units_custom_services`

Removed entirely: 159 lines of role code and roughly 240 lines of Molecule scaffolding.

The interface accepted `name`, `unit_content`, `state`, `enabled`, and `unit_file_state`, wrote the
content beneath `/etc/systemd/system`, and reimplemented safe removal through a fixed comment marker,
a `stat`, a `slurp`, and a regular-expression ownership check. Every field is a module parameter. The
role knew nothing about the units it managed.

A role that needs a systemd unit ships that unit in its own `templates/` and owns its lifecycle
directly, which is both shorter and honest about who owns the file. This is the model that
`install_tailscale` will follow.

The printer-discovery policy that shared the role is genuine environment policy and survives as
`disable_printer_discovery`.

### `config_desktop_qt5ct`

Removed. It wrote `QT_QPA_PLATFORMTHEME=qt5ct` into `/etc/environment`, defaulted to `false`, and is
not policy this environment wants.

## Enable interface

### Semantics

Every policy role exposes `<role>_enabled`, set in `group_vars` so one fleet-wide play can vary
policy by group. This is the single targeting mechanism; plays are not also split by group to
achieve the same effect.

`<role>_enabled` means "this host should have this policy". It is not an implementation opt-out. A
Boolean that suppresses a required package, service, firewall rule, or validation step remains
banned, as in `0.7.0`.

### Converging and skipping flags

Two behaviours are permitted, and each role README states which it implements.

**Converging.** `false` actively returns the host to the unmanaged state. Required wherever the
revert is safe, unambiguous, and confined to artefacts the role owns.

**Skipping.** `false` leaves existing state untouched. Permitted only where reverting would require
the role to assert state it has no business asserting, and the README must say so explicitly, because
a skipping flag does not undo a previous run.

| Role | Behaviour when `false` | Reason |
| --- | --- | --- |
| `allow_ping` | Converging: rules set to `state: absent` | The role owns both named rules; removal is exact. |
| `disable_usb_storage` | Converging: modprobe file removed | Already implemented; one owned file. |
| `auto_updates` | Converging: timers and APT periodic counters set to disabled | Already implemented. |
| `auto_login` | Converging: autologin removed when the user variable is empty | Already implemented; the user variable is the switch. |
| `disable_printer_discovery` | Skipping | Reverting means starting `avahi-daemon` and `cups-browsed` on a host, which the role must not decide. |
| `ssh`, `git`, `time_sync`, `local_accounts`, `install_app`, `mount_network_share`, `power_policy` | Skipping | Reverting means removing packages, accounts, mounts, or a power plan the role did not originate. |

### Defaults

A role's own primary capability defaults to `true`: including the role is the deliberate act, and the
flag exists so a broad play can switch it off for a group. Anything that increases network exposure
or reduces security defaults to off and requires an explicit value. `auto_login` therefore stays off
until a user is named.

## Validation through argument specifications

Every role gains `meta/argument_specs.yml`. Ansible inserts a validation task before the role's first
task, which is the correct place for the pre-task checks currently written by hand.

The specification owns types, `required`, `choices`, `default` documentation, and nested `options`
for list-of-dict interfaces. Roughly 25 `assert` tasks are removed.

Two categories of `assert` survive, because a specification cannot express them:

- **Platform gates.** `tasks/main.yml` keeps its explicit `assert` on `ansible_facts.system` or
  `ansible_facts.os_family`. Its `fail_msg` remains a stable, role-named string that Molecule
  scenarios assert on verbatim.
- **Cross-field constraints.** Rules relating one option to another, such as `install_app_debs`
  requiring `dest` when `src` or `url` is given.

Specifications document the `main` entry point only. Roles are not invoked with `tasks_from`.

## Operating-system handling

Three concerns are separated, because `0.7.0` conflated them inside `tasks/<platform>/`.

**Platform gate.** An explicit `assert` at the top of `tasks/main.yml`, then a `when`-guarded
`include_tasks` per platform. Dynamic `first_found` dispatch is not used for this: it fails on an
unknown platform with an unusable message, and the explicit assertion is the role's documented
contract.

**Distribution data.** Package names, configuration paths, and service names move to `vars/`, loaded
through `ansible.builtin.first_found` over `{{ ansible_facts.distribution }}.yml` then
`{{ ansible_facts.os_family }}.yml`. Task files then use `ansible.builtin.package` and reference the
variable, so the same task file serves every distribution.

**Distribution procedure.** Only a genuine difference in the steps themselves earns a task file
under `tasks/linux/`. `auto_updates` qualifies: `unattended-upgrades` and `dnf-automatic` are
different workflows, not different package names. A directory is created beneath `tasks/linux/` only
when a family needs more than one file; a single file stays flat as `tasks/linux/apt.yml`.

With validation moved into the specification, every `tasks/main.yml` becomes a short gate-and-dispatch
file.

### Distribution support is not widened

`git`, `time_sync`, and `ssh` gain the `vars/` structure but keep their existing Debian and Ubuntu
assertions. The structure makes future Fedora support a small change; this release does not claim
support it has not tested. Adding Fedora requires new Molecule platforms and is deliberately deferred.

## Collection and site boundary

The collection ships capabilities. The playbook repository ships the standard.

`local_accounts` takes a list of accounts. It does not encode that this environment has one primary
user and one IT administrator account, because account names, group membership, and vaulted passwords
are site data. Encoding them in a published Galaxy collection would make the collection unpublishable
and the standard unvaultable. The standard set lives in `group_vars/` in the consuming playbook
repository.

The same boundary explains why `install_app` ships no package list and `mount_network_share` ships no
shares.

## Target role designs

Only changes beyond the rename and the two universal additions (argument specification, enable flag)
are listed.

### `disable_printer_discovery`

Linux only. Stops and disables `cups-browsed.service`, `avahi-daemon.service`, and
`avahi-daemon.socket` where they are loaded; missing services are compliant, not errors. The
`systemd` service-manager assertion is retained. `custom_services` and all of its validation,
ownership-marker, and removal machinery are gone. Skipping flag, documented as such.

### `disable_usb_storage`

Linux only. Behaviour is unchanged: it installs the modprobe policy for `usb-storage` and `uas`,
unloads both when loaded, and removes the policy file when disabled. Only the role name, the file
name, and the variable prefix change. The `blacklist_kernel_modules_disable_usb_storage` flag becomes
`disable_usb_storage_enabled`, which is now the role's own enable flag rather than a sub-capability
selector.

### `auto_login`

Linux only. Configures GDM and LightDM autologin where their configuration is detected.
`auto_login_gdm_user` and `auto_login_lightdm_user` remain the interface; an empty string removes
autologin, so they are their own converging switch and the role does not add a separate
`auto_login_enabled`.

The GDM path continues to set `WaylandEnable = false` alongside autologin. This is retained as a
genuine dependency, not an unrelated policy: autologin in this environment requires X11. The role
README states the coupling explicitly so it stops being a surprise.

### `allow_ping`

Windows only. Owns the `Allow ICMPv4 ping` and `Allow ICMPv6 ping` inbound rules. `allow_ping_enabled`
converges: `true` sets both rules `present`, `false` sets both `absent`. This replaces the previous
skip behaviour, which the old README apologised for.

The role is deliberately not a firewall-subsystem role. Firewall access belongs to the capability it
serves, as `ssh` demonstrates by owning `OpenSSH Server (sshd)` with a `localport` driven by
`ssh_server_port`. Ping is the residual case: no service serves ICMP, so it gets its own policy role. A
future RDP opening would be `allow_rdp`, not a second flag here.

### `power_policy`

Windows only. Power plan, sleep and standby timeouts, and hibernation. Behaviour unchanged.

### `ssh`

Debian and Ubuntu, plus Windows. Retains complete server ownership: OpenSSH installation, client and
server configuration, validation, the Windows firewall rule keyed to `ssh_server_port`, service state,
and the Windows default shell. Authorised keys remain owned by `local_accounts`.

Distribution data moves to `vars/`: the OpenSSH package names and the service name currently derived
by a `stat` on `/etc/init.d/ssh`. The runtime `stat` is replaced by the variable, removing the
`ssh_service_name is none` sentinel from the interface.

### `git`

Debian and Ubuntu. Package name moves to `vars/`; the task uses `ansible.builtin.package`. Execution
user semantics are unchanged and remain documented.

### `time_sync`

Debian and Ubuntu. `ntpsec` package name, configuration path, and service name move to `vars/`.
Behaviour is unchanged.

### `local_accounts`

Linux and Windows. Owns account fields, authorised-key contents, Windows key-file ACLs, and Windows
password policy. The name changes because the role manages the full lifecycle rather than creating
accounts, and manages a set rather than one user. "local" draws the boundary against domain accounts.

`password` becomes optional. It is currently required on every account, which forces key-only Linux
accounts to pass a placeholder; the collection's own Molecule scenario works around it with
`password: '!'`. When `password` is absent, the parameter is omitted on both platforms.

### `install_app`, `mount_network_share`, `auto_updates`

No behavioural change. Argument specifications replace their inline type assertions, cross-field
assertions are retained, and `install_app` and `mount_network_share` gain enable flags.
`auto_updates_enabled` already exists and already converges; it is documented as the model.

## Relationship to the 0.7.0 design

Retained without change:

- Complete capability ownership: a role owns its packages, configuration, validation, firewall
  access, and service state.
- Single ownership: no two roles manage the same artefact for the same purpose.
- Explicit unsupported-platform failure with a stable, role-named message.
- `tasks/main.yml` as platform validator and dispatcher, with `tasks/linux/` and `tasks/windows/`.
- File-splitting heuristic: focused files for substantial responsibilities, not for symmetry.
- Useful defaults; variables express policy, not choreography.
- Firewall access belongs to the capability that needs it.

Superseded:

| `0.7.0` section | Superseded by |
| --- | --- |
| Collection ethos: structured variables suit "arbitrary systemd units" | Deleted with `custom_services`. Structured variables suit repeated *environment* policy only. |
| Scope: "does not introduce new capabilities" | Expired with `0.7.0`. This release renames and deletes; later releases add roles such as `install_tailscale`. |
| `config_systemd_units` target design | Replaced by `disable_printer_discovery`. |
| `config_desktop`: "keeps separate GDM, LightDM, and Qt policy files" | Replaced by `auto_login`; Qt deleted. |
| `config_firewall`: owns "host-wide firewall posture" | Never implemented. Replaced by `allow_ping`, a discrete policy role. |
| `blacklist_kernel_modules`: future module policies become Booleans inside this role | Each policy becomes its own role. |
| Universal task structure: silent on distribution data | `vars/` pattern added. |
| Platform validation by hand-written `assert` | `meta/argument_specs.yml` for option validation; `assert` retained only for platform gates and cross-field rules. |
| Defaults: implied distinction between policy and suppression Booleans | Stated explicitly, with converging and skipping behaviours defined. |

Deliberately unchanged despite being adjacent: nothing in this release adds a Linux firewall. Linux
`ssh` opens no port and relies on the distribution default. This is a recorded gap, not an oversight;
closing it needs `ufw` and `firewalld` support plus a wider Molecule matrix.

## Documentation

`AGENTS.md` replaces its `Role design` section with the naming rule, the argument-specification
convention, the three-way operating-system split, enable-flag semantics including the converging and
skipping distinction, and the collection-and-site boundary.

Each role README continues to be the local design record. It additionally states which enable
behaviour the role implements and, where the behaviour is skipping, that disabling does not undo a
previous run.

`extensions/molecule/README.md` records that scenarios assert platform `fail_msg` strings verbatim,
so a role rename requires updating both the role and its scenario.

## Compatibility and release

Breaking release, `0.7.1` to `0.8.0`. `CHANGELOG.rst` gains a newest-first `0.8.0` section covering
the eight role renames with their full variable-prefix changes, the two deleted interfaces, the
`allow_ping` convergence change, optional `local_accounts` passwords, the argument-specification
convention, and the `vars/` structure.

This is the second breaking release in two versions. That is accepted deliberately: the naming is
wrong now, and it is cheaper to fix before `1.0.0` than after.

## Testing and acceptance

Tests pin observable contracts, not task-file shape.

- Each renamed role's Molecule scenario directory, `scenario.name`, converge FQCN, variable names,
  and asserted `fail_msg` strings are updated together.
- `disable_printer_discovery` keeps only its printer-policy coverage. All `custom_services` fixtures,
  rejection blocks, and verify assertions are deleted.
- `allow_ping` gains coverage for the converging false branch where the harness can reach it; the
  rule behaviour itself remains Windows-integration-only, as Docker cannot execute Windows tasks.
- `local_accounts` drops the `password: '!'` workaround and instead proves a key-only account.
- Scenarios that exercise rejected input through `block`/`rescue` are reviewed against the argument
  specification, since validation now fails earlier and with a different message.
- Per-change gate: `ansible-lint .`, `yamllint .`, and the scenario covering the change.
- Release gate: `ANSIBLE_CONFIG=ansible.cfg MOLECULE_GLOB='extensions/molecule/**/molecule.yml'
  molecule test --all`, the Windows Proxmox pass covering `ssh`, `power_policy`, `allow_ping`,
  `local_accounts`, and `mount_network_share`, then `ansible-galaxy collection build`.

## Non-goals

- Linux firewall management.
- Widening `git`, `time_sync`, or `ssh` to Fedora in this release.
- Adding `install_tailscale` in this release; it is the first role built under these conventions
  afterwards, and it validates them rather than inflating this refactor.
- Encoding site-specific account names, packages, or shares in the collection.
- Compatibility aliases for any renamed role or variable.
- Restructuring Molecule beyond what the renames and deletions require.

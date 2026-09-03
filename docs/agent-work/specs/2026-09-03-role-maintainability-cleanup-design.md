# Role Maintainability Cleanup Design

## Status

Approved for the unreleased collection version `0.9.0`. Execute this design only after
`docs/agent-work/plans/2026-09-03-fedora-support-and-role-cleanup.md` is complete. That work owns the
Fedora 44 and Ubuntu 26.04 support changes that this cleanup must preserve.

This design supersedes only that design's non-goal of keeping every remaining public role option
form unchanged. Its approved list-only network-share input is the additional `0.9.0` interface
change. All platform decisions from the Fedora design remain in force.

## Purpose

Make role implementation files easier to read and maintain for Glass Expansion. Prefer one clear
input form, local working variables, native Ansible modules, and role-owned static scripts. Do not
add abstractions or compatibility behaviour for environments that Glass Expansion does not use.

Correct desired state, secret handling, explicit failure, and idempotence remain required. A
simplification must not weaken them.

## Decisions

### Network-share input and working values

`mount_network_share_shares[].fstab_options` accepts a YAML list of strings only. Remove the
comma-separated string compatibility form and its normalisation task.

Every share entry must define `name`, `server`, `share`, and `mount_point`, including when
`mount_network_share_enabled` is false. Put those unconditional requirements in
`meta/argument_specs.yml`. Keep task assertions only for rules that the argument specification
cannot express, such as paired username and password values and strict list-only input.

Keep one dynamic task include per share. Pass calculated values as variables on that include. Do not
store per-share working values with `set_fact`, and do not add a common role, custom filter, or
effective-share abstraction.

### Platform gates

Each role has one complete supported-platform gate in `tasks/main.yml`. An OS task file contains
implementation prerequisites only. A prerequisite includes an existing account, home directory,
GNOME schema, service manager, or supported option combination.

Preserve the support added by the Fedora cleanup:

- `power_policy`: Windows, Ubuntu 22.04/24.04/26.04, and Fedora
- `desktop_layout`: Ubuntu 22.04/24.04/26.04
- `time_sync`: Debian, Ubuntu, and Fedora
- `auto_updates`: Windows, or Linux with APT, DNF4, or DNF5

Do not remove Fedora or Ubuntu 26.04 expectations. Do not add another platform.

### Static scripts

Keep short commands and small Ansible glue inline. Put a cohesive shell or PowerShell algorithm in a
static file under the owning role. Run static PowerShell with
`ansible.windows.win_powershell.path` and pass changing values through `parameters`. Do not template
script source unless parameter passing cannot represent the required input.

Move the Windows power timeout algorithm to
`roles/power_policy/files/Disable-PowerPolicySleep.ps1`. Preserve
`power_policy_disable_sleep` and its current AC/DC monitor and standby contract. The script reports
idempotence through `$Ansible.Changed`.

Move the Windows authorised-key ACL algorithm to
`roles/local_accounts/files/Set-AuthorizedKeyAcl.ps1`. It owns the two existing ACL policies:

- the administrator key file is owned by Administrators and permits Administrators and SYSTEM
- a standard user's `.ssh` directory and `authorized_keys` file are owned by that user and permit
  that user, Administrators, and SYSTEM

Do not create a shared script role or a generic ACL framework.

### Argument specifications and documentation

Keep argument specifications for public option types, choices, nested structure, defaults, required
fields, and `ansible-doc` metadata. Keep role defaults as the executable source of default values.
Use role READMEs for guarantees, ownership, supported platforms, implementation maps, enable
behaviour, invariants, and migration notes. Do not repeat every schema field in prose.

Record the maintenance rules in `AGENTS.md` so later roles follow the same boundary.

## Release and compatibility

This work joins unreleased `0.9.0`; `galaxy.yml` remains `0.9.0`. Requiring list-valued
`fstab_options` and valid disabled share entries are intentional pre-1.0 breaking changes. Expand the
existing `0.9.0` changelog section in the same change. Do not edit historical release entries.

## Testing

- Use Molecule to prove list-only mount options, unconditional required fields, desired share state,
  supported-platform failures, and idempotence.
- Use controller-side Ansible contract tests to prove that Windows task files call static scripts and
  retain the required public options and policy tokens.
- Use Proxmox VM `101` for Windows execution, ACL, and idempotence checks. Restore snapshot `fresh`
  before and after testing.
- Run `ansible-lint .`, `yamllint .`, and each affected Molecule scenario with
  `ANSIBLE_CONFIG=ansible.cfg`.
- Do not run the full `molecule test --all` pre-publish gate for this maintenance change unless the
  collection is being prepared for publication.

## Non-goals

- a common utility role
- custom Ansible modules or filter plugins
- a shared script library across unrelated roles
- localisation-independent `powercfg` parsing
- new platform support
- removal of Fedora or Ubuntu 26.04 support
- a mechanical ban on `set_fact`
- changes to desired-state ownership that are not required by this cleanup
- a collection-wide README rewrite

# Capability Role Naming and Interfaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or
> executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Rename every role after the outcome it delivers, delete the two interfaces that only
restate Ansible module arguments, replace hand-written validation with native argument
specifications, and release the result as `0.8.0`.

**Architecture:** Each role keeps the `0.7.0` platform layout (`tasks/main.yml` validates and
dispatches to `tasks/linux/` or `tasks/windows/`). On top of that, `meta/argument_specs.yml` takes
over option validation, `vars/` takes over distribution data, and a single `<role>_enabled` flag
lets one fleet-wide play vary policy by group. Roles are named for outcomes, never mechanisms.

**Tech Stack:** Ansible core 2.20 (`min_ansible_version` 2.18), YAML, Molecule with the Docker
driver, ansible-lint, yamllint, Windows WinRM integration against Proxmox VM `101`.

**Spec:** `docs/designs/2026-09-02-capability-role-naming-and-interfaces-design.md`

## Global Constraints

- The approved design is `docs/designs/2026-09-02-capability-role-naming-and-interfaces-design.md`.
  It supersedes `docs/designs/2026-08-07-role-structure-and-ownership-design.md`, which must not be
  edited.
- Australian English. No em dashes; use a comma, parentheses, a colon, or a full stop.
- FQCN always: `ansible.builtin.apt`, never `apt`.
- Single quotes; double quotes only when nesting inside single quotes or escaping.
- Explicit `state: present` or `state: absent` on every module where the parameter is optional.
- Multi-line map syntax always, even for a single pair. Sort variables alphabetically.
- `become: true` at task level unless every task in the play requires it.
- Task names: action verb, capitalised, no trailing period, no role prefix.
- Play key order: `hosts`, host options alphabetically, `pre_tasks`, `roles`, `tasks`.
- Task key order: `name`, module, parameters, `loop`, task options alphabetically, `tags`.
- Every Molecule command carries `ANSIBLE_CONFIG=ansible.cfg`.
- Per-change gate: `ansible-lint .`, `yamllint .`, and the scenario covering the change.
- No compatibility aliases for any renamed role or variable.
- Platform `fail_msg` strings are stable contracts asserted verbatim by Molecule scenarios. Rename
  the role and its scenario assertion in the same commit.
- Do not add Fedora support, Linux firewall support, or `install_tailscale` in this plan.
- `galaxy.yml` version and `CHANGELOG.rst` change together, in the final release task only.

## Role and Variable Rename Reference

Every task below refers to this table. Renames are exhaustive; there are no aliases.

| Old role | New role | Variable changes |
| --- | --- | --- |
| `config_systemd_units` | `disable_printer_discovery` | `config_systemd_units_disable_printer_services` to `disable_printer_discovery_enabled`; `config_systemd_units_custom_services` deleted |
| `blacklist_kernel_modules` | `disable_usb_storage` | `blacklist_kernel_modules_disable_usb_storage` to `disable_usb_storage_enabled` |
| `config_desktop` | `auto_login` | `config_desktop_gdm_user` to `auto_login_gdm_user`; `config_desktop_lightdm_user` to `auto_login_lightdm_user`; `config_desktop_qt5ct` deleted |
| `config_firewall` | `allow_ping` | `config_firewall_allow_ping` to `allow_ping_enabled` |
| `config_power` | `power_policy` | `config_power_power_plan` to `power_policy_plan`; `config_power_disable_sleep` to `power_policy_disable_sleep`; `config_power_disable_hibernate` to `power_policy_disable_hibernate`; add `power_policy_enabled` |
| `config_ssh` | `ssh` | `config_ssh_sshd_*` to `ssh_server_*`; `config_ssh_ssh_*` to `ssh_client_*`; `config_ssh_service_name` moves to `vars/` as an internal value; add `ssh_enabled` |
| `config_git` | `git` | `config_git_user_name` to `git_user_name`; `config_git_user_email` to `git_user_email`; add `git_enabled` |
| `create_user` | `local_accounts` | `create_user_accounts` to `local_accounts_users`; add `local_accounts_enabled` |
| `auto_updates` | unchanged | none; `auto_updates_enabled` already exists |
| `install_app` | unchanged | add `install_app_enabled` |
| `mount_network_share` | unchanged | add `mount_network_share_enabled` |
| `time_sync` | unchanged | add `time_sync_enabled` |

`ssh` server variable mapping in full: `port`, `listen_address`, `login_grace_time`,
`permit_root_login`, `max_auth_tries`, `pubkey_authentication`, `password_authentication`,
`permit_empty_passwords`, `allow_users`, `allow_groups`, `deny_users`, `deny_groups`,
`x11_forwarding`, `allow_tcp_forwarding`, `allow_agent_forwarding`, `client_alive_interval`,
`client_alive_count_max`, `use_dns`.

`ssh` client variable mapping in full: `port`, `server_alive_interval`, `server_alive_count_max`,
`pubkey_authentication`, `password_authentication`, `strict_host_key_checking`, `forward_agent`,
`forward_x11`, `connect_timeout`, `compression`, `host_overrides`.

## Target File Map

| Role | Files after this plan |
| --- | --- |
| `allow_ping` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `tasks/main.yml`, `tasks/windows/{main,ping}.yml`, `README.md` |
| `auto_login` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `tasks/main.yml`, `tasks/linux/{main,gdm,lightdm}.yml`, `README.md` |
| `auto_updates` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `tasks/main.yml`, `tasks/linux/{main,apt,dnf}.yml`, `tasks/windows/main.yml`, `templates/*.j2`, `README.md` |
| `disable_printer_discovery` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `tasks/main.yml`, `tasks/linux/main.yml`, `README.md` |
| `disable_usb_storage` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `files/disable-usb-storage.conf`, `tasks/main.yml`, `tasks/linux/main.yml`, `README.md` |
| `git` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `vars/{Debian,Ubuntu}.yml`, `tasks/main.yml`, `tasks/linux/main.yml`, `README.md` |
| `install_app` | unchanged tree plus `meta/argument_specs.yml` |
| `local_accounts` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `tasks/main.yml`, `tasks/linux/{main,accounts,authorized_keys}.yml`, `tasks/windows/{main,accounts,authorized_keys,passwords}.yml`, `README.md` |
| `mount_network_share` | unchanged tree plus `meta/argument_specs.yml` |
| `power_policy` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `tasks/main.yml`, `tasks/windows/main.yml`, `README.md` |
| `ssh` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `vars/{Debian,Ubuntu}.yml`, `handlers/main.yml`, `tasks/main.yml`, `tasks/linux/{main,client,server}.yml`, `tasks/windows/{main,server}.yml`, `templates/*.j2`, `README.md` |
| `time_sync` | `meta/{main,argument_specs}.yml`, `defaults/main.yml`, `vars/{Debian,Ubuntu}.yml`, `handlers/main.yml`, `tasks/main.yml`, `tasks/linux/main.yml`, `README.md` |

Files deleted: `roles/config_systemd_units/tasks/linux/custom_services.yml`,
`roles/config_systemd_units/tasks/linux/printer_services.yml` (folded into `linux/main.yml`),
`roles/config_desktop/tasks/linux/qt5ct.yml`.

---

### Task 1: Establish the conventions in project documentation

**Files:**

- Modify: `AGENTS.md:74-82` (the `Role design` section)
- Modify: `extensions/molecule/README.md`

**Interfaces:**

- Produces: the normative conventions every later task cites. No role code changes.

- [ ] **Step 1: Replace the `Role design` section in `AGENTS.md`**

Replace the whole existing `## Role design` section (lines 74 to 82) with:

```markdown
## Role design

- Name a role after the outcome it produces, never the module, subsystem, or technique it uses.
  No prefixes. Subsystem nouns (`ssh`, `time_sync`, `power_policy`) where the role configures an
  existing subsystem; verb phrases (`disable_usb_storage`, `allow_ping`) for one discrete policy.
- The interface test: a variable must describe the environment, not the module call. A list of
  packages is policy. A list of `systemd_service` parameters is a wrapper and does not belong here.
- `tasks/main.yml` asserts the supported platform, then dispatches to `tasks/linux/main.yml` or
  `tasks/windows/main.yml`. The `fail_msg` is a stable contract asserted verbatim by Molecule.
- `meta/argument_specs.yml` owns option types, `required`, and `choices`. Keep `assert` only for
  platform gates and cross-field rules a specification cannot express.
- Distribution data (package names, paths, service names) lives in `vars/`, loaded with
  `ansible.builtin.first_found` over `{{ ansible_facts.distribution }}.yml` then
  `{{ ansible_facts.os_family }}.yml`. Only a genuine difference in procedure earns a task file.
  A directory under `tasks/linux/` exists only when a family needs more than one file.
- Every policy role exposes `<role>_enabled`, set in `group_vars`. It means "this host should have
  this policy", never "skip an implementation step". Primary capabilities default to `true`;
  anything increasing exposure or reducing security defaults to `false`.
- `<role>_enabled: false` must converge (return the host to the unmanaged state) wherever the
  revert is safe, unambiguous, and confined to artefacts the role owns. Where it cannot, `false`
  skips and the role README states that disabling does not undo a previous run.
- Capability roles own required packages or features, configuration, validation, firewall access,
  and service state. Firewall access belongs to the capability that needs it.
- Unsupported platforms fail explicitly. Each managed artefact has one owning role.
- The collection ships capabilities; the playbook repo ships the standard. No site-specific account
  names, packages, or shares in this collection.
- Every role README records the guarantee, ownership, supported platforms, implementation map,
  interface, enable behaviour, invariants, and migration notes.
```

- [ ] **Step 2: Add the rename contract note to `extensions/molecule/README.md`**

Under the existing `## Scenario conventions` section, append:

```markdown
Scenarios assert platform `fail_msg` strings verbatim. A role rename therefore changes the role
and its scenario assertion in the same commit, along with the scenario directory name and
`scenario.name`.
```

- [ ] **Step 3: Verify the documentation lints**

Run: `. .venv/bin/activate && yamllint . && ansible-lint .`
Expected: PASS. No role code changed, so nothing else can regress.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md extensions/molecule/README.md docs/designs docs/plans
git commit -m "docs: record capability role naming conventions and 0.8.0 design"
```

---

### Task 2: Delete the `custom_services` interface

**Files:**

- Delete: `roles/config_systemd_units/tasks/linux/custom_services.yml`
- Modify: `roles/config_systemd_units/tasks/linux/main.yml`
- Modify: `roles/config_systemd_units/defaults/main.yml`
- Modify: `roles/config_systemd_units/README.md`
- Modify: `extensions/molecule/config_systemd_units/converge.yml`
- Modify: `extensions/molecule/config_systemd_units/verify.yml`
- Modify: `extensions/molecule/config_systemd_units/prepare.yml`

**Interfaces:**

- Consumes: nothing.
- Produces: a `config_systemd_units` role whose only capability is printer-service suppression,
  ready for Task 3's rename.

This task deletes before renaming so Task 3 moves the smallest possible tree.

- [ ] **Step 1: Strip `custom_services` from the Molecule converge**

Replace the entire contents of `extensions/molecule/config_systemd_units/converge.yml` with:

```yaml
---
- name: Converge config_systemd_units scenario
  hosts: all
  gather_facts: true
  roles:
    - role: 'jaythomasonprojects.sys_admin.config_systemd_units'
```

- [ ] **Step 2: Strip `custom_services` fixtures from prepare and verify**

In `extensions/molecule/config_systemd_units/prepare.yml`, delete every task that creates a
`molecule-external.service` or any other custom-unit fixture. Keep only the tasks that install and
start the printer services the role is expected to disable (`cups-browsed`, `avahi-daemon`).

In `extensions/molecule/config_systemd_units/verify.yml`, delete every assertion referring to
`molecule-created.service`, `molecule-remove.service`, or `molecule-external.service`. Keep the
assertions that the printer services are stopped and disabled.

- [ ] **Step 3: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s config_systemd_units`
Expected: FAIL. `tasks/linux/main.yml` still includes `custom_services.yml`, which now validates an
undefined-in-converge variable, and `verify.yml` no longer matches the state the role produces.

- [ ] **Step 4: Delete the task file and its dispatch**

```bash
git rm roles/config_systemd_units/tasks/linux/custom_services.yml
```

Replace the entire contents of `roles/config_systemd_units/tasks/linux/main.yml` with the following.
Note that `printer_services.yml` is folded in: with `custom_services` gone the role has a single
responsibility and the separate file no longer earns its place.

```yaml
---
- name: Require systemd service management
  ansible.builtin.assert:
    that:
      - ansible_facts.service_mgr == 'systemd'
    fail_msg: >-
      config_systemd_units requires a host using systemd as its service manager.

- name: Inspect printer service load states
  ansible.builtin.command:
    argv:
      - 'systemctl'
      - 'show'
      - '--property=LoadState'
      - '--value'
      - '{{ item }}'
  loop: '{{ config_systemd_units_printer_services }}'
  loop_control:
    label: '{{ item }}'
  register: config_systemd_units_load_states
  changed_when: false
  check_mode: false
  failed_when: false
  when: config_systemd_units_disable_printer_services | bool

- name: Stop and disable loaded printer services
  ansible.builtin.systemd_service:
    enabled: false
    name: '{{ item.item }}'
    state: 'stopped'
  loop: '{{ config_systemd_units_load_states.results | default([]) }}'
  loop_control:
    label: '{{ item.item }}'
  become: true
  when:
    - not item.skipped | default(false)
    - item.stdout == 'loaded'
```

```bash
git rm roles/config_systemd_units/tasks/linux/printer_services.yml
```

- [ ] **Step 5: Move the printer service list into `vars/`**

Create `roles/config_systemd_units/vars/main.yml`:

```yaml
---
# Printer discovery services. Internal to the role: callers select the policy,
# not the service list.
config_systemd_units_printer_services:
  - 'avahi-daemon.service'
  - 'avahi-daemon.socket'
  - 'cups-browsed.service'
```

Replace the entire contents of `roles/config_systemd_units/defaults/main.yml` with:

```yaml
---
config_systemd_units_disable_printer_services: true
```

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s config_systemd_units`
Expected: PASS, including the idempotence step.

- [ ] **Step 7: Update the role README**

Rewrite `roles/config_systemd_units/README.md` to describe only printer-service suppression. Delete
every mention of custom services, unit content, ownership markers, and `unit_file_state`. State that
`config_systemd_units_disable_printer_services` skips rather than converges when `false`, and that
disabling it does not restart services a previous run stopped.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles/config_systemd_units extensions/molecule/config_systemd_units
git commit -m "feat!: remove config_systemd_units custom service interface"
```

---

### Task 3: Rename `config_systemd_units` to `disable_printer_discovery`

**Files:**

- Rename: `roles/config_systemd_units/` to `roles/disable_printer_discovery/`
- Rename: `extensions/molecule/config_systemd_units/` to
  `extensions/molecule/disable_printer_discovery/`
- Create: `roles/disable_printer_discovery/meta/argument_specs.yml`
- Modify: all files within both directories

**Interfaces:**

- Consumes: the single-capability role from Task 2.
- Produces: role `jaythomasonprojects.sys_admin.disable_printer_discovery` with the public variable
  `disable_printer_discovery_enabled` (boolean, default `true`).

- [ ] **Step 1: Update the scenario to the new name first**

```bash
git mv extensions/molecule/config_systemd_units extensions/molecule/disable_printer_discovery
```

In `extensions/molecule/disable_printer_discovery/molecule.yml`, set:

```yaml
scenario:
  name: 'disable_printer_discovery'
```

Replace the entire contents of `extensions/molecule/disable_printer_discovery/converge.yml` with:

```yaml
---
- name: Converge disable_printer_discovery scenario
  hosts: all
  gather_facts: true
  roles:
    - role: 'jaythomasonprojects.sys_admin.disable_printer_discovery'
```

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s disable_printer_discovery`
Expected: FAIL with a role-not-found error for
`jaythomasonprojects.sys_admin.disable_printer_discovery`.

- [ ] **Step 3: Rename the role directory and its variables**

```bash
git mv roles/config_systemd_units roles/disable_printer_discovery
```

Across every file under `roles/disable_printer_discovery/`, rename:

- `config_systemd_units_disable_printer_services` to `disable_printer_discovery_enabled`
- `config_systemd_units_printer_services` to `disable_printer_discovery_services`
- `config_systemd_units_load_states` to `disable_printer_discovery_load_states`

Replace `roles/disable_printer_discovery/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.system == 'Linux'
    fail_msg: 'disable_printer_discovery supports Linux hosts only.'

- name: Disable printer discovery on Linux hosts
  ansible.builtin.include_tasks: 'linux/main.yml'
```

Update the `fail_msg` in `tasks/linux/main.yml` to read
`disable_printer_discovery requires a host using systemd as its service manager.`

Replace `roles/disable_printer_discovery/defaults/main.yml` with:

```yaml
---
disable_printer_discovery_enabled: true
```

- [ ] **Step 4: Add the argument specification**

Create `roles/disable_printer_discovery/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Stop and disable printer discovery services
    description:
      - Stops and disables the Avahi and CUPS browsing services on Linux hosts.
      - Services that are not present on the host are already compliant.
    options:
      disable_printer_discovery_enabled:
        description:
          - Whether this host should have printer discovery disabled.
          - Setting this to false skips the policy. It does not restart services
            that an earlier run stopped.
        type: bool
        default: true
```

- [ ] **Step 5: Update role metadata**

In `roles/disable_printer_discovery/meta/main.yml`, set the description to
`Stop and disable Avahi and CUPS printer discovery services`. Leave the platform list unchanged.

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s disable_printer_discovery`
Expected: PASS, including idempotence.

- [ ] **Step 7: Rewrite the role README**

Rewrite `roles/disable_printer_discovery/README.md` with an H1 of `disable_printer_discovery`,
covering: the guarantee, the single `disable_printer_discovery_enabled` variable, the fact that it
skips rather than converges, the supported platform and its exact `fail_msg`, and a migration note
naming the old role and both old variables.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename config_systemd_units to disable_printer_discovery"
```

---

### Task 4: Rename `config_desktop` to `auto_login` and delete the Qt policy

**Files:**

- Rename: `roles/config_desktop/` to `roles/auto_login/`
- Delete: `roles/auto_login/tasks/linux/qt5ct.yml`
- Rename: `extensions/molecule/config_desktop/` to `extensions/molecule/auto_login/`
- Create: `roles/auto_login/meta/argument_specs.yml`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: role `jaythomasonprojects.sys_admin.auto_login` with public variables
  `auto_login_gdm_user` and `auto_login_lightdm_user`, both strings defaulting to `''`.

This role has no separate `_enabled` flag: an empty user string already removes autologin, so the
user variables are their own converging switch.

- [ ] **Step 1: Update the scenario to the new name and variables**

```bash
git mv extensions/molecule/config_desktop extensions/molecule/auto_login
```

In `extensions/molecule/auto_login/molecule.yml`, set `scenario.name` to `auto_login`.

In `extensions/molecule/auto_login/converge.yml`, rename the play, change the role reference to
`jaythomasonprojects.sys_admin.auto_login`, rename `config_desktop_gdm_user` to
`auto_login_gdm_user` and `config_desktop_lightdm_user` to `auto_login_lightdm_user`, delete any
`config_desktop_qt5ct` variable, and change the asserted rejection string at line 32 to
`'auto_login supports Linux hosts only.'`

In `extensions/molecule/auto_login/verify.yml`, delete every assertion about `/etc/environment` or
`QT_QPA_PLATFORMTHEME`. Rename remaining variable references.

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_login`
Expected: FAIL with a role-not-found error for `jaythomasonprojects.sys_admin.auto_login`.

- [ ] **Step 3: Rename the role and delete the Qt policy**

```bash
git mv roles/config_desktop roles/auto_login
git rm roles/auto_login/tasks/linux/qt5ct.yml
```

Replace `roles/auto_login/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.system == 'Linux'
    fail_msg: 'auto_login supports Linux hosts only.'

- name: Configure automatic login on Linux hosts
  ansible.builtin.import_tasks: 'linux/main.yml'
```

Replace `roles/auto_login/tasks/linux/main.yml` with:

```yaml
---
- name: Check if GDM configuration is present
  ansible.builtin.stat:
    path: '/etc/gdm3/custom.conf'
  register: auto_login_gdm_config

- name: Configure GDM automatic login
  ansible.builtin.include_tasks: 'gdm.yml'
  when: auto_login_gdm_config.stat.exists

- name: Check if LightDM configuration directory is present
  ansible.builtin.stat:
    path: '/etc/lightdm/lightdm.conf.d'
  register: auto_login_lightdm_config

- name: Configure LightDM automatic login
  ansible.builtin.include_tasks: 'lightdm.yml'
  when: auto_login_lightdm_config.stat.exists
```

Replace `roles/auto_login/defaults/main.yml` with:

```yaml
---
auto_login_gdm_user: ''
auto_login_lightdm_user: ''
```

In `roles/auto_login/tasks/linux/gdm.yml` and `roles/auto_login/tasks/linux/lightdm.yml`, rename
`config_desktop_gdm_user` to `auto_login_gdm_user` and `config_desktop_lightdm_user` to
`auto_login_lightdm_user`. In `lightdm.yml`, update the `blockinfile` marker to
`# {mark} ANSIBLE MANAGED BLOCK auto_login`.

Leave the `Disable Wayland for GDM` task in place. It is a genuine dependency of autologin in this
environment, not an unrelated policy.

- [ ] **Step 4: Add the argument specification**

Create `roles/auto_login/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Configure display manager automatic login
    description:
      - Configures automatic login for GDM and LightDM where their configuration
        is detected on the host.
      - Setting a user to an empty string removes automatic login for that
        display manager.
    options:
      auto_login_gdm_user:
        description:
          - Account that GDM logs in automatically.
          - Setting this also disables Wayland, which automatic login requires
            in this environment.
          - An empty string disables GDM automatic login.
        type: str
        default: ''
      auto_login_lightdm_user:
        description:
          - Account that LightDM logs in automatically.
          - An empty string removes the managed LightDM autologin block.
        type: str
        default: ''
```

- [ ] **Step 5: Update role metadata**

In `roles/auto_login/meta/main.yml`, set the description to
`Configure GDM and LightDM automatic login policy`.

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_login`
Expected: PASS, including idempotence.

- [ ] **Step 7: Rewrite the role README**

Rewrite `roles/auto_login/README.md`. It must state explicitly that setting `auto_login_gdm_user`
also disables Wayland, and why. Include a migration note listing the old role name and all three old
variables, recording that `config_desktop_qt5ct` is removed with no replacement.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename config_desktop to auto_login and drop Qt theme policy"
```

---

### Task 5: Rename `blacklist_kernel_modules` to `disable_usb_storage`

**Files:**

- Rename: `roles/blacklist_kernel_modules/` to `roles/disable_usb_storage/`
- Rename: `roles/disable_usb_storage/files/blacklist-kernel-modules-usb-storage.conf` to
  `roles/disable_usb_storage/files/disable-usb-storage.conf`
- Rename: `extensions/molecule/blacklist_kernel_modules/` to
  `extensions/molecule/disable_usb_storage/`
- Create: `roles/disable_usb_storage/meta/argument_specs.yml`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: role `jaythomasonprojects.sys_admin.disable_usb_storage` with public variable
  `disable_usb_storage_enabled` (boolean, default `true`, converging).

The behaviour already converges: `false` removes the modprobe file. Only names change.

- [ ] **Step 1: Update the scenario to the new name and variable**

```bash
git mv extensions/molecule/blacklist_kernel_modules extensions/molecule/disable_usb_storage
```

Set `scenario.name` to `disable_usb_storage` in `molecule.yml`. In `converge.yml`, change the role
reference to `jaythomasonprojects.sys_admin.disable_usb_storage` and rename
`blacklist_kernel_modules_disable_usb_storage` to `disable_usb_storage_enabled`.

In `verify.yml`, change the asserted rejection string at line 81 to
`'disable_usb_storage supports Linux hosts only.'` and change every path reference from
`/etc/modprobe.d/blacklist-kernel-modules-usb-storage.conf` to
`/etc/modprobe.d/disable-usb-storage.conf`.

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s disable_usb_storage`
Expected: FAIL with a role-not-found error.

- [ ] **Step 3: Rename the role, the policy file, and the variables**

```bash
git mv roles/blacklist_kernel_modules roles/disable_usb_storage
git mv roles/disable_usb_storage/files/blacklist-kernel-modules-usb-storage.conf \
       roles/disable_usb_storage/files/disable-usb-storage.conf
```

Set the first line of `roles/disable_usb_storage/files/disable-usb-storage.conf` to
`# Ansible managed: disable_usb_storage USB mass-storage policy.` and leave the four policy lines
unchanged.

Replace `roles/disable_usb_storage/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.system == 'Linux'
    fail_msg: 'disable_usb_storage supports Linux hosts only.'

- name: Configure USB mass-storage policy on Linux hosts
  ansible.builtin.import_tasks: 'linux/main.yml'
```

Move the body of `tasks/linux/usb_storage.yml` into `tasks/linux/main.yml`, since the role now has a
single responsibility and the extra file no longer earns its place. Replace
`roles/disable_usb_storage/tasks/linux/main.yml` with:

```yaml
---
- name: Create modprobe configuration directory
  ansible.builtin.file:
    group: 'root'
    mode: '0755'
    owner: 'root'
    path: '/etc/modprobe.d'
    state: 'directory'
  become: true
  when: disable_usb_storage_enabled | bool

- name: Install USB mass-storage policy
  ansible.builtin.copy:
    src: 'disable-usb-storage.conf'
    dest: '/etc/modprobe.d/disable-usb-storage.conf'
    group: 'root'
    mode: '0644'
    owner: 'root'
  become: true
  when: disable_usb_storage_enabled | bool

- name: Remove USB mass-storage policy when disabled
  ansible.builtin.file:
    path: '/etc/modprobe.d/disable-usb-storage.conf'
    state: 'absent'
  become: true
  when: not (disable_usb_storage_enabled | bool)

- name: Unload USB mass-storage kernel modules
  community.general.modprobe:
    name: '{{ item }}'
    state: 'absent'
  loop:
    - 'uas'
    - 'usb_storage'
  become: true
  when: disable_usb_storage_enabled | bool
```

```bash
git rm roles/disable_usb_storage/tasks/linux/usb_storage.yml
```

Replace `roles/disable_usb_storage/defaults/main.yml` with:

```yaml
---
disable_usb_storage_enabled: true
```

- [ ] **Step 4: Add the argument specification**

Create `roles/disable_usb_storage/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Blacklist the USB mass-storage kernel modules
    description:
      - Persistently blacklists the usb-storage and uas kernel modules and
        unloads either when already loaded.
      - USB input devices and the wider USB controller stack are unaffected.
    options:
      disable_usb_storage_enabled:
        description:
          - Whether this host should have USB mass storage disabled.
          - Setting this to false removes the managed modprobe policy file.
            Modules already unloaded are not reloaded until the next boot.
        type: bool
        default: true
```

- [ ] **Step 5: Update role metadata**

In `roles/disable_usb_storage/meta/main.yml`, set the description to
`Blacklist and unload the USB mass-storage kernel modules`.

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s disable_usb_storage`
Expected: PASS, including idempotence.

- [ ] **Step 7: Rewrite the role README**

Rewrite `roles/disable_usb_storage/README.md`. State that the flag converges, that a `false` run
removes the policy file, and that unloaded modules return only after a reboot. Include a migration
note naming the old role and variable.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename blacklist_kernel_modules to disable_usb_storage"
```

---

### Task 6: Rename `config_firewall` to `allow_ping` and make it converge

**Files:**

- Rename: `roles/config_firewall/` to `roles/allow_ping/`
- Rename: `extensions/molecule/config_firewall/` to `extensions/molecule/allow_ping/`
- Create: `roles/allow_ping/meta/argument_specs.yml`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: role `jaythomasonprojects.sys_admin.allow_ping` with public variable
  `allow_ping_enabled` (boolean, default `true`, converging).

The behaviour change: `false` previously skipped, leaving stale rules. It now sets both rules
`absent`. The Docker scenario can only exercise the platform rejection, so the rule behaviour itself
is verified in the Windows integration pass in Task 16.

- [ ] **Step 1: Update the scenario to the new name**

```bash
git mv extensions/molecule/config_firewall extensions/molecule/allow_ping
```

Set `scenario.name` to `allow_ping` in `molecule.yml`. Replace the entire contents of
`extensions/molecule/allow_ping/converge.yml` with:

```yaml
---
- name: Converge allow_ping scenario
  hosts: all
  gather_facts: true
  tasks:
    - name: Reject Linux hosts
      block:
        - name: Configure ping access on Linux
          ansible.builtin.include_role:
            name: 'jaythomasonprojects.sys_admin.allow_ping'
      rescue:
        - name: Record Linux rejection
          ansible.builtin.set_fact:
            allow_ping_linux_error: >-
              {{ ansible_failed_result.msg | default('') }}

    - name: Assert Linux is rejected
      ansible.builtin.assert:
        that:
          - >-
            allow_ping_linux_error | default('') ==
            'allow_ping supports Windows hosts only.'
```

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s allow_ping`
Expected: FAIL with a role-not-found error.

- [ ] **Step 3: Rename the role and collapse the dispatch**

```bash
git mv roles/config_firewall roles/allow_ping
```

Replace `roles/allow_ping/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.os_family == 'Windows'
    fail_msg: 'allow_ping supports Windows hosts only.'

- name: Manage ping access on Windows hosts
  ansible.builtin.include_tasks: 'windows/main.yml'
```

Delete `roles/allow_ping/tasks/windows/ping.yml` and fold its content into
`roles/allow_ping/tasks/windows/main.yml`, which becomes the whole Windows implementation:

```yaml
---
# ICMP type 8 is IPv4 Echo Request; type 128 is the IPv6 equivalent.
- name: Manage ICMPv4 ping rule
  community.windows.win_firewall_rule:
    action: allow
    direction: in
    enabled: true
    icmp_type_code: '8:*'
    name: 'Allow ICMPv4 ping'
    protocol: 'icmpv4'
    state: "{{ 'present' if allow_ping_enabled | bool else 'absent' }}"

- name: Manage ICMPv6 ping rule
  community.windows.win_firewall_rule:
    action: allow
    direction: in
    enabled: true
    icmp_type_code: '128:*'
    name: 'Allow ICMPv6 ping'
    protocol: 'icmpv6'
    state: "{{ 'present' if allow_ping_enabled | bool else 'absent' }}"
```

```bash
git rm roles/allow_ping/tasks/windows/ping.yml
```

Replace `roles/allow_ping/defaults/main.yml` with:

```yaml
---
allow_ping_enabled: true
```

- [ ] **Step 4: Add the argument specification**

Create `roles/allow_ping/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Manage the Windows inbound ICMP echo request rules
    description:
      - Owns the Allow ICMPv4 ping and Allow ICMPv6 ping inbound firewall rules.
      - Firewall access for a service belongs to that service's role. This role
        covers ping only, because no service owns ICMP.
    options:
      allow_ping_enabled:
        description:
          - Whether this host should answer ping.
          - Setting this to false removes both managed rules.
        type: bool
        default: true
```

- [ ] **Step 5: Update role metadata**

In `roles/allow_ping/meta/main.yml`, set the description to
`Manage the Windows inbound ICMP echo request firewall rules`.

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s allow_ping`
Expected: PASS. This proves the platform contract only; rule behaviour is covered in Task 16.

- [ ] **Step 7: Rewrite the role README**

Rewrite `roles/allow_ping/README.md`. It must state that the flag converges, that `false` removes
both rules, and that this replaces the previous skip behaviour. Explain that firewall access for a
service belongs to that service's role, naming `ssh` and its `ssh_server_port`-driven rule as the
example. Include a migration note for `config_firewall` and `config_firewall_allow_ping`.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename config_firewall to allow_ping and converge on disable"
```

---

### Task 7: Rename `config_power` to `power_policy`

**Files:**

- Rename: `roles/config_power/` to `roles/power_policy/`
- Rename: `extensions/molecule/config_power/` to `extensions/molecule/power_policy/`
- Create: `roles/power_policy/meta/argument_specs.yml`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: role `jaythomasonprojects.sys_admin.power_policy` with public variables
  `power_policy_enabled` (bool, default `true`), `power_policy_plan` (str, default
  `'high performance'`), `power_policy_disable_sleep` (bool, default `true`),
  `power_policy_disable_hibernate` (bool, default `true`).

- [ ] **Step 1: Update the scenario to the new name**

```bash
git mv extensions/molecule/config_power extensions/molecule/power_policy
```

Set `scenario.name` to `power_policy`. In `converge.yml`, change the role reference to
`jaythomasonprojects.sys_admin.power_policy`, rename the play, and change the asserted string at
line 22 to `'power_policy supports Windows hosts only.'`

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s power_policy`
Expected: FAIL with a role-not-found error.

- [ ] **Step 3: Rename the role and its variables**

```bash
git mv roles/config_power roles/power_policy
```

Replace `roles/power_policy/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.os_family == 'Windows'
    fail_msg: 'power_policy supports Windows hosts only.'

- name: Configure power policy on Windows hosts
  ansible.builtin.include_tasks: 'windows/main.yml'
  when: power_policy_enabled | bool
```

Replace `roles/power_policy/defaults/main.yml` with:

```yaml
---
power_policy_disable_hibernate: true
power_policy_disable_sleep: true
power_policy_enabled: true
power_policy_plan: 'high performance'
```

In `roles/power_policy/tasks/windows/main.yml`, rename `config_power_power_plan` to
`power_policy_plan`, `config_power_disable_sleep` to `power_policy_disable_sleep`,
`config_power_disable_hibernate` to `power_policy_disable_hibernate`, and
`config_power_sleep_result` to `power_policy_sleep_result`. Leave the PowerShell script bodies
unchanged.

- [ ] **Step 4: Add the argument specification**

Create `roles/power_policy/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Configure Windows power plan, timeouts, and hibernation
    description:
      - Applies the active power plan, clears sleep and monitor timeouts on both
        AC and DC power, and disables hibernation.
    options:
      power_policy_disable_hibernate:
        description: Whether to run powercfg /hibernate off.
        type: bool
        default: true
      power_policy_disable_sleep:
        description:
          - Whether to set monitor and standby timeouts to never on AC and DC.
        type: bool
        default: true
      power_policy_enabled:
        description:
          - Whether this host should have a managed power policy.
          - Setting this to false skips the role. It does not restore the
            timeouts or power plan an earlier run applied.
        type: bool
        default: true
      power_policy_plan:
        description:
          - Name of the Windows power plan to activate.
          - An empty string leaves the active plan unchanged.
        type: str
        default: 'high performance'
```

- [ ] **Step 5: Update role metadata**

In `roles/power_policy/meta/main.yml`, set the description to
`Configure Windows power plan, sleep timeouts, and hibernation policy`.

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s power_policy`
Expected: PASS.

- [ ] **Step 7: Rewrite the role README**

Rewrite `roles/power_policy/README.md`, stating that `power_policy_enabled` skips rather than
converges and why. Include a migration note mapping all three old variable names.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename config_power to power_policy"
```

---

### Task 8: Rename `config_git` to `git` and add the `vars/` structure

**Files:**

- Rename: `roles/config_git/` to `roles/git/`
- Create: `roles/git/defaults/main.yml` (the role currently has none)
- Create: `roles/git/vars/Debian.yml`, `roles/git/vars/Ubuntu.yml`
- Create: `roles/git/meta/argument_specs.yml`
- Rename: `extensions/molecule/config_git/` to `extensions/molecule/git/`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: role `jaythomasonprojects.sys_admin.git` with public variables `git_enabled` (bool,
  default `true`), `git_user_name` (str, default `''`), `git_user_email` (str, default `''`).
- Produces: the `vars/` first-found pattern that Tasks 9 and 10 copy.

This role currently ships **no `defaults/main.yml`**, so `config_git_user_name | length > 0` fails
on an undefined variable unless the caller supplies it. The argument specification fixes this by
declaring documented defaults.

- [ ] **Step 1: Update the scenario to the new name and variables**

```bash
git mv extensions/molecule/config_git extensions/molecule/git
```

Set `scenario.name` to `git`. In `converge.yml`, change the role reference to
`jaythomasonprojects.sys_admin.git`, rename `config_git_user_name` to `git_user_name` and
`config_git_user_email` to `git_user_email`, change the asserted string at line 33 to
`'git supports Linux hosts only.'` and at line 55 to `'git supports Debian and Ubuntu hosts only.'`

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s git`
Expected: FAIL with a role-not-found error.

- [ ] **Step 3: Rename the role and introduce `vars/`**

```bash
git mv roles/config_git roles/git
```

Create `roles/git/vars/Debian.yml`:

```yaml
---
git_package: 'git'
```

Create `roles/git/vars/Ubuntu.yml`:

```yaml
---
git_package: 'git'
```

Create `roles/git/defaults/main.yml`:

```yaml
---
git_enabled: true
git_user_email: ''
git_user_name: ''
```

Replace `roles/git/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.system == 'Linux'
    fail_msg: 'git supports Linux hosts only.'

- name: Configure Git on Linux hosts
  ansible.builtin.include_tasks: 'linux/main.yml'
  when: git_enabled | bool
```

Replace `roles/git/tasks/linux/main.yml` with:

```yaml
---
- name: Assert supported Linux distribution
  ansible.builtin.assert:
    that:
      - ansible_facts.distribution in ['Debian', 'Ubuntu']
    fail_msg: 'git supports Debian and Ubuntu hosts only.'

# Distribution data lives in vars/ so the task body stays distribution-agnostic
# and Fedora support later needs a vars file, not a new task file.
- name: Load distribution variables
  ansible.builtin.include_vars: '{{ lookup("ansible.builtin.first_found", git_vars_params) }}'
  vars:
    git_vars_params:
      files:
        - '{{ ansible_facts.distribution }}.yml'
        - '{{ ansible_facts.os_family }}.yml'
      paths:
        - 'vars'

- name: Install Git
  ansible.builtin.package:
    name: '{{ git_package }}'
    state: present
  become: true

- name: Set Git user name
  community.general.git_config:
    name: 'user.name'
    scope: 'global'
    state: present
    value: '{{ git_user_name }}'
  when: git_user_name | length > 0

- name: Set Git user email
  community.general.git_config:
    name: 'user.email'
    scope: 'global'
    state: present
    value: '{{ git_user_email }}'
  when: git_user_email | length > 0
```

Note the change from `ansible.builtin.apt` with `update_cache: true` to `ansible.builtin.package`.
If the scenario's image needs a fresh APT cache, add the cache refresh to the scenario's
`prepare.yml`, not to the role.

- [ ] **Step 4: Add the argument specification**

Create `roles/git/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Install Git and configure global identity
    description:
      - Installs Git and sets the global user identity for the account the play
        runs as.
      - Configuring identity for multiple accounts is not supported.
    options:
      git_enabled:
        description:
          - Whether this host should have managed Git configuration.
          - Setting this to false skips the role. It does not remove Git or the
            identity an earlier run configured.
        type: bool
        default: true
      git_user_email:
        description:
          - Value for the global user.email setting.
          - An empty string leaves the existing value unchanged.
        type: str
        default: ''
      git_user_name:
        description:
          - Value for the global user.name setting.
          - An empty string leaves the existing value unchanged.
        type: str
        default: ''
```

- [ ] **Step 5: Update role metadata**

In `roles/git/meta/main.yml`, set the description to
`Install Git and configure global user identity`.

- [ ] **Step 6: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s git`
Expected: PASS, including idempotence.

- [ ] **Step 7: Rewrite the role README**

Rewrite `roles/git/README.md`. Document the execution-user semantics (identity applies to the
account the play runs as), the `vars/` structure and why Fedora is not yet claimed, and the enable
flag's skip behaviour. Include a migration note for `config_git` and both old variables.

- [ ] **Step 8: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename config_git to git and split distribution data into vars"
```

---

### Task 9: Add `vars/`, an argument specification, and an enable flag to `time_sync`

**Files:**

- Create: `roles/time_sync/vars/Debian.yml`, `roles/time_sync/vars/Ubuntu.yml`
- Create: `roles/time_sync/meta/argument_specs.yml`
- Modify: `roles/time_sync/defaults/main.yml`, `roles/time_sync/tasks/main.yml`,
  `roles/time_sync/tasks/linux/main.yml`, `roles/time_sync/handlers/main.yml`,
  `roles/time_sync/README.md`
- Modify: `extensions/molecule/time_sync/converge.yml`

**Interfaces:**

- Consumes: the `vars/` first-found pattern established in Task 8.
- Produces: `time_sync_enabled` (bool, default `true`) alongside the existing `time_sync_server`
  (str, default `''`).

No rename. The role name already describes its outcome.

- [ ] **Step 1: Add the enable-flag case to the scenario**

In `extensions/molecule/time_sync/converge.yml`, after the existing role invocation, add a block
that includes the role with `time_sync_enabled: false` and asserts no failure occurs:

```yaml
    - name: Apply disabled time synchronisation
      ansible.builtin.include_role:
        name: 'jaythomasonprojects.sys_admin.time_sync'
      vars:
        time_sync_enabled: false
        time_sync_server: ''
```

An empty `time_sync_server` with the role enabled currently fails validation. This step proves the
enable flag short-circuits before that assertion, which is the contract.

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync`
Expected: FAIL with `time_sync_server must be a non-empty string.`, because the enable flag does not
yet exist and validation still runs.

- [ ] **Step 3: Add the flag, the `vars/` files, and gate the dispatch**

Create `roles/time_sync/vars/Debian.yml`:

```yaml
---
time_sync_config_dir: '/etc/ntpsec'
time_sync_config_file: '/etc/ntpsec/ntp.conf'
time_sync_package: 'ntpsec'
time_sync_service: 'ntpsec'
```

Create `roles/time_sync/vars/Ubuntu.yml` with identical content.

Replace `roles/time_sync/defaults/main.yml` with:

```yaml
---
time_sync_enabled: true
time_sync_server: ''
```

Replace `roles/time_sync/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.system == 'Linux'
    fail_msg: 'time_sync supports Linux hosts only.'

- name: Configure time synchronisation on Linux hosts
  ansible.builtin.include_tasks: 'linux/main.yml'
  when: time_sync_enabled | bool
```

In `roles/time_sync/tasks/linux/main.yml`: keep the distribution assertion and the
`time_sync_server` non-empty assertion (a cross-field rule the specification cannot express, since
it is only required when the role is enabled). Insert the `include_vars` first-found block after the
distribution assertion, using `time_sync_vars_params` as the variable name. Then replace every
hardcoded value with its variable: `ntpsec` becomes `{{ time_sync_package }}` in the install task
(switching `ansible.builtin.apt` to `ansible.builtin.package`), `/etc/ntpsec` becomes
`{{ time_sync_config_dir }}`, and `/etc/ntpsec/ntp.conf` becomes `{{ time_sync_config_file }}` in
all four tasks that reference it.

In `roles/time_sync/handlers/main.yml`, replace the hardcoded `'ntpsec'` service name with
`'{{ time_sync_service }}'`.

- [ ] **Step 4: Add the argument specification**

Create `roles/time_sync/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Configure ntpsec time synchronisation
    description:
      - Installs ntpsec, points it at a single upstream pool, comments out
        unmanaged pool entries, and runs the service.
    options:
      time_sync_enabled:
        description:
          - Whether this host should have managed time synchronisation.
          - Setting this to false skips the role. It does not remove ntpsec or
            restore pool entries an earlier run commented out.
        type: bool
        default: true
      time_sync_server:
        description:
          - Upstream NTP pool hostname.
          - Required when time_sync_enabled is true.
        type: str
        default: ''
```

- [ ] **Step 5: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync`
Expected: PASS, including idempotence.

- [ ] **Step 6: Update the role README**

Update `roles/time_sync/README.md` with the enable flag, its skip behaviour, and the `vars/`
structure. State that `time_sync_server` is required only when the role is enabled.

- [ ] **Step 7: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles/time_sync extensions/molecule/time_sync
git commit -m "feat: add time_sync enable flag, argument spec, and distribution vars"
```

---

### Task 10: Rename `config_ssh` to `ssh` and add the `vars/` structure

**Files:**

- Rename: `roles/config_ssh/` to `roles/ssh/`
- Create: `roles/ssh/vars/Debian.yml`, `roles/ssh/vars/Ubuntu.yml`
- Create: `roles/ssh/meta/argument_specs.yml`
- Modify: every file under `roles/ssh/`, including both templates
- Rename: `extensions/molecule/config_ssh/` to `extensions/molecule/ssh/`

**Interfaces:**

- Consumes: the `vars/` first-found pattern from Task 8.
- Produces: role `jaythomasonprojects.sys_admin.ssh`. Public variables are `ssh_enabled` plus the
  `ssh_server_*` and `ssh_client_*` families listed in the Rename Reference above. `ssh_service_name`
  becomes an internal `vars/` value and is no longer a caller-facing default.
- Produces: `ssh_server_port`, which `allow_ping`'s README cites as the example of a service owning
  its own firewall rule.

This is the largest rename: 30 public variables plus two Jinja templates.

- [ ] **Step 1: Update the scenario to the new names**

```bash
git mv extensions/molecule/config_ssh extensions/molecule/ssh
```

Set `scenario.name` to `ssh`. In `converge.yml`, change the role reference to
`jaythomasonprojects.sys_admin.ssh`, rename every `config_ssh_sshd_*` variable to `ssh_server_*` and
every `config_ssh_ssh_*` to `ssh_client_*`, and change the asserted string at line 38 to
`'ssh supports Linux and Windows hosts only.'` Apply the same variable renames in `verify.yml` and
`prepare.yml`.

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s ssh`
Expected: FAIL with a role-not-found error.

- [ ] **Step 3: Rename the role and replace the service-name sentinel with `vars/`**

```bash
git mv roles/config_ssh roles/ssh
```

Create `roles/ssh/vars/Debian.yml`:

```yaml
---
ssh_packages:
  - 'openssh-client'
  - 'openssh-server'
ssh_service_name: 'ssh'
```

Create `roles/ssh/vars/Ubuntu.yml` with identical content.

Replace `roles/ssh/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - >-
        ansible_facts.os_family == 'Windows'
        or ansible_facts.distribution | default('') in ['Debian', 'Ubuntu']
    fail_msg: 'ssh supports Linux and Windows hosts only.'

- name: Configure SSH on Debian and Ubuntu hosts
  ansible.builtin.include_tasks: 'linux/main.yml'
  when:
    - ssh_enabled | bool
    - ansible_facts.distribution | default('') in ['Debian', 'Ubuntu']

- name: Configure SSH on Windows hosts
  ansible.builtin.include_tasks: 'windows/main.yml'
  when:
    - ssh_enabled | bool
    - ansible_facts.os_family == 'Windows'
```

Replace `roles/ssh/tasks/linux/main.yml` with:

```yaml
---
- name: Load distribution variables
  ansible.builtin.include_vars: '{{ lookup("ansible.builtin.first_found", ssh_vars_params) }}'
  vars:
    ssh_vars_params:
      files:
        - '{{ ansible_facts.distribution }}.yml'
        - '{{ ansible_facts.os_family }}.yml'
      paths:
        - 'vars'

- name: Install OpenSSH packages
  ansible.builtin.package:
    name: '{{ ssh_packages }}'
    state: present
  become: true

- name: Configure SSH client
  ansible.builtin.include_tasks: 'client.yml'

- name: Configure SSH server
  ansible.builtin.include_tasks: 'server.yml'
```

This removes the `Detect Debian SSH service name` `stat` task, the `Select SSH service name`
`set_fact`, and the `config_ssh_service_name: ~` sentinel default. The service name now comes from
`vars/`.

- [ ] **Step 4: Rename variables throughout the role**

Apply the full `ssh_server_*` and `ssh_client_*` mapping from the Rename Reference across:

- `roles/ssh/defaults/main.yml` (delete the `config_ssh_service_name: ~` entry entirely)
- `roles/ssh/handlers/main.yml` (`config_ssh_service_name` becomes `ssh_service_name`)
- `roles/ssh/tasks/linux/server.yml` (`config_ssh_cloudinit_conf` becomes `ssh_cloudinit_conf`)
- `roles/ssh/tasks/windows/server.yml` (`config_ssh_install` becomes `ssh_install`;
  `config_ssh_sshd_port` becomes `ssh_server_port`)
- `roles/ssh/templates/ssh_custom.conf.j2` (all `config_ssh_ssh_*` become `ssh_client_*`)
- `roles/ssh/templates/sshd_custom.conf.j2` (all `config_ssh_sshd_*` become `ssh_server_*`)
- `roles/ssh/templates/sshd_config_win.j2` (all `config_ssh_sshd_*` become `ssh_server_*`)

Sort `roles/ssh/defaults/main.yml` alphabetically, with `ssh_enabled: true` added.

- [ ] **Step 5: Add the argument specification**

Create `roles/ssh/meta/argument_specs.yml`. Declare every public option with its type and default.
Use `type: int` for `ssh_server_port`, `ssh_client_port`, `ssh_server_max_auth_tries`,
`ssh_server_client_alive_interval`, `ssh_server_client_alive_count_max`,
`ssh_client_server_alive_interval`, `ssh_client_server_alive_count_max`, and
`ssh_client_connect_timeout`. Use `type: bool` for `ssh_enabled`. Use `type: list` with
`elements: str` for `ssh_server_allow_users`, `ssh_server_allow_groups`, `ssh_server_deny_users`,
and `ssh_server_deny_groups`, each defaulting to `null`. Use `type: list` with `elements: dict` and
nested `options` for `ssh_client_host_overrides`, whose items take `host` (str, required) and
`settings` (dict, required). Use `type: str` with `choices` for the sshd yes/no options, adding
`prohibit-password` to the `ssh_server_permit_root_login` choices and `ask` to
`ssh_client_strict_host_key_checking`. Everything else is `type: str`.

- [ ] **Step 6: Update role metadata**

In `roles/ssh/meta/main.yml`, set the description to
`Install OpenSSH and own client policy, server policy, firewall access, and service state`.

- [ ] **Step 7: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s ssh`
Expected: PASS, including idempotence.

- [ ] **Step 8: Rewrite the role README**

Rewrite `roles/ssh/README.md`. It must state that the role owns the Windows firewall rule keyed to
`ssh_server_port`, that authorised keys belong to `local_accounts`, that `ssh_enabled` skips rather
than converges, and that the service name now comes from `vars/` rather than runtime detection.
Include a full migration table mapping all 30 old variable names to new ones and recording that
`config_ssh_service_name` is removed from the public interface.

- [ ] **Step 9: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename config_ssh to ssh with server and client variable families"
```

---

### Task 11: Rename `create_user` to `local_accounts` and make `password` optional

**Files:**

- Rename: `roles/create_user/` to `roles/local_accounts/`
- Create: `roles/local_accounts/meta/argument_specs.yml`
- Rename: `extensions/molecule/create_user/` to `extensions/molecule/local_accounts/`

**Interfaces:**

- Consumes: nothing from earlier tasks. Task 10's README references this role for key ownership.
- Produces: role `jaythomasonprojects.sys_admin.local_accounts` with public variables
  `local_accounts_enabled` (bool, default `true`) and `local_accounts_users` (list of dict, default
  `[]`).

Account item schema after this task: `name` (str, required), `password` (str, optional),
`append` (bool), `comment` (str), `create_home` (bool), `groups` (list of str),
`password_never_expires` (bool), `shell` (str), `ssh_authorized_keys` (list of str),
`update_password` (str).

- [ ] **Step 1: Update the scenario and prove a key-only account**

```bash
git mv extensions/molecule/create_user extensions/molecule/local_accounts
```

Set `scenario.name` to `local_accounts`. In `converge.yml`, change the role reference to
`jaythomasonprojects.sys_admin.local_accounts`, rename `create_user_accounts` to
`local_accounts_users`, change the asserted string at line 48 to
`'local_accounts supports Linux and Windows hosts only.'`, and **delete the `password: '!'` line**
from the `molecule` account so the fixture proves a key-only account.

In `verify.yml`, rename every `create_user_*` reference and add an assertion that the `molecule`
account exists and its `authorized_keys` file contains both fixture keys.

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts`
Expected: FAIL with a role-not-found error.

- [ ] **Step 3: Rename the role and its variables**

```bash
git mv roles/create_user roles/local_accounts
```

Replace `roles/local_accounts/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - >-
        ansible_facts.system == 'Linux'
        or ansible_facts.os_family == 'Windows'
    fail_msg: 'local_accounts supports Linux and Windows hosts only.'

- name: Configure local accounts on Linux hosts
  ansible.builtin.include_tasks: 'linux/main.yml'
  when:
    - local_accounts_enabled | bool
    - ansible_facts.system == 'Linux'

- name: Configure local accounts on Windows hosts
  ansible.builtin.include_tasks: 'windows/main.yml'
  when:
    - local_accounts_enabled | bool
    - ansible_facts.os_family == 'Windows'
```

Replace `roles/local_accounts/defaults/main.yml` with:

```yaml
---
local_accounts_enabled: true
local_accounts_users: []
```

Across all six task files under `roles/local_accounts/tasks/`, rename `create_user_accounts` to
`local_accounts_users`, `create_user_windows_administrators` to
`local_accounts_windows_administrators`, and `create_user_windows_administrator_keys` to
`local_accounts_windows_administrator_keys`.

- [ ] **Step 4: Make `password` optional on both platforms**

In `roles/local_accounts/tasks/linux/accounts.yml`, change the password parameter to:

```yaml
    password: '{{ item.password | default(omit) }}'
```

In `roles/local_accounts/tasks/windows/accounts.yml`, change the password parameter identically.

Replace the whole of `roles/local_accounts/tasks/windows/passwords.yml` with a version that skips
accounts without a password:

```yaml
---
- name: Update Windows user passwords
  ansible.windows.win_user:
    name: '{{ item.name }}'
    password: '{{ item.password }}'
    state: present
    update_password: '{{ item.update_password | default("always") }}'
  loop: '{{ local_accounts_users }}'
  when: item.password is defined
  no_log: true
```

Retain `no_log: true` on every task that touches a password or a key.

- [ ] **Step 5: Add the argument specification**

Create `roles/local_accounts/meta/argument_specs.yml`:

```yaml
---
argument_specs:
  main:
    short_description: Manage local accounts, authorised keys, and password policy
    description:
      - Owns local account fields, authorised-key contents, Windows key-file
        ACLs, and Windows password policy.
      - Account names and passwords are site data. Supply them from group_vars
        in the consuming playbook repository, not from this collection.
    options:
      local_accounts_enabled:
        description:
          - Whether this host should have managed local accounts.
          - Setting this to false skips the role. It does not remove accounts an
            earlier run created.
        type: bool
        default: true
      local_accounts_users:
        description: Local accounts to manage on this host.
        type: list
        elements: dict
        default: []
        options:
          append:
            description: Add the supplied groups instead of replacing them.
            type: bool
            default: false
          comment:
            description: Account description, or GECOS field on Linux.
            type: str
          create_home:
            description: Whether to create a Linux home directory.
            type: bool
            default: true
          groups:
            description: Linux groups or Windows local groups for the account.
            type: list
            elements: str
          name:
            description: Account name.
            type: str
            required: true
          password:
            description:
              - Hashed password on Linux, plain password on Windows.
              - Omit for key-only accounts. The parameter is then not sent.
            type: str
          password_never_expires:
            description: Windows password expiry policy.
            type: bool
          shell:
            description: Linux login shell.
            type: str
          ssh_authorized_keys:
            description:
              - Public keys for the account.
              - Linux keys are additive. Windows treats the list as the complete
                content of the account's key file.
            type: list
            elements: str
          update_password:
            description: Windows final password policy.
            type: str
            choices:
              - 'always'
              - 'on_create'
            default: 'always'
```

- [ ] **Step 6: Update role metadata**

In `roles/local_accounts/meta/main.yml`, set the description to
`Manage local accounts, authorised keys, and password policy`.

- [ ] **Step 7: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts`
Expected: PASS, including idempotence, with the key-only account created successfully.

- [ ] **Step 8: Rewrite the role README**

Rewrite `roles/local_accounts/README.md`. Preserve the existing Windows key-semantics and ACL
sections verbatim, updating variable names. Add: why the role is named `local_accounts` (it owns the
full lifecycle of a set of accounts, and "local" excludes domain accounts), that `password` is now
optional, that the standard account set belongs in the consuming repository's `group_vars`, and that
`ssh` must be applied separately for OpenSSH itself. Include a migration note for `create_user` and
`create_user_accounts`.

- [ ] **Step 9: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles extensions/molecule
git commit -m "feat!: rename create_user to local_accounts and make password optional"
```

---

### Task 12: Add an argument specification and enable flag to `install_app`

**Files:**

- Create: `roles/install_app/meta/argument_specs.yml`
- Modify: `roles/install_app/defaults/main.yml`, `roles/install_app/tasks/main.yml`,
  `roles/install_app/README.md`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: `install_app_enabled` (bool, default `true`). All existing list variables keep their
  names.

No rename: `install_app` already describes its outcome, and generic package installation is
legitimately the capability.

- [ ] **Step 1: Add the enable-flag case to the scenario**

In `extensions/molecule/install_app/converge.yml`, add a block that includes the role with
`install_app_enabled: false` and a package name that does not exist, asserting no failure:

```yaml
    - name: Apply disabled application installation
      ansible.builtin.include_role:
        name: 'jaythomasonprojects.sys_admin.install_app'
      vars:
        install_app_enabled: false
        install_app_packages:
          - 'this-package-does-not-exist'
```

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app`
Expected: FAIL with a package-not-found error, because the enable flag does not yet gate the
dispatch.

- [ ] **Step 3: Add the flag and gate the dispatch**

Replace `roles/install_app/tasks/main.yml` with:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - >-
        ansible_facts.system == 'Linux'
        or ansible_facts.os_family == 'Windows'
    fail_msg: 'install_app supports Linux and Windows hosts only.'

- name: Install applications on Linux hosts
  ansible.builtin.include_tasks: 'linux/main.yml'
  when:
    - install_app_enabled | bool
    - ansible_facts.system == 'Linux'

- name: Install applications on Windows hosts
  ansible.builtin.include_tasks: 'windows/main.yml'
  when:
    - install_app_enabled | bool
    - ansible_facts.os_family == 'Windows'
```

Replace `roles/install_app/defaults/main.yml` with:

```yaml
---
install_app_debs: []
install_app_enabled: true
install_app_flatpaks: []
install_app_manage_flatpak_remote: true
install_app_npm_packages: []
install_app_packages: []
```

- [ ] **Step 4: Add the argument specification**

Create `roles/install_app/meta/argument_specs.yml` declaring: `install_app_enabled` (bool, default
`true`), `install_app_packages` (list of str, default `[]`), `install_app_npm_packages` (list of
str, default `[]`), `install_app_flatpaks` (list of str, default `[]`),
`install_app_manage_flatpak_remote` (bool, default `true`), and `install_app_debs` (list of dict,
default `[]`) with nested options `checksum` (str), `creates` (str), `deb` (str), `dest` (str),
`enabled` (bool, default `true`), `mode` (str, default `'0644'`), `name` (str), `src` (str),
`state` (str, choices `present` and `absent`, default `present`), and `url` (str).

Keep the existing cross-field assertion in `roles/install_app/tasks/linux/deb_package.yml`
unchanged: the "src or url or deb, and dest when src or url" rule cannot be expressed in a
specification. Keep the npm package-name regex assertion in `roles/install_app/tasks/linux/npm.yml`
for the same reason.

- [ ] **Step 5: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app`
Expected: PASS, including idempotence.

- [ ] **Step 6: Update the role README**

Add the enable flag and its skip behaviour to `roles/install_app/README.md`, and state that package
lists are site data supplied from the consuming repository.

- [ ] **Step 7: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles/install_app extensions/molecule/install_app
git commit -m "feat: add install_app enable flag and argument spec"
```

---

### Task 13: Add an argument specification and enable flag to `mount_network_share`

**Files:**

- Create: `roles/mount_network_share/meta/argument_specs.yml`
- Modify: `roles/mount_network_share/defaults/main.yml`,
  `roles/mount_network_share/tasks/main.yml`, `roles/mount_network_share/README.md`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: `mount_network_share_enabled` (bool, default `true`). `mount_network_share_shares` and
  `mount_network_share_reload_remote_fs` keep their names.

- [ ] **Step 1: Add the enable-flag case to the scenario**

In `extensions/molecule/mount_network_share/converge.yml`, add a block that includes the role with
`mount_network_share_enabled: false` and a share entry missing its required `mount_point`, asserting
no failure occurs.

- [ ] **Step 2: Run the scenario to verify it fails**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share`
Expected: FAIL on the share-entry validation assertion, because the flag does not yet gate it.

- [ ] **Step 3: Add the flag and gate the dispatch**

Replace `roles/mount_network_share/tasks/main.yml` with a version that checks the enable flag before
anything else, moving the existing entry validation behind the gate:

```yaml
---
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - >-
        ansible_facts.system == 'Linux'
        or ansible_facts.os_family == 'Windows'
    fail_msg: 'mount_network_share supports Linux and Windows hosts only.'

- name: Manage network shares
  when: mount_network_share_enabled | bool
  block:
    - name: Validate share credential pairing
      ansible.builtin.assert:
        that:
          - >-
            (
              mount_network_share_item.username is not defined
              and mount_network_share_item.password is not defined
            )
            or
            (
              mount_network_share_item.username is string
              and mount_network_share_item.username | length > 0
              and mount_network_share_item.password is string
              and mount_network_share_item.password | length > 0
            )
        fail_msg: >-
          Define username and password together as non-empty strings, or omit
          both.
      loop: '{{ mount_network_share_shares }}'
      loop_control:
        loop_var: mount_network_share_item
        label: '{{ mount_network_share_item.name | default("unnamed") }}'
      no_log: true

    - name: Manage network shares on Linux hosts
      ansible.builtin.include_tasks: 'linux/main.yml'
      when: ansible_facts.system == 'Linux'

    - name: Manage network shares on Windows hosts
      ansible.builtin.include_tasks: 'windows/main.yml'
      when: ansible_facts.os_family == 'Windows'
```

The `name`, `server`, `share`, and `mount_point` required-field checks move out of this assertion
and into the argument specification, which enforces them. The credential-pairing rule stays here
because it relates two fields.

Replace `roles/mount_network_share/defaults/main.yml` with:

```yaml
---
mount_network_share_enabled: true
mount_network_share_reload_remote_fs: false
mount_network_share_shares: []
```

- [ ] **Step 4: Add the argument specification**

Create `roles/mount_network_share/meta/argument_specs.yml` declaring `mount_network_share_enabled`
(bool, default `true`), `mount_network_share_reload_remote_fs` (bool, default `false`), and
`mount_network_share_shares` (list of dict, default `[]`) with nested options: `name` (str,
required), `server` (str, required), `share` (str, required), `mount_point` (str, required),
`username` (str), `password` (str, `no_log: true`), `credentials_path` (str),
`credentials_owner` (str, default `'root'`), `credentials_group` (str, default `'root'`),
`credentials_mode` (str, default `'0600'`), `fstab_options` (list of str), `owner` (str, default
`'root'`), `group` (str, default `'root'`), `mode` (str, default `'0755'`), and `state` (str,
choices `present`, `absent`, `mounted`, `unmounted`, `absent_from_fstab`, default `present`).

- [ ] **Step 5: Run the scenario to verify it passes**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share`
Expected: PASS, including idempotence.

- [ ] **Step 6: Update the role README**

Add the enable flag and its skip behaviour to `roles/mount_network_share/README.md`, and note that
required share fields are now enforced by the argument specification.

- [ ] **Step 7: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles/mount_network_share extensions/molecule/mount_network_share
git commit -m "feat: add mount_network_share enable flag and argument spec"
```

---

### Task 14: Add an argument specification to `auto_updates`

**Files:**

- Create: `roles/auto_updates/meta/argument_specs.yml`
- Modify: `roles/auto_updates/README.md`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: no new variables. `auto_updates_enabled` already exists and already converges.

This role is the model for the converging enable flag: `auto_updates_enabled: false` writes zeroed
APT periodic counters and stops the `dnf-automatic` timer rather than skipping.

- [ ] **Step 1: Add the argument specification**

Create `roles/auto_updates/meta/argument_specs.yml` declaring every existing variable:
`auto_updates_enabled` (bool, default `true`), `auto_updates_apt_origins` (list of str, default
`[]`), `auto_updates_apt_package_blacklist` (list of str, default `[]`),
`auto_updates_apt_auto_reboot` (bool, default `false`), `auto_updates_apt_auto_reboot_time` (str,
default `'02:00'`), `auto_updates_dnf_download_updates` (bool, default `true`),
`auto_updates_dnf_apply_updates` (bool, default `true`), `auto_updates_dnf_random_sleep` (int,
default `0`), `auto_updates_dnf_upgrade_type` (str, choices `default` and `security`, default
`default`), `auto_updates_dnf_reboot` (str, choices `never`, `when-changed`, `when-needed`, default
`never`), `auto_updates_dnf_emit_via` (str, default `stdio`), and `auto_updates_win_reboot` (bool,
default `true`).

The description for `auto_updates_enabled` must state that it converges: disabling it writes a
disabled schedule rather than skipping.

- [ ] **Step 2: Run the scenario to verify nothing regressed**

Run: `. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates`
Expected: PASS. The specification adds validation without changing behaviour. If it fails, the
declared types disagree with the scenario's inputs; fix the specification, not the scenario.

- [ ] **Step 3: Update the role README**

Update `roles/auto_updates/README.md` to describe `auto_updates_enabled` as the collection's
reference converging flag, and remove the existing note at line 11 that Windows "does not use
`auto_updates_enabled`" if the specification now documents that limitation instead.

- [ ] **Step 4: Lint and commit**

```bash
. .venv/bin/activate && ansible-lint . && yamllint .
git add -A roles/auto_updates
git commit -m "feat: add auto_updates argument spec"
```

---

### Task 15: Update collection documentation and prepare the release

**Files:**

- Modify: `roles/README.md`
- Modify: `README.md`
- Modify: `CHANGELOG.rst`
- Modify: `galaxy.yml:5`

**Interfaces:**

- Consumes: every rename and interface change from Tasks 2 to 14.
- Produces: the shippable `0.8.0` artefact metadata.

- [ ] **Step 1: Check for stale references**

Run:

```bash
grep -rn 'config_ssh\|config_git\|config_power\|config_firewall\|config_desktop\|config_systemd_units\|create_user\|blacklist_kernel_modules' \
  --include='*.yml' --include='*.md' --include='*.rst' --include='*.j2' \
  roles extensions README.md AGENTS.md
```

Expected: matches only inside migration notes in role READMEs and the new `CHANGELOG.rst` entry.
Any match in a task file, template, default, or scenario is a missed rename; fix it before
continuing.

- [ ] **Step 2: Update `roles/README.md`**

Add a short paragraph recording the naming rule (subsystem nouns for subsystem configuration, verb
phrases for discrete policies, no prefixes) and the enable-flag convention with its converging and
skipping distinction. Keep the existing statement that the directory listing is the catalogue; do
not add a role table that will drift.

- [ ] **Step 3: Update the collection `README.md`**

Update any role name referenced in the collection README. Confirm the existing pre-1.0 breaking
change warning is present and points at `CHANGELOG.rst`.

- [ ] **Step 4: Add the `0.8.0` changelog entry**

Insert a new section directly beneath the `jaythomasonprojects.sys_admin changelog` heading and
above `0.7.1`:

```rst
0.8.0
-----

- Renamed eight roles after the outcome they deliver rather than the mechanism
  they use: ``config_systemd_units`` to ``disable_printer_discovery``,
  ``blacklist_kernel_modules`` to ``disable_usb_storage``, ``config_desktop`` to
  ``auto_login``, ``config_firewall`` to ``allow_ping``, ``config_power`` to
  ``power_policy``, ``config_ssh`` to ``ssh``, ``config_git`` to ``git``, and
  ``create_user`` to ``local_accounts``. Every public variable takes the new
  role prefix. There are no compatibility aliases.
- Removed ``config_systemd_units_custom_services``. The role managed arbitrary
  unit files through an interface that only restated ``systemd_service``
  parameters. A role that needs a unit now ships that unit itself.
- Removed ``config_desktop_qt5ct``. The Qt platform theme is no longer managed.
- ``allow_ping_enabled`` now converges: setting it to ``false`` removes both
  managed ICMP rules instead of leaving them in place.
- Renamed the ``config_ssh`` variables into ``ssh_server_*`` and ``ssh_client_*``
  families matching the task files, and removed ``config_ssh_service_name`` from
  the public interface. The service name comes from ``vars/`` instead of runtime
  detection.
- ``local_accounts`` no longer requires ``password`` on every account, so
  key-only accounts need no placeholder value.
- Added ``meta/argument_specs.yml`` to every role. Option types, required
  fields, and choices are validated before the first task runs. Inline type
  assertions are removed; platform gates and cross-field rules remain.
- Added ``<role>_enabled`` to every policy role. It expresses whether a host
  should have the policy, so a fleet-wide play can vary policy by group. Each
  role README states whether disabling converges or skips.
- Moved distribution data for ``git``, ``ssh``, and ``time_sync`` into ``vars/``
  loaded by first-found lookup. Supported distributions are unchanged; the
  structure prepares for future additions.
```

- [ ] **Step 5: Bump the collection version**

In `galaxy.yml`, change `version: '0.7.1'` to `version: '0.8.0'`.

- [ ] **Step 6: Verify the build packages every renamed role**

```bash
. .venv/bin/activate
ansible-galaxy collection build --force --output-path dist
tar -tzf dist/jaythomasonprojects-sys_admin-0.8.0.tar.gz | grep 'roles/' | cut -d/ -f2 | sort -u
```

Expected: exactly twelve role names, all new, with no `config_*`, `create_user`, or
`blacklist_kernel_modules` entries.

- [ ] **Step 7: Commit**

```bash
git add -A roles/README.md README.md CHANGELOG.rst galaxy.yml
git commit -m "release: prepare 0.8.0"
```

---

### Task 16: Run the full release gate

**Files:** none modified unless a failure is found.

**Interfaces:**

- Consumes: the complete refactor from Tasks 1 to 15.

- [ ] **Step 1: Lint the whole collection**

```bash
. .venv/bin/activate
ansible-lint .
yamllint .
```

Expected: PASS with no errors.

- [ ] **Step 2: Run every Molecule scenario**

```bash
. .venv/bin/activate
ANSIBLE_CONFIG=ansible.cfg \
  MOLECULE_GLOB='extensions/molecule/**/molecule.yml' \
  molecule test --all
```

Expected: PASS for all twelve scenarios. Scenario directory names must all match their role names.

- [ ] **Step 3: Run the Windows integration pass**

Follow the workflow in `AGENTS.md`: restore Proxmox VM `101` at `192.168.41.103` to snapshot
`fresh`, run a playbook applying `ssh`, `power_policy`, `allow_ping`, `local_accounts`, and
`mount_network_share`, then restore `fresh`.

Verify specifically:

1. `ssh` reachability, and that the `OpenSSH Server (sshd)` rule's local port matches
   `ssh_server_port`.
2. `allow_ping` with `allow_ping_enabled: true` creates both rules, and a second run with
   `allow_ping_enabled: false` **removes** them. This is the behaviour change in Task 6 and Docker
   cannot exercise it.
3. `local_accounts` key file paths and ACLs are unchanged from `0.7.1`, and an account declared
   without a `password` is created successfully.
4. `power_policy` applies the plan and timeouts under its renamed variables.
5. `mount_network_share` still mounts under the argument specification.

Remember that the first account pass rotates the bootstrap account to its vaulted password, so
reconnect before later tasks.

- [ ] **Step 4: Build the final artefact**

```bash
. .venv/bin/activate
ansible-galaxy collection build --force --output-path dist
```

Expected: `dist/jaythomasonprojects-sys_admin-0.8.0.tar.gz` is produced.

- [ ] **Step 5: Commit any gate fixes**

If Steps 1 to 4 required changes, commit them with a message describing the fix, not the gate. If
nothing changed, there is nothing to commit and the branch is ready for review.

---

## Self-Review Notes

Checked against the spec:

- **Naming rule:** Tasks 3 to 11 cover all eight renames. Task 1 records the rule.
- **Deletions:** `custom_services` in Task 2, `qt5ct` in Task 4.
- **Enable interface:** converging flags in Tasks 5 (`disable_usb_storage`), 6 (`allow_ping`), 14
  (`auto_updates`); `auto_login`'s user variables in Task 4. Skipping flags in Tasks 3, 7, 8, 9, 10,
  11, 12, 13.
- **Argument specifications:** every role has one by the end of Task 14.
- **Operating-system handling:** `vars/` in Tasks 8, 9, 10. Platform gates retained in every
  `tasks/main.yml`. Distribution support deliberately not widened.
- **Collection and site boundary:** stated in Task 1, in the `local_accounts` specification in
  Task 11, and in the `install_app` README in Task 12.
- **Release:** Task 15 bumps `galaxy.yml` and `CHANGELOG.rst` together in one commit.
- **Testing:** Task 16 covers the full gate including the `allow_ping` convergence check, which is
  the only behaviour change Docker cannot verify.

Deliberately out of scope, per the spec's non-goals: Linux firewall, Fedora support,
`install_tailscale`.

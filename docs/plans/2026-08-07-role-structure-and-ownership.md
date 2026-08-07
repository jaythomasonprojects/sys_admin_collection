# Role Structure and Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor every role into a predictable platform layout with complete, opinionated capability ownership and release the clean breaking interface as collection version `0.7.0`.

**Architecture:** Root task files validate and dispatch to Linux or Windows implementations. Capability roles own their required packages, configuration, firewall access, and services; focused task files exist only for substantial responsibilities or independently selectable policy. Role READMEs are local design records, while Molecule and the Windows VM verify observable contracts rather than task-file structure.

**Tech Stack:** Ansible 2.18+, YAML, Molecule with Docker, ansible-lint, yamllint, Windows WinRM integration on Proxmox VM `101`.

## Global Constraints

- The approved design is `docs/designs/2026-08-07-role-structure-and-ownership-design.md`.
- Use Australian English and no em dashes.
- Use FQCNs, single quotes, explicit module states, multi-line maps, task-level `become: true`, and repository key ordering from `AGENTS.md`.
- `tasks/main.yml` validates support and dispatches; platform implementations live under `tasks/linux/` or `tasks/windows/`.
- Do not create empty files for symmetry or split cohesive implementations without a substantial responsibility seam.
- Unsupported platforms fail explicitly with a stable role-specific message.
- Required packages, configuration, firewall rules, and service state cannot be disabled independently.
- No compatibility aliases or wrapper roles are retained.
- Tests pin observable contracts, not task counts, include paths, or parsed YAML structure.
- Every Molecule command uses `ANSIBLE_CONFIG=ansible.cfg`.
- Each role task includes its README, metadata, scenario, lint, and scenario acceptance gate.
- The clean break is released as `0.7.0`; `galaxy.yml` and `CHANGELOG.rst` change together in the final release task.

## Target File Map

| Role | Target platform implementation |
|---|---|
| `auto_updates` | `linux/{main,apt,dnf}.yml`, `windows/main.yml` |
| `config_desktop` | `linux/{main,gdm,lightdm,qt5ct}.yml` |
| `config_firewall` | `windows/{main,ping}.yml` |
| `config_git` | `linux/main.yml` |
| `config_power` | `windows/main.yml` |
| `config_ssh` | `linux/{main,client,server}.yml`, `windows/{main,server}.yml` |
| `config_systemd_units` | `linux/{main,printer_services,custom_services}.yml` |
| `create_user` | `linux/{main,accounts,authorized_keys}.yml`, `windows/{main,accounts,authorized_keys,passwords}.yml` |
| `install_app` | `linux/{main,native_packages,debian_packages,deb_package,npm,flatpaks}.yml`, `windows/main.yml` |
| `mount_network_share` | `linux/{main,share}.yml`, `windows/{main,share}.yml` |
| `time_sync` | `linux/main.yml` |
| `blacklist_kernel_modules` | `linux/{main,usb_storage}.yml` |

---

### Task 1: Establish collection-wide role conventions

**Files:**
- Modify: `AGENTS.md`
- Modify: `extensions/molecule/README.md`
- Modify: `roles/README.md`

**Interfaces:**
- Produces: the implementation and test conventions every later task follows.

- [ ] **Step 1: Add the role-design conventions to `AGENTS.md`**

Add a concise section containing these normative statements:

```markdown
## Role design

- `tasks/main.yml` validates the supported platform and dispatches to `tasks/linux/main.yml` or `tasks/windows/main.yml`.
- Add focused task files only for substantial responsibilities, independently selectable capabilities, or multi-subsystem workflows.
- Capability roles own required packages or features, configuration, validation, firewall access, and service state.
- Booleans express desired policy or optional capabilities, never suppression of required implementation steps.
- Structured variables represent repeated policy such as users, applications, shares, and role-owned custom services.
- Unsupported platforms fail explicitly. Each managed artefact has one owning role.
- Every role README records the role guarantee, ownership, supported platforms, implementation map, interface, invariants, and migration notes.
```

- [ ] **Step 2: Update the Molecule guide**

State that scenarios must test supported behaviour, idempotence, and explicit unsupported-platform rejection. Prohibit static task-tree parsing and test-only package or service opt-outs. Correct the release order to lint, all scenarios, Windows integration, then build.

- [ ] **Step 3: Update `roles/README.md`**

Describe each role README as the local design record and direct readers there instead of adding a duplicated role catalogue.

- [ ] **Step 4: Verify and commit**

Run:

```bash
ansible-lint .
yamllint .
```

Expected: both commands exit `0`.

```bash
git add AGENTS.md extensions/molecule/README.md roles/README.md
git commit -m "docs: define opinionated role conventions"
```

---

### Task 2: Replace generic systemd policy with owned capabilities

**Files:**
- Modify: `roles/config_systemd_units/defaults/main.yml`
- Modify: `roles/config_systemd_units/tasks/main.yml`
- Create: `roles/config_systemd_units/tasks/linux/main.yml`
- Create: `roles/config_systemd_units/tasks/linux/printer_services.yml`
- Create: `roles/config_systemd_units/tasks/linux/custom_services.yml`
- Modify: `roles/config_systemd_units/meta/main.yml`
- Modify: `roles/config_systemd_units/README.md`
- Modify: `extensions/molecule/config_systemd_units/{prepare,converge,verify}.yml`

**Interfaces:**
- Removes: `config_systemd_units` arbitrary existing-unit policy.
- Produces: `config_systemd_units_disable_printer_services: bool` and `config_systemd_units_custom_services: list`.

- [ ] **Step 1: Rewrite the scenario to pin the new contract**

Prepare active printer fixtures, one deliberately missing printer unit, one untouched external unit, and one custom unit created by an initial role invocation. Converge with one present and one absent custom service. Verify printer fixtures are stopped and disabled, the external unit is unchanged, and role-owned units are created or removed.

Use this custom definition shape in `converge.yml`:

```yaml
config_systemd_units_custom_services:
  - name: 'molecule-created.service'
    enabled: true
    state: 'started'
    unit_content: |
      [Unit]
      Description=Molecule role-created fixture

      [Service]
      ExecStart=/usr/bin/sleep infinity

      [Install]
      WantedBy=multi-user.target
  - name: 'molecule-remove.service'
    unit_file_state: 'absent'
    unit_content: |
      [Service]
      ExecStart=/usr/bin/true
```

Add rescued validation checks for missing `unit_content`, unknown keys including `masked`, duplicate names, printer-policy names, and contradictory absent lifecycle.

- [ ] **Step 2: Run the scenario to verify the old interface fails the new contract**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_systemd_units
```

Expected: FAIL because the new defaults and task interfaces do not exist.

- [ ] **Step 3: Implement the dispatcher and defaults**

```yaml
---
config_systemd_units_custom_services: []
config_systemd_units_disable_printer_services: true
```

`tasks/main.yml` must assert Linux with `config_systemd_units supports Linux hosts only.` and include `linux/main.yml`. The Linux main file asserts `ansible_facts.service_mgr == 'systemd'`, validates top-level types, conditionally includes printer policy, then includes custom services.

- [ ] **Step 4: Implement opinionated printer policy**

In `printer_services.yml`, inspect fixed units with `systemctl show --property=LoadState --value`. Treat `not-found` as compliant and stop/disable only loaded units:

```yaml
config_systemd_units_printer_services:
  - 'cups-browsed.service'
  - 'avahi-daemon.service'
  - 'avahi-daemon.socket'
```

Keep this list internal to the task file.

- [ ] **Step 5: Implement role-owned custom services**

Validate every item before mutation. Require `name` ending in `.service` and non-empty `unit_content`; permit only `enabled`, `name`, `state`, `unit_content`, and `unit_file_state`. Reject duplicates and printer names. Write present files under `/etc/systemd/system` as `root:root` mode `0644`, reload once after file changes, and apply optional `started|stopped` and `enabled`. For absent files, stop and disable an existing role-owned path before removal. Never inspect or mutate arbitrary vendor units.

- [ ] **Step 6: Rewrite metadata and README**

Document the printer policy and custom-service schema, missing-unit compliance, ownership of custom files, and non-ownership of arbitrary existing units. Include examples for creation and removal.

- [ ] **Step 7: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_systemd_units
git add roles/config_systemd_units extensions/molecule/config_systemd_units
git commit -m "refactor: deepen systemd unit policy"
```

Expected: lint passes; scenario passes convergence, idempotence, and verification.

---

### Task 3: Rename hardening to opinionated USB-storage policy

**Files:**
- Delete: `roles/workstation_hardening/`
- Create: `roles/blacklist_kernel_modules/{defaults,tasks/linux,meta,files}/...`
- Create: `roles/blacklist_kernel_modules/README.md`
- Delete: `extensions/molecule/workstation_hardening/`
- Create: `extensions/molecule/blacklist_kernel_modules/`

**Interfaces:**
- Removes: role `workstation_hardening`, `workstation_hardening_blacklisted_modules`, `workstation_hardening_apply_runtime_changes`.
- Produces: role `blacklist_kernel_modules`, `blacklist_kernel_modules_disable_usb_storage: true`.

- [ ] **Step 1: Rename and rewrite the scenario first**

Use `ubuntu-enabled` and `ubuntu-disabled`. Seed the managed policy file only on the disabled host. Assert the host-shared kernel does not have `usb_storage` loaded before convergence. Verify exact persistent policy, `modprobe -n -v usb-storage` resolving to `/bin/false`, stale-policy removal when disabled, explicit Darwin rejection, and idempotence.

- [ ] **Step 2: Confirm the scenario fails before implementation**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s blacklist_kernel_modules
```

Expected: FAIL because the renamed role does not exist.

- [ ] **Step 3: Create the role interface and dispatcher**

```yaml
---
blacklist_kernel_modules_disable_usb_storage: true
```

`tasks/main.yml` asserts Linux with `blacklist_kernel_modules supports Linux hosts only.` and includes `linux/main.yml`. The Linux main file includes `usb_storage.yml`.

- [ ] **Step 4: Implement desired USB-storage state**

Install this fixed file as `/etc/modprobe.d/blacklist-kernel-modules-usb-storage.conf` when enabled:

```text
# Ansible managed: blacklist_kernel_modules USB mass-storage policy.
install usb-storage /bin/false
blacklist usb-storage
install uas /bin/false
blacklist uas
```

Unload both runtime module names, `usb_storage` and `uas`, with `community.general.modprobe` and `state: absent`. When the Boolean is false, remove the managed policy file and do not load either module. Do not add arbitrary lists, initramfs rebuilding, or runtime opt-outs.

- [ ] **Step 5: Write metadata and README, then remove legacy paths**

Document that USB controllers and input devices are unaffected, runtime unloading is mandatory when selected, and the managed file is the role's only persistent artefact. Preserve historical changelog references for the final release task.

- [ ] **Step 6: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s blacklist_kernel_modules
rg -n 'workstation_hardening|workstation-hardening' roles extensions/molecule README.md galaxy.yml meta
```

Expected: lint and scenario pass; the live-reference search has no matches.

```bash
git add roles extensions/molecule
git commit -m "refactor: add opinionated kernel module policy"
```

---

### Task 4: Refactor Windows firewall and power roles

**Files:**
- Modify: `roles/config_firewall/{defaults/main.yml,tasks/main.yml,meta/main.yml,README.md}`
- Create: `roles/config_firewall/tasks/windows/{main,ping}.yml`
- Modify: `extensions/molecule/config_firewall/{converge,verify}.yml`
- Modify: `roles/config_power/{tasks/main.yml,README.md}`
- Create: `roles/config_power/tasks/windows/main.yml`
- Modify: `extensions/molecule/config_power/{converge,verify}.yml`

**Interfaces:**
- Replaces: both `config_firewall_enable_icmp_*` variables with `config_firewall_allow_ping: true`.
- Preserves: existing `config_power_*` policy variables.

- [ ] **Step 1: Rewrite Docker scenarios as explicit rejection contracts**

On Ubuntu, include each role in `block`/`rescue` and assert exact messages:

```text
config_firewall supports Windows hosts only.
config_power supports Windows hosts only.
```

Remove UFW and `powercfg` package assertions because they do not observe supported behaviour.

- [ ] **Step 2: Confirm both scenarios fail**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_firewall
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_power
```

Expected: FAIL until explicit validation exists.

- [ ] **Step 3: Implement the firewall platform tree**

```yaml
---
config_firewall_allow_ping: true
```

Root main asserts Windows and dispatches. `windows/main.yml` includes `ping.yml` when the Boolean is true. Move both existing ICMP rules unchanged into `ping.yml`, remove their platform and old-variable guards, and retain exact rule names.

- [ ] **Step 4: Implement the power platform tree**

Root main asserts Windows and dispatches. Move the cohesive power plan, timeout, and hibernation tasks unchanged into `windows/main.yml`; retain only policy guards.

- [ ] **Step 5: Rewrite both role READMEs**

Firewall documents ping ownership, both protocol rules, false as unmanaged rather than removal, no Linux support, and no SSH ownership. Power documents active-plan, timeout, and hibernation ownership and its cohesive Windows main file.

- [ ] **Step 6: Verify Docker gates and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_firewall
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_power
git add roles/config_firewall roles/config_power extensions/molecule/config_firewall extensions/molecule/config_power
git commit -m "refactor: structure Windows host policy roles"
```

Windows supported-path observations are part of Task 13 after all Windows roles settle.

---

### Task 5: Make Git configuration a complete Linux capability

**Files:**
- Modify: `roles/config_git/tasks/main.yml`
- Create: `roles/config_git/tasks/linux/main.yml`
- Modify: `roles/config_git/{meta/main.yml,README.md}`
- Modify: `extensions/molecule/config_git/{prepare,converge,verify}.yml`

**Interfaces:**
- Preserves: `config_git_user_name`, `config_git_user_email`, and execution-user global-config semantics.
- Produces: mandatory Git package ownership.

- [ ] **Step 1: Change the scenario to start without Git**

Remove Git installation from prepare. Add package presence, identity, and exact unsupported-platform rejection assertions. Preserve `HOME: '/root'` so the tested execution-user contract remains explicit.

- [ ] **Step 2: Run the failing scenario**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_git
```

Expected: FAIL because the role does not install Git or reject unsupported platforms.

- [ ] **Step 3: Implement cohesive Linux policy**

Root main asserts Linux. `linux/main.yml` validates Debian/Ubuntu support, installs `git` with `ansible.builtin.apt` and `state: present`, then runs the two existing `community.general.git_config` tasks in caller execution context. Empty identity values continue to leave their keys unmanaged.

- [ ] **Step 4: Align metadata and README**

Declare Debian/Ubuntu support and direct `community.general` use. Document package ownership, effective-user and `HOME` semantics, and non-ownership of repositories, credentials, signing, or multi-user orchestration.

- [ ] **Step 5: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_git
git add roles/config_git extensions/molecule/config_git
git commit -m "refactor: make Git configuration self-contained"
```

---

### Task 6: Structure desktop policy by Linux subsystem

**Files:**
- Modify: `roles/config_desktop/tasks/main.yml`
- Create: `roles/config_desktop/tasks/linux/main.yml`
- Move: `roles/config_desktop/tasks/{gdm,lightdm,qt5ct}.yml` to `tasks/linux/`
- Modify: `roles/config_desktop/{meta/main.yml,README.md}`
- Modify: `extensions/molecule/config_desktop/converge.yml`

**Interfaces:** Preserves all three `config_desktop_*` variables and detected-software semantics.

- [ ] **Step 1: Add an unsupported-platform contract test**

Use synthetic Darwin facts and assert `config_desktop supports Linux hosts only.` Keep existing observable GDM, LightDM, and environment verification.

- [ ] **Step 2: Run the scenario and observe failure**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_desktop
```

Expected: FAIL because current tasks silently skip unsupported hosts.

- [ ] **Step 3: Move and dispatch tasks**

Root main asserts Linux and includes `linux/main.yml`. Move current detection/orchestration into Linux main and move the three focused files without changing their policy bodies.

- [ ] **Step 4: Align README and metadata**

Document policy for detected software, ownership of exact managed blocks/entries, non-ownership of desktop installation, and why the three independent policy files exist. Keep runtime and Galaxy platform claims identical.

- [ ] **Step 5: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_desktop
git add roles/config_desktop extensions/molecule/config_desktop
git commit -m "refactor: structure desktop policy by subsystem"
```

---

### Task 7: Make time synchronisation own ntpsec completely

**Files:**
- Modify: `roles/time_sync/{defaults/main.yml,tasks/main.yml,handlers/main.yml,meta/main.yml,README.md}`
- Create: `roles/time_sync/tasks/linux/main.yml`
- Modify: `extensions/molecule/time_sync/{molecule,prepare,converge,verify}.yml`

**Interfaces:**
- Removes: `time_sync_manage_package`, `time_sync_manage_service`.
- Preserves: `time_sync_server`.

- [ ] **Step 1: Convert the scenario to a systemd-capable contract test**

Use the existing privileged cgroup pattern from `config_systemd_units`. Remove package and service opt-outs and prepare-time role-owned state. Verify `ntpsec` installation, managed configuration, enabled/running `ntp` service, unsupported-platform rejection, and idempotence.

- [ ] **Step 2: Run the failing scenario**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
```

Expected: FAIL because the current fixture suppresses package and service ownership.

- [ ] **Step 3: Implement the cohesive Linux flow**

Root main asserts Linux. Linux main rejects hosts outside the Debian/Ubuntu APT contract before package work. Move the current configuration flow to `linux/main.yml`, remove both management guards, always install `ntpsec`, and ensure the `ntp` service is enabled and started. Keep the handler unconditional when notified by configuration change.

- [ ] **Step 4: Rewrite metadata and README**

Document the role specifically as ntpsec policy, not a generic time-sync adapter. Record package, config, and service ownership plus removal of both opt-outs.

- [ ] **Step 5: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
git add roles/time_sync extensions/molecule/time_sync
git commit -m "refactor: make time synchronisation complete"
```

---

### Task 8: Normalise automatic-update platform dispatch

**Files:**
- Modify: `roles/auto_updates/tasks/main.yml`
- Create: `roles/auto_updates/tasks/linux/main.yml`
- Move: `roles/auto_updates/tasks/{apt,dnf}.yml` to `tasks/linux/`
- Move: `roles/auto_updates/tasks/win.yml` to `tasks/windows/main.yml`
- Modify: `roles/auto_updates/{meta/main.yml,README.md}`
- Modify: `extensions/molecule/auto_updates/{converge,README}.yml`

**Interfaces:** Preserves every existing `auto_updates_*` variable and Windows immediate-install behaviour.

- [ ] **Step 1: Add unsupported-system and unsupported-package-manager tests**

Use rescued role inclusion with synthetic facts. Retain all existing package, rendered-policy, and DNF timer assertions.

- [ ] **Step 2: Run the failing scenario**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
```

Expected: FAIL because unsupported environments currently skip.

- [ ] **Step 3: Implement platform and package-manager dispatch**

Root main accepts Linux or Windows and rejects everything else. Linux main accepts `apt`, `dnf`, or `dnf5` and dispatches to moved files. Windows main preserves `ansible.windows.win_updates` with `state: installed`; do not add scheduling or bind Windows behaviour to `auto_updates_enabled`.

- [ ] **Step 4: Rewrite README and metadata**

State explicitly that Linux configures persistent automatic updates while Windows performs an immediate installation. Document all policy variables and platform ownership.

- [ ] **Step 5: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
git add roles/auto_updates extensions/molecule/auto_updates
git commit -m "refactor: normalise automatic update dispatch"
```

---

### Task 9: Separate application installation channels

**Files:**
- Modify: `roles/install_app/tasks/main.yml`
- Create: `roles/install_app/tasks/linux/{main,native_packages,debian_packages,deb_package,npm,flatpaks}.yml`
- Create: `roles/install_app/tasks/windows/main.yml`
- Delete superseded flat task files after moves.
- Modify: `roles/install_app/{meta/main.yml,README.md}`
- Modify: `extensions/molecule/install_app/{converge,README}.yml`

**Interfaces:** Preserves all current package lists, Debian item schema, and channel order. Adds automatic npm and Flatpak prerequisite ownership when those channels are requested.

- [ ] **Step 1: Strengthen observable channel tests**

Have Fedora receive a Debian fixture definition and prove it is skipped before access. Add rescued invalid Debian-item validation. Replace the missing-npm rejection fixture with an assertion that requesting npm packages installs its native tool. Remove the missing-Flatpak rejection fixture because missing prerequisites are no longer a supported outcome. Keep both Flatpak prerequisite and application success coverage listed as one deferred contract until the documented deterministic remote/runtime fixture is available.

- [ ] **Step 2: Run the strengthened scenario**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app
```

Expected: FAIL because the npm prerequisite is still caller-managed under the old implementation.

- [ ] **Step 3: Build the Linux channel tree**

Preserve order: native packages, Debian packages, npm, Flatpak. Keep `install_app_deb` loop scope and labels when moving `deb_package.yml`. In `native_packages.yml`, derive required native tools without exposing another variable:

```yaml
install_app_channel_packages: >-
  {{
    (['npm'] if install_app_npm_packages | length > 0 and ansible_facts.pkg_mgr == 'apt' else [])
    + (['nodejs-npm'] if install_app_npm_packages | length > 0 and ansible_facts.pkg_mgr in ['dnf', 'dnf5'] else [])
    + (['flatpak'] if install_app_flatpaks | length > 0 else [])
  }}
```

Install the unique union of `install_app_packages` and this internal list with `state: present`. Keep executable validation after installation, not as a caller-prerequisite rejection.

- [ ] **Step 4: Move Windows implementation and update root dispatch**

Move the cohesive Chocolatey task to `windows/main.yml`. Root main retains Linux/Windows assertion and includes platform main files.

- [ ] **Step 5: Rewrite metadata and README**

Document channel ownership and validation, automatic npm and Flatpak prerequisite installation, task map, ordering invariants, and no variable migration.

- [ ] **Step 6: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app
git add roles/install_app extensions/molecule/install_app
git commit -m "refactor: separate application installation channels"
```

---

### Task 10: Make network-share prerequisites mandatory

**Files:**
- Modify: `roles/mount_network_share/{defaults/main.yml,tasks/main.yml,README.md}`
- Create: `roles/mount_network_share/tasks/linux/{main,share}.yml`
- Create: `roles/mount_network_share/tasks/windows/{main,share}.yml`
- Delete superseded flat task files after moves.
- Modify: `extensions/molecule/mount_network_share/{converge,verify}.yml`

**Interfaces:** Removes `mount_network_share_manage_packages`; preserves structured shares and `mount_network_share_reload_remote_fs`.

- [ ] **Step 1: Rewrite the scenario around observable ownership**

Remove the package opt-out and static Windows YAML parsing. Add a `cifs-utils` package assertion while retaining mount-point, credential-file, mode, ownership, content, and `/etc/fstab` assertions.

- [ ] **Step 2: Record the supported Linux baseline**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
```

Expected: PASS because current defaults already install `cifs-utils`. Preserve this observable baseline while removing the public opt-out and moving task files.

- [ ] **Step 3: Implement platform orchestration**

Root main validates all entries and dispatches once. Linux main always installs `cifs-utils` and loops over `share.yml`. Windows main loops over its own `share.yml`. Preserve current credential, mount, absent-state, and `remote-fs.target` semantics.

- [ ] **Step 4: Rewrite the README**

Document required schema, Linux path versus Windows drive-letter semantics, package ownership, credential restrictions, Windows local-user/SMB coupling, one credential per server/user, activation policy, and the removed opt-out.

- [ ] **Step 5: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
git add roles/mount_network_share extensions/molecule/mount_network_share
git commit -m "refactor: make network share setup complete"
```

---

### Task 11: Align SSH and user ownership

**Files:**
- Modify: `roles/config_ssh/{defaults/main.yml,tasks/main.yml,handlers/main.yml,templates/sshd_config_win.j2,meta/main.yml,README.md}`
- Create: `roles/config_ssh/tasks/linux/{main,client,server}.yml`
- Create: `roles/config_ssh/tasks/windows/{main,server}.yml`
- Delete superseded flat SSH task files.
- Modify: `roles/create_user/tasks/main.yml`
- Create: `roles/create_user/tasks/linux/{main,accounts,authorized_keys}.yml`
- Create: `roles/create_user/tasks/windows/{main,accounts,authorized_keys,passwords}.yml`
- Delete superseded flat user task files.
- Modify: `roles/create_user/{meta/main.yml,README.md}`
- Modify: both `extensions/molecule/{config_ssh,create_user}/` scenarios.

**Interfaces:**
- Removes: unprefixed `sshd_permit_root_login` fallback.
- Preserves: prefixed SSH policy and `create_user_accounts` schema.
- Transfers: all authorised-key contents and ACL ownership from SSH to users.

- [ ] **Step 1: Strengthen both scenarios before the move**

Convert SSH to a systemd-capable Ubuntu scenario that begins without OpenSSH packages. Verify client/server packages, rendered config, cloud-init cleanup, `sshd -t`, enabled/running service, and unsupported-platform rejection. Expand user verification for account fields, home, key ownership/modes, multiple keys, and existing rejection behaviour. Remove any SSH assertion over authorised-key files.

- [ ] **Step 2: Run both scenarios and record expected failures**

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_ssh
ANSIBLE_CONFIG=ansible.cfg molecule test -s create_user
```

Expected: SSH fails package/service ownership checks; user tests expose missing ownership or schema assertions where applicable.

- [ ] **Step 3: Build Linux SSH client/server flow**

Linux main validates Debian/Ubuntu support, installs `openssh-client` and `openssh-server`, resolves service name, then includes `client.yml` and `server.yml`. Fold cloud-init cleanup into server flow. Invalid `sshd -t` must fail rather than remove the file and continue. Ensure the selected SSH service is enabled and running.

- [ ] **Step 4: Build Windows SSH server flow**

Windows main includes only `server.yml`. Preserve OpenSSH Server installation, `C:\ProgramData\ssh`, server config, exact firewall rule, running/automatic service, and PowerShell default-shell registry value. Remove creation and ACL management of `administrators_authorized_keys`. Do not add empty Windows client policy.

- [ ] **Step 5: Remove the SSH compatibility fallback**

Set:

```yaml
config_ssh_sshd_permit_root_login: 'no'
```

Do not reference `sshd_permit_root_login`.

- [ ] **Step 6: Split user account and key responsibilities**

Linux order is accounts then authorised keys. Windows order is accounts with `update_password: on_create`, authorised keys and ACLs, then final password policy. Windows authorised-key flow owns the administrator aggregate file and standard-user files. Preserve `no_log` and the reconnect constraint after bootstrap-password rotation.

- [ ] **Step 7: Make Windows ACL contracts explicit**

Administrator key ownership is set to the well-known Administrators SID `S-1-5-32-544`; inheritance is disabled; and the only explicit full-control entries are Administrators and SYSTEM (`S-1-5-18`). Standard-user `.ssh` and key-file ownership is set to the managed account SID; inheritance is disabled; and the only explicit full-control entries are that account, Administrators, and SYSTEM. Use SIDs rather than localised group names when constructing ACLs. Treat declared administrator keys as the complete managed aggregate so an explicitly empty list clears stale managed keys.

- [ ] **Step 8: Rewrite both READMEs and metadata**

SSH documents complete reachability, platform task maps, firewall/service ownership, Linux firewall non-goal, and authorised-key non-ownership. User README documents the full item schema, Linux additive versus Windows authoritative key semantics, ACLs, password ordering, and OpenSSH non-ownership. Add direct `ansible.posix` metadata usage to `create_user`.

- [ ] **Step 9: Verify and commit**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_ssh
ANSIBLE_CONFIG=ansible.cfg molecule test -s create_user
git add roles/config_ssh roles/create_user extensions/molecule/config_ssh extensions/molecule/create_user
git commit -m "refactor: align SSH and user ownership"
```

---

### Task 12: Publish the coordinated 0.7.0 interface

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.rst`
- Modify: `galaxy.yml`

**Interfaces:** Produces the collection-level migration contract and version `0.7.0`.

- [ ] **Step 1: Update the collection README**

Explain complete capability ownership, link to role READMEs, add this prominent disclaimer, and correct all Molecule commands to use `ANSIBLE_CONFIG=ansible.cfg`:

```markdown
> [!WARNING]
> Releases before `1.0.0` may contain breaking role and variable changes. Review `CHANGELOG.rst` before upgrading.
```

- [ ] **Step 2: Write the complete 0.7.0 migration entry**

List the role rename; every removed, renamed, and added variable; systemd printer/custom-service replacement; USB-storage policy; prerequisite ownership; platform failures; key ownership transfer; ping flag; and universal layout. Preserve historical release text unchanged.

- [ ] **Step 3: Bump and refresh collection metadata**

Change `galaxy.yml` from `0.6.0` to `0.7.0` and replace stale staged-role wording with the current opinionated capability description.

- [ ] **Step 4: Run all Linux acceptance gates**

```bash
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test --all
```

Expected: all commands exit `0`; every scenario completes convergence, idempotence, verification, and cleanup.

- [ ] **Step 5: Run the complete Windows integration workflow**

Restore Proxmox VM `101` snapshot `fresh`, run the local collection through WinRM, reconnect after bootstrap-password rotation, and observe:

- both ping rules with correct protocols and ICMP types;
- power plan, timeout, and hibernation policy;
- OpenSSH Server installation, valid config, exact firewall rule, running/automatic service, PowerShell shell, and key-authenticated reachability;
- administrator and standard-user authorised-key contents and ACLs;
- persisted network-share registry mapping and Credential Manager entry;
- second-run idempotence for every supported Windows path.

Restore snapshot `fresh` again regardless of outcome.

- [ ] **Step 6: Build and inspect the collection artefact**

```bash
ansible-galaxy collection build --force --output-path dist
ansible-galaxy collection install dist/jaythomasonprojects-sys_admin-0.7.0.tar.gz -p ./.ansible/collections --force
```

Inspect the archive and installed collection. Confirm all nested task files and `roles/blacklist_kernel_modules/` exist, and `roles/workstation_hardening/` does not.

- [ ] **Step 7: Commit the coordinated release**

```bash
git add README.md CHANGELOG.rst galaxy.yml
git commit -m "release: prepare 0.7.0"
```

Do not publish unless explicitly requested.

# Fedora Support and Role Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or
> executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Remove the obsolete `git` role, support Fedora 44 across applicable Linux roles, add
Ubuntu 26.04 GNOME coverage, migrate time synchronisation to chrony, and rename the collection-owned
APT policy file.

**Architecture:** Keep one shared `tasks/linux/` implementation whenever Ansible modules and common
procedure already abstract distribution differences. Put package names, service names, and paths in
first-found `vars/` files. Retain package-manager-specific automatic-update implementations because
APT and DNF are genuinely different seams, while representing DNF4/DNF5 differences as internal
data.

**Tech Stack:** Ansible >=2.18, community.general, ansible.posix, Molecule Docker, Ubuntu
22.04/24.04/26.04, Fedora 44, systemd, GNOME dconf/GSettings, chrony, ansible-lint, and yamllint.

**Spec:** `docs/agent-work/specs/2026-09-03-fedora-support-and-role-cleanup-design.md`

## Global Constraints

- Work from the current worktree, including its uncommitted `desktop_layout` and `power_policy`
  implementation; do not reset or overwrite those changes.
- Keep `galaxy.yml` at `0.9.0`; this work joins the unreleased `0.9.0` release.
- Support Ubuntu GNOME 22.04, 24.04, and 26.04 where the role has release-specific GNOME behaviour.
- Use Fedora 44 as the current Fedora Molecule target.
- Keep `desktop_layout` Ubuntu-only and reject Fedora explicitly.
- Support only `ssh_server_port: 22` on Fedora. Do not add SELinux or firewalld ownership.
- Use chrony on Debian, Ubuntu, and Fedora; do not retain an ntpsec implementation switch.
- Do not add `tasks/linux/fedora.yml`; Fedora differences in this release are internal data or
  narrow validations.
- Keep historical changelog entries, designs, and plans unchanged.
- Use FQCNs, single quotes, explicit states, multi-line mappings, project key order, and task-level
  `become: true` as specified by `AGENTS.md`.
- Every Molecule command must include `ANSIBLE_CONFIG=ansible.cfg`.
- A scenario failure unrelated to the change is reported rather than treated as a blocker.

## File Map

### Delete obsolete capability

- `roles/git/`
- `extensions/molecule/git/`

### Distribution data

- Create `roles/auto_login/vars/Debian.yml`
- Create `roles/auto_login/vars/Fedora.yml`
- Create `roles/power_policy/vars/Fedora.yml`
- Create `roles/ssh/vars/Fedora.yml`
- Rewrite `roles/time_sync/vars/{Debian,Ubuntu}.yml`
- Create `roles/time_sync/vars/Fedora.yml`
- Create `roles/install_app/vars/Debian.yml`
- Create `roles/install_app/vars/RedHat.yml`

### Role implementation and contracts

- Modify `roles/auto_login/{tasks/linux/main.yml,tasks/linux/gdm.yml,tasks/linux/lightdm.yml,README.md,meta/main.yml}`
- Modify `roles/auto_updates/{tasks/linux/main.yml,tasks/linux/apt.yml,tasks/linux/dnf.yml,templates/automatic.conf.j2,README.md}`
- Rename `roles/auto_updates/templates/52jtprojects-unattended-upgrades.j2` to
  `roles/auto_updates/templates/52sys-admin-auto-updates.j2`
- Modify `roles/desktop_layout/{tasks/linux/main.yml,README.md,meta/main.yml}`
- Modify `roles/power_policy/{tasks/linux/main.yml,README.md,meta/main.yml}`
- Modify `roles/time_sync/{tasks/linux/main.yml,handlers/main.yml,README.md,meta/main.yml}`
- Modify `roles/ssh/{tasks/main.yml,tasks/linux/main.yml,README.md,meta/main.yml}`
- Modify `roles/install_app/{tasks/linux/main.yml,tasks/linux/native_packages.yml,tasks/linux/deb_package.yml,tasks/linux/flatpaks.yml,README.md,meta/main.yml}`
- Modify `roles/mount_network_share/{tasks/linux/main.yml,tasks/linux/share.yml,handlers/main.yml}`
- Modify `roles/local_accounts/meta/main.yml`

### Molecule scenarios

- Modify `extensions/molecule/auto_login/{molecule,prepare,converge,verify}.yml`
- Modify `extensions/molecule/auto_updates/{molecule,prepare,verify,verify_apt,verify_dnf}.yml`
- Modify `extensions/molecule/desktop_layout/{molecule,prepare,converge,verify}.yml`
- Modify `extensions/molecule/power_policy/{molecule,prepare,converge,verify}.yml`
- Modify `extensions/molecule/time_sync/{molecule,prepare,converge,verify}.yml`
- Modify `extensions/molecule/ssh/{molecule,prepare,converge,verify}.yml`
- Modify `extensions/molecule/disable_printer_discovery/molecule.yml`
- Modify `extensions/molecule/disable_usb_storage/{molecule,prepare,converge,verify}.yml`
- Modify `extensions/molecule/local_accounts/molecule.yml`
- Modify `extensions/molecule/mount_network_share/{molecule,prepare,verify}.yml`
- Modify `extensions/molecule/install_app/{molecule,prepare,verify}.yml`

### Shared documentation and release

- Modify `README.md`
- Modify `extensions/molecule/README.md`
- Modify `CHANGELOG.rst`
- Keep `galaxy.yml` at version `0.9.0`

---

### Task 1: Remove the `git` role and live references

**Files:**
- Delete: `roles/git/`
- Delete: `extensions/molecule/git/`
- Modify: `extensions/molecule/README.md:55-57`

**Interfaces:**
- Consumes: the approved decision that Stow-managed dotfiles replace this role.
- Produces: a collection with no callable `jaythomasonprojects.sys_admin.git` role or discovered
  `git` Molecule scenario.

- [ ] **Step 1: Record the current live references**

Run:

```bash
rg -n 'jaythomasonprojects\.sys_admin\.git|roles/git|molecule/git|`git` for' \
  roles extensions README.md
```

Expected: matches in `roles/git/`, `extensions/molecule/git/`, and the lightweight-package example
in `extensions/molecule/README.md`.

- [ ] **Step 2: Delete the role and scenario**

Run:

```bash
git rm -r roles/git extensions/molecule/git
```

- [ ] **Step 3: Remove the obsolete harness example**

Delete item 5 at `extensions/molecule/README.md:55-57`. Do not replace it with another role-specific
example; items 1-4 already state the reusable runtime requirements.

- [ ] **Step 4: Verify only historical references remain**

Run:

```bash
test ! -d roles/git
rg -n 'jaythomasonprojects\.sys_admin\.git|roles/git|molecule/git' \
  roles extensions README.md || true
```

Expected: both directory checks pass and the final search prints no live references.

- [ ] **Step 5: Commit the removal**

```bash
git add -A roles/git extensions/molecule/git extensions/molecule/README.md
git commit -m "feat!: remove git role"
```

### Task 2: Add Fedora-aware display-manager paths

**Files:**
- Create: `roles/auto_login/vars/Debian.yml`
- Create: `roles/auto_login/vars/Fedora.yml`
- Modify: `roles/auto_login/tasks/linux/main.yml`
- Modify: `roles/auto_login/tasks/linux/gdm.yml`
- Modify: `roles/auto_login/tasks/linux/lightdm.yml`
- Modify: `roles/auto_login/README.md`
- Modify: `roles/auto_login/meta/main.yml`
- Modify: `extensions/molecule/auto_login/{molecule,prepare,converge,verify}.yml`

**Interfaces:**
- Consumes: existing `auto_login_gdm_user` and `auto_login_lightdm_user` options.
- Produces: internal `auto_login_gdm_config_path`, with one shared GDM implementation for
  Debian-family and Fedora hosts.

- [ ] **Step 1: Extend the scenario with a realistic Fedora fixture**

Add this platform to `extensions/molecule/auto_login/molecule.yml`:

```yaml
  - name: 'auto-login-fedora44'
    command: 'sleep infinity'
    image: 'docker.io/geerlingguy/docker-fedora44-ansible:latest'
    pre_build_image: true
```

In `prepare.yml`, create `/etc/gdm/custom.conf` with a `[daemon]` section on Fedora and continue to
create `/etc/gdm3/custom.conf` on Ubuntu. In `verify.yml`, select the expected path from
`ansible_facts.distribution` and assert that `AutomaticLoginEnable`, `AutomaticLogin`, and
`WaylandEnable` occur beneath `[daemon]`.

- [ ] **Step 2: Run the scenario to prove Fedora currently fails**

Run:

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_login
```

Expected: FAIL because the role probes only `/etc/gdm3/custom.conf` and leaves Fedora's
`/etc/gdm/custom.conf` unchanged.

- [ ] **Step 3: Add distribution path data**

Create `roles/auto_login/vars/Debian.yml`:

```yaml
---
auto_login_gdm_config_path: '/etc/gdm3/custom.conf'
```

Create `roles/auto_login/vars/Fedora.yml`:

```yaml
---
auto_login_gdm_config_path: '/etc/gdm/custom.conf'
```

Load these with `first_found` in `tasks/linux/main.yml`, using distribution then OS family. Probe
`{{ auto_login_gdm_config_path }}` instead of a literal path.

- [ ] **Step 4: Make GDM editing shared and section-aware**

Replace literal paths in `gdm.yml` with `{{ auto_login_gdm_config_path }}`. Use
`community.general.ini_file` with `section: 'daemon'`, `no_extra_spaces: false`, and explicit
`state`; preserve the existing enabled/disabled semantics for the three keys. Add `become: true` to
all GDM and LightDM file mutations.

- [ ] **Step 5: Align documentation and metadata**

Document both GDM paths, retain display-manager installation as a precondition, and list Debian,
Ubuntu, and Fedora under `roles/auto_login/meta/main.yml` platforms.

- [ ] **Step 6: Run the scenario and lint**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_login
ansible-lint roles/auto_login extensions/molecule/auto_login
```

Expected: all commands PASS, including idempotence on Ubuntu and Fedora.

- [ ] **Step 7: Commit**

```bash
git add roles/auto_login extensions/molecule/auto_login
git commit -m "feat: support Fedora automatic login"
```

### Task 3: Rename APT policy and support DNF5

**Files:**
- Rename: `roles/auto_updates/templates/52jtprojects-unattended-upgrades.j2` to
  `roles/auto_updates/templates/52sys-admin-auto-updates.j2`
- Modify: `roles/auto_updates/tasks/linux/{main,apt,dnf}.yml`
- Modify: `roles/auto_updates/templates/automatic.conf.j2`
- Modify: `roles/auto_updates/README.md`
- Modify: `extensions/molecule/auto_updates/{molecule,prepare,verify,verify_apt,verify_dnf}.yml`

**Interfaces:**
- Consumes: all existing `auto_updates_*` options without renaming them.
- Produces: internal DNF package/timer selection and APT path
  `/etc/apt/apt.conf.d/52sys-admin-auto-updates`.

- [ ] **Step 1: Write migration and DNF5 assertions**

Change the Fedora platform to `docker.io/geerlingguy/docker-fedora44-ansible:latest`. In
`prepare.yml`, create `/etc/apt/apt.conf.d/52jtprojects-unattended-upgrades` on APT hosts with
fixture content. Update `verify_apt.yml` to slurp `52sys-admin-auto-updates`, stat the old path, and
assert:

```yaml
- not auto_updates_legacy_policy.stat.exists
- actual_policy.strip() == expected_policy.strip()
```

Update `verify_dnf.yml` so DNF5 expects `dnf5-plugin-automatic` and
`dnf5-automatic.timer`; DNF4 expects `dnf-automatic` and `dnf-automatic.timer`.

- [ ] **Step 2: Run the scenario to verify both failures**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
```

Expected: FAIL because the old APT filename remains current and Fedora 44 does not satisfy the
legacy DNF package/timer assertions.

- [ ] **Step 3: Rename and migrate the APT policy**

Run:

```bash
git mv roles/auto_updates/templates/52jtprojects-unattended-upgrades.j2 \
  roles/auto_updates/templates/52sys-admin-auto-updates.j2
```

In `apt.yml`, remove the legacy path with `ansible.builtin.file` and `state: absent`, then render:

```yaml
src: '52sys-admin-auto-updates.j2'
dest: '/etc/apt/apt.conf.d/52sys-admin-auto-updates'
```

Add `become: true` to package, file, and template tasks.

- [ ] **Step 4: Parameterise DNF4 and DNF5 data**

In `tasks/linux/main.yml`, set these internal values before including `dnf.yml`:

```yaml
auto_updates_dnf_package: >-
  {{ 'dnf5-plugin-automatic' if ansible_facts.pkg_mgr == 'dnf5'
     else 'dnf-automatic' }}
auto_updates_dnf_timer: >-
  {{ 'dnf5-automatic.timer' if ansible_facts.pkg_mgr == 'dnf5'
     else 'dnf-automatic.timer' }}
```

Use `ansible.builtin.package` with `auto_updates_dnf_package` and use
`auto_updates_dnf_timer` in the systemd task. Add task-level `become: true`.

- [ ] **Step 5: Correct common automatic-update configuration**

Move `random_sleep = {{ auto_updates_dnf_random_sleep }}` from `[base]` to `[commands]` in
`automatic.conf.j2`. Keep `[base]` only if another configured base option remains; otherwise remove
the empty section.

- [ ] **Step 6: Update the role contract**

In `roles/auto_updates/README.md`, name the new APT path and both DNF implementations. Explain that
the `52` prefix loads after `50unattended-upgrades` and that convergence deletes the former
`52jtprojects-unattended-upgrades` path.

- [ ] **Step 7: Verify**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
ansible-lint roles/auto_updates extensions/molecule/auto_updates
```

Expected: PASS with exact APT content, absent legacy path, DNF5 package, active timer, and
idempotence.

- [ ] **Step 8: Commit**

```bash
git add roles/auto_updates extensions/molecule/auto_updates
git commit -m "feat: support DNF5 automatic updates"
```

### Task 4: Extend GNOME release coverage

**Files:**
- Create: `roles/power_policy/vars/Fedora.yml`
- Modify: `roles/desktop_layout/{tasks/linux/main.yml,README.md,meta/main.yml}`
- Modify: `roles/power_policy/{tasks/linux/main.yml,README.md,meta/main.yml}`
- Modify: `extensions/molecule/desktop_layout/{molecule,prepare,converge,verify}.yml`
- Modify: `extensions/molecule/power_policy/{molecule,prepare,converge,verify}.yml`

**Interfaces:**
- Consumes: existing `desktop_layout_*` and `power_policy_*` public options.
- Produces: Ubuntu 26.04 compatibility for both roles and Fedora GNOME compatibility for
  `power_policy` only.

- [ ] **Step 1: Add Ubuntu 26.04 and Fedora test platforms**

Add `docker.io/geerlingguy/docker-ubuntu2604-ansible:latest` to both scenarios. Add
`docker.io/geerlingguy/docker-fedora44-ansible:latest` to `power_policy` only. Prepare Fedora with
`gnome-settings-daemon` and `gsettings-desktop-schemas`; do not install dash-to-dock or add Fedora
to `desktop_layout`.

- [ ] **Step 2: Update failure assertions before implementation**

Use these exact contracts in converge rescue assertions:

```text
desktop_layout supports Ubuntu 22.04, 24.04, and 26.04 hosts only.
power_policy supports Windows, Ubuntu 22.04, 24.04, and 26.04, and Fedora hosts only.
```

Keep a synthetic Fedora rejection assertion in `desktop_layout`. Add successful Fedora dconf
assertions to `power_policy/verify.yml`.

- [ ] **Step 3: Run both scenarios to prove the new platforms fail**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s desktop_layout
ANSIBLE_CONFIG=ansible.cfg molecule test -s power_policy
```

Expected: FAIL because Ubuntu 26.04 and Fedora are outside the current gates and Fedora package data
does not exist.

- [ ] **Step 4: Widen the role gates**

Allow `desktop_layout` only when Ubuntu's version is in `['22.04', '24.04', '26.04']`. Allow
`power_policy` for that Ubuntu list or `ansible_facts.distribution == 'Fedora'`. Use the exact stable
messages from Step 2.

- [ ] **Step 5: Add Fedora power-policy data**

Create `roles/power_policy/vars/Fedora.yml`:

```yaml
---
power_policy_packages:
  - 'dbus-daemon'
  - 'dconf'
  - 'glib2'
  - 'python3-gobject'
  - 'python3-psutil'
```

Do not create a Fedora task file; existing schema checks and dconf tasks remain unchanged.

- [ ] **Step 6: Update role documentation and metadata**

Document Ubuntu 26.04 for both roles, Fedora for `power_policy`, and Fedora's explicit exclusion from
`desktop_layout`. Keep GNOME and required schemas as host preconditions.

- [ ] **Step 7: Verify**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s desktop_layout
ANSIBLE_CONFIG=ansible.cfg molecule test -s power_policy
ansible-lint roles/desktop_layout roles/power_policy extensions/molecule/desktop_layout extensions/molecule/power_policy
```

Expected: all commands PASS on Ubuntu 22.04, 24.04, 26.04 and the applicable Fedora platform.

- [ ] **Step 8: Commit**

```bash
git add roles/desktop_layout roles/power_policy extensions/molecule/desktop_layout extensions/molecule/power_policy
git commit -m "feat: extend GNOME platform support"
```

### Task 5: Replace ntpsec with chrony

**Files:**
- Modify: `roles/time_sync/tasks/linux/main.yml`
- Modify: `roles/time_sync/handlers/main.yml`
- Modify: `roles/time_sync/vars/Debian.yml`
- Modify: `roles/time_sync/vars/Ubuntu.yml`
- Create: `roles/time_sync/vars/Fedora.yml`
- Modify: `roles/time_sync/README.md`
- Modify: `roles/time_sync/meta/main.yml`
- Modify: `extensions/molecule/time_sync/{molecule,prepare,converge,verify}.yml`

**Interfaces:**
- Consumes: unchanged `time_sync_enabled: bool` and `time_sync_server: str` options.
- Produces: chrony package, configuration, and service ownership on Debian, Ubuntu, and Fedora.

- [ ] **Step 1: Rewrite the scenario contract for chrony**

Add a privileged Fedora 44 systemd platform alongside Ubuntu. Remove chrony before convergence so
the role proves package ownership. Verify the package, one active configured pool, configuration
mode `0644`, and enabled/running service. Branch only expected path/service data:

```yaml
time_sync_expected_config: >-
  {{ '/etc/chrony.conf' if ansible_facts.distribution == 'Fedora'
     else '/etc/chrony/chrony.conf' }}
time_sync_expected_service: >-
  {{ 'chronyd' if ansible_facts.distribution == 'Fedora' else 'chrony' }}
```

Change the synthetic unsupported-platform assertion to
`time_sync supports Debian, Ubuntu, and Fedora hosts only.`

- [ ] **Step 2: Run the scenario to verify it fails against ntpsec**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
```

Expected: FAIL because the role still rejects Fedora and installs/configures ntpsec on Ubuntu.

- [ ] **Step 3: Replace distribution data**

Set Debian and Ubuntu vars to:

```yaml
time_sync_config_dir: '/etc/chrony'
time_sync_config_file: '/etc/chrony/chrony.conf'
time_sync_package: 'chrony'
time_sync_service: 'chrony'
```

Create Fedora vars with:

```yaml
time_sync_config_dir: '/etc'
time_sync_config_file: '/etc/chrony.conf'
time_sync_package: 'chrony'
time_sync_service: 'chronyd'
```

- [ ] **Step 4: Generalise names while retaining one Linux procedure**

Allow Debian, Ubuntu, and Fedora in `tasks/linux/main.yml`. Rename the affected task labels to
`Install chrony`, `Ensure chrony configuration directory exists`, `Ensure chrony configuration file
exists`, and `Enable and start chrony service`. Keep the shared package, directory, file, pool
replacement, `lineinfile`, and systemd tasks. Rename the handler to `Restart chrony service` and
change both notifications to that exact name; the handler continues to use `time_sync_service`.

- [ ] **Step 5: Rewrite the role README**

State that the role owns chrony, list each distribution's path/service, retain skipping semantics,
and record that upgrades no longer use the old `/etc/ntpsec/ntp.conf` artefact.

- [ ] **Step 6: Verify**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
ansible-lint roles/time_sync extensions/molecule/time_sync
```

Expected: PASS with chrony active and idempotent on Ubuntu and Fedora.

- [ ] **Step 7: Commit**

```bash
git add roles/time_sync extensions/molecule/time_sync
git commit -m "feat!: migrate time synchronisation to chrony"
```

### Task 6: Add constrained Fedora SSH support

**Files:**
- Create: `roles/ssh/vars/Fedora.yml`
- Modify: `roles/ssh/tasks/main.yml`
- Modify: `roles/ssh/tasks/linux/main.yml`
- Modify: `roles/ssh/README.md`
- Modify: `roles/ssh/meta/main.yml`
- Modify: `extensions/molecule/ssh/{molecule,prepare,converge,verify}.yml`

**Interfaces:**
- Consumes: existing SSH public options.
- Produces: Fedora OpenSSH support when `ssh_server_port == 22`, with no Linux firewall or SELinux
  ownership.

- [ ] **Step 1: Add Fedora behaviour and rejection tests**

Add a Fedora 44 privileged systemd platform. Make package removal and package assertions branch on
distribution. Apply the role successfully with port 22, assert `openssh-clients`, `openssh-server`,
`sshd`, and rendered drop-ins, then use a rescued include with port 2222 and assert exactly:

```text
ssh_server_port must be 22 on Fedora hosts.
```

- [ ] **Step 2: Run the scenario to prove Fedora is rejected**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s ssh
```

Expected: FAIL at the current Debian/Ubuntu-only platform gate.

- [ ] **Step 3: Add Fedora distribution data**

Create `roles/ssh/vars/Fedora.yml`:

```yaml
---
ssh_packages:
  - 'openssh-clients'
  - 'openssh-server'
ssh_service_name: 'sshd'
```

- [ ] **Step 4: Widen and constrain the shared implementation**

Allow Debian, Ubuntu, Fedora, and Windows in `tasks/main.yml`, preserving the Windows dispatch. In
`tasks/linux/main.yml`, assert port 22 when the distribution is Fedora before loading vars or
installing packages. Continue to use shared `client.yml` and `server.yml`.

- [ ] **Step 5: Align documentation and metadata**

List Fedora package/service names, document the Fedora port-22 invariant, and retain the statement
that Linux firewall policy is outside role ownership.

- [ ] **Step 6: Verify**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s ssh
ansible-lint roles/ssh extensions/molecule/ssh
```

Expected: PASS on Ubuntu and Fedora, including idempotence and the custom-port rejection.

- [ ] **Step 7: Commit**

```bash
git add roles/ssh extensions/molecule/ssh
git commit -m "feat: support OpenSSH on Fedora"
```

### Task 7: Prove shared policy roles on Fedora

**Files:**
- Modify: `roles/local_accounts/meta/main.yml`
- Modify: `extensions/molecule/disable_printer_discovery/molecule.yml`
- Modify: `extensions/molecule/disable_usb_storage/{molecule,prepare,converge,verify}.yml`
- Modify: `extensions/molecule/local_accounts/molecule.yml`

**Interfaces:**
- Consumes: existing distribution-neutral role interfaces and tasks.
- Produces: Fedora 44 evidence without new Fedora role implementation files.

- [ ] **Step 1: Refresh printer-discovery coverage**

Replace the Fedora 40 image with `docker.io/geerlingguy/docker-fedora44-ansible:latest` in
`disable_printer_discovery/molecule.yml`; retain its dummy systemd units and privileged runtime.

- [ ] **Step 2: Add Fedora USB-storage fixtures**

Add Fedora enabled and disabled instances. Replace the APT-only `kmod` preparation with
`ansible.builtin.package`, and replace hostname equality checks with membership in `enabled` and
`disabled` inventory groups. Preserve the host-kernel safety assertion before runtime unload tests.

- [ ] **Step 3: Add Fedora local-account coverage**

Add one Fedora 44 platform to `local_accounts/molecule.yml`. Add Fedora to role metadata; do not
change its shared `ansible.builtin.user` or `ansible.posix.authorized_key` tasks.

- [ ] **Step 4: Run the scenarios**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s disable_printer_discovery
ANSIBLE_CONFIG=ansible.cfg molecule test -s disable_usb_storage
ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts
```

Expected: PASS on Fedora 44 and existing Ubuntu instances, with no role-side distribution branches.

- [ ] **Step 5: Lint and commit**

```bash
ansible-lint roles/local_accounts extensions/molecule/disable_printer_discovery extensions/molecule/disable_usb_storage extensions/molecule/local_accounts
```

### Task 8: Make application and share capabilities portable

**Files:**
- Create: `roles/install_app/vars/Debian.yml`
- Create: `roles/install_app/vars/RedHat.yml`
- Modify: `roles/install_app/tasks/linux/{main,native_packages,deb_package,flatpaks}.yml`
- Modify: `roles/install_app/README.md`
- Modify: `roles/install_app/meta/main.yml`
- Modify: `extensions/molecule/install_app/{molecule,prepare,verify}.yml`
- Modify: `roles/mount_network_share/tasks/linux/{main,share}.yml`
- Modify: `roles/mount_network_share/handlers/main.yml`
- Modify: `extensions/molecule/mount_network_share/{molecule,prepare,verify}.yml`

**Interfaces:**
- Consumes: existing `install_app_*` and `mount_network_share_*` options.
- Produces: internal `install_app_npm_prerequisite` distribution data and non-root-safe privileged
  operations on Ubuntu and Fedora.

- [ ] **Step 1: Add Fedora 44 share coverage and refresh app coverage**

Change `install_app` from Fedora 41 to Fedora 44. Add a Fedora 44 platform to
`mount_network_share`. Replace its unconditional APT cache preparation with package-manager-aware
preparation. Keep invalid SMB endpoints and `state: present` so verification never contacts a real
server.

- [ ] **Step 2: Extend Fedora runtime assertions**

Continue to assert native package state, npm prerequisite state, Flatpak and Debian-installer
channel skipping, CIFS package state, share directories, credential modes, and fstab entries on the
new Fedora 44 platforms. Use `package_facts` and branch only commands that must inspect RPM rather
than dpkg state.

- [ ] **Step 3: Run scenarios before implementation**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app
ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
```

Expected: the Fedora 44 assertions establish whether existing module-driven behaviour already
passes. Record any failure at the package-name, package-manager, or system-path seam before changing
the role; do not add a distribution task file to bypass it.

- [ ] **Step 4: Move npm prerequisite names to distribution data**

Create `roles/install_app/vars/Debian.yml`:

```yaml
---
install_app_npm_prerequisite: 'npm'
```

Create `roles/install_app/vars/RedHat.yml`:

```yaml
---
install_app_npm_prerequisite: 'nodejs-npm'
```

Load distribution then OS-family vars at the start of `tasks/linux/main.yml`. Replace the current
package-manager expression in `native_packages.yml` with the internal prerequisite when
`install_app_npm_packages` is non-empty.

- [ ] **Step 5: Add task-level privilege escalation**

Add `become: true` to native package installation, Debian installer preparation/installation,
system Flatpak remote/application tasks, CIFS package installation, system directory and credential
management, `ansible.posix.mount`, and the daemon-reload handler. Do not elevate npm operations that
are intentionally scoped by their existing module semantics.

- [ ] **Step 6: Align role metadata and documentation**

Add Ubuntu to `install_app/meta/main.yml`, document its first-found npm prerequisite data, and retain
the shared channel task map. No Fedora task file is added. Existing `mount_network_share`
documentation remains accurate unless it implies root-only execution.

- [ ] **Step 7: Verify**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app
ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
ansible-lint roles/install_app roles/mount_network_share extensions/molecule/install_app extensions/molecule/mount_network_share
```

Expected: PASS on Ubuntu and Fedora with idempotence.

- [ ] **Step 8: Commit**

```bash
git add roles/install_app roles/mount_network_share extensions/molecule/install_app extensions/molecule/mount_network_share
git commit -m "fix: make Linux capabilities portable"
```

### Task 9: Align release documentation and run the gate

**Files:**
- Modify: `README.md`
- Modify: `extensions/molecule/README.md`
- Modify: `CHANGELOG.rst`
- Verify unchanged version: `galaxy.yml`

**Interfaces:**
- Consumes: completed role contracts from Tasks 1-8.
- Produces: one coherent unreleased `0.9.0` release description and final validation evidence.

- [ ] **Step 1: Update shared documentation**

In `extensions/molecule/README.md`, update the GNOME paragraph to say `desktop_layout` validates
Ubuntu 22.04/24.04/26.04 while `power_policy` also validates Fedora 44. Retain the live-GNOME
coverage limitation. In `README.md`, describe Fedora 44 systemd scenario requirements without
naming only `auto_updates` if several scenarios now require them.

- [ ] **Step 2: Expand the existing `0.9.0` changelog entry**

Add bullets covering:

- removal of `git`
- Fedora support and Fedora 44 Molecule coverage
- Ubuntu 26.04 GNOME coverage
- chrony replacing ntpsec
- DNF5 automatic updates
- APT policy rename to `52sys-admin-auto-updates` and removal of the old path

Do not edit older release sections.

- [ ] **Step 3: Verify release version consistency**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
assert "version: '0.9.0'" in Path('galaxy.yml').read_text()
assert '0.9.0\n-----' in Path('CHANGELOG.rst').read_text()
PY
```

Expected: exit status 0.

- [ ] **Step 4: Run static validation**

```bash
. .venv/bin/activate && ansible-lint .
```

Expected: all commands PASS.

- [ ] **Step 5: Run the complete pre-publish Molecule gate**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg \
  MOLECULE_GLOB='extensions/molecule/**/molecule.yml' molecule test --all
```

Expected: every discovered scenario PASS, including idempotence and verify.

- [ ] **Step 6: Build the collection artefact**

```bash
. .venv/bin/activate && ansible-galaxy collection build --force --output-path dist
```

Expected: a `dist/jaythomasonprojects-sys_admin-0.9.0.tar.gz` artefact is created successfully.

- [ ] **Step 7: Inspect the final diff and commit release files**

```bash
git status --short
  docs/agent-work/specs/2026-09-03-fedora-support-and-role-cleanup-design.md \
  docs/agent-work/plans/2026-09-03-fedora-support-and-role-cleanup.md
```

Expected: only intended source changes or ignored/generated build output remain after the commit.

# Role Maintainability Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or
> executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Simplify role implementation by narrowing the network-share interface, keeping temporary
values local, consolidating platform gates, and moving substantial Windows algorithms into
role-owned static PowerShell files.

**Architecture:** Keep capability roles independent and keep one OS dispatch in each role's
`tasks/main.yml`. Use argument specifications for unconditional interface structure, scoped task
variables for local calculations, and static parameterised scripts for procedural Windows logic.
Preserve Fedora 44 and Ubuntu 26.04 support from the preceding release work.

**Tech Stack:** Ansible >=2.18, ansible.windows, ansible.posix, PowerShell 5.1, Molecule Docker,
Proxmox/WinRM Windows integration, ansible-lint, and yamllint.

**Spec:** `docs/agent-work/specs/2026-09-03-role-maintainability-cleanup-design.md`

## Global Constraints

- Complete `docs/agent-work/plans/2026-09-03-fedora-support-and-role-cleanup.md` before starting this
  plan. Do not execute both plans against the same role files at the same time.
- Work from the completed Fedora-support state. Preserve its uncommitted or committed work; do not
  reset or overwrite it.
- Keep `galaxy.yml` at `0.9.0`; this work joins the unreleased `0.9.0` release.
- Preserve Windows, Ubuntu 22.04/24.04/26.04, and Fedora support in `power_policy`.
- Preserve Ubuntu 22.04/24.04/26.04 support in `desktop_layout`.
- Preserve Debian, Ubuntu, and Fedora support in `time_sync`.
- Preserve Windows and Linux APT/DNF4/DNF5 support in `auto_updates`.
- Keep `power_policy_disable_sleep` and its Windows AC/DC monitor and standby behaviour.
- Require `mount_network_share_shares[].fstab_options` to be a YAML list when supplied.
- Require every network-share entry to define `name`, `server`, `share`, and `mount_point`, even when
  the role is disabled.
- Keep username/password pairing validation and secret-bearing tasks under `no_log: true`.
- Use FQCNs, single quotes, explicit states, multi-line mappings, project key order, and task-level
  `become: true` as specified by `AGENTS.md`.
- Every Molecule command must include `ANSIBLE_CONFIG=ansible.cfg`.
- A scenario failure unrelated to this change is a report, not a blocker.

## File Map

### Network-share simplification

- Modify: `roles/mount_network_share/meta/argument_specs.yml`
- Modify: `roles/mount_network_share/tasks/main.yml`
- Modify: `roles/mount_network_share/tasks/linux/main.yml`
- Modify: `roles/mount_network_share/tasks/linux/share.yml`
- Modify: `roles/mount_network_share/README.md`
- Modify: `extensions/molecule/mount_network_share/converge.yml`

### Static Windows scripts

- Create: `roles/power_policy/files/Disable-PowerPolicySleep.ps1`
- Modify: `roles/power_policy/tasks/windows/main.yml`
- Modify: `roles/power_policy/README.md`
- Modify: `tests/check_power_policy_windows_contract.yml`
- Create: `roles/local_accounts/files/Set-AuthorizedKeyAcl.ps1`
- Modify: `roles/local_accounts/tasks/windows/authorized_keys.yml`
- Modify: `roles/local_accounts/README.md`
- Create: `tests/check_local_accounts_windows_contract.yml`

### Complete platform gates

- Modify: `roles/time_sync/tasks/main.yml`
- Modify: `roles/time_sync/tasks/linux/main.yml`
- Modify: `roles/time_sync/README.md`
- Modify: `extensions/molecule/time_sync/converge.yml`
- Modify: `roles/auto_updates/tasks/main.yml`
- Modify: `roles/auto_updates/tasks/linux/main.yml`
- Modify: `roles/auto_updates/README.md`
- Modify: `extensions/molecule/auto_updates/converge.yml`

### Durable rules and release record

- Modify: `AGENTS.md`
- Modify: `CHANGELOG.rst`
- Verify unchanged: `galaxy.yml`

---

### Task 1: Narrow and localise the network-share interface

**Files:**
- Modify: `roles/mount_network_share/meta/argument_specs.yml:21-86`
- Modify: `roles/mount_network_share/tasks/main.yml:10-51`
- Modify: `roles/mount_network_share/tasks/linux/main.yml:7-12`
- Modify: `roles/mount_network_share/tasks/linux/share.yml:2-35`
- Modify: `roles/mount_network_share/README.md:15-69`
- Modify: `extensions/molecule/mount_network_share/converge.yml:8-70`

**Interfaces:**
- Consumes: `mount_network_share_shares: list[dict]` and the existing per-share options.
- Produces: list-only `fstab_options`, unconditionally required `name`, `server`, `share`, and
  `mount_point`, and include-scoped internal variables named `mount_network_share_credentials_path`,
  `mount_network_share_has_credentials`, `mount_network_share_option_list`,
  `mount_network_share_present`, `mount_network_share_source`, and `mount_network_share_state`.

- [ ] **Step 1: Change the Molecule fixtures to the approved public interface**

Replace the comma-separated value at `extensions/molecule/mount_network_share/converge.yml:31` with:

```yaml
        fstab_options:
          - '_netdev'
          - 'nofail'
          - 'vers=3.0'
```

Keep the first share's existing list and all desired-state assertions.

- [ ] **Step 2: Add failing validation cases**

Replace the unguarded disabled malformed-share call at the end of `converge.yml` with a rescued
negative test. It must call the disabled role with a share that omits `mount_point`, fail explicitly
if the role accepts it, and assert that the rescued message contains both `missing required
arguments` and `mount_point`:

```yaml
    - name: Reject incomplete disabled share definitions
      block:
        - name: Include disabled role with an incomplete share
          ansible.builtin.include_role:
            name: 'jaythomasonprojects.sys_admin.mount_network_share'
          vars:
            mount_network_share_enabled: false
            mount_network_share_shares:
              - name: 'invalid_share'
                server: 'files.example.invalid'
                share: 'Invalid'

        - name: Fail when incomplete disabled share is accepted
          ansible.builtin.fail:
            msg: 'mount_network_share accepted an incomplete disabled share.'
      rescue:
        - name: Assert required mount point rejection
          ansible.builtin.assert:
            that:
              - "'missing required arguments' in ansible_failed_result.msg"
              - "'mount_point' in ansible_failed_result.msg"
```

Add a second rescued call with a complete enabled share and
`fstab_options: '_netdev,nofail'`. Assert the exact role message:

```text
mount_network_share fstab_options must be a YAML list of strings.
```

The explicit failure after the role call must say:

```text
mount_network_share accepted comma-separated fstab_options.
```

- [ ] **Step 3: Run the scenario to verify both new contracts fail**

Run:

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
```

Expected: FAIL because argument specifications do not yet require `mount_point` and the role still
accepts comma-separated `fstab_options`.

- [ ] **Step 4: Move unconditional fields into the argument specification**

Add `required: true` to the nested `name`, `server`, `share`, and `mount_point` options in
`roles/mount_network_share/meta/argument_specs.yml`. Keep `fstab_options` as `type: list` with
`elements: str`.

Remove the `Validate required share fields` task from `roles/mount_network_share/tasks/main.yml`.
Keep the credential-pairing task unchanged.

- [ ] **Step 5: Enforce list-only mount options before Linux work**

Add this assertion inside the enabled block in `tasks/main.yml`, before credential validation and
platform dispatch:

```yaml
    - name: Validate Linux mount options
      ansible.builtin.assert:
        that:
          - >-
            mount_network_share_item.fstab_options is not defined or
            (mount_network_share_item.fstab_options is sequence and
            mount_network_share_item.fstab_options is not string)
        fail_msg: >-
          mount_network_share fstab_options must be a YAML list of strings.
      loop: '{{ mount_network_share_shares }}'
      loop_control:
        loop_var: mount_network_share_item
        label: '{{ mount_network_share_item.name }}'
      when: ansible_facts.system == 'Linux'
      no_log: true
```

This strict assertion is necessary because Ansible argument type validation is coercive and returns
the original value to the role.

- [ ] **Step 6: Scope calculated values to each share include**

Add these variables to the `Manage SMB/CIFS shares` include in
`roles/mount_network_share/tasks/linux/main.yml`:

```yaml
  vars:
    mount_network_share_credentials_path: >-
      {{ mount_network_share_item.credentials_path | default(
           '/etc/samba/credentials/' ~ mount_network_share_item.name
         ) }}
    mount_network_share_has_credentials: >-
      {{ mount_network_share_item.username is defined
         and mount_network_share_item.password is defined }}
    mount_network_share_option_list: >-
      {{ mount_network_share_item.fstab_options | default(
           ['_netdev', 'nofail', 'iocharset=utf8']
         ) }}
    mount_network_share_present: >-
      {{ mount_network_share_item.state | default('present')
         not in ['absent', 'absent_from_fstab'] }}
    mount_network_share_source: >-
      {{ '//' ~ mount_network_share_item.server ~ '/'
         ~ mount_network_share_item.share }}
    mount_network_share_state: >-
      {{ mount_network_share_item.state | default('present') }}
```

Delete both `set_fact` tasks from `tasks/linux/share.yml`. Do not add an effective-share dictionary,
filter plugin, or common role. Keep all module tasks and their conditions in the same order.

- [ ] **Step 7: Align the role documentation**

Update the implementation map to say that `tasks/main.yml` validates enabled share invariants and
that `tasks/linux/main.yml` passes scoped values to each share include. State that all share entries
must remain structurally valid when the role is disabled. State that `fstab_options` accepts a YAML
list only, and remove the comma-separated form.

- [ ] **Step 8: Verify the network-share role**

Run:

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
ansible-lint roles/mount_network_share extensions/molecule/mount_network_share
yamllint roles/mount_network_share extensions/molecule/mount_network_share
```

Expected: all commands PASS. The scenario must prove both negative contracts, the existing mount and
credential state, and idempotence on every platform inherited from the completed Fedora plan.

- [ ] **Step 9: Commit the network-share simplification**

```bash
git add roles/mount_network_share extensions/molecule/mount_network_share
git commit -m "refactor!: simplify network share input"
```

### Task 2: Extract the Windows power timeout algorithm

**Files:**
- Create: `roles/power_policy/files/Disable-PowerPolicySleep.ps1`
- Modify: `roles/power_policy/tasks/windows/main.yml:8-67`
- Modify: `roles/power_policy/README.md`
- Modify: `tests/check_power_policy_windows_contract.yml`

**Interfaces:**
- Consumes: `power_policy_disable_sleep: bool` with default `true`.
- Produces: a static `Disable-PowerPolicySleep.ps1` script that manages AC/DC monitor and standby
  timeout values and sets `$Ansible.Changed`; the task file calls it through
  `ansible.windows.win_powershell.path`.

- [ ] **Step 1: Rewrite the controller-side contract test before implementation**

Keep the existing defaults and argument-specification assertions in
`tests/check_power_policy_windows_contract.yml`. Add a slurp for
`roles/power_policy/files/Disable-PowerPolicySleep.ps1`, and replace task-file token checks with
these contracts:

```yaml
          - >-
            power_policy_windows_tasks.content | b64decode is search(
            "path: 'Disable-PowerPolicySleep.ps1'")
          - >-
            power_policy_windows_tasks.content | b64decode is search(
            'power_policy_disable_sleep \| bool')
          - >-
            power_policy_sleep_script.content | b64decode is search(
            '\$Ansible.Changed = \$false')
```

Also assert that the decoded script contains `monitor-timeout-ac`, `standby-timeout-ac`,
`monitor-timeout-dc`, and `standby-timeout-dc`. Keep the existing failure message.

- [ ] **Step 2: Run the contract test to verify it fails**

Run:

```bash
. .venv/bin/activate && ansible-playbook tests/check_power_policy_windows_contract.yml
```

Expected: FAIL because `roles/power_policy/files/Disable-PowerPolicySleep.ps1` does not exist.

- [ ] **Step 3: Create the static PowerShell script**

Create `roles/power_policy/files/Disable-PowerPolicySleep.ps1` with this fixed policy algorithm:

```powershell
[CmdletBinding()]
param ()

$Ansible.Changed = $false
$settings = @(
    @{
        Change = 'monitor-timeout-ac'
        PowerSource = 'AC'
        Setting = 'VIDEOIDLE'
        Subgroup = 'SUB_VIDEO'
    },
    @{
        Change = 'standby-timeout-ac'
        PowerSource = 'AC'
        Setting = 'STANDBYIDLE'
        Subgroup = 'SUB_SLEEP'
    },
    @{
        Change = 'monitor-timeout-dc'
        PowerSource = 'DC'
        Setting = 'VIDEOIDLE'
        Subgroup = 'SUB_VIDEO'
    },
    @{
        Change = 'standby-timeout-dc'
        PowerSource = 'DC'
        Setting = 'STANDBYIDLE'
        Subgroup = 'SUB_SLEEP'
    }
)

foreach ($setting in $settings) {
    $pattern = 'Current ' + $setting.PowerSource +
        ' Power Setting Index: 0x([0-9a-f]+)'
    $query = powercfg /query SCHEME_CURRENT $setting.Subgroup $setting.Setting
    if ($LASTEXITCODE -ne 0) {
        throw "Could not query $($setting.PowerSource) timeout for " +
            "$($setting.Subgroup)/$($setting.Setting)."
    }
    $matches = @($query | Select-String $pattern)
    if ($matches.Count -ne 1) {
        throw "Could not read $($setting.PowerSource) timeout for " +
            "$($setting.Subgroup)/$($setting.Setting)."
    }
    $value = [Convert]::ToInt32(
        $matches[0].Matches[0].Groups[1].Value, 16)
    if ($value -ne 0) {
        powercfg /change $setting.Change 0
        if ($LASTEXITCODE -ne 0) {
            throw "Could not set $($setting.Change) to never."
        }
        $Ansible.Changed = $true
    }
}
```

Do not add localisation logic or a generic power-setting parameter model.

- [ ] **Step 4: Replace the inline script with a direct path call**

Replace the inline `win_powershell` task, its register, and its `changed_when` with:

```yaml
- name: Disable sleep and standby timeouts
  ansible.windows.win_powershell:
    path: 'Disable-PowerPolicySleep.ps1'
  when:
    - power_policy_disable_sleep | bool
```

Keep the power-plan and hibernation tasks unchanged.

- [ ] **Step 5: Document the role-owned script**

In `roles/power_policy/README.md`, update the implementation map or Windows implementation text to
name `files/Disable-PowerPolicySleep.ps1`. State that the script owns the fixed AC/DC monitor and
standby timeout algorithm and reports whether it changed a timeout.

- [ ] **Step 6: Run controller-side validation**

```bash
. .venv/bin/activate && ansible-playbook tests/check_power_policy_windows_contract.yml
ansible-lint roles/power_policy tests/check_power_policy_windows_contract.yml
yamllint roles/power_policy tests/check_power_policy_windows_contract.yml
```

Expected: all commands PASS. The contract test must find the public option, path call, direct changed
reporting, and all four timeout names.

- [ ] **Step 7: Run Windows integration for the power script**

Restore Proxmox VM `101` at `192.168.41.103` to snapshot `fresh`. Run `power_policy` through WinRM
with `power_policy_disable_sleep: true`, `power_policy_disable_hibernate: true`, and the configured
power plan. Reconnect after bootstrap password rotation when required by `AGENTS.md`.

Verify with `powercfg` that AC/DC `VIDEOIDLE` and `STANDBYIDLE` are zero. Run the role a second time
and verify that the static script task reports `changed: false`. Restore snapshot `fresh` again.

- [ ] **Step 8: Commit the power-script extraction**

```bash
git add roles/power_policy tests/check_power_policy_windows_contract.yml
git commit -m "refactor: extract Windows power policy script"
```

### Task 3: Extract the Windows authorised-key ACL algorithm

**Files:**
- Create: `roles/local_accounts/files/Set-AuthorizedKeyAcl.ps1`
- Modify: `roles/local_accounts/tasks/windows/authorized_keys.yml:2-168`
- Modify: `roles/local_accounts/README.md`
- Create: `tests/check_local_accounts_windows_contract.yml`

**Interfaces:**
- Consumes: existing `local_accounts_users` entries and administrator group membership.
- Produces: `Set-AuthorizedKeyAcl.ps1` with `Administrator: switch` and `UserName: string` parameter
  sets; administrator and standard-user task calls use the same role-specific policy script.

- [ ] **Step 1: Add a failing static contract test**

Create `tests/check_local_accounts_windows_contract.yml`:

```yaml
---
- name: Check local_accounts Windows authorised-key contract
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: Read Windows authorised-key tasks
      ansible.builtin.slurp:
        src: >-
          {{ playbook_dir }}/../roles/local_accounts/tasks/windows/authorized_keys.yml
      register: local_accounts_windows_tasks

    - name: Read Windows authorised-key ACL script
      ansible.builtin.slurp:
        src: >-
          {{ playbook_dir }}/../roles/local_accounts/files/Set-AuthorizedKeyAcl.ps1
      register: local_accounts_acl_script

    - name: Assert static ACL policy contract
      ansible.builtin.assert:
        that:
          - >-
            local_accounts_windows_tasks.content | b64decode is search(
            "path: 'Set-AuthorizedKeyAcl.ps1'")
          - >-
            local_accounts_windows_tasks.content | b64decode is search(
            'Administrator: true')
          - >-
            local_accounts_windows_tasks.content | b64decode is search(
            "UserName: '{{ item.name }}'")
          - >-
            local_accounts_windows_tasks.content | b64decode is not search(
            'script: \|')
          - >-
            local_accounts_acl_script.content | b64decode is search(
            '\$Ansible.Changed = \$false')
          - >-
            local_accounts_acl_script.content | b64decode is search('S-1-5-32-544')
          - >-
            local_accounts_acl_script.content | b64decode is search('S-1-5-18')
        fail_msg: >-
          local_accounts must use one static script for both authorised-key ACL
          policies.
```

- [ ] **Step 2: Run the static contract test to verify it fails**

```bash
. .venv/bin/activate && ansible-playbook tests/check_local_accounts_windows_contract.yml
```

Expected: FAIL because `roles/local_accounts/files/Set-AuthorizedKeyAcl.ps1` does not exist.

- [ ] **Step 3: Create the role-specific ACL script**

Create `roles/local_accounts/files/Set-AuthorizedKeyAcl.ps1`:

```powershell
[CmdletBinding(DefaultParameterSetName = 'StandardUser')]
param (
    [Parameter(Mandatory, ParameterSetName = 'Administrator')]
    [Switch] $Administrator,

    [Parameter(Mandatory, ParameterSetName = 'StandardUser')]
    [String] $UserName
)

$Ansible.Changed = $false
$administratorSid = [System.Security.Principal.SecurityIdentifier]::new(
    'S-1-5-32-544')
$systemSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18')

if ($Administrator) {
    $ownerSid = $administratorSid
    $expectedSids = @($administratorSid, $systemSid)
    $paths = @('C:\ProgramData\ssh\administrators_authorized_keys')
}
else {
    $account = [System.Security.Principal.NTAccount]::new(
        $env:COMPUTERNAME, $UserName)
    $ownerSid = $account.Translate(
        [System.Security.Principal.SecurityIdentifier])
    $expectedSids = @($ownerSid, $administratorSid, $systemSid)
    $paths = @(
        "C:\Users\$UserName\.ssh",
        "C:\Users\$UserName\.ssh\authorized_keys"
    )
}

$fullControl = [System.Security.AccessControl.FileSystemRights]::FullControl
foreach ($path in $paths) {
    $acl = Get-Acl -LiteralPath $path
    $rules = @($acl.GetAccessRules(
        $true,
        $true,
        [System.Security.Principal.SecurityIdentifier]
    ))
    $actualOwner = $acl.GetOwner(
        [System.Security.Principal.SecurityIdentifier])
    $aclMatches = $acl.AreAccessRulesProtected -and
        $actualOwner.Value -eq $ownerSid.Value -and
        $rules.Count -eq $expectedSids.Count

    foreach ($sid in $expectedSids) {
        $matchingRules = @($rules | Where-Object {
            $_.IdentityReference.Value -eq $sid.Value -and
            -not $_.IsInherited -and
            $_.AccessControlType -eq 'Allow' -and
            [int] $_.FileSystemRights -eq [int] $fullControl -and
            $_.InheritanceFlags -eq 'None' -and
            $_.PropagationFlags -eq 'None'
        })
        $aclMatches = $aclMatches -and ($matchingRules.Count -eq 1)
    }

    if (-not $aclMatches) {
        $acl.SetOwner($ownerSid)
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($rule in @($acl.Access)) {
            [void] $acl.RemoveAccessRuleSpecific($rule)
        }
        foreach ($sid in $expectedSids) {
            $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
                $sid,
                'FullControl',
                'Allow'
            )
            [void] $acl.AddAccessRule($rule)
        }
        Set-Acl -LiteralPath $path -AclObject $acl
        $Ansible.Changed = $true
    }
}
```

This script is specific to the role's authorised-key policy. Do not generalise it into arbitrary
paths, rights, inheritance flags, or access-rule inputs.

- [ ] **Step 4: Replace both inline ACL scripts**

Replace the administrator ACL task body with:

```yaml
- name: Set administrator authorised-key ACL
  ansible.windows.win_powershell:
    path: 'Set-AuthorizedKeyAcl.ps1'
    parameters:
      Administrator: true
  when: local_accounts_windows_administrators | length > 0
  no_log: true
```

Replace the standard-user ACL task body with:

```yaml
- name: Set standard-user SSH ACLs
  ansible.windows.win_powershell:
    path: 'Set-AuthorizedKeyAcl.ps1'
    parameters:
      UserName: '{{ item.name }}'
  loop: '{{ local_accounts_users }}'
  when:
    - item.ssh_authorized_keys is defined
    - item.groups is not defined or 'Administrators' not in item.groups
  no_log: true
```

Keep the existing file and directory tasks unchanged.

- [ ] **Step 5: Scope administrator list calculations to their tasks**

Replace the two opening `set_fact` tasks with a block named `Manage administrator authorised keys`.
Put the administrator key copy and ACL call inside it. Define these block variables:

```yaml
  vars:
    local_accounts_windows_administrators: >-
      {{ local_accounts_users
         | selectattr('groups', 'defined')
         | selectattr('groups', 'contains', 'Administrators')
         | list }}
    local_accounts_windows_administrator_keys: >-
      {{ local_accounts_users
         | selectattr('groups', 'defined')
         | selectattr('groups', 'contains', 'Administrators')
         | map(attribute='ssh_authorized_keys', default=[])
         | flatten
         | list }}
```

Apply `when: local_accounts_windows_administrators | length > 0` and `no_log: true` to the block.
Remove the repeated conditions from its two child tasks.

- [ ] **Step 6: Document the ACL implementation boundary**

Update `roles/local_accounts/README.md` to name `files/Set-AuthorizedKeyAcl.ps1` in the Windows
implementation map. Keep the existing exact ACL ownership contract. State that the script has only
administrator and standard-user modes.

- [ ] **Step 7: Run controller-side validation**

```bash
. .venv/bin/activate && ansible-playbook tests/check_local_accounts_windows_contract.yml
ansible-lint roles/local_accounts tests/check_local_accounts_windows_contract.yml
yamllint roles/local_accounts tests/check_local_accounts_windows_contract.yml
```

Expected: all commands PASS. The task file must contain no inline PowerShell script and both ACL
calls must use the same static file.

- [ ] **Step 8: Run Windows integration for both ACL modes**

Restore Proxmox VM `101` at `192.168.41.103` to snapshot `fresh`. Apply `local_accounts` through
WinRM with one administrator account and one standard account, each with an authorised key. Reconnect
after bootstrap password rotation when required by `AGENTS.md`.

Verify that `C:\ProgramData\ssh\administrators_authorized_keys` has protected inheritance, owner
Administrators, and exactly one FullControl allow rule each for Administrators and SYSTEM. Verify
that the standard user's `.ssh` directory and `authorized_keys` have protected inheritance, the user
as owner, and exactly one FullControl allow rule each for that user, Administrators, and SYSTEM.
Run the role again and verify both ACL tasks report `changed: false`. Restore snapshot `fresh` again.

- [ ] **Step 9: Commit the ACL-script extraction**

```bash
git add roles/local_accounts tests/check_local_accounts_windows_contract.yml
git commit -m "refactor: extract authorised key ACL script"
```

### Task 4: Complete the remaining top-level platform gates

**Files:**
- Modify: `roles/time_sync/tasks/main.yml:2-10`
- Modify: `roles/time_sync/tasks/linux/main.yml:2-6`
- Modify: `roles/time_sync/README.md`
- Modify: `extensions/molecule/time_sync/converge.yml:12-41`
- Modify: `roles/auto_updates/tasks/main.yml:2-18`
- Modify: `roles/auto_updates/tasks/linux/main.yml:2-26`
- Modify: `roles/auto_updates/README.md`
- Modify: `extensions/molecule/auto_updates/converge.yml:24-78`

**Interfaces:**
- Consumes: Fedora-support platform contracts and existing role options.
- Produces: one complete platform gate in each root task file; `time_sync` accepts Debian, Ubuntu,
  and Fedora; `auto_updates` accepts Windows or Linux with APT, DNF4, or DNF5.

- [ ] **Step 1: Make disabled time synchronisation prove the root gate**

In the unsupported Rocky Linux call in `extensions/molecule/time_sync/converge.yml`, set:

```yaml
            time_sync_enabled: false
            time_sync_server: ''
```

Keep the exact expected message:

```text
time_sync supports Debian, Ubuntu, and Fedora hosts only.
```

- [ ] **Step 2: Set the new automatic-update support message in the test**

Replace the unsupported package-manager substring assertion in
`extensions/molecule/auto_updates/converge.yml` with this exact message:

```text
auto_updates supports Windows and Linux hosts with apt, dnf, or dnf5 only.
```

Use the same exact message for unsupported Darwin and unsupported Linux package-manager fixtures.

- [ ] **Step 3: Run both scenarios to verify the root contracts fail**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
```

Expected: `time_sync` FAILS because disabled Rocky bypasses the nested distribution gate.
`auto_updates` FAILS because its current root and nested assertions return different messages.

- [ ] **Step 4: Move the complete time-sync support rule to the root**

Change `roles/time_sync/tasks/main.yml` to assert:

```yaml
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - ansible_facts.system == 'Linux'
      - ansible_facts.distribution in ['Debian', 'Fedora', 'Ubuntu']
    fail_msg: 'time_sync supports Debian, Ubuntu, and Fedora hosts only.'
```

Delete the opening distribution assertion from `tasks/linux/main.yml`. Keep server validation and
all chrony tasks unchanged.

- [ ] **Step 5: Put the complete automatic-update support rule at the root**

Replace the root assertion in `roles/auto_updates/tasks/main.yml` with:

```yaml
- name: Assert supported platform
  ansible.builtin.assert:
    that:
      - >-
        ansible_facts.os_family == 'Windows' or
        (ansible_facts.system == 'Linux' and
        ansible_facts.pkg_mgr in ['apt', 'dnf', 'dnf5'])
    fail_msg: >-
      auto_updates supports Windows and Linux hosts with apt, dnf, or dnf5
      only.
```

Delete the package-manager assertion from `tasks/linux/main.yml`.

- [ ] **Step 6: Scope DNF implementation data to its include**

Delete the DNF `set_fact` task from `roles/auto_updates/tasks/linux/main.yml`. Add these variables to
the `Configure automatic updates for DNF systems` include:

```yaml
  vars:
    auto_updates_dnf_package: >-
      {{ 'dnf5-plugin-automatic' if ansible_facts.pkg_mgr == 'dnf5'
         else 'dnf-automatic' }}
    auto_updates_dnf_timer: >-
      {{ 'dnf5-automatic.timer' if ansible_facts.pkg_mgr == 'dnf5'
         else 'dnf-automatic.timer' }}
```

Keep the APT and DNF includes and their existing package-manager conditions.

- [ ] **Step 7: Update the two implementation maps**

In each README, state that `tasks/main.yml` owns the complete support gate and dispatch. State that
the Linux task file contains only the shared implementation and package-manager dispatch. Do not
change the supported-platform lists.

- [ ] **Step 8: Verify both roles**

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
ansible-lint roles/time_sync roles/auto_updates extensions/molecule/time_sync extensions/molecule/auto_updates
yamllint roles/time_sync roles/auto_updates extensions/molecule/time_sync extensions/molecule/auto_updates
```

Expected: all commands PASS, including disabled unsupported-platform rejection, all existing desired
state, and idempotence. Fedora and DNF5 coverage must remain present.

- [ ] **Step 9: Confirm other completed gates remain complete**

Read these files and confirm they still contain their full support contracts after the Fedora plan:

```text
roles/power_policy/tasks/main.yml
roles/desktop_layout/tasks/main.yml
roles/ssh/tasks/main.yml
```

Expected: `power_policy` still names Windows, Ubuntu 22.04/24.04/26.04, and Fedora;
`desktop_layout` still names Ubuntu 22.04/24.04/26.04; `ssh` still names Debian, Ubuntu, Fedora, and
Windows. Do not edit a file when its gate is already complete.

- [ ] **Step 10: Commit the platform-gate cleanup**

```bash
git add roles/time_sync roles/auto_updates extensions/molecule/time_sync extensions/molecule/auto_updates
git commit -m "refactor: centralise role platform gates"
```

### Task 5: Record the maintenance rules and verify the release

**Files:**
- Modify: `AGENTS.md`
- Modify: `CHANGELOG.rst:4-12`
- Verify unchanged: `galaxy.yml:7`
- Include: `docs/agent-work/specs/2026-09-03-role-maintainability-cleanup-design.md`
- Include: `docs/agent-work/plans/2026-09-03-role-maintainability-cleanup.md`

**Interfaces:**
- Consumes: completed role changes from Tasks 1-4.
- Produces: durable repository rules and an accurate `0.9.0` release record.

- [ ] **Step 1: Add the approved implementation boundaries to `AGENTS.md`**

Add these rules under project or role conventions:

```markdown
- Keep the complete supported-platform gate in `tasks/main.yml`; OS task files own implementation
  prerequisites, not narrower platform gates.
- Put cohesive shell or PowerShell algorithms in static files under the owning role and pass values
  as parameters. Keep short commands and small Ansible glue inline; use a template only when script
  source must vary.
- Do not use `set_fact` for temporary aliases when task, block, or include variables give the value
  the required scope. Keep a named calculated value when it is clearer than repeated expressions.
- Support one public input shape unless a real consumer requires another. Do not retain compatibility
  forms only for hypothetical consumers.
```

- [ ] **Step 2: Expand the unreleased changelog entry**

Add concise `0.9.0` bullets that state:

- `mount_network_share` now requires list-valued `fstab_options` and structurally valid share entries
- temporary per-share facts were replaced with scoped include variables
- substantial Windows power and authorised-key ACL algorithms now use role-owned static PowerShell
  files
- complete platform gates now live in each role's root task file

Do not edit older changelog sections. Preserve the Fedora 44 and Ubuntu 26.04 bullets added by the
preceding plan.

- [ ] **Step 3: Verify version consistency**

Run:

```bash
python3 - <<'PY'
from pathlib import Path

assert "version: '0.9.0'" in Path('galaxy.yml').read_text()
assert '0.9.0\n-----' in Path('CHANGELOG.rst').read_text()
PY
```

Expected: exit status 0.

- [ ] **Step 4: Run every affected portable test**

```bash
. .venv/bin/activate && ansible-playbook tests/check_power_policy_windows_contract.yml
ansible-playbook tests/check_local_accounts_windows_contract.yml
ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
ANSIBLE_CONFIG=ansible.cfg molecule test -s power_policy
ANSIBLE_CONFIG=ansible.cfg molecule test -s local_accounts
ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync
ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates
```

Expected: all commands PASS. The PowerShell execution evidence comes from the Windows integration
steps, not from Docker.

- [ ] **Step 5: Run repository static validation**

```bash
. .venv/bin/activate && ansible-lint .
yamllint .
```

Expected: both commands PASS.

- [ ] **Step 6: Inspect the final diff**

```bash
git status --short
git diff --check
git diff --stat
```

Expected: no whitespace errors, no generated collection archive, no `.venv` content staged, and no
files outside this plan or the preceding Fedora plan changed unexpectedly.

- [ ] **Step 7: Commit the durable rules and release record**

```bash
git add AGENTS.md CHANGELOG.rst \
  docs/agent-work/specs/2026-09-03-role-maintainability-cleanup-design.md \
  docs/agent-work/plans/2026-09-03-role-maintainability-cleanup.md
git commit -m "docs: record role maintenance conventions"
```

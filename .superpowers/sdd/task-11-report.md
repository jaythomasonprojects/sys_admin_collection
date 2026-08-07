# Task 11 Report

## Scope

Completed Task 11 only: `config_ssh` and `create_user` ownership alignment.

## Changes

- Split `config_ssh` into Debian/Ubuntu client and server flows, plus a
  Windows server flow.
- Made `config_ssh` install both Linux OpenSSH packages, remove cloud-init
  server drop-ins, validate `sshd -t`, and enable/start the selected service.
- Kept the Windows OpenSSH Server capability, server configuration, exact
  firewall rule, automatic running service, and PowerShell default shell in
  `config_ssh`; removed all authorised-key and ACL handling from that role.
- Set the prefixed root-login policy default directly to `'no'`.
- Split `create_user` into account, authorised-key, and Windows password-policy
  flows. Linux keys remain additive through `ansible.posix.authorized_key`.
- Moved Windows administrator aggregate and standard-user key ownership to
  `create_user`, with SID-based owners, disabled inheritance, and explicit
  full-control ACLs only for the required principals.
- Added direct `ansible.posix` metadata to `create_user` and rewrote both role
  READMEs with ownership, task-map, schema, semantic, ACL, and migration
  contracts.
- Strengthened Molecule scenarios: systemd-capable SSH validation begins with
  neither OpenSSH package installed; user validation covers account fields,
  key modes and owners, and multiple keys.

## TDD Evidence

- The strengthened SSH scenario failed before implementation because `sshd`
  and the SSH service were absent. The previous role removed its invalid
  configuration and the restart handler then failed for a missing service.
- The strengthened user scenario initially exposed an incorrect test field
  index. The contract was corrected to Ansible's `getent passwd` field layout
  before implementation. It then confirmed the existing Linux user contract.

## Verification

The final checkout artefact was built and installed before Molecule validation:

```text
ansible-galaxy collection build --force --output-path dist
ansible-galaxy collection install \
  dist/jaythomasonprojects-sys_admin-0.6.0.tar.gz \
  -p ./.ansible/collections --force
```

Successful gates:

```text
ansible-lint .
ANSIBLE_CONFIG=ansible.cfg molecule test -s config_ssh
ANSIBLE_CONFIG=ansible.cfg molecule test -s create_user
```

Both Molecule scenarios completed convergence, idempotence, verification,
cleanup, and destruction. Molecule reports its existing missing optional
`requirements.yml` dependency entries, but no scenario failures.

## Windows Validation Blocker

Windows integration could not run. The reachability probe failed:

```text
ssh -o BatchMode=yes -o ConnectTimeout=10 root@proxmox02 true
ssh: connect to host proxmox02 port 4022: Connection timed out
```

VM 101 was therefore not restored or modified. Once Proxmox is reachable, run
the prescribed snapshot restore, WinRM validation, reconnect after bootstrap
password rotation, inspect the Windows OpenSSH and key ACL contracts, and
restore `fresh` again.

## Review Fix

- Updated `roles/create_user/tasks/windows/authorized_keys.yml` so both ACL
  tasks compare the current owner, inheritance protection, and complete
  explicit DACL with the required SID-based full-control rules before calling
  `Set-Acl`.
- The tasks set `$Ansible.Changed` only after correcting a differing ACL. A
  compliant ACL makes no mutation and reports unchanged; owner or DACL drift
  is remediated and reports changed.

## Review Verification

- Built `dist/jaythomasonprojects-sys_admin-0.6.0.tar.gz` from this checkout
  and installed it into `.ansible/collections` before testing.
- `ansible-lint .` passed with zero failures. It emitted the existing duplicate
  collection and incompatible yamllint-configuration warnings.
- `yamllint .` passed.
- `molecule test -s create_user` passed convergence, idempotence, verification,
  cleanup, and destruction using the checkout-built artefact. Its included task
  paths resolved under this checkout's `.ansible/collections` directory. The
  existing missing optional `requirements.yml` dependency entries were reported.

## Review Windows Validation Blocker

Proxmox was reachable and VM 101 was restored to `fresh`. The built artefact
was installed into `Projects/AnsiblePlaybooks/.ansible/collections`, but the
Windows playbook could not start because the required vault file is unreadable:

```text
Could not read vault password file '/home/jthomason/.vault_pass': [Errno 13] Permission denied
```

The file is owned by `root` with mode `0600`; `sudo -n` also failed because it
requires a password. The VM was restored to `fresh` again after the attempt,
and no WinRM task ran.

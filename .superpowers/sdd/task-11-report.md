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

# jaythomasonprojects.sys_admin

Reusable Ansible Galaxy collection of opinionated system-administration
capabilities. Each role owns the packages or features it requires, its
configuration, validation, firewall access, and service state. Role-specific
guarantees, supported platforms, interfaces, invariants, and migration notes
live in the corresponding [`roles/<role>/README.md`](roles/README.md).

> [!WARNING]
> Releases before `1.0.0` may contain breaking role and variable changes. Review `CHANGELOG.rst` before upgrading.

## Setup

Local Molecule runs use the Docker driver, so make sure Docker is installed and running before you
start. The Fedora `auto_updates` scenario also relies on a privileged systemd container, so local
Docker needs to allow privileged containers and the `/sys/fs/cgroup` mount used by Molecule.

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements-test.txt
ansible-galaxy collection install -r requirements.yml -p ./.ansible/collections --force
```

## Testing

Run all scenarios:

```bash
. .venv/bin/activate
ansible-lint .
yamllint .
ANSIBLE_CONFIG=ansible.cfg molecule test --all
```

Scenario names are the directories under `extensions/molecule/`. To run or iterate on one:

```bash
ANSIBLE_CONFIG=ansible.cfg molecule test -s <scenario>
ANSIBLE_CONFIG=ansible.cfg molecule converge -s <scenario>
ANSIBLE_CONFIG=ansible.cfg molecule verify -s <scenario>
ANSIBLE_CONFIG=ansible.cfg molecule destroy -s <scenario>
```

### Windows role integration test

Docker Molecule scenarios cannot execute Windows tasks. Test Windows roles on
Proxmox VM `101` (`192.168.41.103`) instead. Restore the `fresh` snapshot
before and after each run:

```bash
ssh root@proxmox02 'qm rollback 101 fresh --start 1'
```

The fresh image accepts WinRM through the `Admin` bootstrap account with password
`Yocker95`. Use it only to establish the initial connection and run the user
configuration, which rotates the account to the password from Ansible Vault. A
WinRM task following that rotation can fail because its connection still has the
bootstrap password; reconnect with the vaulted credentials before continuing.

Install the local collection artefact in `AnsiblePlaybooks`, run the R&D
Windows share tag against `scanner2-pc` with
`ansible_host=192.168.41.103`, then confirm the configured user's persisted
`R:` drive entry under `HKU\<user-SID>\Network\R` points to
`\\192.168.40.1\RnD`. Restore `fresh` once verification finishes.

## Publish

```bash
. .venv/bin/activate
ansible-galaxy collection build --force --output-path dist
ansible-galaxy collection publish dist/jaythomasonprojects-sys_admin-*.tar.gz \
  --token "$(tr -d '\n' < ~/.ansible/galaxy_token)"
```

To smoke-test the packaged artifact before publishing, install from `dist/` first:

```bash
ansible-galaxy collection install dist/jaythomasonprojects-sys_admin-*.tar.gz \
  -p ./.ansible/collections --force
```

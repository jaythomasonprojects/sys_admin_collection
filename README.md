# jaythomasonprojects.sys_admin

Reusable Ansible Galaxy collection. Environment-agnostic roles for system setup and configuration.

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
molecule test --all
```

Scenario names are the directories under `extensions/molecule/`. To run or iterate on one:

```bash
molecule test -s <scenario>
molecule converge -s <scenario>
molecule verify -s <scenario>
molecule destroy -s <scenario>
```

### Windows role integration test

Docker Molecule scenarios cannot execute Windows tasks. Test Windows roles on
Proxmox VM `101` (`192.168.41.103`) instead. Restore the `fresh` snapshot
before and after each run:

```bash
ssh root@proxmox02 'qm rollback 101 fresh --start 1'
```

The fresh image accepts WinRM as `Admin` with bootstrap password `Yocker95`.
Use that password only to establish the initial connection and run the user
configuration, which rotates `Admin` to the password from Ansible Vault. A
WinRM task following that rotation can fail because its connection still has
the bootstrap password; reconnect with the vaulted credentials before
continuing.

Install the local collection artefact in `AnsiblePlaybooks`, run the R&D
Windows share tag against `scanner2-pc` with
`ansible_host=192.168.41.103`, then confirm the configured user's persisted
drive entry under `HKU\<user-SID>\Network\Z` points to
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

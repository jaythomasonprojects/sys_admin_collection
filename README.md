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

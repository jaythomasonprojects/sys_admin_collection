# jaythomasonprojects.sys_admin

Reusable Ansible Galaxy collection. Environment-agnostic roles for system setup and configuration.

## Setup

Local Molecule runs use the Docker driver, so make sure Docker is installed and
running before you start. The Fedora `auto_updates` scenario also relies on a
privileged systemd container, so local Docker needs to allow privileged
containers and the `/sys/fs/cgroup` mount used by Molecule.

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements-test.txt
ansible-galaxy collection install -r requirements.yml -p ./.ansible/collections --force
```

This installs the Python tooling used for local validation, including Ansible, Molecule, the Docker driver, and the linters used by this repository.

## Molecule workflow

Run Molecule commands from the repository root with the virtual environment activated:

```bash
. .venv/bin/activate
```

A full scenario run uses:

```bash
molecule test -s create_user
molecule test -s config_git
molecule test -s config_ssh
molecule test -s config_desktop
molecule test -s install_app
molecule test -s auto_updates
molecule test -s mount_network_share
molecule test -s workstation_hardening
molecule test -s time_sync
```

`molecule test` runs the complete scenario lifecycle:

1. install dependencies
2. create the test instance
3. run `prepare`
4. run `converge`
5. check idempotence
6. run `verify`
7. run `cleanup`
8. destroy the instance

Useful commands while developing a scenario:

```bash
molecule converge -s create_user
molecule converge -s config_git
molecule converge -s config_ssh
molecule converge -s config_desktop
molecule converge -s install_app
molecule converge -s auto_updates
molecule converge -s mount_network_share
molecule converge -s workstation_hardening
molecule converge -s time_sync
molecule verify -s create_user
molecule verify -s config_git
molecule verify -s config_ssh
molecule verify -s config_desktop
molecule verify -s install_app
molecule verify -s auto_updates
molecule verify -s mount_network_share
molecule verify -s workstation_hardening
molecule verify -s time_sync
molecule destroy -s create_user
molecule destroy -s config_git
molecule destroy -s config_ssh
molecule destroy -s config_desktop
molecule destroy -s install_app
molecule destroy -s auto_updates
molecule destroy -s mount_network_share
molecule destroy -s workstation_hardening
molecule destroy -s time_sync
```

Use these to iterate more quickly when you do not need the full `test` sequence every time.

## Build and validate

For day-to-day development, validate directly from the checked-out source:

```bash
. .venv/bin/activate
ansible-lint .
yamllint .
molecule test -s create_user
molecule test -s config_git
molecule test -s config_ssh
molecule test -s config_desktop
molecule test -s install_app
molecule test -s auto_updates
molecule test -s mount_network_share
molecule test -s workstation_hardening
molecule test -s time_sync
```

If you also want to smoke-test the packaged collection artifact, build into `dist/` and install from there:

```bash
. .venv/bin/activate
mkdir -p dist
rm -f dist/*.tar.gz
ansible-galaxy collection build --force --output-path dist
ansible-galaxy collection install dist/jaythomasonprojects-sys_admin-*.tar.gz \
  -p ./.ansible/collections --force
```

## Publish

```bash
. .venv/bin/activate
mkdir -p dist
rm -f dist/*.tar.gz
ansible-galaxy collection build --force --output-path dist
ansible-galaxy collection publish dist/jaythomasonprojects-sys_admin-*.tar.gz \
  --token "$(tr -d '\n' < ~/.ansible/galaxy_token)"
```

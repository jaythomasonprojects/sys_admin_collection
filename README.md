# jaythomason.infra_management

This directory is the standalone `jaythomason.infra_management` Ansible collection scaffold.

## Current scope

- Collection metadata for `ansible-galaxy collection build`
- Runtime compatibility metadata
- Extracted `create_users`, `config_git`, `config_ssh`, `install_apps`, and `update_apps` roles under `roles/`
- Dependency metadata for installed-collection consumption
- Collection-local lint and Molecule scaffolding under `extensions/molecule/`

Consumer playbooks in this repository now reference these extracted roles by FQCN.
During the transition to a standalone published collection, use
`./scripts/bootstrap_ansible_content.sh` from the repository root to build and
install the collection into the repo-scoped Ansible paths.

## Build

```bash
./scripts/bootstrap_ansible_content.sh
```

## Validate

These commands assume the repository virtualenv is active so `ansible-lint`,
`molecule`, and the Ansible CLI tools resolve from `.venv/bin`.

```bash
source ../.venv/bin/activate
cd infra_management
pip install -r requirements-test.txt
ansible-galaxy collection install -r requirements.yml -p ./.ansible/collections
ansible-lint .
yamllint .
molecule test -s create_users
```

`config_git` is extracted and linted, but its Molecule scenario is currently
deferred under `extensions/molecule/config_git/README.md` until the collection
has a more reliable package-manager test image.

`config_ssh` keeps an explicit placeholder only under
`extensions/molecule/config_ssh/`. Its handler and `sshd -t` validation need a
container image with a reliable `sshd` and service baseline before a scenario
can be enabled without flakiness.

`install_apps` and `update_apps` are extracted and linted, but their Molecule
scenarios are intentionally deferred until they have a stable package-manager
test baseline. Do not expect `molecule test -s install_apps` or
`molecule test -s update_apps` to work yet.

## Publish path

The current transition flow is:

1. develop roles in `infra_management/`
2. build and install the collection locally with `./scripts/bootstrap_ansible_content.sh`
3. consume the installed collection from this repo via FQCNs

When the collection is ready to split out:

1. move `infra_management/` into its own repository
2. keep the same `jaythomason.infra_management` collection identity
3. tag releases there
4. replace the local bootstrap/install flow with Ansible Galaxy consumption

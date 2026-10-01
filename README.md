# jaythomasonprojects.sys_admin

An Ansible Galaxy collection of system-administration roles for managed
workstations. Roles manage accounts, applications, SSH, updates, and desktop
policies. Ubuntu and Windows are the primary environment. Several roles also
support Fedora and Debian. Check each role's supported platforms
before using it.

> [!CAUTION]
> **Do not use this collection in production or depend on its interfaces before
> `1.0.0`.** Pre-1.0 releases may change roles, variables, or behaviour without
> compatibility aliases.

## Install the collection

Use Ansible with ansible-core 2.18 or later:

```bash
ansible-galaxy collection install jaythomasonprojects.sys_admin
```

Galaxy installs the latest published release, which may differ from the version
in this checkout's `galaxy.yml`. Consult the documentation for the version you
install. To test unreleased source, use the local build and installation steps
in the [Molecule guide](extensions/molecule/README.md#run-your-first-linux-test).

## Use a role

This example installs `jq` on hosts in your inventory's `linux_workstations`
group. The role owns package installation and privilege escalation:

```yaml
---
- name: Install workstation applications
  hosts: linux_workstations
  vars:
    install_app_packages:
      - 'jq'
  roles:
    - role: 'jaythomasonprojects.sys_admin.install_app'
```

Save the play as `applications.yml` and run it against your own inventory:

```bash
ansible-playbook -i inventory.yml applications.yml
```

Use fully qualified role names. Put environment-specific policy in the consuming
playbook repository, normally in `group_vars`. Keep sensitive values in Ansible
Vault and reference their `vault_` variables from normal group variables.
The collection does not ship your standard account names, packages, or shares.

## Find the reference

- [Role documentation](roles/README.md) covers supported hosts, inputs,
  prerequisites, ownership, disable behaviour, and migration notes.
- [CHANGELOG.rst](CHANGELOG.rst) records release changes. Review it and the
  affected role's migration notes before upgrading. The unreleased `0.10.0`
  changes Windows authorised keys, SMB credential-file options, and Debian
  package inputs. SMB authentication remains per-share, with fixed Linux paths
  and permissions. Move any interim host-level credential mapping into its shares.
- [Molecule guide](extensions/molecule/README.md) explains testing from the
  lifecycle through Linux and Windows setup, commands, and recovery.
- [Contributor instructions](AGENTS.md) record coding and versioning rules.

Before publishing, complete the Molecule guide's
[release gate](extensions/molecule/README.md#release-gate). It includes lint and
every Linux and Windows scenario. Publish only the archive that passed it.

# Molecule harness guide

`extensions/molecule/create_user/` is the reference harness for this
collection.

## Shared pattern

- `extensions/molecule/config.yml` holds the shared dependency, provisioner,
  verifier, test sequence, and shared state for every scenario in this
  collection.
- Keep each scenario's `molecule.yml` limited to scenario-specific runtime
  details such as the driver, image, and any scenario-only overrides.
- Put shared explanation here or in the top-level `README.md` instead of adding
  repetitive per-scenario docs.

## Supported coverage today

- `create_user` uses the shared Ubuntu container harness directly.
- `config_git` extends that same base image with `git` at image-build time so
  `community.general.git_config` can be verified without runtime package
  installs.
- `config_desktop` verifies rendered GDM, LightDM, and `/etc/environment`
  changes while keeping service restarts disabled for Docker.
- `install_app` uses shared Ubuntu and Fedora container platforms to verify the
  native package-install paths with a small fixture package and local `.deb`
  fixtures. Flatpak coverage remains deferred until a deterministic
  Flatpak-capable image is available.
- `auto_updates` uses the shared Ubuntu container harness plus a
  systemd-capable Fedora container to verify rendered APT configuration and the
  DNF automatic-update path.
- `mount_network_share` verifies credential file handling, directory creation,
  and `/etc/fstab` rendering without attempting a real CIFS mount.
- `workstation_hardening` verifies rendered blacklist policy while keeping runtime
  service and module changes disabled for Docker compatibility.
- `time_sync` verifies rendered `ntpsec` configuration for a caller-provided NTP
  server without requiring live NTP reachability.
- `config_ssh` extends the base image with OpenSSH server support so Molecule
  can verify drop-in rendering, cloud-init cleanup, `sshd -t`, and
  distro-appropriate SSH service restarts.
- `config_print_services` uses a systemd-capable Fedora container with dummy
  printer discovery units to verify no-op defaults and opt-in stop or disable
  behaviour without requiring real CUPS or Avahi packages.

## What the reference harness proves

The `create_user` scenario is the baseline example for roles that can be
validated in a lightweight Docker container:

- repo-local tooling from `.venv`
- Docker driver
- converge + idempotence + verify flow
- explicit prepare and cleanup playbooks
- verify assertions that inspect the runtime state directly

## Runtime assumptions for future scenarios

Future scenarios should satisfy these assumptions before they copy the
`create_user` pattern:

1. The image is stable under Molecule's Docker driver and can stay alive with a
   long-running command such as `sleep infinity`.
2. The image already includes the runtime Ansible needs for remote execution
   (for example Python and a usable privilege-escalation path).
3. The role can be validated without a full init system unless the scenario
   intentionally introduces one.
4. Any role that depends on package-manager behavior, service management, or
   SSHD layout needs an image that makes those behaviors deterministic; if not,
   keep the scenario deferred and document the missing capability in shared
   docs.
5. If a lightweight role only needs one missing binary (for example `git` for
   `community.general.git_config`), prefer a scenario-local Dockerfile that
   extends the stable base image at image-build time instead of installing
   packages during `prepare`.

## Deferred coverage gaps

### `install_app` Flatpak coverage

The first supported `install_app` scenario intentionally proves only native OS
package installation. Promote Flatpak coverage only after the harness has all of
the following:

1. an image with a working `flatpak` binary under Docker
2. a predictable Flatpak remote that can be seeded during the scenario
3. fixture refs that are stable enough to verify without relying on flaky
   external state

## Release gate

A published `jaythomasonprojects.sys_admin` tag should only claim the supported
scenarios listed in this document.

Before publishing:

1. run `ansible-lint .`
2. run `yamllint .`
3. run `ansible-galaxy collection build --force`
4. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s create_user`
5. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s config_git`
6. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s config_ssh`
7. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s config_desktop`
8. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s install_app`
9. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s auto_updates`
10. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share`
11. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s workstation_hardening`
12. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s time_sync`
13. run `ANSIBLE_CONFIG=ansible.cfg molecule test -s config_print_services`

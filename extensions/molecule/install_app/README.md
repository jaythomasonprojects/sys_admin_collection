# install_app Molecule scenario

This scenario verifies native package installation and npm prerequisite
ownership for `jaythomasonprojects.sys_admin.install_app` on Ubuntu and Fedora.
It also verifies that Debian installer definitions are validated on APT hosts
and skipped without access on Fedora.

Flatpak prerequisite and application installation remain deferred until the
shared harness has a deterministic Flatpak runtime and remote fixture.

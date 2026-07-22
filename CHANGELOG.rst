jaythomasonprojects.sys_admin changelog
=======================================

0.4.4
-----

- Made ``config_print_services`` disable printer discovery services whenever
  the role is invoked.
- Defined Windows ``mount_network_share`` drive-letter mount points as bare
  letters, such as ``Z``.

0.4.3
-----

- Corrected Windows UNC rendering so mapped drives use valid
  ``\\server\share`` paths.
- Restored initial SMB authentication for Windows mapped drives while
  retaining per-share interactive ``runas`` impersonation.
- Left Windows mapped-drive task failures visible for connection debugging.

0.4.2
-----

- Fixed ``mount_network_share`` Windows mapped-drive impersonation so each
  share's configured credentials override inventory-level become credentials.

0.4.1
-----

- Removed unnecessary ``ssh-keygen -A`` host key generation task from
  ``config_ssh`` on Windows; ``sshd`` auto-generates host keys on first
  start (confirmed against Microsoft Learn documentation and verified
  on a clean Windows 10 VM).
- Fixed ``config_ssh`` OpenSSH capability install task to use a Jinja2
  test (``is search``) for ``changed_when`` instead of a string
  comparison, which ansible-core 2.18+ rejects as non-boolean.
- Standardised ``auto_updates`` to use ``ansible_facts.pkg_mgr is
  defined`` guards (matching ``install_app``) so Linux tasks skip
  cleanly on Windows hosts where ``pkg_mgr`` is undefined.

0.4.0
-----

- Added Windows host support to ``install_app`` (Chocolatey),
  ``create_user`` (``win_user`` + SSH key management),
  ``mount_network_share`` (``win_mapped_drive``),
  ``auto_updates`` (``win_updates``), and ``config_ssh``
  (OpenSSH Server, firewall rule, ``sshd_config``).
- Added ``config_power`` and ``config_firewall`` roles for
  Windows-only checklist items.
- Added OS-family guards to ``config_desktop``,
  ``workstation_hardening``, ``time_sync``, and
  ``config_print_services`` so they skip cleanly on Windows hosts.
- Added ``ansible.windows``, ``chocolatey.chocolatey``, and
  ``community.windows`` collection dependencies.

0.3.0
-----

- Added ``config_print_services`` role to manage printer discovery
  services (e.g. cups-browsed, avahi-daemon) on systemd hosts, with
  Molecule coverage for Fedora using dummy service fixtures.

0.2.0
-----

- Added workstation-focused ``config_desktop``, ``mount_network_share``,
  ``time_sync``, and ``workstation_hardening`` roles with Molecule coverage.
- Simplified ``install_app`` package-manager dispatch and Debian package task
  naming.
- Removed the superseded ``update_apps`` role.
- Renamed ``mount_network_shares`` to ``mount_network_share``.
- Simplified ``config_desktop`` inputs to
  ``config_desktop_gdm_user``, ``config_desktop_lightdm_user``, and
  ``config_desktop_qt5ct``.

0.1.0
-----

- First Galaxy-facing release under the ``jaythomasonprojects.sys_admin`` identity.
- Initial collection scaffold
- Extracted ``create_users``, ``config_git``, ``config_ssh``, and ``install_app``
- Added collection-focused linting and Molecule scaffolding
- Documented that ``create_users`` and ``config_git`` are the supported
  Molecule scenarios today, while ``config_ssh`` and ``install_app`` remain
  extracted but deferred

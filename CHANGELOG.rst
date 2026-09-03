jaythomasonprojects.sys_admin changelog
=======================================

0.9.0
-----

- Added the Ubuntu GNOME ``desktop_layout`` role.
- Added Ubuntu 22.04 and 24.04 support to ``power_policy``.
- Removed ``power_policy_disable_sleep`` in favour of independent AC suspend
  and screen-timeout controls, and intentionally stopped managing DC standby.
- Removed the ``git`` role; dotfile management now owns Git configuration.
- Added Fedora support where the Linux capability has a meaningful shared
  implementation, with Fedora 44 Molecule coverage.
- Added Ubuntu 26.04 Molecule coverage for the GNOME capabilities.
- Replaced ``ntpsec`` with chrony for time synchronisation on Debian, Ubuntu,
  and Fedora.
- Added DNF5 automatic-update support using ``dnf5-plugin-automatic`` and
  ``dnf5-automatic.timer``.
- Renamed the collection-owned APT policy to
  ``52sys-admin-auto-updates`` and removes the former
  ``52jtprojects-unattended-upgrades`` path during convergence.

0.8.0
-----

- Renamed eight roles after the outcome they deliver rather than the mechanism
  they use: ``config_systemd_units`` to ``disable_printer_discovery``,
  ``blacklist_kernel_modules`` to ``disable_usb_storage``, ``config_desktop`` to
  ``auto_login``, ``config_firewall`` to ``allow_ping``, ``config_power`` to
  ``power_policy``, ``config_ssh`` to ``ssh``, ``config_git`` to ``git``, and
  ``create_user`` to ``local_accounts``. Every public variable takes the new
  role prefix. There are no compatibility aliases.
- Removed ``config_systemd_units_custom_services``. The role managed arbitrary
  unit files through an interface that only restated ``systemd_service``
  parameters. A role that needs a unit now ships that unit itself.
- Removed ``config_desktop_qt5ct``. The Qt platform theme is no longer managed.
- ``allow_ping_enabled`` now converges: setting it to ``false`` removes both
  managed ICMP rules instead of leaving them in place.
- Renamed the ``config_ssh`` variables into ``ssh_server_*`` and ``ssh_client_*``
  families matching the task files, and removed ``config_ssh_service_name`` from
  the public interface. The service name comes from ``vars/`` instead of runtime
  detection.
- ``local_accounts`` no longer requires ``password`` on every account, so
  key-only accounts need no placeholder value.
- Added ``meta/argument_specs.yml`` to every role. Option types, required
  fields, and choices are validated before the first task runs. Inline type
  assertions are removed; platform gates and cross-field rules remain.
- Added ``<role>_enabled`` to every policy role. It expresses whether a host
  should have the policy, so a fleet-wide play can vary policy by group. Each
  role README states whether disabling converges or skips.
- Moved distribution data for ``git``, ``ssh``, and ``time_sync`` into ``vars/``
  loaded by first-found lookup. Supported distributions are unchanged; the
  structure prepares for future additions.

0.7.1
-----

- Prevented user account passwords and SSH keys appearing in task output when
  account or authorised-key tasks are skipped or fail.

0.7.0
-----

- Renamed ``workstation_hardening`` to ``blacklist_kernel_modules``. Removed
  ``workstation_hardening_blacklisted_modules`` and
  ``workstation_hardening_apply_runtime_changes``; added
  ``blacklist_kernel_modules_disable_usb_storage``. The replacement owns a
  fixed persistent USB-storage policy for ``usb-storage`` and ``uas`` and
  unloads both modules when enabled.
- Replaced arbitrary existing-unit ``config_systemd_units`` policy with
  ``config_systemd_units_disable_printer_services`` and
  ``config_systemd_units_custom_services``. The role owns fixed printer-service
  disabling and explicitly declared, role-marked custom unit files; it does not
  manage arbitrary vendor units.
- Replaced ``config_firewall_enable_icmp_v4`` and
  ``config_firewall_enable_icmp_v6`` with ``config_firewall_allow_ping``. When
  enabled, ``config_firewall`` owns both Windows ping rules with their required
  protocols and ICMP types.
- Removed ``time_sync_manage_package`` and ``time_sync_manage_service``.
  ``time_sync`` now owns the Debian/Ubuntu ``ntpsec`` package, configuration,
  and enabled service.
- Removed ``mount_network_share_manage_packages``. Linux
  ``mount_network_share`` now always owns its ``cifs-utils`` prerequisite.
- Removed the unprefixed ``sshd_permit_root_login`` compatibility fallback.
  ``config_ssh_sshd_permit_root_login`` now defaults directly to ``'no'``.
- Moved Windows authorised-key contents and ACL ownership from ``config_ssh``
  to ``create_user``. ``config_ssh`` owns complete server reachability:
  OpenSSH Server, validated configuration, the exact firewall rule, running
  automatic service, and the PowerShell default shell.
- Made ``config_git`` own the Debian/Ubuntu ``git`` package. ``install_app``
  now owns native npm and Flatpak prerequisites when those channels are
  requested; ``auto_updates`` retains persistent Linux policy and immediate
  Windows update installation.
- All roles now use a root platform validator and platform-specific task tree;
  unsupported platforms fail explicitly instead of silently skipping policy.

0.6.0
-----

- Added ``config_systemd_units`` to manage existing systemd units and inline
  custom unit files through host-provided policy.
- Added global npm application installation to ``install_app`` through a
  host-provided package-name list, with explicit native npm and executable
  dependency validation.
- Removed the superseded ``config_print_services`` role and
  ``workstation_hardening_services`` interface. Printer and hardening service
  policies now use ``config_systemd_units``.

0.5.0
-----

- Delegated native Linux package installation in ``install_app`` to Ansible's
  detected package manager while retaining APT cache refreshes and specialised
  Debian package handling.
- Installed requested Flatpak applications in one operation and failed clearly
  when Flatpak was unavailable instead of completing with applications missing.

0.4.6
-----

- Normalized Linux and Windows task dispatch in the ``create_user``,
  ``config_ssh``, ``install_app``, and ``mount_network_share`` roles.
- Prevented Windows ``install_app`` runs from entering Linux-only Debian and
  Flatpak task paths.
- Applied Windows SSH keys before rotating managed account passwords so the
  active WinRM connection remains valid through key configuration.

0.4.5
-----

- Persisted credentialed Windows ``mount_network_share`` SMB connections in
  the configured user's Credential Manager, so mapped drives continue working
  after that local Windows password changes.
- Added per-user Windows ``password_never_expires`` support to ``create_user``.

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

# auto_login

Configures automatic login for detected GDM and LightDM display managers on
Linux hosts.

## Guarantee and ownership

This role supports Linux hosts only. It fails explicitly with
`auto_login supports Linux hosts only.` on every other platform.

It configures GDM only when `/etc/gdm3/custom.conf` exists on Debian-family
hosts or `/etc/gdm/custom.conf` exists on Fedora hosts, and LightDM only when
`/etc/lightdm/lightdm.conf.d` exists. It owns the exact GDM automatic login and
Wayland entries it manages, and its marked LightDM automatic login block. It
does not install, select, or otherwise manage display-manager or desktop
software. Installing a display manager remains a precondition.

Setting `auto_login_gdm_user` also disables Wayland by setting
`WaylandEnable = false`. GDM automatic login requires Wayland to be disabled in
this environment.

## Implementation

- `tasks/main.yml` validates the platform and dispatches to Linux tasks.
- `tasks/linux/main.yml` detects GDM and LightDM before applying their
  automatic-login configuration, using distribution data for the GDM path.
- `gdm.yml` configures GDM automatic login and its required Wayland setting.
- `lightdm.yml` manages the LightDM automatic-login block.

## Interface

- `auto_login_gdm_user`: configure GDM automatic login for this user when
  `/etc/gdm3/custom.conf` exists on Debian-family hosts or
  `/etc/gdm/custom.conf` exists on Fedora hosts. The default is `''`.
- `auto_login_lightdm_user`: configure LightDM automatic login for this user
  when `/etc/lightdm/lightdm.conf.d` exists. The default is `''`.

There is no separate enabled flag. Each user variable is its display manager's
converging switch.

## Enable behaviour

Set either user variable to an account name to configure automatic login for
that display manager. Set it to `''` to remove that display manager's automatic
login configuration. Setting `auto_login_gdm_user` to `''` disables GDM
automatic login and removes its managed login-user entry. Setting
`auto_login_lightdm_user` to `''` removes the managed LightDM automatic-login
block.

## Invariants

- GDM automatic login retains the Wayland-disable dependency while a GDM user
  is configured.
- LightDM configuration is confined to the role-managed block in
  `/etc/lightdm/lightdm.conf.d/autologin.conf`.

## Migration

This role replaces `config_desktop`. Rename
`config_desktop_gdm_user` to `auto_login_gdm_user` and
`config_desktop_lightdm_user` to `auto_login_lightdm_user`.
`config_desktop_qt5ct` is removed with no replacement: this role no longer
manages the Qt platform theme.

# config_desktop

Configures detected desktop display-manager autologin and environment policy on
Linux hosts.

## Guarantee and ownership

This role supports Linux hosts only. It fails explicitly with
`config_desktop supports Linux hosts only.` on every other platform.

It configures GDM only when `/etc/gdm3/custom.conf` exists and LightDM only
when `/etc/lightdm/lightdm.conf.d` exists. It owns the exact GDM autologin and
Wayland entries it manages, its marked LightDM autologin block, and the
`QT_QPA_PLATFORMTHEME=qt5ct` entry in `/etc/environment`. It does not install,
select, or otherwise manage desktop software.

## Implementation

- `tasks/main.yml` validates the platform and dispatches to Linux tasks.
- `tasks/linux/main.yml` detects GDM and LightDM before applying policy, then
  applies the optional Qt platform theme policy.
- The independent `gdm.yml`, `lightdm.yml`, and `qt5ct.yml` task files keep the
  unrelated display-manager and environment policies separately selectable.

## Variables

- `config_desktop_gdm_user`: configure GDM autologin for this user when
  `/etc/gdm3/custom.conf` exists. Set it to an empty string to disable the
  managed GDM autologin entry.
- `config_desktop_lightdm_user`: configure LightDM autologin for this user when
  `/etc/lightdm/lightdm.conf.d` exists. Set it to an empty string to remove the
  managed LightDM autologin block.
- `config_desktop_qt5ct`: set `QT_QPA_PLATFORMTHEME=qt5ct` in `/etc/environment`.

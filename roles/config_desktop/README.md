# config_desktop

Minimal desktop configuration role based on the original workstation playbooks.

## Variables

- `config_desktop_gdm_user`: configure GDM autologin for this user when
  `/etc/gdm3/custom.conf` exists. Set it to an empty string to disable the
  managed GDM autologin entry.
- `config_desktop_lightdm_user`: configure LightDM autologin for this user when
  `/etc/lightdm/lightdm.conf.d` exists. Set it to an empty string to remove the
  managed LightDM autologin block.
- `config_desktop_qt5ct`: set `QT_QPA_PLATFORMTHEME=qt5ct` in `/etc/environment`.

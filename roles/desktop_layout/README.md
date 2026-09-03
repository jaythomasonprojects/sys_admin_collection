# desktop_layout

Configures a persistent Ubuntu GNOME dock layout for one named local user.

## Guarantee and ownership

The role owns the dock position and maximum icon size, plus GNOME favourites when
`desktop_layout_gnome_dock_favourites` is non-empty. It writes:

- `/org/gnome/shell/extensions/dash-to-dock/dock-position`
- `/org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size`
- `/org/gnome/shell/favorite-apps` for a non-empty favourites list

## Supported platforms

Ubuntu 22.04, 24.04, and 26.04 with existing GNOME Shell and Ubuntu Dock
schemas. Fedora is explicitly unsupported, as Ubuntu Dock is an Ubuntu-specific
host precondition. Other operating systems and releases fail with
`desktop_layout supports Ubuntu 22.04, 24.04, and 26.04 hosts only.`

## Interface

```yaml
desktop_layout_enabled: true
desktop_layout_gnome_dock_favourites: []
desktop_layout_gnome_dock_icon_size: 32
desktop_layout_gnome_dock_position: 'BOTTOM'
desktop_layout_user: ''
```

`desktop_layout_user` must be an existing local account with an existing home
directory. The role runs dconf as that account and sets its resolved `HOME`.

An empty favourites list is unmanaged and does not clear existing favourites.
Likewise, `desktop_layout_enabled: false` skips the role and preserves prior
values.

## Implementation and requirements

`tasks/main.yml` validates the supported Ubuntu releases, then dispatches
enabled hosts to the Ubuntu implementation. The role owns its `dbus`, `dconf-cli`, `libglib2.0-bin`,
`python3-gi`, and `python3-psutil` runtime packages. GNOME Shell and Ubuntu Dock
schemas are host preconditions, not role-managed dependencies.

The role does not install GNOME, Ubuntu Dock, applications, or launcher targets.
It does not manage wallpaper, themes, shortcuts, fonts, extensions, power policy,
or arbitrary dconf keys.

# power_policy

Configures Windows power plans and Ubuntu or Fedora GNOME suspend and display
policy. It supports Windows, Ubuntu 22.04, 24.04, and 26.04, and Fedora.
Other hosts fail explicitly, even when the role is disabled.

## Guarantee and ownership

Windows selects the requested power plan, optionally disables hibernation, and
can set monitor and standby timeouts to never for mains and battery power.
Linux writes the configured user's GNOME AC suspend action and display idle
delay. It owns required dconf runtime packages, not GNOME installation.

Linux requires an existing `power_policy_user` and home directory. Each enabled
policy requires its GNOME schema. Settings are written as that user with the
resolved `HOME`. The role does not manage Linux battery suspend policy.

## Interface

| Variable | Default | Platform and effect |
| --- | --- | --- |
| `power_policy_enabled` | `true` | Both: apply the requested policies |
| `power_policy_disable_ac_suspend` | `true` | Linux: set mains inactivity suspend to `nothing` |
| `power_policy_disable_screen_timeout` | `false` | Linux: set display idle delay to zero |
| `power_policy_user` | `''` | Linux: existing local account whose GNOME settings are managed |
| `power_policy_disable_hibernate` | `true` | Windows: run `powercfg /hibernate off` |
| `power_policy_disable_sleep` | `true` | Windows: disable monitor and standby timeouts on AC and DC |
| `power_policy_plan` | `'balanced'` | Windows: activate this power plan; `''` leaves it unchanged |

AC means mains power; DC means battery power. Each platform ignores the other
platform's options. Windows's `power_policy_disable_sleep` controls both screen
and standby timeouts; the separate screen-timeout input is Linux-only.

## Enable behaviour and invariants

`power_policy_enabled: false` skips policy work. It does not restore a previous
power plan, timeout, or hibernation setting. An individual `disable_*: false`
also leaves that setting unmanaged rather than reversing an earlier run.

Linux owns only the declared dconf keys, not arbitrary desktop preferences.
Windows timeout enforcement reads native values and reports changes only for
timeouts it modifies. Hibernation disabling does not report a change count.

## Implementation map

- `tasks/main.yml` checks the complete supported-platform gate.
- `tasks/linux/main.yml` resolves the user, validates schemas, installs runtime
  packages, and writes dconf settings.
- `vars/Ubuntu.yml` and `vars/Fedora.yml` list Linux runtime packages.
- `tasks/windows/main.yml` selects the power plan and applies Windows policies.
- `files/Disable-PowerPolicySleep.ps1` checks and updates Windows timeouts.

## Migration

This role replaces `config_power`; old-prefix aliases are not supported.
Linux uses separate AC suspend and screen-timeout inputs rather than
`power_policy_disable_sleep`, which remains Windows-only. Linux DC standby is
not managed. Disabling a policy does not undo settings from an earlier version.

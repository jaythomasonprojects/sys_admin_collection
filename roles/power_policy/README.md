# power_policy

Configures Windows power-plan policy and Ubuntu and Fedora GNOME suspend and
display policy.

## Interface

```yaml
power_policy_disable_ac_suspend: true
power_policy_disable_hibernate: true
power_policy_disable_screen_timeout: false
power_policy_disable_sleep: true
power_policy_enabled: true
power_policy_plan: 'high performance'
power_policy_user: ''
```

False values are unmanaged: they do not reset a value from an earlier run.

## Platform ownership

On Windows, the role selects the configured power plan, disables hibernation,
and sets monitor and standby timeouts to never for both AC and DC power when
`power_policy_disable_sleep` is true.

On Ubuntu 22.04, 24.04, and 26.04, and Fedora, the role writes the named user's
GNOME AC suspend action and display idle delay. It owns dconf runtime packages,
requires an existing user home, and requires each enabled policy's GNOME schema.
GNOME and the required schemas are host preconditions, not role-managed
dependencies.
`power_policy_plan`, `power_policy_disable_hibernate`, and
`power_policy_disable_sleep` are Windows-only. `power_policy_disable_ac_suspend`
and `power_policy_disable_screen_timeout` are Linux-only.

## Enable behaviour and migration

`power_policy_enabled: false` skips policy work. Linux dconf tasks run as
`power_policy_user` with its resolved `HOME`. Unsupported hosts fail with
`power_policy supports Windows, Ubuntu 22.04, 24.04, and 26.04, and Fedora hosts only.`

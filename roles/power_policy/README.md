# power_policy

Configures the active Windows power plan and optional power-saving policies.

## Guarantee

The role applies the configured active power plan, clears monitor and standby
timeouts for both AC and DC power, and disables hibernation when each matching
policy variable is enabled.

## Ownership

This role owns the active power plan, monitor and standby sleep timeouts for
both AC and DC power, and hibernation. It does not manage any other Windows
power policy.

## Supported platforms

Windows hosts only. Other platforms fail with
`power_policy supports Windows hosts only.`

## Implementation map

- `tasks/main.yml` rejects unsupported platforms and dispatches Windows hosts.
- `tasks/windows/main.yml` applies the active plan, sleep and standby timeouts,
  and hibernation policy.

## Interface

```yaml
power_policy_disable_hibernate: true
power_policy_disable_sleep: true
power_policy_enabled: true
power_policy_plan: 'high performance'
```

- `power_policy_plan` activates the named Windows power plan. An empty string
  leaves the active plan unchanged.
- `power_policy_disable_sleep` sets monitor and standby timeouts to `0` (never)
  for both AC and DC power.
- `power_policy_disable_hibernate` runs `powercfg /hibernate off`.

## Enable behaviour

`power_policy_enabled` defaults to `true`. When `false`, the role skips all
Windows power-policy tasks rather than restoring a previous policy. Restoring
the prior plan and timeouts is not safe or unambiguous because the role cannot
know the settings that preceded its earlier run.

Setting either `power_policy_disable_sleep` or
`power_policy_disable_hibernate` to `false` also leaves that policy unmanaged;
it does not undo a setting from an earlier run.

## Invariants

- An unsupported platform always fails with the documented stable message.
- The role changes only its owned power-plan, timeout, and hibernation policy.
- Disabling the role or an individual policy does not restore prior settings.

## Requirements

Requires the `ansible.windows` and `community.windows` collections.

## Migration

`power_policy` replaces `config_power`. Rename
`config_power_power_plan` to `power_policy_plan`,
`config_power_disable_sleep` to `power_policy_disable_sleep`, and
`config_power_disable_hibernate` to `power_policy_disable_hibernate`. No
compatibility aliases are provided.

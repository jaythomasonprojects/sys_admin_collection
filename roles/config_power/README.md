# config_power

Configures the active Windows power plan and optional power-saving policies.

## Guarantee and ownership

This role supports Windows hosts only. It fails explicitly with
`config_power supports Windows hosts only.` on every other platform.

The role owns the active power plan, monitor and standby sleep timeouts for
both AC and DC power, and hibernation. It does not manage any other Windows
power policy.

## Implementation

- `tasks/main.yml` validates that the host is Windows and dispatches the role.
- `tasks/windows/main.yml` cohesively applies all owned Windows power policy:
  the active plan, sleep and standby timeouts, and hibernation.

## Variables

- `config_power_power_plan`: Windows power plan to activate. Defaults to
  `'high performance'`. An empty string leaves the active power plan unmanaged.
- `config_power_disable_sleep`: sets monitor and standby timeouts to `0`
  (never) for both AC and DC power when `true`. Defaults to `true`; `false`
  leaves those timeouts unmanaged.
- `config_power_disable_hibernate`: runs `powercfg /hibernate off` when
  `true`. Defaults to `true`; `false` leaves hibernation unmanaged.

## Non-goals

- Linux and other non-Windows platforms.
- Restoring or removing power settings when a policy variable is disabled.
- Power settings beyond the active plan, monitor and standby timeouts, and
  hibernation.

## Requirements

Requires the `ansible.windows` and `community.windows` collections.

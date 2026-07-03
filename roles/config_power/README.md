# config_power

Configure power management on Windows hosts: set the active power plan, disable sleep/standby timeouts, and disable hibernate.

## Variables

- `config_power_power_plan`: name of the Windows power plan to activate. Default: `'high performance'`. Set to an empty string to skip.
- `config_power_disable_sleep`: disable monitor and standby timeout (AC and DC). Default: `true`.
- `config_power_disable_hibernate`: run `powercfg /hibernate off`. Default: `true`.

## Requirements

Requires the `ansible.windows` and `community.windows` collections.

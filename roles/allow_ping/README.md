# allow_ping

Manages Windows inbound Internet Control Message Protocol (ICMP) echo rules.
It allows the host to answer IPv4 and IPv6 ping requests when enabled.

## Guarantee

The role converges the inbound firewall rules named `Allow ICMPv4 ping` and
`Allow ICMPv6 ping`. A disabled run removes both rules.

## Ownership

This role owns only the two named ICMP echo request rules. Firewall access for
a service belongs to that service's role. For example, `ssh` owns its inbound
rule, using `ssh_server_port` to select the port.

## Supported platforms

Windows hosts only. Other platforms fail with
`allow_ping supports Windows hosts only.`

## Interface

```yaml
allow_ping_enabled: false
```

This is the role's only public variable. Set `allow_ping_enabled: true` to opt in
to inbound IPv4 and IPv6 echo request access through the role-owned rules.

## Enable behaviour

`allow_ping_enabled` converges both owned rules. `true` creates them and
`false` (the default) removes them. Removing these rules does not block ping
traffic permitted by another firewall rule.

## Invariants

- The role owns `Allow ICMPv4 ping` and `Allow ICMPv6 ping` only.
- ICMPv4 Echo Request uses type `8`; ICMPv6 Echo Request uses type `128`.
- A disabled run removes both owned rules.

## Requirements

Requires the `community.windows` collection.

## Implementation map

- `tasks/main.yml` rejects unsupported platforms and dispatches Windows hosts.
- `tasks/windows/main.yml` creates or removes the two named ping rules.

## Migration

`allow_ping` replaces `config_firewall`. Rename
`config_firewall_allow_ping` to `allow_ping_enabled`. No compatibility aliases
are provided.

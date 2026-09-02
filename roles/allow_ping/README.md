# allow_ping

Manages the Windows inbound ICMP echo request rules. It allows the host to
answer IPv4 and IPv6 ping requests when enabled.

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

## Implementation map

- `tasks/main.yml` rejects unsupported platforms and dispatches Windows hosts.
- `tasks/windows/main.yml` creates or removes the two named ping rules.

## Interface

```yaml
allow_ping_enabled: true
```

This is the role's only public variable.

## Enable behaviour

`allow_ping_enabled` converges both owned rules. `true` creates them and
`false` removes them. This replaces the previous skip behaviour, where `false`
left rules created by an earlier run in place.

## Invariants

- The role owns `Allow ICMPv4 ping` and `Allow ICMPv6 ping` only.
- ICMPv4 Echo Request uses type `8`; ICMPv6 Echo Request uses type `128`.
- A disabled run removes both owned rules.

## Requirements

Requires the `community.windows` collection.

## Migration

`allow_ping` replaces `config_firewall`. Rename
`config_firewall_allow_ping` to `allow_ping_enabled`. No compatibility aliases
are provided.

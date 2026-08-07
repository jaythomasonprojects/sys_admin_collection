# config_firewall

Manage Windows Firewall inbound rules for ICMP ping access.

This role owns the IPv4 and IPv6 Echo Request rules named `Allow ICMPv4 ping`
and `Allow ICMPv6 ping`. It supports Windows hosts only. It does not manage
SSH access or any Linux firewall.

## Variables

- `config_firewall_allow_ping`: manage inbound ICMPv4 Echo Request (type 8)
  and ICMPv6 Echo Request (type 128) rules. Default: `true`. Set to `false`
  to leave both rules unmanaged. It does not remove rules created by an
  earlier run.

## Requirements

Requires the `community.windows` collection.

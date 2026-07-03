# config_firewall

Manage Windows Firewall inbound rules for ICMP ping access (IPv4 and IPv6).

## Variables

- `config_firewall_enable_icmp_v4`: allow inbound ICMPv4 Echo Request (type 8). Default: `true`.
- `config_firewall_enable_icmp_v6`: allow inbound ICMPv6 Echo Request (type 128). Default: `true`.

## Requirements

Requires the `community.windows` collection.

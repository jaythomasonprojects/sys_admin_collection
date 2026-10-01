# allow_ping Windows scenario

This scenario checks the role-owned IPv4 and IPv6 echo rules, foreign-rule preservation,
disabled removal, and enabled restoration. The normal convergence pass must
be idempotent. `prepare.yml` seeds the rules; `verify.yml` checks the
transitions.

The clone uses SSH. Follow the [Molecule guide](../../README.md#set-up-windows-testing) and use
selector `allow_ping/windows`.

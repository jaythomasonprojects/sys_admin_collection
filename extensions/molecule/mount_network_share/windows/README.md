# mount_network_share Windows scenario

This scenario checks a usable mapped drive under the configured user's SID
and profile, disabled skipping, and a consequential mapping failure. Repeat
acceptance checks function rather than zero reported changes. Native password
refresh remains visible. Credentials are declared on each share. The fixture
uses one account and server; it does not test multiple Windows account contexts.

`prepare.yml` creates the test account and local share. The synthetic password
is set in `molecule.yml`. The scenario does not scan Ansible output for the
password; the role's `no_log` settings are not tested at runtime.

The clone uses SSH. Follow the [Molecule guide](../../README.md#set-up-windows-testing) and use
selector `mount_network_share/windows`.

# ssh Molecule scenario

This scenario verifies native SSH policy and client configuration on Debian,
Ubuntu, and Fedora systemd containers. It checks service activity, effective
policy, and ordinary idempotence. The foreign cloud-init drop-in stays present
but cannot override the owned complete server configuration. Invalid
candidates must preserve the installed policy and running service. Valid
transitions must update both rendered policy and native effective values.

Use selector `ssh/linux` with the
[shared test procedure](../../README.md#run-the-affected-scenario).

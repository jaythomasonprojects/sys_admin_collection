# time_sync Linux scenario

This scenario uses disposable Ubuntu 24.04/26.04 Proxmox VM clones. Native
chrony systemd conditions remain intact. An independent guest kernel lets
Ubuntu 26.04 exercise its packaged service without a container override.

This scenario checks chrony is installed, enabled, and active, with one
configured upstream pool. The configuration must remain root-owned with mode
`0644`. It checks ordinary idempotence and unsupported-platform/release rejection.

It checks service and policy state, not successful synchronisation with the
synthetic upstream. Use selector `time_sync/linux` with the
[shared test procedure](../../README.md).

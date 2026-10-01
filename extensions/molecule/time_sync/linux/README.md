# time_sync Linux scenario

This scenario checks chrony is installed, enabled, and active, with one
configured upstream pool. The configuration must remain root-owned with mode
`0644`. It checks ordinary idempotence and unsupported-platform rejection.

It checks service and policy state, not successful synchronisation with the
synthetic upstream. Use selector `time_sync/linux` with the
[shared test procedure](../../README.md).

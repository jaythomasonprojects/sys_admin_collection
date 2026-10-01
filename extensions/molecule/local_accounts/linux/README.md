# local_accounts Linux scenario

This scenario checks the managed account's comment, home, shell, authorised
keys, and ownership. The SSH directory must be mode `0700`, and its key file
must be mode `0600`. It checks ordinary idempotence and explicit
unsupported-platform rejection.

Use selector `local_accounts/linux` with the [shared test procedure](../../README.md).

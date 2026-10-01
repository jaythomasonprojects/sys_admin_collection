# local_accounts Windows scenario

This scenario checks resolved SIDs and native profiles,
per-user authorised keys, and protected ACLs. Real SSH logins must select the
correct identity and reject cross-user keys and keys present only in the
shared administrator file. It checks an alternate native profile, key
replacement, explicit clearing, and ordinary idempotence.

`verify.yml` owns acceptance, including the key replacement and clearing
transitions. `files/Inspect-PerUserKeys.ps1` inspects keys.
Management stays on independent WinRM while SSH files change. Follow the
[Molecule guide](../../README.md#set-up-windows-testing) and use selector
`local_accounts/windows`.

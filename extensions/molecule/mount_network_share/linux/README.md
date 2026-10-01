# mount_network_share Linux scenario

This scenario checks two CIFS declarations use different per-share credentials,
with root ownership, root group, mode `0600`, and matching fstab references.
Removal preserves the remaining share and both credential files. It checks
ordinary idempotence, filename escape and duplicate rejection, missing enabled
authentication, disabled and empty inputs, and retained legacy files and metadata.

The container checks persisted mount policy, not a live SMB server.
`verify.yml` includes `verify_rejected_declaration.yml` once for each rejected
declaration.
Use selector `mount_network_share/linux` with the
[shared test procedure](../../README.md).

# auto_login Linux scenario

This scenario checks GDM and LightDM configuration, distribution-specific GDM
paths, and ordinary idempotence. Empty user inputs must remove managed login
configuration. An unrelated Debian GDM file must remain unchanged.

It verifies persisted configuration, not a graphical login session.
Use selector `auto_login/linux` with the [shared test procedure](../../README.md).

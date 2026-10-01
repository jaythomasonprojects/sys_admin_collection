# power_policy Linux scenario

This scenario checks independent AC suspend and screen-timeout settings in
the configured user's persisted GNOME dconf state. It checks ordinary
idempotence, disabled skipping, and platform rejection on the configured
Ubuntu and Fedora containers.

The containers do not run GNOME Shell or demonstrate physical suspend.
Use selector `power_policy/linux` with the [shared test procedure](../../README.md).

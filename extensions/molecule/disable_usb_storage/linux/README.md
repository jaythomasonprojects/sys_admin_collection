# disable_usb_storage Linux scenario

This scenario checks the owned modprobe policy and native dry-run resolution
for USB storage. Disabled hosts must lose the owned policy without installing
its prerequisite. It checks ordinary idempotence and the exact Darwin
rejection message.

It does not attach physical USB devices or unload host kernel modules.
Use selector `disable_usb_storage/linux` with the
[shared test procedure](../../README.md).

# disable_usb_storage

Disables USB mass storage on Linux hosts. When enabled, the role persistently
prevents `usb-storage` and `uas` from loading, then unloads both runtime
modules.

## Guarantee

The role manages the USB mass-storage modprobe policy and unloads the fixed
module list when that policy is enabled. USB controllers and input devices are
unaffected.

## Ownership

This role owns only `/etc/modprobe.d/disable-usb-storage.conf`.

## Supported platforms

Linux hosts only. Other platforms fail with
`disable_usb_storage supports Linux hosts only.`

## Implementation

- `tasks/main.yml` rejects unsupported platforms and dispatches Linux hosts.
- `tasks/linux/main.yml` creates or removes the policy file and unloads the
  `usb_storage` and `uas` modules when enabled.

## Interface

```yaml
disable_usb_storage_enabled: true
```

This is the role's only public variable.

## Enable behaviour

`disable_usb_storage_enabled` converges the owned policy file. A `false` run
removes `/etc/modprobe.d/disable-usb-storage.conf` and does not load modules.
Modules already unloaded by an earlier enabled run return only after a reboot.

## Invariants

- Runtime unloading is mandatory while the policy is enabled.
- The managed file is the role's only persistent artefact.
- Disabling the policy removes the managed file and does not load modules.

## Migration

`disable_usb_storage` replaces `blacklist_kernel_modules`. Rename
`blacklist_kernel_modules_disable_usb_storage` to
`disable_usb_storage_enabled`.

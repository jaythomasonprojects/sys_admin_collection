# disable_usb_storage

Disables USB mass storage on Linux hosts. When enabled, the role persistently
prevents `usb-storage` and `uas` from loading, then unloads both runtime
modules.

## Guarantee

The role installs `kmod`, manages the USB mass-storage modprobe policy and
unloads the fixed module list when that policy is enabled. USB controllers and
input devices are unaffected. A disabled run does not install or remove `kmod`.

## Ownership

This role owns only `/etc/modprobe.d/disable-usb-storage.conf`.

## Supported platforms

Linux hosts only. Other platforms fail with
`disable_usb_storage supports Linux hosts only.`

## Interface

```yaml
disable_usb_storage_enabled: true
```

This is the role's only public variable.

## Enable behaviour

`disable_usb_storage_enabled` converges the owned policy file. A `false` run
removes `/etc/modprobe.d/disable-usb-storage.conf` and does not load modules.
The role does not reload modules unloaded by an earlier run; a later boot can
load them as needed.

## Invariants

- Runtime unloading is mandatory while the policy is enabled.
- The managed file is the role's only persistent artefact.
- Disabling the policy removes the managed file and does not load modules.

## Implementation

- `tasks/main.yml` rejects unsupported platforms and dispatches Linux hosts.
- `tasks/linux/main.yml` loads package data with a Linux fallback, installs
  `kmod` when enabled, manages the policy file, and unloads `usb_storage` and `uas`.
- `vars/Linux.yml` names the module-management package.
- `files/disable-usb-storage.conf` supplies the persistent modprobe policy.

## Migration

`disable_usb_storage` replaces `blacklist_kernel_modules`. Rename
`blacklist_kernel_modules_disable_usb_storage` to
`disable_usb_storage_enabled`.

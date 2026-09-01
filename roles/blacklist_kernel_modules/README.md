# blacklist_kernel_modules

Guarantees an opinionated USB mass-storage policy on Linux hosts. When enabled,
the role persistently prevents `usb-storage` and `uas` from loading, then
unloads both runtime modules.

## Ownership

This role owns only
`/etc/modprobe.d/blacklist-kernel-modules-usb-storage.conf`. USB controllers
and input devices are unaffected.

## Supported platforms

Linux hosts only. Other platforms fail explicitly.

## Interface

- `blacklist_kernel_modules_disable_usb_storage`: enables the USB mass-storage
  policy. Defaults to `true`.

## Implementation

`tasks/main.yml` validates the platform and dispatches to Linux tasks. The
USB-storage task installs or removes the fixed policy file. Enabling the policy
always unloads `usb_storage` and `uas` at runtime.

## Invariants

- Runtime unloading is mandatory while the policy is enabled.
- The managed file is the role's only persistent artefact.
- Disabling the policy removes the managed file and does not load modules.

## Migration

Replace the former module-list configuration with this role and
`blacklist_kernel_modules_disable_usb_storage`.

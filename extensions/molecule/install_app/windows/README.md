# Windows package acceptance

Uses one disposable Windows 11 Proxmox clone with the shared lifecycle and
prepared administrative SSH access. Preparation removes 7-Zip. Convergence
installs `7zip` through `install_app_choco_packages`, idempotence requires no
changes on repetition, and verification checks the installed Chocolatey list.

After [controller and Windows setup](../../README.md#set-up-windows-testing),
activate the checkout and run from the collection root:

```bash
source .envrc
molecule test -s install_app/windows
```

Run scenarios sequentially in an exclusive test window. This checks one
Chocolatey package, not every package or the Linux application channels.

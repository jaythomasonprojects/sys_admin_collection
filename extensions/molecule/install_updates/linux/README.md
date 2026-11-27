# Ubuntu explicit-update acceptance

Uses the public role on native Ubuntu 24.04/26.04 guests and the shared lifecycle.
Preparation selects a real installed package with a newer repository candidate,
holds Bash and records native versions and boot identity. It invokes the public
role before optional tools are installed, proving native updates continue when
those tools are absent. After installing the tools, it verifies empty-global-npm
handling before installing real older npm/Flatpak fixtures.

Flatpak uses the signed Flathub remote, an older Calculator commit from native
history and its real runtime. A native sandbox execution must succeed. Missing
history, unavailable commits or an unusable runtime fail preparation rather than
silently skipping acceptance. Global npm uses `is-odd@3.0.0` with a separately
observed registry candidate. The installation pin is not a maintenance hold.

Convergence updates all channels without reboot permission, verifies actual
versions/commits and boot preservation, then permits required reboot completion.
The unchanged second pass must report no changes. Verification reads native
APT/dpkg state, deployment commits, npm versions and boot identity independently.
It distinguishes a package-generated pending reboot from an unavailable reboot
fixture. It never creates a synthetic reboot marker or alters guest clocks.

No available real candidate leaves acceptance incomplete. Fixture tools and data
are confined to disposable clones. Source templates remain unchanged.

Use `molecule test -s install_updates/linux` after the
[shared setup](../../README.md#set-up-linux-testing).

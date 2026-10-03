# install_app Molecule scenario

This scenario first removes npm during Ubuntu preparation and confirms it is
absent. An npm-only role invocation on that host then verifies that the role
installs its prerequisite and the requested global application without a native
package, Debian installer or Flatpak request. Ordinary Ubuntu and Fedora passes
subsequently verify native packages, executables, the Debian installer on APT,
non-APT skipping, disabled-role behaviour, rejection cases and idempotence.

The APT case installs two previously absent packages, one from a managed-host
path and one from an unchanged loopback-only HTTP URL. Their installed package
states and executables are checked after Molecule's unchanged second pass.
Unavailable references on Fedora and in disabled role calls prove skipping,
while a missing active APT path must fail with a package-reference error. The
container's native destruction also disposes of the fixture HTTP server.

The npm inputs are bare `is-number`, `is-odd@3.0.1`, and scoped
`@colors/colors@1.6.0`. Verification checks global npm JSON for package presence
and both exact versions. Molecule's existing idempotence phase checks that the
repeat reports zero changes. Convergence uses an unprivileged caller with
escalation; disabled calls skip installation without removing packages.

There are no additional npm test helpers or fixtures. Registry access is needed.
The scenario checks installation, not application execution or other npm syntax.

Flatpak installation remains deferred until the test environment has a working
runtime and stable remote fixture. Use selector `install_app/linux` with the
[shared test procedure](../../README.md#run-the-affected-scenario).

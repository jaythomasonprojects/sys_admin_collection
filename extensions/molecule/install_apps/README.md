`install_apps` is extracted into the shared collection, but its runtime Molecule
scenario is intentionally deferred.

The role needs a more reliable package-manager/container baseline before
converge, idempotence, and verify can run without flakiness across environments.

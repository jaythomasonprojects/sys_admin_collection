`config_git` is extracted into the shared collection, but its runtime Molecule
scenario is intentionally deferred.

The role itself is straightforward, but the current lightweight container test
baseline does not provide a stable way to install `git` during scenario setup
without sporadic container exits. Keep the role extracted and linted for now,
and enable Molecule coverage once the collection has a more reliable package
manager test image.

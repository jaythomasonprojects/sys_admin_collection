# desktop_layout Linux scenario

This scenario checks the configured user's persisted GNOME dock position,
icon size, and favourites on Ubuntu 24.04 and 26.04. It also checks
ordinary idempotence and unsupported-platform rejection.

The containers do not run GNOME Shell. This is a dconf and schema check,
not a visual desktop test. Use selector `desktop_layout/linux` with the
[shared test procedure](../../README.md).

Molecule builds the two supported-release images from `Dockerfile.ubuntu2404`
and `Dockerfile.ubuntu2604` during `create`. They extend the Geerling images
with the GNOME Shell and Ubuntu Dock schema packages. The first build takes a
few minutes per image; later runs reuse Docker's cached layers until the base
image or a Dockerfile changes. The missing-schema rejection uses a plain
Ubuntu 24.04 image.

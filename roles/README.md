# Roles

Collection roles for `jaythomasonprojects.sys_admin`, consumed from the
installed collection via FQCN such as
`jaythomasonprojects.sys_admin.local_accounts`.

Each role directory carries its own `README.md`, the local design record for
that role's guarantee, ownership, supported platforms, implementation map,
interface, invariants, and migration notes. Consult the role README rather
than adding a duplicate catalogue here; the directory listing is the catalogue
and a maintained list drifts as roles are added and removed.

Role names describe the outcome: subsystem nouns configure an existing
subsystem, discrete policies use verb phrases, and names carry no prefixes.
Every policy role exposes a `<role>_enabled` flag. When disabling a role can
safely and unambiguously remove artefacts it owns, the role converges; otherwise
it skips implementation. Each role README records which behaviour applies.

Molecule scenarios live in `extensions/molecule/<role>/`. See
`extensions/molecule/README.md` for the shared harness pattern, the runtime
assumptions for new scenarios, and the release gate.

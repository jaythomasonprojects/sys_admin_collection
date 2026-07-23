# Windows SMB Credential Persistence Design

## Goal

Make Windows mapped drives created by `mount_network_share` keep using the
SMB credentials supplied during provisioning after the local Windows account
password changes.

The existing per-share `username` and `password` inputs remain the only
credential inputs. At provisioning time they identify both the local account
used for interactive `runas` and the SMB account. They may diverge later when
the local account password changes.

## Task Structure

`roles/mount_network_share/tasks/win_share.yml` will contain two tasks.

1. A `ansible.windows.win_credential` task creates or updates a
   `domain_password` Credential Manager entry named for
   `mount_network_share_item.server`. It stores the configured username and
   password with `persistence: local` and runs under the configured local user
   through interactive `ansible.builtin.runas` with profile loading.
2. A `ansible.windows.win_mapped_drive` task maps the configured drive under
   the same interactive user. It will not pass `username` or `password` to the
   module, allowing Windows to use that user's saved credential.

Both tasks use task-level `ansible_become_user` and `ansible_become_pass`
variables, so each share's credentials override any inventory-level become
identity. Neither task uses `become_user`, avoiding its lower-precedence,
inventory-overridable behavior.

For shares without a complete username/password pair, the credential task is
skipped and the mapped-drive task keeps its existing non-impersonated path.
The validation in `tasks/main.yml` already guarantees that credential inputs
are either both non-empty strings or both omitted.

## Credential Lifecycle

`state: absent` removes only the mapped drive. It does not remove the
Credential Manager entry because multiple shares on the same server can use
the same saved credential.

Windows Credential Manager permits one `domain_password` credential for a
given server target and type per user. If multiple configured shares use the
same server with different credentials, each credential task updates that
single entry in loop order; the final configured share wins. This limitation
will be documented rather than rejected.

## Documentation And Tests

The role README will explain Windows credential persistence, that the mapping
uses the saved credential rather than module-level initial credentials, the
local-password-change use case, unchanged credentials on drive removal, and
the same-server last-write-wins constraint. It will not contain real
credentials.

The Molecule source-level check will assert the two Windows tasks, credential
parameters, interactive impersonation, task-level become variables, valid UNC
rendering, and the absence of `win_mapped_drive` module-level `username` and
`password`. Docker Molecule remains unable to run Windows tasks.

Live validation against the documented Windows VM will provision an account
where local and SMB passwords initially match, verify the mapped drive and
server credential, change only the local Windows password, log in with the new
local password, and verify the drive continues to connect. No release is
published until that validation succeeds.

## Release

This is a backward-compatible behavioral fix. The collection version changes
from `0.4.4` to `0.4.5`, with a matching newest-first `CHANGELOG.rst` entry.
Automated validation runs `ansible-lint .` and `yamllint .`; the implementation
plan will also include the applicable Molecule source-level verification.

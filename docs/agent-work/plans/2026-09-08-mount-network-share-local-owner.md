# Mount Network Share Local Owner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a configured Linux mount-point owner and group also become the local owner and group presented by CIFS.

**Architecture:** Make the role derive CIFS `uid` and `gid` options from each share's existing `owner` and `group` values. Molecule verifies the generated fstab options, including preservation of explicit options. Live SMB write verification occurs after deployment and is outside this change.

**Tech Stack:** Ansible 2.18+, `ansible.posix.mount`, mount.cifs, Molecule Docker, ansible-lint, yamllint

**Spec:** None, concise plan requested directly.

## Global Constraints

- Keep the existing `mount_network_share_shares` input shape.
- Use FQCNs, single quotes, and the repository task-key ordering.
- Treat this backward-compatible behaviour correction as a patch release.
- Run only the `mount_network_share` Molecule scenario as the per-change gate.

---

### Task 1: Prove and automate CIFS local ownership

**Files:**
- Modify: `roles/mount_network_share/tasks/linux/main.yml`
- Modify: `roles/mount_network_share/README.md`
- Modify: `extensions/molecule/mount_network_share/converge.yml`
- Modify: `extensions/molecule/mount_network_share/verify.yml`
- Modify: `galaxy.yml`
- Modify: `CHANGELOG.rst`

**Interfaces:**
- Consumes: existing per-share `owner`, `group`, and `fstab_options` values
- Produces: CIFS options `uid=<owner>` and `gid=<group>` when explicit equivalents are absent

- [ ] **Step 1: Write the failing Molecule contract**

Remove the scenario's manually supplied `uid=1000` and `gid=1000`. Assert that the generated fstab entry instead contains `uid=molecule` and `gid=molecule`, derived from the configured `owner` and `group`. Add a second assertion showing that explicit `uid=` or `gid=` options are not duplicated or replaced.

- [ ] **Step 2: Confirm the test fails**

Run:

```bash
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
```

Expected: the ownership-option assertion fails because the role does not yet derive `uid` and `gid`.

- [ ] **Step 3: Implement the minimal option derivation**

In the scoped option-list calculation, append `uid={{ mount_network_share_item.owner | default('root') }}` and `gid={{ mount_network_share_item.group | default('root') }}` only when `fstab_options` does not already contain the corresponding option. Keep the local directory task unchanged. Document that SMB still enforces the credential account's server-side permissions.

- [ ] **Step 4: Bump and document the patch release**

Change `galaxy.yml` from `0.9.0` to `0.9.1` and add a matching newest-first `CHANGELOG.rst` entry for corrected Linux CIFS ownership mapping.

- [ ] **Step 5: Run the change gate**

```bash
. .venv/bin/activate && ansible-lint .
. .venv/bin/activate && yamllint .
. .venv/bin/activate && ANSIBLE_CONFIG=ansible.cfg molecule test -s mount_network_share
```

Expected: all three commands pass, including Molecule convergence, idempotence, and runtime fstab assertions.

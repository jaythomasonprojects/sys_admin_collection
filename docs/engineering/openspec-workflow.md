# OpenSpec workflow

Use OpenSpec for substantial behaviour changes. The generated `/opsx-*` commands are the source of
truth for command behaviour; this guide records the review checkpoints around them.

1. Use `/opsx-explore` when the problem or requirements need discussion.
2. Use `/opsx-propose` to create the change and its planning artifacts.
3. Review before implementation. Use `/opsx-update` to check artifact coherence. For a substantial
   change, request a fresh-session technical review with the prompt below.
4. Use `/opsx-apply` after the artifacts have been reviewed. Follow the TDD and verification
   guidance returned by OpenSpec.
5. Use `/opsx-verify` to compare the implementation with the artifacts, then inspect the actual test
   evidence separately.
6. Fix material findings and recheck the affected areas.
7. Use `/opsx-archive` after the result is accepted.

Before implementation, use:

> Review this OpenSpec change before implementation. Read its artifacts and relevant code. Identify
> contradictions, missing requirements, unsafe assumptions and inadequate verification. Report
> actionable findings; do not implement.

After implementation, use:

> Run OpenSpec verify for this change. Also review the diff against the loaded coding standards and
> inspect the verification evidence. Distinguish observed results from inference and name anything
> not verified.

Do not repeat reviews mechanically. Request another pass when code changed in response to findings,
a material finding remains unresolved, or there is a concrete new concern.

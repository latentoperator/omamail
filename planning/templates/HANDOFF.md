# <TASK-ID> handoff

Status: READY FOR REVIEW / BLOCKED. Never mark ACCEPTED here.

## Identity

- Task and covered acceptance criteria:
- Base SHA:
- Candidate SHA:
- Branch/worktree:
- Private PR:
- Accepted prerequisite decisions and their SHAs:
- Implementer/model (if known):

## Behavior and scope

Explain the concrete before/after behavior. List changed files and why each was necessary. Identify any contract changes; link their prior supervisor acceptance.

## Verification

| Command or manual scenario | Environment/fixture | Exit/result | Evidence location |
| --- | --- | --- | --- |
| <exact command> | <versions and synthetic data> | PASS / FAIL / NOT RUN | <path/link> |

- Regression reproduction on previous behavior:
- Acceptance criterion → test/scenario mapping:
- Real integration evidence beyond mocks:
- Matched screenshots (UI tasks):
- Known baseline failures, matching reproduction, and unverified items:
- Product/security-relevant edge cases covered:

## Review risks and limitations

Separate demonstrated behavior from assumptions. Explain error, cancellation, and compatibility behavior. State any remaining uncertainty without declaring it safe by inference.

## Boundaries

- Production mailbox/configuration touched: no / exact authorized action
- Credentials or real email included in artifacts: no (otherwise stop and remediate)
- Installed daily runtime changed: no
- Unrelated modifications preserved:

## Next action

Request supervisor review of this exact candidate. If blocked, name the smallest missing dependency or design decision and give a reproduction. Do not merge, deploy, or self-approve.

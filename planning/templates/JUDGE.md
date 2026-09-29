# <TASK-ID or release> supervisor judgment

- Decision: ACCEPT / REVISE / BLOCKED
- Reviewed candidate SHA:
- Base/integration SHA:
- Review date:
- Supervisor identity/session:
- Independent reviewer and findings record:
- Candidate binary SHA-256 (release review):

## Requirements and evidence

Map S1–S6/E1–E7 or the assigned subset to inspected code, reproduced commands and manual scenarios. Record exit statuses and environments. List evidence personally reproduced separately from worker-reported evidence.

## Findings and disposition

| Finding | Severity | Resolution/evidence | Status |
| --- | --- | --- | --- |
| <finding or explicit none within scope> | <severity> | <evidence> | <resolved/open> |

## Security verdict

PASS / BLOCK / NOT VERIFIED. Name the exact reviewed boundaries, forbidden effects tested, evidence, and remaining limits. This is a scoped change review, not a full repository audit.

## Baseline limitations

List any inherited failures, baseline reproduction, impact analysis, and explicit disposition. No new feature failure may be waived as inherited without evidence.

## Final disposition

Explain why this exact candidate is accepted or which changes/dependencies remain. A later code change invalidates this acceptance. ACCEPT makes the candidate eligible for the separately authorized deployment task; it is not a record that deployment happened.

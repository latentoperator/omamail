# Project state

Updated: 2026-09-29. This file records facts; planned actions are not completed work.

## Bootstrap

- Local development checkout: `/home/chrisgray/Projects/omamail`.
- Upstream source baseline: `2a5a26cf5559dee78291fc5e34876fc5dfd39959`.
- Upstream remote: `https://github.com/huacnlee/omamail.git`; local upstream push URL disabled.
- Private remote: pending GitHub authentication and creation.
- GitHub visibility verification: pending.
- GitHub Actions state: pending repository creation; intended disabled until F00 audit.
- Branch protection: not configured; supervisor gate currently procedural.
- Daily plugin and backend: unchanged by repository setup.
- Planning documents: authored and independently reviewed; no must-fix findings. Supervisor accepted the plan for task assignment. This is not acceptance of unimplemented features.
- Feature implementation: not started.
- Full baseline build/test suite: not run; Rust/Cargo/CMake missing from inspected PATH.
- Sonnet/Hunspell present; American English dictionary availability requires F00 verification/provisioning.

## Execution board

| Task | State | Accepted candidate / evidence |
| --- | --- | --- |
| F00 | NOT STARTED — next implementation task | — |
| S00 | WAITING FOR F00 | — |
| S01 | WAITING FOR S00 | — |
| S02 | WAITING FOR S01 | — |
| S03 | WAITING FOR S02 | — |
| S04 | WAITING FOR S03 | — |
| E00 | WAITING FOR F00 | — |
| E01 | WAITING FOR E00 | — |
| E02 | WAITING FOR E01 | — |
| E03 | WAITING FOR E02 | — |
| I00 | WAITING FOR S04 + E03 | — |
| R00 | WAITING FOR I00 | — |
| J00 | WAITING FOR R00 | — |
| D01 | WAITING FOR J00 + deployment authorization | — |

Only the supervisor changes a task to ACCEPTED after recording an exact-commit judgment. Workers can report READY FOR REVIEW or BLOCKED with evidence. Update successor prerequisites when accepted commits are integrated.

## Known pre-existing observations

The daily source is upstream 0.10.7 with released backend API 5 and development API 6. The same version string can describe different source/API builds. Existing cleanup runs and one live read-only account listing reported an IMAP failure during initial inspection. These are outside the feature scope; no cause or fix is claimed.

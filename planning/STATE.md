# Project state

Updated: 2026-09-29. This file records facts; planned actions are not completed work.

## Bootstrap

- Local development checkout: `/home/chrisgray/Projects/omamail`.
- Upstream source baseline: `2a5a26cf5559dee78291fc5e34876fc5dfd39959`.
- Upstream remote: `https://github.com/huacnlee/omamail.git`; local upstream push URL disabled.
- Public remote: `https://github.com/latentoperator/omamail.git`; repository created as `omamail-private`, then made public and renamed on 2026-09-29. The bootstrap evidence records its original private state. The repository has no live credentials or real mail; the TLS key in upstream testdata is a synthetic localhost fixture. See `planning/evidence/F00.md` §5.
- GitHub Actions: enabled after the public-repository review (`enabled: true`, default token permission read). CI and Native credential contracts are active; Pages, Release, and CI report remain individually disabled. F00 adapted the released-backend gate to fetch from `huacnlee/omamail`.
- Branch protection: configured on `main` — required check `Published backend merge gate` (strict), no force pushes, no deletions, administrators retain bypass (`enforce_admins: false`). GitHub-enforced protection is now available and complements, but does not replace, the supervisor gate.
- Daily plugin and backend: unchanged by repository setup.
- Planning documents: authored and independently reviewed; no must-fix findings. Supervisor accepted the plan for task assignment. This is not acceptance of unimplemented features.
- Feature implementation: not started.
- Toolchain (F00): `rust`/`cargo` 1.98.1 and `cmake` 4.4.3 installed from Arch `extra` (matching the CI pin); previously absent.
- Baseline (F00): build, Rust tests (627 passed, 11 ignored), JS, shell, backend-process, `app-build`, `test-app-qml`, `qml-check`, and `omarchy plugin validate` all pass. Two recorded failures: `make test-qml` fails 8/1004 (`KeyboardReaderNavigation`) under local Qt 6.11.2; the cause is not yet proven. `cargo clippy --locked --all-targets -- -D warnings` reports 3 existing lint errors. Neither is a CI gate or introduced by F00. Full record: `planning/evidence/F00.md`.
- Sonnet 6.29.0 present; `en_US` Hunspell dictionary now installed (`hunspell-en_us 2026.02.25-1`), clearing the earlier dictionary blocker.
- F00 accepted for exact candidate `880d410aa81e2e6d69ae57e11e37b63443cc4da5` after the required gate, the remaining GitHub Actions checks, and independent review. [PR #1](https://github.com/latentoperator/omamail/pull/1) records the supervisor judgment; merge commit `da0ff530f340cf479142c28c617c2c5854911f69`. The eight QML failures and three clippy errors remain recorded baseline failures, not passing checks.

## Execution board

| Task | State | Accepted candidate / evidence |
| --- | --- | --- |
| F00 | ACCEPTED | `880d410`; [evidence](evidence/F00.md), [judgment](https://github.com/latentoperator/omamail/pull/1) |
| S00 | READY FOR ASSIGNMENT | F00 accepted at `880d410` |
| S01 | WAITING FOR S00 | — |
| S02 | WAITING FOR S01 | — |
| S03 | WAITING FOR S02 | — |
| S04 | WAITING FOR S03 | — |
| E00 | READY FOR REVIEW — awaiting supervisor sign-off | `planning/decisions/E00.md` (base `d88833e`) |
| E01 | READY FOR REVIEW — awaiting supervisor sign-off | `planning/evidence/E01.md` (base `b730830`) |
| E02 | READY FOR REVIEW — awaiting supervisor sign-off | `planning/evidence/E02.md` (base `19d8a79`) |
| E03 | READY FOR REVIEW — awaiting supervisor sign-off | `planning/evidence/E03.md` (base `5aa0002`) |
| I00 | WAITING FOR S04 + E03 | — |
| R00 | WAITING FOR I00 | — |
| J00 | WAITING FOR R00 | — |
| D01 | WAITING FOR J00 + deployment authorization | — |

Only the supervisor changes a task to ACCEPTED after recording an exact-commit judgment. Workers can report READY FOR REVIEW or BLOCKED with evidence. Update successor prerequisites when accepted commits are integrated.

## Known pre-existing observations

The daily source is upstream 0.10.7 with released backend API 5 and development API 6. The same version string can describe different source/API builds. Existing cleanup runs and one live read-only account listing reported an IMAP failure during initial inspection. These are outside the feature scope; no cause or fix is claimed.

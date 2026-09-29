# Supervisor review and acceptance gate

Chris is product owner. The supervising Codex agent is the final technical judge. Smaller models implement bounded tasks; independent reviewers provide findings. Neither a worker's self-report nor passing CI substitutes for final judgment.

## Per-task review

1. Verify candidate SHA, base SHA, diff, task scope, and accepted prerequisite decisions. Inspect the actual changed code and tests.
2. Match each acceptance criterion to evidence. Inspect test assertions: a test that only mirrors an implementation or asserts a menu string does not establish transport, storage, or editing correctness.
3. Reproduce the decisive behavior independently. For changes touching mail bytes, filesystem writes, account routing, optional module loading, undo, or focus, run the corresponding real integration tests rather than relying solely on mocks.
4. Obtain a fresh-context reviewer for the complete feature patch or significant boundary change. Give it base/head SHAs, requirements and agreements; ask for concrete defects, severity, reproduction and missing evidence. The reviewer cannot merge or award final acceptance.
5. Resolve findings and rerun checks affected by fixes. Any changed candidate SHA makes the previous approval stale.
6. Record ACCEPT, REVISE, or BLOCKED against the exact candidate SHA. Separately record security PASS, BLOCK, or NOT VERIFIED with the reviewed boundary and evidence.

## Mandatory final matrix

| Area | Required evidence | Blocks acceptance when |
| --- | --- | --- |
| Scope | S1–S6 and E1–E7 mapped to tests/manual scenarios | A required scenario is omitted or silently deferred |
| Body spelling | Real Sonnet highlighter, multiple compose modes, plain text unchanged | Underlines are faked or dirty state changes during checking |
| Subject spelling | Single line, Enter/Tab/IME/Unicode/undo/RTL/recovery | Subject rewrite breaks existing editing or header safety |
| Suggestions | Clicked word, stale menu, selection, repeat words, five-item bound | Wrong word replaced or replacement cannot be undone normally |
| Dictionaries | en_US verified, isolated persistence and ignore lifetime | Silent language substitution, global preference mutation, or lost personal words |
| Optional support | Module/dictionary absent, plugin and standalone load | A missing Sonnet import breaks the mail application |
| Original message | Synthetic server payload equals exported file byte-for-byte | Content is reconstructed, truncated, decoded/re-encoded, or loses attachments |
| Account/message identity | Unified list, duplicate UIDs across accounts, member vs conversation, account switch | Active account/selection can redirect an in-flight export |
| Mail state | Observed BODY.PEEK and unchanged server flags; no mutation commands | Export marks mail read, sends, moves, or modifies mail |
| Native storage | Unique names, private modes, safe components, symlink/race/failure cleanup | Existing files overwritten, path escape possible, or partial file left |
| Resource bounds | Enforced size/deadline/concurrency, cancellation tests | Oversized input or canceled work can allocate/write without bound |
| Backend compatibility | Stock API 5, stock API 6 missing private method, private candidate | Version number alone enables a nonexistent/incompatible operation |
| UI polish | Actual interactions in two themes and compact/wide layouts | Only mocks, one theme, or screenshots without functioning controls |
| Regression | make validate, clippy, process tests, contracts | New failure, silently skipped check, or unclassified baseline failure |
| Distribution | Candidate commit/hash, private runtime provenance, tested rollback | Old backend used accidentally or update can silently replace private behavior |
| Review | Independent findings resolved, final exact-commit judgment | Worker self-approval or review applies to an older SHA |

## Evidence rules

Every record names the candidate SHA, baseline SHA, runtime versions, command, exit status, fixture/scenario, observed result and limitation. Raw test logs stay in ignored local artifacts; use only synthetic or sanitized screenshots in public PR attachments and tracked Markdown. Never publish real account data to substantiate a test.

A failing test may be inherited. Prove it at the baseline under the same environment, record it as a failure, and assess whether the changed area depends on it. Only the supervisor may accept a demonstrated unrelated baseline limitation with written reasoning. A failure in the feature, its identity/storage boundary, or required visual path is a blocker. Do not weaken or remove a test to make CI green.

Changes to optional QML loading must be tested both with and without the module on the import path. Mocked Sonnet tests alone do not prove actual underlining. File export must be checked against the raw wire fixture; parsing both sides and comparing visible text is insufficient.

## Final decisions

- **ACCEPT:** requirements met, evidence current, no unresolved blockers, reviewed security boundaries PASS. Candidate may proceed to the separately assigned deployment task.
- **REVISE:** concrete defects or missing evidence remain. List required changes by file/scenario; return to the relevant worker packet.
- **BLOCKED:** external prerequisite or unresolved product/architecture decision prevents judgment. State the exact dependency and resume condition; do not substitute a weaker criterion.

Security verdicts follow the inherited AGENTS agreement. PASS is scoped to reviewed changes, not a certification of the entire upstream mail client. BLOCK means a demonstrated problem remains. NOT VERIFIED means evidence is insufficient and blocks feature release.

## What the repository can enforce

AGENTS instructions, task records, and PR templates communicate the workflow. Branch protection or a repository ruleset can require PRs and checks where GitHub supports it, but it cannot distinguish which model acted through Chris's credentials. Document actual remote settings in STATE. Do not invent an automated judge service, store a model/API credential, or configure auto-merge as part of planning.

The bootstrap commit that creates this plan is setup, not approval of feature implementation. Implementation task states begin at NOT STARTED. Final judgment is a future act performed on real code and test results.

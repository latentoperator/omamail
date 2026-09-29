# Worker assignment prompt

The supervisor fills the values in angle brackets. Give a worker one task; do not paste the entire conversation.

```text
You are implementing task <TASK-ID> for Chris Gray's public Omamail derivative.
Repository: /home/chrisgray/Projects/omamail (origin must be latentoperator/omamail).
Task worktree: <ABSOLUTE-PATH>
Base commit: <FULL-SHA>
Branch: task/<TASK-ID>-<short-purpose>

Read AGENTS.md, PRIVATE-FORK.md, planning/PROJECT-PLAN.md, and only your task packet
in planning/TASKS.md plus its listed source files/accepted decisions. Read
planning/STATE.md to verify prerequisites were actually accepted. Preserve the
upstream MIT license and source history.

Implement your assigned packet completely with the smallest cohesive patch.
Use the frozen contracts and synthetic tests. Do not expand provider support,
rewrite unrelated code, loosen existing checks, or silently change acceptance
criteria. Search for callers before changing interfaces. Capture before/after
behavior where a regression test is required. Verify against actual installed
APIs rather than guessing method names. Missing tooling is NOT RUN, not PASS.

Work only in the assigned worktree. Never edit the installed plugin or its real
accounts/caches; never run make install, make publish, scripts/link-plugin.sh,
or real mailbox mutations. Do not send email or launch AI calls for tests.
Never copy production credentials/mail into the repository or CI artifacts.

Run the packet's focused tests and required affected gates. Record commands,
exit codes, source commit, environment, and exact limitations. Do not iterate
on the same failed approach indefinitely: after two focused failed attempts,
return a reproduction and smallest decision needed from the supervisor.
Escalate before changing frozen contracts or broadening scope.

Commit your task changes. Finish with planning/templates/HANDOFF.md filled in
for the exact candidate SHA, plus a draft PR in this repository if that publication was
included in this assignment. Status is READY FOR REVIEW, not ACCEPTED. You
cannot merge, approve your own work, deploy, or publish a release. The supervising
Codex agent makes the final judgment after independent review.
```

## Supervisor assignment notes

Prefer a smaller coding model for implementation after design is frozen. Assign S00/E00 as evidence-gathering tasks with an explicit supervisor design checkpoint. Assign security-sensitive review and final judgment to the supervisor or a suitably capable independent reviewer. Do not route acceptance to the cheapest model just because it implemented the feature.

Parallel work needs separate worktrees and non-overlapping edits. Start S00 and E00 after F00. Shared App/composer/settings changes should be integrated serially. Workers never write concurrently into the main development checkout or edit another worker's branch.

A typical worktree setup, run by the supervisor after substituting actual values:

```sh
git worktree add ../omamail-S01 -b task/S01-body-spelling <accepted-base-sha>
```

Before assigning a successor, update STATE with the accepted prerequisite SHA and link to the decision/handoff. A worker's completion message does not satisfy a prerequisite by itself.

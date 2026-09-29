# Omamail development copy

Owner: Chris Gray. Supervising technical judge: the Codex agent directing this project. Created: 2026-09-29.

This public repository preserves the source history of [huacnlee/omamail](https://github.com/huacnlee/omamail) and its [MIT license](LICENSE). It was created as an independent private development copy and later made public; it is not a GitHub-network fork. Upstream updates can still be fetched and merged through the `upstream` remote.

## Deliverables

1. Local spelling underlines in the composer body and subject, with correction suggestions, session ignore, and a persistent personal dictionary.
2. A message-menu action that saves the original selected Outlook/IMAP message as `.eml` to the operating system's Downloads directory, including all MIME parts and attachments.
3. A tested private installation and rollback procedure, accepted by the supervisor before use on the daily desktop.

`.msg` conversion, grammar/AI proofreading, automatic correction, bulk export, and new mail providers are deferred. The first target is this laptop's Omarchy plugin; shared UI changes must continue to load in the standalone host without Sonnet installed.

## Start here

| Document | Purpose |
| --- | --- |
| [Project plan](planning/PROJECT-PLAN.md) | Scope, architecture, fixed contracts, decisions, risks, and milestones |
| [Task packets](planning/TASKS.md) | Bounded assignments with dependencies, allowed changes, tests, and stop conditions |
| [Worker prompt](planning/WORKER-PROMPT.md) | Copyable instructions for a smaller implementation model |
| [Review gate](planning/REVIEW-GATE.md) | Independent review, supervisor acceptance, and release conditions |
| [Current state](planning/STATE.md) | What actually exists, what is unverified, and the next task |
| [Handoff template](planning/templates/HANDOFF.md) | Evidence an implementer must return |
| [Judge template](planning/templates/JUDGE.md) | Exact-commit decision record |

## Working copy and remotes

Development checkout: `/home/chrisgray/Projects/omamail`. The daily plugin remains a separate checkout under `~/.config/omarchy/plugins/omamail`. Edits in the daily plugin tree can hot-reload the desktop; do not develop there.

`origin` is this public repository. `upstream` is the original public project, with its local push URL disabled. Use `git fetch upstream` to inspect updates; integrate them in a dedicated `maintenance/upstream-YYYY-MM-DD` branch and repeat the affected gates. Preserve the upstream history and license. Do not use a mirror push against an existing repository.

Initial source baseline: `2a5a26cf5559dee78291fc5e34876fc5dfd39959`, upstream main, 2026-09-27. Installed plugin/backend: 0.10.7. The released backend speaks API 5; the checkout implements API 6. Having the same application version does not imply identical APIs or features.

## Execution policy

One task per worker assignment and normally one task per PR. Workers may submit candidates but cannot accept or deploy them. The supervisor reviews evidence and the actual patch, reproduces decisive checks, and records ACCEPT, REVISE, or BLOCKED. No unattended merge or release automation is part of this project. The current request authorizes repository setup and planning; implementation starts when assigned.

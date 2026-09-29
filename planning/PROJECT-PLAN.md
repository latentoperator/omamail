# Project plan: spelling and message export

Status: ready for supervised task assignment after repository bootstrap. This is an implementation specification, not a claim that either feature exists. Owner: Chris Gray. Final technical judge: supervising Codex. Date: 2026-09-29. Source baseline: `2a5a26cf5559dee78291fc5e34876fc5dfd39959`.

## 1. Product outcomes

Chris wants the familiar web-mail experience of visible spelling errors while composing and a downloaded email file usable outside the mail application. Deliver spelling in the body and subject, plus complete `.eml` export from a selected message to Downloads. The first supported export providers are Outlook/Microsoft 365 and generic IMAP, which share the native IMAP transport. This covers the two configured work accounts without adding Microsoft Graph mail-reading consent.

### Required behavior

| ID | Acceptance criterion |
| --- | --- |
| S1 | Misspelled words receive a visible wavy underline while composing a new message, reply, reply-all, or forward. The draft text itself is never decorated or rewritten by checking. |
| S2 | Checking applies to body and subject. Address fields are excluded. The subject remains a single-line field with existing Enter-to-body and Tab navigation. |
| S3 | Right-clicking a misspelled word offers at most five suggestions, Ignore for this session, and Add to dictionary, alongside the existing editing commands. A correction targets the clicked word even if the caret is elsewhere. |
| S4 | A correction can be undone through the normal editor undo command and participates correctly in dirty state and draft recovery. Merely checking, selecting, ignoring, or opening a menu never changes draft content or dirty state. |
| S5 | American English (`en_US`) is the initial language. Checking is local, with no network or model calls. An explicit setting enables/disables spelling. Missing optional support never prevents composing; show a useful setup explanation when appropriate. |
| S6 | A personal word survives restart; Ignore lasts for the current application process/session only. Language or disabled state is persisted in private app settings rather than modifying global Sonnet preferences. |
| E1 | A single-message action named Save as .eml writes the exact RFC 5322/MIME octets returned by the server for that message, including headers, HTML/plain alternatives, nested messages, inline images, and attachments. |
| E2 | Export uses the account and folder-qualified message ID captured when the action is requested. It does not mark unread mail read, change flags, move messages, send mail, or fetch remote images. |
| E3 | Save to the OS-configured Downloads directory (normally `~/Downloads`), with a sanitized subject filename and `.eml` extension. Duplicate names receive a numeric suffix without overwriting existing files. |
| E4 | Show a busy state, refuse duplicate in-flight exports for the same account/message, and report the actual saved filename and directory. Failures produce an actionable safe error, never a success notice. |
| E5 | A selected conversation member exports only that member. Opening a context menu on one row and then changing the selected account/message cannot redirect the request. No bulk export in v1. |
| E6 | Unsupported providers and backends cannot dispatch export. Old backends remain usable for all existing features. |
| E7 | Cancellation, timeout, oversize, missing message, disk-full, or permission errors leave no newly created partial `.eml`. Existing user files are untouched. |

### Explicitly deferred

`.msg` output; Gmail/JMAP/HEY export; export of unsent drafts; importing mail; bulk export; spelling in the AI prompt or calendar; grammar checking; automatic correction; multilingual auto-detection; a browser rendering engine; new standalone distribution packages; cleanup-script fixes. Deferred work must not be quietly included in a task.

## 2. Verified starting point and uncertainties

The daily checkout was clean and matched upstream main at inspection. Omamail uses Rust business logic and a QML UI over persistent stdio JSON-RPC. The same shared UI supports an Omarchy Quickshell plugin and a standalone Qt host. The plugin uses an exact private binary pin, independent of PATH.

| Area | Observed fact | Consequence |
| --- | --- | --- |
| Composer | `ui/components/ComposeView.qml` has a plain-text `TextEdit` body and a `TextField` subject. | Sonnet can attach to the body's text document; the subject needs a carefully tested editor adapter. |
| Menus | `ui/components/TextMenu.qml` is shared; `TextMenuTrigger` is an inline component in the composer. | Extend the existing menu and pass editor/position explicitly. Do not invent a duplicate global context-menu implementation. |
| Spelling | Sonnet 6.29.0, Hunspell, and Enchant are installed. Sonnet's QML module exports `SpellcheckHighlighter`. The inspected Hunspell directory has British-English variants but no `en_US` dictionary. | Prove available languages in F00/S00; do not assume American English is installed or silently use British English. |
| Desktop | Qt 6.11.2 and Quickshell 0.3.1 are installed. QML tools live under `/usr/lib/qt6/bin/`. | PATH-only tool detection would give false negatives for QML tools. |
| Build | Node, Python, make, and g++ are available. Cargo, rustc, and CMake were not found on PATH. | F00 establishes tools and an honest baseline before implementation. No full build/test pass is claimed today. |
| Mail transport | `src/providers/imap/read.rs` fetches full `BODY.PEEK[]` and parses it into a common resource. | Retrieve and retain original literal bytes for export; do not serialize parsed display data back into an email. |
| Storage | `src/attachment/mod.rs` and `src/platform/private_fs*` already handle private, unique file creation. Attachment storage has a 20 MiB payload limit; IMAP responses have a 32 MiB bound. | Reuse filesystem primitives, not blindly the attachment RPC or its payload limit. Export needs its own tested bounded native path. |
| Runtime | Pin 0.10.7 / released API 5; source API 6 already has unreleased search semantics. | Add new methods to the current unreleased contract; do not increment to API 7 while released remains 5. Feature availability must also verify method support because upstream API 6 alone will not prove this private extension exists. |
| Hosting | Upstream download URLs and release automation name the public project. | Private builds require deliberate provenance, capability checks, and installation. Merely changing the Git remote does not change where the backend comes from. |

A read-only live listing failed for one work account during inspection; the other succeeded. The pre-existing cleanup timer also reported failures that morning. Neither is a feature regression. Implementation tests use synthetic fixtures, and live acceptance must distinguish account/network failures from candidate defects.

Some inherited docs describe earlier transports and API levels. Source, `backend-api.json`, Make targets, and verified behavior at the baseline are authoritative. Read inherited instructions, but do not copy obsolete architecture claims into new code.

## 3. Architecture and decisions

### 3.1 Spelling adapter

Use the installed Sonnet QML highlighter, backed by a local dictionary. First prove its behavior with the installed Qt/Quickshell and a synthetic editor. Put Sonnet imports in a separately loaded optional component, provisionally `ui/compose/SpellcheckAdapter.qml`. Shared entry points must not acquire a mandatory `org.kde.sonnet` import: doing so could prevent the entire application loading when the dependency is absent.

The adapter accepts an editor's `textDocument`, cursor/selection, desired language, enabled flag, and inherited theme error color. It exposes availability, missing-dictionary status, suggestions at a position, ignore, and add-word operations. All names are proposed until S00 freezes the small interface in a decision record. Use documented exports verified against the local `.qmltypes`; do not assume a QWidget API is available in QML.

Underline color comes from a semantic theme role passed through the existing component hierarchy; use Sonnet's `misspelledColor` rather than accepting a literal library default that violates project rules. Underlines remain display formatting and must not affect plain draft strings, outbound MIME, signatures, recovery snapshots, or caret movement. Keep current-word behavior compatible with natural typing; test completion on whitespace/punctuation.

Capture the clicked editor, UTF-16 character position, word bounds, and editor revision when opening the menu. If the text changes before applying a suggestion, recompute safely or refuse the stale operation. Do not replace the caret word simply because Sonnet happens to know it. Preserve selection, keyboard navigation, paste-image behavior, and focus ownership. Use actual Sonnet integration tests as well as menu mocks.

S00 must establish how personal words persist and how session ignore behaves across multiple composers. Sonnet may own its personal lexicon, but toggling this app's settings must not rewrite global language/checker defaults. If Sonnet's global storage scope or runtime behavior makes the desired semantics unavailable, stop with evidence and request a supervisor design decision before adding another dictionary engine.

The subject may become a styled one-line `TextEdit` wrapper. Preserve the existing object name, public properties used by the composer, placeholder, theme, selection, horizontal scrolling, keyboard shortcuts, and dirty-state callbacks. Normalize pasted CR/LF to spaces at the input boundary; do not repeatedly assign all text on each keystroke and destroy undo/IME behavior. Sonnet itself does not support a `TextField` without a text document.

### 3.2 Raw message export

Add a provider-neutral service operation in Rust, provisionally `mail.exportEml`, with a single account-bound message. A native adapter reads exact IMAP literal bytes using existing authentication, connection, framing, and cancellation machinery. Export never passes raw mail through QML, does not use a subprocess with credentials, and does not reassemble mail from the reader projection.

Preferred RPC shape to freeze in E00:

```json
{"method":"mail.exportEml","params":{"accountId":"outlook:person@example.test","messageId":"42:INBOX","suggestedName":"Project update"}}
```

Successful result:

```json
{"accountId":"outlook:person@example.test","messageId":"42:INBOX","path":"/synthetic/Downloads/Project update.eml","filename":"Project update.eml","bytes":12345}
```

The client-supplied name is an untrusted display hint, never a path. There is no arbitrary output directory parameter and no format parameter in v1. Backend validation rejects empty/unknown accounts rather than falling back to the currently active account. Provider must be Outlook or IMAP. Validate UID/folder syntax and control characters before credential lookup or network connection. If a backend dispatcher requires a different normalized naming convention, E00 documents it and the supervisor freezes it before E01/E02 start.

The native path must extract exactly one literal for the requested UID and folder. Preserve CRLF, non-UTF-8 octets, MIME boundaries, folded headers, and attachment encodings. Ignore unrelated unsolicited FETCH records. Refuse truncated literals, mismatched UIDs, duplicate/ambiguous results, NIL/missing body, or a failed tagged completion. Test the complete wire operation with a local synthetic server; a MIME parse round trip is insufficient. Use `BODY.PEEK[]`; any SELECT/EXAMINE choice must preserve existing connection ownership and keep `\Seen` unchanged.

Initial product size limit: 25 MiB raw message bytes. This sits below the current 32 MiB IMAP response bound and above attachment storage's 20 MiB limit. E00 must confirm framing overhead, allocation, RPC deadline, and concurrency behavior support it without globally increasing limits. If they do not, escalate the limit as a product/architecture decision. Check announced literals before allocation and count actual bytes. Export is bounded to one in-flight request per account and at most two overall. Reuse existing request cancellation and deadlines; proposed operation deadline is 60 seconds, but both native dispatch and QML deadline must agree before freezing the contract.

Store within the native Downloads resolver and private filesystem abstraction. Sanitize and cap the UTF-8 filename to a safe component, strip separators/control characters and platform-reserved forms, fall back to `message.eml`, and append `.eml` once. Use exclusive creation/atomic publication and actual error cleanup; avoid check-then-overwrite. Preserve existing names and unrelated files under concurrent saves. Reuse handle-anchored/no-follow primitives where available and test symlink destinations. Success is emitted only after a complete committed file; a finalization race with cancellation needs an explicit documented rule. Once committed, return success with the path rather than falsely claiming cancellation and leaving an unexplained file.

### 3.3 Availability, account routing, and API identity

Use the shared native provider capability mapping and QML projection, not unrelated provider-ID checks scattered through views. The export action is enabled only for a persisted eligible message, a ready owning account, and a backend that advertises `mail.exportEml` with the agreed extension contract. API version alone is insufficient. Test stock API 5, stock API 6 without the method, and the private candidate with the method.

A unified-list message must resolve to its actual account and raw provider ID; a conversation rail member must resolve to its actual member. Capture those identities before asynchronous work. On account switch, the export can finish for its captured account, but its callback must not overwrite the new account's status or selection. Determine in E03 whether an app-wide completion notice or account-scoped notice fits current ownership; record the decision and test it.

Extend `backend-api.json`, method inventory, versioned fixtures, and native/QML compatibility checks. Keep `releasedApiVersion=5` and `apiVersion=6` during development on this baseline; include the private export method and cases under `unreleased`. Rebase this decision if upstream advances the release. A source binary at version 0.10.7 can differ from the published 0.10.7 binary, so handoffs and deployment must also record source commit and binary SHA-256.

### 3.4 Private runtime and upstream updates

Develop in the Projects checkout or its worktrees. F00 proves a standalone synthetic session or an isolated shell/test harness with temporary XDG configuration/cache/data/state roots and a source-built backend. Do not replace the active plugin or global private binary to make tests pass. The existing `OMAMAIL_BIN` development route must be verified in actual startup code; a running shell cannot receive new environment variables from a later toggle command.

R00 decides the exact private release version, manifest/pin relationship, source fingerprint, and authenticated/local artifact installation before D01. Do not simply point an unauthenticated public downloader at private release assets or weaken checksum/handshake verification. For this one-laptop scope, an explicitly installed verified local build is acceptable and may be simpler than a private release service. Its interaction with `install-local`, local-build metadata, regular update checks, and rollback must be proven.

F00 audits and adapts CI before Actions is enabled. Inherited Pages and release workflows are not deployment mechanisms for this derivative. No Pages site or release publication is requested. The regular CI suite expects release assets that this derivative does not own; F00 must preserve the upstream published-backend gate deliberately, not fake assets or drop it silently.

## 4. Milestones and dependency order

| Milestone | Tasks | Exit |
| --- | --- | --- |
| Foundation | F00 | Tools, isolated test environment, CI decision, baseline evidence |
| Spelling | S00 → S01 → S02 → S03 → S04 | Body and subject underlines, corrections, settings, regression evidence |
| Export | E00 → E01 → E02 → E03 | Byte-exact native retrieval, safe storage/RPC, correctly routed UI |
| Integration | I00 | Both features together pass tests and visual acceptance |
| Release readiness | R00 | Verified private candidate, installation plan, rollback rehearsal |
| Supervisor acceptance | J00 | Exact candidate accepted with independent review and complete evidence |
| Deployment | D01 | Explicitly assigned installation verified on the laptop; rollback available |

After F00, S00 and E00 may run in parallel in separate worktrees. Feature branches remain separate until their contracts are accepted. S03 and E03 both touch shared UI files and should be scheduled serially or integrated by the supervisor with a reviewed resolution. I00 begins only after both feature tracks are accepted. No task is accepted by elapsed time or by a worker's own PASS assertion.

## 5. Model assignment and escalation

Use smaller coding models for bounded tasks with frozen interfaces, nearby examples, and explicit tests. The supervisor owns architecture, ambiguous domain semantics, failed-gate classification, security judgment, and final acceptance. Do not assume a particular model is competent because its output is confident. Correct implementation and evidence determine acceptance.

Each worker gets one packet, the exact base SHA, read scope, branch, and allowed files. It returns a commit, diff summary, reproduction, commands with exit statuses, test results, limitations, and a handoff. Ask the supervisor when two focused attempts fail for the same reason, a task would require changing a frozen contract, scope grows into another subsystem, or a dependency cannot be satisfied. A stopped worker should retain reproducible evidence and recommend the smallest next decision; it must not weaken a test or hide a failure to finish.

An independent reviewer starts with a fresh context and reads the patch plus requirements, not the implementer's conversation. It does not merge. The final judge inspects the diff and reruns the decisive checks. GitHub protections, if available, complement this procedure; they cannot authenticate the intellectual identity of a model using the same user credentials.

## 6. Validation and release evidence

Targeted task tests must exercise behavior and fail on the missing/broken implementation. At integration run `make validate`, `cargo clippy --locked --all-targets -- -D warnings`, the real process bridge checks, the changed contract against the source build, and the released contract against the checksum-verified pinned binary. `make validate` includes Rust, JavaScript, shell, QML, standalone QML, lint, and plugin validation; it is not just a linter. Build the standalone backend/host before its tests as required by current Make dependencies.

Record baseline failures before feature work. Reproduce suspected pre-existing failures at both baseline and candidate under matching conditions. Never call an incomplete suite green. The supervisor alone can classify a proven unrelated failure as a documented limitation, and must still show all changed behavior and affected boundaries passed. A new failure blocks acceptance.

Visual acceptance uses synthetic mail, light and dark themes, compact and wide windows, and keyboard plus mouse. Capture matched before/after views for every changed interaction: body underline, subject underline, suggestions menu, missing dictionary, save busy state, success, and error. Keep images out of Git history; use only sanitized PR attachments or local artifacts and link the evidence. Each record names commit, runtime, theme, size, and scenario. A screenshot of a mock is not evidence of a live plugin interaction.

EML acceptance compares file bytes/digests with the controlled server's original payload and opens a synthetic exported message in an independent MIME reader or available mail client. Check attachment digest, headers, dates, Unicode subject, alternative bodies, and unread state. Real account exports, if used for final owner acceptance, stay local and are never committed or attached to PRs.

See [REVIEW-GATE.md](REVIEW-GATE.md) for the decision matrix and [TASKS.md](TASKS.md) for commands and expected evidence.

## 7. Sources

- [Sonnet SpellcheckHighlighter](https://api.kde.org/qml-org-kde-sonnet-spellcheckhighlighter.html): text-document integration and QML API; cross-check the installed `.qmltypes` before implementation.
- [Microsoft MIME export](https://learn.microsoft.com/en-us/graph/outlook-get-mime-message): `.eml` as complete MIME mail. The chosen v1 implementation uses existing IMAP access, not new Graph permissions.
- [Microsoft MSG format](https://learn.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxmsg/cd44ec9f-01bb-4ea3-b335-87cfeb827594): separate structured binary serialization, deferred.
- [GitHub fork visibility](https://docs.github.com/en/pull-requests/reference/forks): background on how this independent repository was created.
- Local contracts: [AGENTS.md](../AGENTS.md), [architecture](../docs/ARCHITECTURE.md), [keys](../docs/KEYS.md), [runtime](../docs/BACKEND-RUNTIME.md), [API](../backend-api.json), and [Makefile](../Makefile).

# Executable task packets

Read [PROJECT-PLAN.md](PROJECT-PLAN.md) and the root [AGENTS.md](../AGENTS.md) first. Status lives in [STATE.md](STATE.md). Every assignment names one task ID and an exact base commit. Proposed new files below are suggestions, not claims they already exist. Existing file paths are relative to the repository root.

## Common procedure for every task

1. Confirm `git status --short`, branch, and exact base SHA. Work in a clean isolated worktree; never in the installed plugin. Report unrelated changes and preserve them.
2. Read the packet's listed source plus the relevant root agreements. Find callers with `rg` before editing an interface. Inspect actual APIs; do not fabricate methods from documentation examples.
3. Add behavioral tests and reproduce their failure on the prior behavior where meaningful. Implement the smallest complete change. Synthetic fixtures use reserved example domains and no live credentials.
4. Run focused checks first. Run the required aggregate gates for the affected layer before handoff. Record exact commands and exit codes; retain failure output outside tracked source. Missing tools or skipped tests are NOT RUN.
5. Commit only task changes with an outcome-oriented subject. Submit a private draft PR when assigned to do so. Include a handoff based on [the template](templates/HANDOFF.md), including candidate SHA and acceptance criterion IDs.
6. Stop at READY FOR REVIEW. Only the supervisor can accept, integrate, or authorize the deployment task. Later changes invalidate earlier exact-commit acceptance.

## F00 — Establish reproducible development and baseline

**Owner:** implementation worker; supervisor accepts environment and CI decisions. **Depends on:** repository bootstrap. **Branch:** `task/F00-foundation`.

**Read:** `Makefile`, `dev`, `docs/BACKEND-RUNTIME.md`, `scripts/backend-runtime.py`, `scripts/link-plugin.sh`, `tests/run_qml_native.py`, `app/CMakeLists.txt`, all `.github/workflows/`.

**Allowed changes:** setup documentation, scoped development helpers, CI configuration, and test infrastructure necessary to run the baseline. No product features, production config edits, pin changes, or shell restarts.

**Steps:**

1. Inventory the toolchain and installed dictionary languages. Resolve missing Rust/Cargo/CMake through the user's established package/tool manager; use the Omarchy skill for system/package changes. Do not independently update all desktop packages. Record versions and how they were installed; lock Rust version for reproducibility if appropriate to existing CI.
2. Build the unmodified baseline and establish an isolated test environment with temporary config/cache/data/state roots. Never repurpose shell `$HOME`; if an existing test harness isolates child-process HOME, retain its documented behavior. Ensure no credential reads or production account discovery occur.
3. Run the baseline gates below. Preserve separate baseline artifacts and the exact source SHA. Investigate failures enough to distinguish missing dependencies from code failures; do not fix unrelated product defects in this packet.
4. Prove a synthetic Qt/Quickshell composer can load with the native build without changing the installed plugin, accounts, timer, or active backend. Record launch/stop commands and verify isolation.
5. Audit inherited workflows before enabling Actions. Keep Pages, release publication, and unsolicited comment automation disabled. Decide which read-only checks to enable, with bounded concurrency and no live credentials. Adapt the published-backend gate to the verified upstream release source; a private copy has no historical GitHub release assets even though it has Git history/tags.
6. Record actual remote protection capabilities. Request PR checks when supported by the account plan; if protection is unavailable, retain the supervisor workflow and state plainly that it is procedural. Never claim model-specific protection is enforced by GitHub.

**Verification:** `cargo build --locked --bin omamail`; `make app-build`; `make validate`; `cargo clippy --locked --all-targets -- -D warnings`; `make test-backend-process`. Inspect these targets first because platform prerequisites matter. No live mail commands are needed.

**Accept when:** reproducible build instructions, isolated harness, baseline pass/failure record, dictionary inventory, and explicit CI/protection state exist. A missing tool blocks dependent tasks. A baseline product failure requires supervisor disposition, not a worker waiver.

**Deliver:** `planning/evidence/F00.md` and minimal helpers/CI changes. **Escalate:** privileged install blocked, real credentials unexpectedly needed, live desktop restart required for isolated tests, or CI requires release secrets.

## S00 — Prove Sonnet and freeze the adapter interface

**Owner:** bounded research/prototype worker; supervisor approves design. **Depends on:** F00. **Branch:** `task/S00-spelling-contract`.

**Read:** `ui/components/ComposeView.qml` (body, subject, inline `TextMenuTrigger`), `ui/components/TextMenu.qml`, installed Sonnet `.qmltypes`, official Sonnet QML docs, `ui/tests/qml/` harness examples.

**Allowed changes:** a small synthetic test/prototype under test directories and `planning/decisions/S00.md`. No production editor rewrite.

**Steps:** instantiate real Sonnet on a plain `TextEdit`; verify underline, language selection, clicked-position suggestions, replacement/undo, ignore, and persistent words. Determine missing-module and missing-dictionary behavior. Confirm that setting language/enabled locally does not rewrite global Sonnet settings. Inventory `en_US`; provision it through the approved environment setup if absent. Test one invalid word among otherwise valid words, because automatic highlighter heuristics may disable checking on mostly invalid text.

**Tests:** plain words, apostrophe, punctuation, mixed case, emoji preceding an error (UTF-16 offsets), multiple repeated misspellings, cursor elsewhere, large pasted body, session restart, and isolated personal dictionary. Capture a real highlighter screenshot with synthetic text.

**Freeze:** adapter inputs/outputs, document lifecycle, position handling, personal-word ownership, ignore scope, missing-dependency status, desired theme color, and loading fallback. Define how checking defers work during IME composition and does not lose caret/undo.

**Accept when:** actual Sonnet runtime evidence supports the interface, optional loading works, and the supervisor signs the decision. **Escalate:** QML API lacks required behavior, personal-dictionary semantics conflict, or a custom compiled plugin would be required. Do not silently switch to hand-drawn underlines or another engine.

## S01 — Add optional body spellchecking

**Depends on:** accepted S00. **Branch:** `task/S01-body-spelling`. **Covers:** S1, S4, S5.

**Read:** S00 decision, `ui/components/ComposeView.qml`, `ui/App.qml`, `ui/Service.qml`, `app/qml/Main.qml`, `Makefile`, `app/tests/test_qml_inventory.py`.

**Allowed changes:** optional spelling adapter/component under `ui/compose/`, body integration, theme-property plumbing, required resource/QML inventories, focused QML tests. Do not implement suggestions or subject conversion here.

**Steps:** load Sonnet through a separate optional component; bind it to the existing plain-text body document; pass semantic error color; handle document replacement/destruction; release resources when a composer closes; expose status without blocking editing. Use a temporary enabled/language input consistent with S00; S04 supplies persisted user settings.

**Tests:** underlines after completing words in all compose modes; content unchanged before/after checking; no extra draft-dirty/recovery events; undo/redo unchanged; cursor/selection and Unicode correct; missing plugin and dictionary yield usable editor; multiple composers remain isolated; standalone loads without Sonnet. Do not rely solely on mocked underline state.

**Accept when:** body checking works in the real highlighter with no text mutation or hard import failure, and relevant Qt tests/inventories pass. **Deliver:** matched synthetic body screenshots, focused tests, handoff. **Escalate:** source-body assignments required solely to add formatting or app startup failure when Sonnet is absent.

## S02 — Add correction, ignore, and personal dictionary actions

**Depends on:** accepted S01. **Branch:** `task/S02-spelling-menu`. **Covers:** S3, S4, S6.

**Read:** S00 decision, `ui/components/TextMenu.qml`, inline `TextMenuTrigger` in `ComposeView.qml`, `ui/components/Menu.js`, `ui/components/MenuActionRow.qml`, `docs/KEYS.md`.

**Allowed changes:** shared text-menu extension, optional spelling adapter methods, composer position/selection plumbing, menu tests. Preserve ordinary reader/editing menus with no spelling provider.

**Steps:** snapshot the clicked target and word position; offer maximum five suggestions only for that word; append Ignore for this session and Add to dictionary; apply a suggestion using the editor/Sonnet operation proven in S00; protect against stale document changes and destroyed composers. Provide keyboard navigation in the popup, preserving Cut/Copy/Paste/Select all and link actions.

**Tests:** clicked misspelling differs from caret word; same word occurs twice; emoji/non-BMP prefix; selection overlaps another word; punctuation and line breaks; popup opened then text changed; no suggestions; keyboard acceptance/Escape; one undo restores correction; correction updates recovery/dirty state; ignore does not survive process restart; added word does; personal dictionary failure is visible; opening menu alone never edits.

**Accept when:** correct target and undo behavior are demonstrated with the production menu and Sonnet. **Deliver:** menu screenshots and isolated dictionary test evidence. **Escalate:** a solution would globally modify unrelated editors/settings or replace whole draft strings.

## S03 — Extend spelling to the subject without breaking input

**Depends on:** accepted S02. **Branch:** `task/S03-subject-spelling`. **Covers:** S2–S4.

**Read:** all `subjectField` references in `ComposeView.qml`, S00 decision, `docs/KEYS.md`, compose recovery and focus tests, shell `TextField` styling contract (read only).

**Allowed changes:** a local subject editor wrapper, composer integration, focused keyboard/draft tests, required inventories. No edits to packaged Omarchy components.

**Steps:** replace/adapt the one-line subject input using a document-backed editor; retain `compose-subject-field` and used properties; preserve placeholder, selection, focus/Tab/Enter semantics, horizontal overflow, colors, font scaling, draft prefill and saved recovery. Collapse pasted CR/LF into spaces without allowing input to inject mail headers or breaking normal undo. Reuse S01/S02 behavior for underlines and menu actions.

**Tests:** empty/prefilled subject; long subject horizontal scrolling; Enter goes to body without inserting newline; Shift+Tab and Tab; multiline paste; Ctrl+Z/Ctrl+Y; IME composition; RTL/reply prefix; emoji; draft load and recovery do not spuriously mark user edits; Ctrl+, and existing compose/send shortcuts behave identically. Send behavior is tested with a synthetic executor only.

**Accept when:** both subject and body satisfy spelling requirements and existing subject interactions pass. **Deliver:** wide/compact and light/dark screenshots, focused tests. **Escalate:** required keyboard changes conflict with centralized key routing or subject adapter becomes a broad composer refactor.

## S04 — Add settings, dependency guidance, and spelling acceptance

**Depends on:** accepted S03. **Branch:** `task/S04-spelling-settings`. **Covers:** S1–S6.

**Read:** settings persistence in `ui/Service.qml`, `ui/components/SettingsPage.qml`, `ui/BarWidget.qml`, `manifest.json`, standalone settings adapter, S00 decision.

**Allowed changes:** spelling settings, adapter bindings, dependency docs, focused settings tests and full spelling acceptance evidence. No unrelated settings cleanup.

**Steps:** add an app-level spelling enabled setting (default on when available) and explicit `en_US` initial language; preserve the user's disable choice across restarts. If American English is unavailable, show a setup explanation and allow editing; do not silently substitute a different language. Keep checker availability distinct from requested enabled state. Document package/module requirements and how a missing optional module degrades. Avoid global Sonnet preference writes.

**Tests:** settings survive restart in plugin and standalone; missing module/dictionary; dictionary later installed; toggling does not mutate body/subject or reset cursor; multiple composers observe the setting; personal words and session ignore meet S6; no network/AI work caused by checking. Run `make validate` on the finished spelling branch and capture all S criteria in handoff.

**Accept when:** complete spelling behavior, graceful absence, settings and real integration evidence pass. **Escalate:** enforcing package dependencies would prevent a supported host from starting.

## E00 — Freeze export contract, capabilities, and limits

**Owner:** bounded research/prototype worker; supervisor approves design. **Depends on:** F00. **Branch:** `task/E00-export-contract`.

**Read:** `src/mail/{mod,types,account,read}.rs`, `src/backend/{mail,mod,methods,rpc}.rs`, `src/providers/imap/{mod,read}.rs`, `src/attachment/mod.rs`, `src/platform/private_fs*`, `src/platform/dirs*`, `backend-api.json`, `ui/backend/Backend.qml`, `ui/backend/Compatibility.js`, `ui/account/MailAccount.qml`, `ui/account/Model.js`, `ui/Service.qml`.

**Allowed changes:** decision record and a tiny synthetic transport/protocol test if needed. No production export implementation.

**Steps:** trace the exact current auth-to-IMAP-to-resource path; identify raw literal extraction before parsing; inspect cancellation/deadline ownership; trace unified and conversation-member IDs back to provider account/ID; choose storage primitive and atomic completion semantics. Confirm proposed 25 MiB raw limit, one per-account/two-global concurrency, and 60-second operation deadline fit current transport/dispatch limits without loosening global limits. Record any revised values for supervisor approval.

**Freeze:** method name/params/result, explicit account requirement, export capability name, method-presence guard plus compatible API/extension identity, error codes/messages, size/deadline bounds, duplicate request handling, Downloads resolution, filename policy, and cancellation commit point. Include a request/response/error table and exact owning modules. No arbitrary output paths or user-supplied server URLs in the RPC.

**Accept when:** supervisor approves a complete contract with negative cases and routing/storage evidence. **Escalate:** transport cannot preserve original bytes, current writer can leak partial files, contract revision conflicts, or testing requires real accounts.

## E01 — Retrieve exact original IMAP/Outlook message bytes

**Depends on:** accepted E00. **Branch:** `task/E01-raw-message`. **Covers:** E1, E2; backend part of E5/E7.

**Read:** E00 decision, `src/providers/imap/{mod,read,cancel}.rs`, existing IMAP controlled-server tests, native account/auth resolution. Use current OAuth handling for Outlook; do not request new Graph permissions.

**Allowed changes:** native raw retrieval operation and narrowly shared parsing/framing helpers, corresponding test fixtures. Do not change normal reader rendering or expose raw mail to QML.

**Steps:** validate account/provider/message identity before network work; fetch only the requested message with `BODY.PEEK[]`; extract exact bytes from the requested UID literal; preserve tagged status and unsolicited response handling; retain bounded allocation/deadlines and cancellation; avoid cache migrations.

**Tests:** exact bytes for CRLF, folded headers, UTF-8 and legacy encodings, multipart alternative/mixed/related, inline images, nested `.eml`, binary-encoded attachment; payload containing fake IMAP tag/FETCH text; unrelated unsolicited UID; missing/NIL/duplicate body; mismatched UID; wrong folder/account; malformed controls; empty response; non-OK completion; truncated/oversized literal; cancellation closes/stops work; capture commands proving PEEK and absence of STORE/MOVE/EXPUNGE. Confirm unread flags unchanged on a controlled server.

**Accept when:** returned bytes equal fixture bytes and the real controlled transport proves identity and no state mutation. Unit tests of string extraction alone are insufficient. **Deliver:** raw retrieval code/test commit and digest evidence. **Escalate:** UTF-8 conversion, MIME reserialization, or reader cache projection is the only proposed byte source.

## E02 — Save export safely and expose the backend operation

**Depends on:** accepted E01. **Branch:** `task/E02-export-backend`. **Covers:** E1–E3, E6–E7.

**Read:** E00 contract, `src/mail/`, `src/backend/{mail,methods,rpc,mod}.rs`, `src/attachment/mod.rs`, `src/platform/private_fs*`, `src/platform/dirs*`, API fixtures and runtime compatibility tests.

**Allowed changes:** export domain service, shared safe storage helpers where required, RPC dispatch/inventory, provider capability declarations/projections, API contract and fixtures. Do not add a CLI export command in v1 or change released pins.

**Steps:** connect explicit account resolution to E01; sanitize basename and resolve Downloads; write complete bytes privately with exclusive non-overwriting publication and cleanup; return actual identity/path/byte count. Register the method and contract cases in the current unreleased API step. Validate stock-vs-private feature detection. Reuse safe errors; raw server responses/credentials never reach notices/logs. Ensure cancellation is observed before commit and define post-commit success consistently.

**Tests:** Unicode/empty/long/control/path-like/reserved filename; extension normalization; duplicate names and concurrent exports; directory symlink/file symlink; unwritable/missing/custom Downloads; disk/write/flush/finalization failure; canceled request; 20–25 MiB message accepted according to frozen limit; over-limit refused before unbounded allocation; complete fixture digest; mode 0600; no output on malformed account/ID/unsupported provider; no partial new file on failure; committed result reports exact file. Use platform abstraction tests where feasible and retain standalone compile compatibility.

**Verification:** focused Rust tests; `cargo test --locked --features integration-test-credentials`; `python3 scripts/package-backend.py check-api`; `python3 tests/test_backend_api.py --binary target/debug/omamail --expected-version 0.10.7` (substitute the actual candidate version if changed by an accepted task). Test stock method absence explicitly, not just an increasing API number.

**Accept when:** byte-exact output and filesystem/RPC boundaries pass and contract fixture is meaningful. **Deliver:** negative test evidence plus separate security verdict with scope. **Escalate:** retaining `.eml` partials, silently truncating, broad filesystem permissions, or bypassing handshake checks.

## E03 — Add message export UI and correct routing

**Depends on:** accepted E02; coordinate shared UI editing with S03/S04. **Branch:** `task/E03-export-ui`. **Covers:** E3–E7 end to end.

**Read:** `ui/components/MessageMenu.qml`, `ui/App.qml`, `ui/Service.qml`, `ui/account/MailAccount.qml`, unified-account routing, conversation rail actions, `ui/backend/Backend.qml`, E00 contract.

**Allowed changes:** message-menu action, service/account routing, transient busy/result/error state, availability projection, focused menu/account/UI tests. No bulk action, auto-open, or auto-send behavior.

**Steps:** add Save as .eml to the single-message menu and reader's existing menu path; capture owning account and provider message ID; check provider and actual backend method support; call the native export; suppress duplicate in-flight requests; preserve current selection/read state. Report actual saved filename/directory and safe errors. Hide or clearly disable unavailable actions according to project capability rules. Export on a conversation rail uses member ID, not the thread/list root.

**Tests:** two accounts with identical UID/folder strings; unified inbox; switch account after click; change selection before callback; remove/sign out account in flight; opened menu belongs to a different row than selection; selected conversation member; double click; unsupported provider; stock API 5; stock API 6 without method; private API 6 with method; disconnected backend; expired auth; error result; no false success after timeout; ordinary read state/selection untouched. Verify all supported UI entry points with a synthetic real backend operation, not just a mocked menu callback.

**Accept when:** one selected message from the right account exports through the production path and saved output digest matches the fixture. **Deliver:** busy/success/error screenshots and all E criteria evidence. **Escalate:** route relies on active account after async dispatch or writes through QML/file scripts.

## I00 — Integrate both features and run acceptance matrix

**Owner:** integration worker; independent reviewer follows. **Depends on:** accepted S04 and E03. **Branch:** `integration/spelling-eml`.

**Allowed changes:** reviewed conflict resolutions, integration regressions, acceptance evidence. Product redesign or broad refactor requires supervisor reassignment.

**Steps:** integrate accepted feature commits; inspect any overlap in composer/App/service/settings; record exactly which commits are included. Run the matrix in REVIEW-GATE. Validate combined behavior with synthetic accounts/mail and Sonnet present/absent. Open an exported fixture in an independent MIME reader/mail client and compare headers, attachments/digests, Unicode, and multipart bodies. Recheck draft recovery and export identity across account switches.

**Required commands:** build candidate backend and standalone host; `make validate`; `cargo clippy --locked --all-targets -- -D warnings`; `make test-backend-process`; candidate API fixtures; `python3 tests/test_backend_api.py --binary /path/to/verified/upstream/omamail --expected-version 0.10.7 --released`. Obtain the upstream binary through the existing checksum-verifying release tooling into isolated storage, never by reinstalling the live backend.

**Accept when:** all changed behavior passes, baseline-only failures are proven and separately adjudicated, required actual UI evidence is complete, and no unseen feature commits are included. **Deliver:** integration handoff with criterion-to-test mapping and reproduction commands. **Escalate:** any new regression, skipped affected boundary, or a test invocation touches the daily account store.

## R00 — Prepare private runtime installation and rollback

**Owner:** release-preparation worker with supervisor design review. **Depends on:** accepted I00. **Branch:** `task/R00-private-runtime`.

**Read:** `docs/BACKEND-RUNTIME.md`, `scripts/backend-runtime.py`, `dev`, release/install tests, runtime compatibility helpers, existing local-build metadata behavior.

**Allowed changes:** private build/install documentation and narrowly scoped tooling/metadata required to install an identified candidate. No deployment, upstream publishing, real mailbox migration, or public release.

**Steps:** settle private version/provenance and pin rules without impersonating an upstream asset; preserve method/extension checks; build candidate, record source and binary hashes; rehearse setup with synthetic XDG roots; document how the active plugin will load the correct binary; prove ordinary update/reinstall paths cannot silently downgrade the feature or fetch a same-numbered stock binary. Decide how future upstream updates are integrated deliberately. A verified local install with truthful provenance is acceptable; private GitHub releases are optional, not assumed.

Prepare exact backup and restore commands for plugin checkout/registration, binary plus runtime metadata, relevant settings, and environment. Keep backups private/local and avoid putting credentials into the repo. Restore the previous plugin and backend as a pair; preserve accounts, drafts, caches, keyring and cleanup script. Note that setting `OMAMAIL_BIN` in a later command cannot affect an already-running shell. Rehearse startup, feature availability, and rollback in the isolated environment.

**Accept when:** candidate provenance is unambiguous; install and rollback both demonstrated in isolation; all tooling changes have focused tests and affected validation rerun. **Deliver:** `planning/decisions/R00.md` and a step-by-step deployment runbook with expected outputs. **Escalate:** downloader needs embedded credentials, same upstream version hides private content, or release script would publish publicly.

## J00 — Final supervisor judgment

**Owner:** supervising Codex only. **Depends on:** accepted R00 and current integrated candidate.

Use [REVIEW-GATE.md](REVIEW-GATE.md) and [templates/JUDGE.md](templates/JUDGE.md). Obtain independent fresh-context review, inspect source and test evidence, reproduce decisive checks, and validate all required scenarios at the final candidate SHA. Output ACCEPT, REVISE, or BLOCKED with a separate security verdict. No worker self-approval or green-CI-only acceptance. Any code change after the reviewed SHA requires renewed review and affected tests.

**Deliver:** an exact-commit judge record in the private PR or a later documentation commit that identifies the earlier tested candidate SHA. The evidence record does not need to contain its own eventual commit SHA. ACCEPT makes the candidate eligible for an explicitly assigned deployment task; it does not itself claim installation happened.

## D01 — Install the accepted candidate on the laptop

**Owner:** supervisor or explicitly assigned deployment worker. **Depends on:** J00 ACCEPT and Chris's authorization to deploy at that time. Current setup/planning authorization does not start D01.

Follow the reviewed R00 runbook. Confirm candidate SHA/hash and no unsaved compose window before any required shell restart. Create and verify backups, install the matching plugin/runtime through supported user paths, restart only as required, and verify version/API/extension identity. Smoke-test spelling with synthetic draft text without sending; save a synthetic test message when available. Any live-message export is local only. Confirm existing accounts, calendar, draft recovery, and cleanup CLI still resolve correctly; do not run the cleanup script as a smoke test because it moves mail.

If installation or core behavior fails, perform the rehearsed rollback immediately and report the failed stage. Record actual install/rollback results, paths, candidate identity and limitations. Do not declare deployment complete while the running backend is still the old binary or while runtime identity is unverified.

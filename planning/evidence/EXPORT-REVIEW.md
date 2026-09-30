# Export review follow-up

Reviewed source: `066c7441271021b632a19ff75a5f3274355af3ad`.
Base: `d88833e44ae64d8b72ebb7ab3a1f014b16fd89f5`.
Environment: Linux, Rust 1.98.1, Qt 6.11.2. All fixtures use synthetic
accounts/messages and temporary HOME/XDG directories.

## Findings resolved

- Cancellation previously depended on reading a closed request channel. A full
  32-request window or blocked response delivery prevented that observation.
  Cancellation now independently wakes and drops the owned dispatch futures.
- The input thread could also block submitting to the 16-frame queue. A Unix
  output observer detects closure independently and wakes that submission by
  cancelling dispatch. The process test submits 60 stalled requests, observes
  all 32 active sockets, closes stdout, and requires a prompt unsuccessful exit.
- An oversized announced IMAP literal left unread bytes on a pooled connection.
  Failed raw fetches now discard their connection. A loopback regression proves
  EOF on the refused socket and a fresh connection for the next message.
- Malformed UID/folder syntax now maps to `mail_export_message_invalid` after
  ordinary parameter validation. Empty, wrong-type, control, and oversized RPC
  parameters retain their general `invalid_params` refusal.

The first three regression tests failed before their fixes. The earlier
single-request cancellation test now waits for actual work to start before
raising cancellation. Clean stdin EOF and quit still drain accepted requests.

## Validation

| Command or scenario | Result |
| --- | --- |
| `make validate` | Exit 2: Rust/JS/shell passed; QML 1009 passed, 8 failed, no skips |
| `cargo test --locked --features integration-test-credentials` (inside validate) | All targets pass; library 593 passed, 11 ignored; stdio 4 passed |
| Independent focused tests | Raw retrieval 19, storage/export 17, scheduler 6, stdio 4 passed |
| Real `serve` with registered synthetic account and loopback IMAP | Exact multipart MIME wire bytes saved with mode 0600; half-close during FETCH completes; close-all-pipes during FETCH closes socket and leaves no file |
| `make test-app-qml qml-check` | Exit 0; existing QML warnings retained |
| `omarchy plugin validate .` and `git diff --check` | Exit 0 |
| `cargo clippy --locked --all-targets` | Exit 0; only existing search.rs:235/694 and mail/tests.rs:88 warnings |
| `python3 tests/test_backend_api.py --binary target/debug/omamail` | Exit 0; API 6, 31 methods, 179 advertised |
| `python3 tests/test_backend_process.py` | Exit 0; real Quickshell/native bridge scenarios pass |
| `python3 tests/test_agent_native_bridge.py` | Exit 0; 22 passed |

Full validation ran on the fixes before final formatting and the Windows
unused-variable cleanup. The independent reviewer reran the affected Rust and
stdio tests on the final source contents and recorded matching SHA-256 hashes.
Logs, the process harness, and full independent report remain in ignored
`artifacts/final-review/`.

## Baseline adjudication and judgment

A detached checkout of the exact base, built from its own source, reproduces
all eight `KeyboardReaderNavigation` failures with the same Qt/software-renderer
and native-test bridge environment. Its focused suite reports 5 passed,
8 failed, no skips. Both feature branches fail the same eight cases. These are
accepted as inherited regression limitations for this review; `make validate`
is not reported green. Export identity/menu tests and the real process checks
cover the changed paths independently.

The fresh reviewer inspected the entire export patch and the follow-up fixes,
verified the final source hashes, and found no remaining must-fix Linux defect.
Security: **PASS for the reviewed Linux export boundaries**. This is not a
repository-wide or cross-platform certification. A concurrent same-user rename
of Downloads can make the returned lexical path stale; the anchored write
remains safe. Windows/macOS runtime behavior is not verified.

Release acceptance: **REVISE** because the planned combined-feature integration,
private runtime provenance/rollback, and final acceptance matrix are unfinished
(I00, R00, J00). This records completion of the defect-review follow-up, not
permission to merge, release, or replace the daily runtime. Screenshots remain
synthetic UI previews and do not establish real-account integration.

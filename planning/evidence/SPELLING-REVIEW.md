# Spelling review follow-up

Reviewed source: `c32dcfab9c244f6771509ec3a12fe9b2cb07525c`.
Base: `d88833e44ae64d8b72ebb7ab3a1f014b16fd89f5`.
Environment: Linux, Rust 1.98.1, Qt 6.11.2, Sonnet 6.29.0,
hunspell-en_us 2026.02.25-1. Fixtures use synthetic text and temporary HOME/XDG
roots. Scope is the composer body; subject checking remains deferred.

## Findings resolved

- Sonnet Ignore can emit textChanged during rehighlighting even with its visual
  highlighter inactive. The composer previously treated the unchanged text as
  a user edit. It now compares plain text before updating dirty state, recovery,
  or the correction-menu revision. Ignore and shared personal-word updates keep
  unchanged focused drafts clean, with selection and undo history preserved.
- Sonnet's process-wide ignore list changed another composer's checking answer
  without updating its cached underlines. Live adapters now broadcast checker
  changes and unregister on destruction. Other composers recheck their ranges.
- Ctrl+. previously refused misspellings with no replacements. It now opens
  the menu so keyboard users can reach Ignore and Add to dictionary.

The fresh independent reviewer reproduced the three issues with real Sonnet,
then verified the fixes and their source hashes. Nine independent checks pass,
including adapter destruction, Loader off/on, real text edits, Undo, and Redo.
Four tracked regressions cover menu Ignore, a separate document's session
Ignore, shared personal-word changes, and the no-suggestions keyboard path.

## Validation

| Command or scenario | Result |
| --- | --- |
| `make validate` | Exit 2: Rust/JS/shell passed; QML 1053 passed, 8 failed, no skips |
| Rust targets inside validate | All pass; library 555 passed, 11 ignored |
| Actual Sonnet adapter/composer/menu suites | 9 / 15 / 16 passed, no failures or skips |
| Independent fix verification | 9 passed, no failures or skips |
| Real missing-Sonnet runner with isolated qt.conf | Production composer edit/Undo 3 passed; standalone composition fixture 30 passed |
| `make test-js test-shell test-app-qml qml-check` | Exit 0; existing QML warnings retained |
| `QT_QPA_PLATFORM=offscreen ctest --test-dir app/build --output-on-failure --no-tests=error -R '^tst_settings$'` | Exit 0; native settings test passed |
| `cmake --build app/build -j2` | Exit 0; rebuilt standalone app with the new session library embedded |
| `QT_QPA_PLATFORM=offscreen ctest --test-dir app/build --output-on-failure --no-tests=error -R '^tst_(settings|resources)$'` | Exit 0; settings and embedded-resource tests passed |
| `omarchy plugin validate .` and `git diff --check` | Exit 0 |
| `python3 tests/test_backend_api.py --binary target/debug/omamail` | Exit 0; unchanged API 6, 30 methods, 178 advertised |
| `python3 tests/test_backend_process.py` | Exit 0; real native bridge scenarios pass |

The missing-module standalone fixture does not include the compiled
NativeProcess host; it proves graceful optional loading, not full host
integration. Logs, restricted-runner fixtures, and independent review remain
in ignored `artifacts/final-review/`. Screenshots show synthetic production-UI
previews, not persisted settings across a real host restart.

## Baseline adjudication and judgment

The exact base, built from its own source under the same environment, reproduces
the same eight `KeyboardReaderNavigation` failures. Those are accepted as
inherited regression limitations; full validation is not reported green.
The known first-line-only underline for a word wrapping across visual lines
remains the documented S01 limitation.

Security: **PASS for the reviewed spelling/configuration changes**. The fresh
review checked local-only spelling, app-owned private configuration, optional
loading, and absence of global dictionary/preferences writes in isolated tests.
It found no additional defect in the fixes. This is scoped to the changed
boundary, not a certification of the upstream application.

Release acceptance: **REVISE**. Fresh real Service/FileView restart evidence for
personal-word persistence and session-ignore lifetime, installed-dictionary
rediscovery, and IME behavior still need acceptance evidence. The current
“reopen settings” installation guidance is an unverified recovery claim because
the service probe stays loaded. Combined-feature integration and private-runtime
provenance/rollback remain I00/R00/J00 work. No merge, release, or daily-runtime
replacement approval is recorded here.

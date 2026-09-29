import QtQuick
import org.kde.sonnet as Sonnet

// Optional spelling adapter (S01). This is the only production file that
// imports org.kde.sonnet, so it is always created through a Loader: a machine
// without the module gets a load error and an editor that still works, rather
// than a composer that refuses to open.
//
// The interface is frozen by planning/decisions/S00.md. Do not rename the
// properties or functions without changing that record.
//
// Two Sonnet behaviours the callers must respect (S00 §2):
//  * corrections must call suggestions() for the same position immediately
//    before replaceWord(), or Sonnet inserts instead of replacing;
//  * the underline colour is Qt's fixed red; misspelledColor has no effect.
Item {
  id: adapter

  // The editor's QQuickTextDocument. Never assigned null once set: Sonnet's
  // setQuickDocument dereferences the parent without a null check. Release the
  // highlighter by destroying the adapter (unload its Loader), not by clearing
  // this.
  property var document: null
  // `enabled` is reused from Item rather than redeclared: the adapter is
  // non-visual, so this keeps the name frozen by S00 without shadowing
  // QQuickItem.enabled (which qmllint rejects). The owning Loader is inactive
  // when spelling is off, so this is a runtime toggle within a loaded adapter.
  property string language: "en_US"
  // App-owned words to treat as correct (S00 §4). Persistence belongs to the
  // settings layer (S04); this property only applies them.
  property var personalWords: []

  readonly property bool available: highlighter.spellCheckerFound
  // "ready", "disabled", or "no-dictionary". A missing module is reported by
  // the owning Loader as Loader.Error, not here.
  readonly property string status: !enabled ? "disabled"
                                            : (available ? "ready" : "no-dictionary")

  Component.onCompleted: applySettings()
  onEnabledChanged: applySettings()
  onLanguageChanged: applySettings()
  onPersonalWordsChanged: applyPersonalWords()

  // Returns { word, misspelled, suggestions }. Call this for the position of a
  // click or the caret; it also primes applyCorrection for the same position.
  function inspect(position) {
    if (!available || document === null) return { word: "", misspelled: false, suggestions: [] }
    var at = Math.max(0, Math.floor(position))
    var list = highlighter.suggestions(at, 5)
    return {
      word: String(highlighter.wordUnderMouse),
      misspelled: highlighter.wordIsMisspelled === true,
      suggestions: list || []
    }
  }

  // Applies a suggestion. The priming call is required: replaceWord anchors the
  // replacement to the word the last suggestions() call remembered.
  function applyCorrection(position, replacement) {
    if (!available || document === null) return false
    var at = Math.max(0, Math.floor(position))
    highlighter.suggestions(at, 0)
    highlighter.replaceWord(String(replacement), at)
    return true
  }

  // Session-only ignore (S00 §4): never written to the user's dictionary.
  function ignoreForSession(word) {
    if (!available || !word) return
    highlighter.ignoreWord(String(word))
  }

  function applySettings() {
    if (!available) return
    if (enabled) {
      highlighter.setCurrentLanguage(language)
      applyPersonalWords()
    }
    highlighter.active = enabled
  }

  function applyPersonalWords() {
    if (!available) return
    for (var i = 0; i < personalWords.length; i++) {
      var word = String(personalWords[i])
      if (word !== "") highlighter.ignoreWord(word)
    }
  }

  onDocumentChanged: if (document !== null) highlighter.document = document

  Sonnet.SpellcheckHighlighter {
    id: highlighter
    active: false
    automatic: false // deterministic language; avoids the too-many-errors heuristic
  }
}

import QtQuick
import org.kde.sonnet as Sonnet

// Optional spelling adapter (S01). This is the only production file that
// imports org.kde.sonnet, so it is always created through a Loader: a machine
// without the module gets a load error and an editor that still works, rather
// than a composer that refuses to open.
//
// The interface is frozen by planning/decisions/S00.md, with one later change:
// the underline is drawn by the caller, not by Sonnet. Sonnet's QML highlighter
// paints the misspelled word red as well as underlining it (its errorFormat
// sets a red foreground; misspelledColor is inert), unlike the QWidget one,
// which only underlines. So the highlighter here stays inactive and is used
// only as a checker: it never writes any format to the document.
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

  // Every misspelled word that is finished, as UTF-16 {start, end} offsets into
  // `text`. A word is finished only when something follows it, so the word the
  // user is still typing is never marked: the underline appears once a
  // delimiter (space, punctuation, newline) has been typed after it.
  function misspelledRanges(text) {
    var ranges = []
    if (!available || !enabled || !text) return ranges
    var length = text.length
    var index = 0
    while (index < length) {
      if (!isWordChar(text.charAt(index))) { index += 1; continue }
      var start = index
      while (index < length && isWordChar(text.charAt(index))) index += 1
      var end = index
      // Nothing follows: this is the word still being typed. Earlier finished
      // words have already been collected, so stop.
      if (end >= length) break
      var wordStart = start
      var wordEnd = end
      while (wordStart < wordEnd && isApostrophe(text.charAt(wordStart))) wordStart += 1
      while (wordEnd > wordStart && isApostrophe(text.charAt(wordEnd - 1))) wordEnd -= 1
      if (wordEnd > wordStart) {
        var word = text.substring(wordStart, wordEnd)
        if (highlighter.isWordMisspelled(word)) ranges.push({ start: wordStart, end: wordEnd })
      }
    }
    return ranges
  }

  function isWordChar(character) {
    // Letters and digits across the common scripts, plus the apostrophes that
    // sit inside a word. A surrogate half (an emoji) matches nothing and is
    // skipped, so it is never treated as a word.
    return /[0-9A-Za-z\u00C0-\u024F\u0300-\u036F\u0370-\u03FF\u0400-\u04FF'\u2019]/.test(character)
  }

  function isApostrophe(character) { return character === "'" || character === "\u2019" }

  function applySettings() {
    if (!available) return
    if (enabled) {
      highlighter.setCurrentLanguage(language)
      applyPersonalWords()
    }
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
    // Never active: Sonnet must not paint the document (it would colour the
    // word red as well as underlining it). Query methods work while inactive.
    active: false
    automatic: false
  }
}

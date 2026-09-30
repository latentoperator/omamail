import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.sonnet as Sonnet

// Interactive playground — a throwaway tool for trying the spelling adapter
// contract by hand, outside the composer.
//
// Run it on the desktop (not offscreen):
//   /usr/lib/qt6/bin/qml tests/spellcheck/playground.qml
//
// Type in the body: misspelled words get Qt's red underline. Put the caret in
// a word to see Sonnet's suggestions; click one to correct it. The correction
// uses the adapter's correction rule — prime with
// suggestions(position, 0) immediately before replaceWord(word, position) —
// because without the prime Sonnet inserts instead of replacing.
ApplicationWindow {
  id: win
  width: 860
  height: 560
  visible: true
  title: "Omamail spelling playground"

  property var suggestions: []
  property string inspectedWord: ""
  property bool inspectedMisspelled: false

  function inspect() {
    var position = body.cursorPosition
    suggestions = highlighter.suggestions(position, 5)
    inspectedWord = highlighter.wordUnderMouse
    inspectedMisspelled = highlighter.wordIsMisspelled
  }

  function correct(replacement) {
    var position = body.cursorPosition
    highlighter.suggestions(position, 0) // prime the word length first
    highlighter.replaceWord(replacement, position)
    inspect()
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 8

    Text {
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      text: "Type below. Misspelled words get a red underline. Put the caret in a word to see " +
            "suggestions; click one to correct it. Press Ctrl+Z to undo a correction."
    }

    TextEdit {
      id: body
      Layout.fillWidth: true
      Layout.fillHeight: true
      textFormat: TextEdit.PlainText
      wrapMode: TextEdit.Wrap
      selectByMouse: true
      font.pixelSize: 18
      text: "This sentance has a mispelled wrod and teh rest is fine."
      onCursorPositionChanged: win.inspect()
    }

    Text {
      Layout.fillWidth: true
      text: win.inspectedWord === ""
            ? "Caret is not in a word."
            : (win.inspectedMisspelled ? "Misspelled: " + win.inspectedWord : "Looks correct: " + win.inspectedWord)
    }

    Row {
      spacing: 6
      Repeater {
        model: win.suggestions
        Button {
          text: modelData
          onClicked: win.correct(modelData)
        }
      }
    }
  }

  Sonnet.SpellcheckHighlighter {
    id: highlighter
    document: body.textDocument
    active: true
    automatic: false
  }
}

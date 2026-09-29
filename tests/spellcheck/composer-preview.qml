import QtQuick
import "../../ui/components" as Omamail

// S01 preview: the real ComposeView with the optional spelling adapter, shown
// in a window so the underline behaviour and suggestion UX can be tuned by hand
// without a mail account and without touching the installed plugin.
//
// Run it on the desktop (the mock shell imports stand in for the Omarchy shell):
//   /usr/lib/qt6/bin/qml -I ui/tests/qml/imports tests/spellcheck/composer-preview.qml
Rectangle {
  id: root
  width: 1040
  height: 780
  color: "#101014"

  property var suggestions: []
  property string inspectedWord: ""
  property bool inspectedMisspelled: false
  property string adapterStatus: "loading"

  function findItem(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var values = item.children || []
    for (var i = 0; i < values.length; i++) {
      var found = findItem(values[i], name)
      if (found) return found
    }
    return null
  }

  function refresh() {
    var adapter = compose.spellingAdapter
    var body = findItem(compose, "compose-body-editor")
    adapterStatus = compose.spellingStatus
    if (!adapter || !body) { suggestions = []; inspectedWord = ""; inspectedMisspelled = false; return }
    var info = adapter.inspect(body.cursorPosition)
    suggestions = info.suggestions
    inspectedWord = info.word
    inspectedMisspelled = info.misspelled
  }

  function correct(replacement) {
    var adapter = compose.spellingAdapter
    var body = findItem(compose, "compose-body-editor")
    if (!adapter || !body) return
    adapter.applyCorrection(body.cursorPosition, replacement)
    refresh()
  }

  function ignoreWord() {
    var adapter = compose.spellingAdapter
    if (adapter && inspectedWord !== "") adapter.ignoreForSession(inspectedWord)
    refresh()
  }

  QtObject {
    id: mailService
    property bool sendPending: false
    property bool sending: false
    property int sendSecondsRemaining: 10
    property var lastSent: null
    property var recipientContacts: []
    property var sendAsAliases: []
    property var sendIdentities: [
      ({ email: "me@example.com", accountId: "me@example.com", label: "me" })
    ]
    property string accountEmail: "me@example.com"
    property string activeAccountId: "me@example.com"
    function preferredSendAs(_r) { return null }
    function switchTo(_id) { return true }
    function refreshRecipientContacts() {}
    function send(_f) { return true }
    function copyText(_t) { return true }
    function clipboardAttachment(_dir, callback) { callback({ ok: false, error: "no-image" }); return true }
  }

  Connections {
    id: bodyConnections
    function onCursorPositionChanged() { root.refresh() }
  }

  Omamail.ComposeView {
    id: compose
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: panel.top
    service: mailService
    textColor: "#e8e8ee"
    backgroundColor: "#101014"
    accentColor: "#ff8a3d"
    dimColor: "#a9a9ae"
    dimmerColor: "#737377"
    popupBackgroundColor: "#1a1a1e"
    popupBorderColor: "#3c3c41"
    panelFontFamily: "sans"
  }

  Rectangle {
    id: panel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 140
    color: "#1a1a1e"

    Column {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      Text {
        color: "#a9a9ae"
        font.pixelSize: 13
        text: "spelling: " + root.adapterStatus +
              "   word: " + (root.inspectedWord === "" ? "(caret not in a word)" : root.inspectedWord) +
              (root.inspectedMisspelled ? "  [misspelled]" : "")
      }

      Row {
        spacing: 6
        Repeater {
          model: root.suggestions
          Rectangle {
            width: suggestionLabel.implicitWidth + 16
            height: 28
            radius: 4
            color: "#2a2a30"
            Text { id: suggestionLabel; anchors.centerIn: parent; color: "#e8e8ee"; text: modelData }
            MouseArea { anchors.fill: parent; onClicked: root.correct(modelData) }
          }
        }
      }

      Row {
        spacing: 12

        Rectangle {
          width: toggleLabel.implicitWidth + 16
          height: 28
          radius: 4
          color: "#2a2a30"
          Text { id: toggleLabel; anchors.centerIn: parent; color: "#e8e8ee"
                 text: compose.spellingEnabled ? "spelling: on" : "spelling: off" }
          MouseArea { anchors.fill: parent; onClicked: { compose.spellingEnabled = !compose.spellingEnabled; root.refresh() } }
        }

        Rectangle {
          width: ignoreLabel.implicitWidth + 16
          height: 28
          radius: 4
          color: "#2a2a30"
          Text { id: ignoreLabel; anchors.centerIn: parent; color: "#e8e8ee"; text: "ignore for session" }
          MouseArea { anchors.fill: parent; onClicked: root.ignoreWord() }
        }
      }

      Text {
        color: "#737377"
        font.pixelSize: 12
        text: "Type in the body; red underlines mark misspellings (Qt's fixed red — S00 D1). " +
              "Caret in a word shows suggestions; Ctrl+Z undoes a correction."
      }
    }
  }

  Component.onCompleted: {
    compose.begin("new", null, "", [])
    bodyConnections.target = findItem(compose, "compose-body-editor")
    refresh()
  }
}

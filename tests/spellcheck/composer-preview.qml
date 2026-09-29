import QtQuick
import qs.Commons
import "../../ui/components" as Omamail

// S01 preview: the real ComposeView with the optional spelling adapter, plus a
// slim suggestion strip for tuning. Every colour and the font come from the
// composer's own theme properties, so this is what the app would inherit.
//
// Run it on the desktop (the mock shell imports stand in for the Omarchy shell):
//   /usr/lib/qt6/bin/qml -I ui/tests/qml/imports tests/spellcheck/composer-preview.qml
Rectangle {
  id: root
  width: 1040
  height: 780
  color: compose.backgroundColor

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
    anchors.bottom: strip.top
    service: mailService
    textColor: "#e8e8ee"
    backgroundColor: "#101014"
    accentColor: "#ff8a3d"
    dimColor: "#a9a9ae"
    dimmerColor: "#737377"
    popupBackgroundColor: "#1a1a1e"
    popupBorderColor: "#3c3c41"
    panelFontFamily: "sans"
    errorColor: "#ff5555"
  }

  // A slim strip, coloured from the composer's theme roles, standing in for the
  // S02 suggestion UI while the behaviour is tuned.
  Rectangle {
    id: strip
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Style.space(30)
    color: compose.popupBackgroundColor

    Rectangle {
      anchors.top: parent.top
      width: parent.width
      height: 1
      color: compose.popupBorderColor
    }

    Row {
      anchors.fill: parent
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(10)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        color: compose.dimColor
        font.family: compose.panelFontFamily
        font.pixelSize: Style.font.caption
        text: inspectedWord === ""
              ? (adapterStatus === "ready" ? "" : "spelling: " + adapterStatus)
              : (inspectedMisspelled ? inspectedWord : "")
      }

      Repeater {
        model: root.suggestions
        Text {
          anchors.verticalCenter: parent.verticalCenter
          color: compose.accentColor
          font.family: compose.panelFontFamily
          font.pixelSize: Style.font.caption
          text: modelData
          MouseArea { anchors.fill: parent; onClicked: root.correct(modelData) }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.inspectedMisspelled && root.inspectedWord !== ""
        color: compose.dimColor
        font.family: compose.panelFontFamily
        font.pixelSize: Style.font.caption
        text: "ignore"
        MouseArea { anchors.fill: parent; onClicked: root.ignoreWord() }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        color: compose.dimColor
        font.family: compose.panelFontFamily
        font.pixelSize: Style.font.caption
        text: compose.spellingEnabled ? "spelling on" : "spelling off"
        MouseArea { anchors.fill: parent; onClicked: { compose.spellingEnabled = !compose.spellingEnabled; root.refresh() } }
      }
    }
  }

  Component.onCompleted: {
    compose.begin("new", null, "", [])
    bodyConnections.target = findItem(compose, "compose-body-editor")
    refresh()
  }
}

import QtQuick
import "../../ui/components" as Omamail

// S01 preview: the real ComposeView with the optional spelling adapter, for
// hands-on tuning of the underline and the suggestion menu.
//
//   right-click a misspelled word  -> suggestions, Ignore, Add to dictionary
//   Ctrl+.                         -> the same, anchored at the caret word
//
// Run it on the desktop (the mock shell imports stand in for the Omarchy shell):
//   /usr/lib/qt6/bin/qml -I ui/tests/qml/imports tests/spellcheck/composer-preview.qml
Rectangle {
  id: root
  width: 1040
  height: 780
  color: compose.backgroundColor

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

  Omamail.ComposeView {
    id: compose
    anchors.fill: parent
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

  Component.onCompleted: compose.begin("new", null, "", [])
}

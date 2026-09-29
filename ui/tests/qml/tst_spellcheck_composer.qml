import QtQuick
import QtTest
import "../../components" as Omamail

// S01: the real composer attaches the optional spelling adapter to its body
// document, does not change the draft while checking, and unloads cleanly when
// disabled. Underlines are proven by the adapter contract test and the S00
// probe; here the point is the wiring, not the highlighter.
Item {
  width: 900
  height: 600

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
    property var spellingPersonalWords: []
    function preferredSendAs(_r) { return null }
    function switchTo(_id) { return true }
    function refreshRecipientContacts() {}
    function send(_f) { return true }
    function copyText(_t) { return true }
    function clipboardAttachment(_dir, callback) { callback({ ok: false, error: "no-image" }); return true }
    function addPersonalWord(word) {
      if (word && spellingPersonalWords.indexOf(word) < 0) {
        var words = spellingPersonalWords.slice(); words.push(word); spellingPersonalWords = words
      }
    }
  }

  Omamail.ComposeView {
    id: compose
    anchors.fill: parent
    service: mailService
    spellingPersonalWords: mailService.spellingPersonalWords
    textColor: Qt.rgba(1, 1, 1, 1)
    backgroundColor: Qt.rgba(0.06, 0.06, 0.06, 1)
    accentColor: Qt.rgba(1, 0.5, 0, 1)
    dimColor: Qt.rgba(0.67, 0.67, 0.67, 1)
    dimmerColor: Qt.rgba(0.47, 0.47, 0.47, 1)
    popupBackgroundColor: Qt.rgba(0.13, 0.13, 0.13, 1)
    popupBorderColor: Qt.rgba(0.3, 0.3, 0.3, 1)
    panelFontFamily: "sans"
  }

  TestCase {
    name: "ComposeSpelling"
    when: windowShown

    function named(item, objectName) {
      if (!item) return null
      if (item.objectName === objectName) return item
      var values = item.children || []
      for (var i = 0; i < values.length; i++) {
        var found = named(values[i], objectName)
        if (found) return found
      }
      return null
    }

    function init() { compose.begin("new", null, "", []) }

    function test_body_adapter_attaches_and_checking_does_not_mutate() {
      var body = named(compose, "compose-body-editor")
      verify(body, "the composer owns a body editor")
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) {
        skip("spelling unavailable (" + compose.spellingStatus + ")")
        return
      }
      body.text = "This sentance has a mispelled wrod."
      var before = body.text
      var info = compose.spellingAdapter.inspect(body.text.indexOf("mispelled"))
      compare(info.misspelled, true)
      compare(info.word, "mispelled")
      // Merely inspecting must not change the draft.
      compare(body.text, before)
    }

    function test_a_correction_changes_the_body_and_undo_restores_it() {
      var body = named(compose, "compose-body-editor")
      verify(body)
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) { skip("spelling unavailable"); return }
      body.text = "a mispelled wrod here"
      var before = body.text
      var at = body.text.indexOf("mispelled")
      var info = compose.spellingAdapter.inspect(at)
      compose.spellingAdapter.applyCorrection(at, info.suggestions[0])
      verify(body.text !== before)
      body.undo()
      compare(body.text, before)
    }

    function test_underline_ranges_require_a_finished_word() {
      var body = named(compose, "compose-body-editor")
      verify(body)
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) { skip("spelling unavailable"); return }
      body.text = "a wrod"
      wait(250) // past the debounce
      compare(compose.spellingRanges.length, 0)
      body.text = "a wrod "
      wait(250)
      compare(compose.spellingRanges.length, 1)
      compare(compose.spellingRanges[0].start, 2)
      compare(compose.spellingRanges[0].end, 6)
    }

    function test_right_click_offers_suggestions_for_the_clicked_word() {
      var body = named(compose, "compose-body-editor")
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) { skip("spelling unavailable"); return }
      body.text = "a mispelled wrod "
      wait(250)
      var box = body.positionToRectangle(body.text.indexOf("mispelled"))
      mouseClick(body, box.x + 2, box.y + box.height / 2, Qt.RightButton)
      wait(20)
      var menu = named(compose, "compose-text-menu")
      verify(menu.opened, "the text menu opened")
      compare(menu.spellingMisspelled, true)
      compare(menu.spellingWord, "mispelled")
      verify(menu.spellingSuggestions.length > 0)
      // Choosing the first suggestion replaces the clicked word.
      menu.chooseSuggestion(0)
      wait(20)
      verify(body.text.indexOf("mispelled") === -1)
    }

    function test_ignore_for_session_stops_marking_the_word() {
      var body = named(compose, "compose-body-editor")
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) { skip("spelling unavailable"); return }
      body.text = "the floobert here "
      wait(250)
      compare(compose.spellingRanges.length, 1)
      var box = body.positionToRectangle(body.text.indexOf("floobert"))
      mouseClick(body, box.x + 2, box.y + box.height / 2, Qt.RightButton)
      wait(20)
      var menu = named(compose, "compose-text-menu")
      compare(menu.spellingWord, "floobert")
      menu.ignoreWordRow.activated()
      wait(250)
      compare(compose.spellingRanges.length, 0)
    }

    function test_add_to_dictionary_stops_marking_the_word() {
      var body = named(compose, "compose-body-editor")
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) { skip("spelling unavailable"); return }
      body.text = "the blorptar here "
      wait(250)
      compare(compose.spellingRanges.length, 1)
      var box = body.positionToRectangle(body.text.indexOf("blorptar"))
      mouseClick(body, box.x + 2, box.y + box.height / 2, Qt.RightButton)
      wait(20)
      var menu = named(compose, "compose-text-menu")
      compare(menu.spellingWord, "blorptar")
      menu.addToDictionaryRow.activated()
      wait(250)
      compare(compose.spellingRanges.length, 0)
    }

    function test_ctrl_period_opens_suggestions_at_the_caret_word() {
      var body = named(compose, "compose-body-editor")
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      if (!compose.spellingAvailable) { skip("spelling unavailable"); return }
      body.text = "the mispelled here "
      wait(250)
      body.cursorPosition = body.text.indexOf("mispelled") + 2
      body.forceActiveFocus()
      keyClick(Qt.Key_Period, Qt.ControlModifier)
      wait(20)
      var menu = named(compose, "compose-text-menu")
      verify(menu.opened, "the caret shortcut opened the menu")
      compare(menu.spellingWord, "mispelled")
      verify(menu.spellingSuggestions.length > 0)
    }

    function test_disabling_unloads_the_adapter_and_re_enabling_restores_it() {
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      compose.spellingEnabled = false
      tryVerify(function() { return compose.spellingAdapter === null }, 3000)
      compare(compose.spellingStatus, "disabled")
      compose.spellingEnabled = true
      tryVerify(function() { return compose.spellingAdapter !== null }, 3000)
      compare(compose.spellingAvailable, true)
    }
  }
}

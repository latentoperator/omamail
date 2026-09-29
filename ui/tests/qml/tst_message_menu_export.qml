import QtQuick 2.15
import QtTest 1.3
import "../../components" as Omamail

// "Save as .eml" in the message menu: it appears only where the service says
// the provider and the connected backend can do it, and choosing it asks the
// service for that exact message rather than routing through a provider verb.
Item {
  width: 500
  height: 500

  QtObject {
    id: fakeService
    property bool canArchive: true
    property bool canReportSpam: true
    property bool canStar: true
    property bool canOpenOnWeb: false
    property bool hasLabels: false
    property string rawLabelId: ""
    property bool exportable: true
    property var exportedIds: []
    property var messages: []
    function canExportEmlFor(id) { return exportable }
    function exportEml(id) { exportedIds = exportedIds.concat([String(id)]); return true }
  }

  Omamail.MessageMenu {
    id: menu
    anchors.fill: parent
    service: fakeService
    textColor: Qt.rgba(0.1, 0.1, 0.1, 1)
    urgentColor: Qt.rgba(0.8, 0.1, 0.1, 1)
    dimColor: Qt.rgba(0.45, 0.45, 0.45, 1)
    popupBackgroundColor: Qt.rgba(0.95, 0.95, 0.95, 1)
    popupBorderColor: Qt.rgba(0.6, 0.6, 0.6, 1)
    panelFontFamily: "monospace"
  }

  TestCase {
    name: "MessageMenuExport"
    when: windowShown

    // exportRow sits after star, before the browser and AI rows.
    function exportRow() { return menu.menuRows[11] }

    function summary() {
      return { id: "42:INBOX", subject: "Project update", unread: false,
        starred: false, inInbox: true, inTrash: false, inSpam: false,
        isSent: false, isDraft: false, labelIds: [] }
    }

    function show() {
      fakeService.messages = [summary()]
      fakeService.exportedIds = []
      menu.close()
      menu.openAt("42:INBOX", 100, 100)
      wait(20)
    }

    function cleanup() { menu.close() }

    function test_the_row_appears_only_when_the_service_says_it_can() {
      fakeService.exportable = true
      show()
      compare(exportRow().visible, true)
      compare(String(exportRow().text), "Save as .eml")

      fakeService.exportable = false
      show()
      compare(exportRow().visible, false,
        "a provider or backend without export must not offer the row")
    }

    function test_choosing_it_asks_the_service_for_that_message() {
      fakeService.exportable = true
      show()
      exportRow().activated()
      compare(fakeService.exportedIds, ["42:INBOX"])
      compare(menu.opened, false, "the menu closes on choosing")
    }
  }
}

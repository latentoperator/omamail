import QtQuick
import "Spelling.js" as Spelling

// Service-owned spelling state. User preference and runtime availability are
// separate: a missing module/dictionary leaves composing available and gives
// Settings a reason even before the first composer opens.
Item {
  id: root
  visible: false
  required property var service
  readonly property bool enabledRequest: Spelling.decodeSettings(service.settings).enabled
  readonly property string languageOverride: Spelling.decodeSettings(service.settings).language
  readonly property string language: Spelling.resolveLanguage(languageOverride, Qt.locale().name)
  readonly property bool available: probe.status === Loader.Ready
    && probe.item !== null && probe.item.available
  readonly property string status: !enabledRequest ? "disabled" : (probe.status === Loader.Error
    ? "no-module" : (probe.item ? probe.item.status : "loading"))
  readonly property alias wordStore: personalWords
  readonly property alias words: personalWords.words
  readonly property alias error: personalWords.error

  // Loaded whether or not checking is on, so a word list is never lost by
  // turning spelling off and back on.
  PersonalWords { id: personalWords; service: root.service }

  // Sonnet enumerates dictionaries once per process. Installing one requires
  // restarting Omamail; a new adapter alone cannot discover it.
  Loader { id: probe; active: root.enabledRequest; source: "SpellcheckAdapter.qml" }
  Binding {
    target: probe.item
    property: "language"
    value: root.language
    when: probe.item !== null
  }
}

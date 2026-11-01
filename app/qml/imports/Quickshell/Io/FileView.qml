import QtQuick
import Quickshell

QtObject {
  id: root

  property string path: ""
  property bool watchChanges: false
  property bool printErrors: false
  property bool atomicWrites: false
  property var store: Quickshell.fileStore
  property string _text: ""
  property string _watchedPath: ""
  // The store announces a failed read as well as returning it. The read
  // that this view started reports through its result alone.
  property bool _reading: false

  signal loaded()
  signal fileChanged()
  // Carries Quickshell's FileViewError so listeners can tell "no file yet"
  // (FileNotFound, 2) from a file that exists but could not be read
  // (Unknown, 1). Listeners that ignore the argument are unaffected.
  signal loadFailed(var error)

  function report(error) {
    if (printErrors && String(error || "") !== "") console.warn(String(error))
  }

  function updateWatch() {
    if (!store || typeof store.watch !== "function") return
    if (_watchedPath !== "") store.watch(_watchedPath, false)
    _watchedPath = watchChanges ? path : ""
    if (_watchedPath !== "") store.watch(_watchedPath, true)
  }

  function readError() {
    if (!store || path === "" || typeof store.exists !== "function") return 2
    return store.exists(path) ? 1 : 2
  }

  function reload() {
    if (!store || typeof store.read !== "function" || path === "") {
      loadFailed(2)
      return
    }
    _reading = true
    var result = store.read(path) || ({})
    _reading = false
    if (!result.ok) {
      report(result.error)
      loadFailed(readError())
      return
    }
    _text = String(result.text || "")
    loaded()
  }

  function text() { return _text }

  function setText(value) {
    _text = String(value || "")
    if (!store || typeof store.write !== "function" || path === "") {
      loadFailed(1)
      return
    }
    var result = store.write(path, _text, atomicWrites) || ({})
    if (!result.ok) {
      report(result.error)
      loadFailed(1)
    }
  }

  onPathChanged: {
    updateWatch()
    reload()
  }
  onWatchChangesChanged: updateWatch()
  onStoreChanged: {
    updateWatch()
    reload()
  }

  property Connections storeConnections: Connections {
    target: root.store
    ignoreUnknownSignals: true
    function onChanged(changedPath) {
      if (String(changedPath) === root.path) root.fileChanged()
    }
    function onFailed(failedPath, error) {
      if (root._reading || String(failedPath) !== root.path) return
      root.report(error)
      root.loadFailed(root.readError())
    }
  }

  Component.onCompleted: {
    updateWatch()
    reload()
  }
  Component.onDestruction: {
    if (store && typeof store.watch === "function" && _watchedPath !== "")
      store.watch(_watchedPath, false)
  }
}

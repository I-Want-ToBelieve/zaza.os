import QtQuick
import org.kde.kwin 3.0
import "../code/krohnkite.js" as K

Item {
    id: scriptRoot
    property var runtime: null
    property var virtualKeyboardCallbacks: []
    property bool virtualKeyboardPending: false

    function configuredColor(name, fallback) {
        var value = KWin.readConfig(name, fallback);
        if (typeof value !== "string" || value.indexOf(",") < 0) return value;
        var channels = value.split(",").map(Number);
        return Qt.rgba(channels[0] / 255, channels[1] / 255, channels[2] / 255,
            channels.length > 3 ? channels[3] / 255 : 1);
    }

    function resolveVirtualKeyboard(visible) {
        virtualKeyboardPending = false;
        var callbacks = virtualKeyboardCallbacks;
        virtualKeyboardCallbacks = [];
        for (var callback of callbacks) callback(visible);
    }

    function queryVirtualKeyboard(callback) {
        virtualKeyboardCallbacks.push(callback);
        if (!virtualKeyboardPending) {
            virtualKeyboardPending = true;
            dbusLoader.item.getDBusVirtualKeyboardVisible().call();
        }
        return function() {
            var index = virtualKeyboardCallbacks.indexOf(callback);
            if (index >= 0) virtualKeyboardCallbacks.splice(index, 1);
        };
    }

    function scheduleTimer(milliseconds, callback) {
        var timer = timerFactory.createObject(scriptRoot, { interval: milliseconds });
        var complete = false;
        function cancel() {
            if (complete) return;
            complete = true;
            timer.stop();
            timer.destroy();
        }
        timer.triggered.connect(function() { if (!complete) callback(); cancel(); });
        timer.start();
        return cancel;
    }

    Component { id: timerFactory; Timer { repeat: false } }

    Loader { id: shortcutsLoader; source: "shortcuts.qml" }
    Loader { id: dbusLoader; source: "dbus.qml" }
    Connections {
        target: dbusLoader.item === null ? null : dbusLoader.item.getDBusVirtualKeyboardVisible()
        function onFinished(result) { scriptRoot.resolveVirtualKeyboard(Boolean(result[0])); }
        function onFailed() {
            console.warn("KROHNKITE: virtual keyboard DBus query failed");
            scriptRoot.resolveVirtualKeyboard(false);
        }
    }
    Loader { id: previewLoader; source: "dragpreview.qml" }
    Loader {
        id: popupLoader
        source: "popup.qml"
        function showNotification(message) {
            if (item !== null) {
                // ClientAreaOption.FullScreenArea is 4 in the KWin scripting API.
                var area = Workspace.clientArea(4, Workspace.activeScreen, Workspace.currentDesktop);
                item.show(message, area, Math.max(0, Number(KWin.readConfig("notificationDuration", 1000))));
            }
        }
    }

    Component.onCompleted: {
        runtime = K.Krohnkite.createRuntime({
            workspace: Workspace,
            // The declarative context's KWin wrapper supplies readConfig; the
            // scripting ClientAreaOption.PlacementArea constant is 0.
            kwin: { PlacementArea: 0 },
            readConfig: function(name, fallback) { return KWin.readConfig(name, fallback); },
            shortcuts: shortcutsLoader.item.shortcutList,
            log: function(message) { console.log(message); },
            notify: function(message) { popupLoader.showNotification(message); },
            movePointerToFocus: function() { dbusLoader.item.getDBusMoveMouseToFocus().call(); },
            movePointerToCenter: function() { dbusLoader.item.getDBusMoveMouseToCenter().call(); },
            scheduleTimer: function(milliseconds, callback) { return scriptRoot.scheduleTimer(milliseconds, callback); },
            queryVirtualKeyboard: function(callback) { return scriptRoot.queryVirtualKeyboard(callback); },
            preview: function(geometry, area) {
                if (previewLoader.item === null) return;
                if (geometry === null) previewLoader.item.hide();
                else previewLoader.item.showRect(area.x, area.y, area.width, area.height,
                    geometry.x, geometry.y, geometry.width, geometry.height,
                    scriptRoot.configuredColor("dockFrameColor", "61, 135, 240, 77"),
                    scriptRoot.configuredColor("dockBorderColor", "61, 135, 240, 230"));
            }
        });
        if (runtime.start()) console.log("KROHNKITE: Effect 4 runtime started");
    }

    // KWin reparses kwinrc before Options.configChanged. readConfig reads that
    // cached KConfig; polling alone would not reload edits made on disk.
    Connections {
        target: Options
        function onConfigChanged() { configReloadTimer.restart(); }
    }

    Timer {
        id: configReloadTimer
        interval: 100
        repeat: false
        onTriggered: if (runtime !== null) runtime.reloadIfChanged()
    }

    Component.onDestruction: {
        configReloadTimer.stop();
        virtualKeyboardCallbacks = [];
        if (runtime !== null) {
            runtime.dispose();
            runtime = null;
        }
    }
}

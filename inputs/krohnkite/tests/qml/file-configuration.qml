import QtQuick
import org.kde.kwin 3.0

// The shell harness copies the installed package beside this fixture, loads it
// with the real "krohnkite" plugin name, and edits its isolated native kwinrc.
Item {
    id: root
    property int phase: 0
    property int attempts: 0
    property int stableSamples: 0
    property bool failed: false
    property bool completed: false

    Loader {
        id: production
        source: "package/contents/ui/main.qml"
        onStatusChanged: {
            if (status === Loader.Error) root.fail("Packaged main.qml failed to load");
        }
    }

    function fail(message) {
        if (failed) return;
        failed = true;
        console.error("KROHNKITE_FILE_CONFIG_FAILED " + message);
    }

    function geometry(window) {
        var value = window.frameGeometry;
        return { x: value.x, y: value.y, width: value.width, height: value.height };
    }

    function equalRect(actual, expected) {
        return actual.x === expected.x && actual.y === expected.y &&
            actual.width === expected.width && actual.height === expected.height;
    }

    function nativeGaps() {
        var values = {};
        for (var side of ["Left", "Right", "Top", "Bottom", "Between"]) {
            values[side] = String(KWin.readConfig("screenGap" + side, "[absent]"));
        }
        return values;
    }

    function expectedGaps() {
        if (phase === 0 || phase === 4) {
            return { Left: "8", Right: "8", Top: "8", Bottom: "8", Between: "8" };
        }
        return {
            Left: phase === 1 ? "16" : phase === 2 ? "not-a-number" : "[absent]",
            Right: "16", Top: "16", Bottom: "16", Between: "16"
        };
    }

    function expectedGeometry() {
        if (phase === 0 || phase === 4) {
            return [
                { x: 8, y: 8, width: 628, height: 784 },
                { x: 644, y: 8, width: 628, height: 784 }
            ];
        }
        if (phase === 1) {
            return [
                { x: 16, y: 16, width: 616, height: 768 },
                { x: 648, y: 16, width: 616, height: 768 }
            ];
        }
        return [
            { x: 0, y: 16, width: 624, height: 768 },
            { x: 640, y: 16, width: 624, height: 768 }
        ];
    }

    function productionReady() {
        if (production.status !== Loader.Ready || production.item === null) return false;
        var names = ["shortcuts.qml", "dbus.qml", "dragpreview.qml", "popup.qml"];
        var ready = [];
        for (var child of production.item.children) {
            if (child.source === undefined) continue;
            var source = String(child.source);
            for (var name of names) {
                if (source.slice(-name.length) !== name) continue;
                if (child.status === Loader.Error) throw new Error(name + " failed to load");
                if (child.status !== Loader.Ready || child.item === null) return false;
                ready.push(name);
            }
        }
        return ready.length === names.length && production.item.runtime !== null &&
            production.item.runtime.isRunning();
    }

    function sample() {
        attempts++;
        if (attempts > 100) {
            throw new Error("Timed out in phase " + phase + ": native=" +
                JSON.stringify(nativeGaps()) + ", windows=" + JSON.stringify(
                    Workspace.stackingOrder.map(function(window) {
                        return { caption: window.caption, geometry: root.geometry(window) };
                    })));
        }
        if (!productionReady()) return false;
        var cached = nativeGaps();
        var expectedConfig = expectedGaps();
        for (var side of ["Left", "Right", "Top", "Bottom", "Between"]) {
            if (cached[side] !== expectedConfig[side]) return false;
        }
        var windows = Workspace.stackingOrder.filter(function(window) {
            return /^Krohnkite file configuration [12]$/.test(window.caption);
        }).sort(function(left, right) { return left.frameGeometry.x - right.frameGeometry.x; });
        if (windows.length !== 2) return false;
        var expected = expectedGeometry();
        var state = production.item.runtime.snapshot();
        if (state === null) return false;
        for (var index = 0; index < windows.length; index++) {
            var window = windows[index];
            if (!window.noBorder || !equalRect(geometry(window), expected[index])) return false;
            var snapshot = state.windows.find(function(entry) {
                return entry.id === String(window.internalId);
            });
            if (snapshot === undefined || snapshot.floating || snapshot.manualFloating ||
                !equalRect(snapshot.geometry, expected[index])) return false;
        }
        return true;
    }

    Timer {
        interval: 200
        repeat: true
        running: !root.failed && !root.completed
        onTriggered: {
            try {
                if (!root.sample()) {
                    root.stableSamples = 0;
                    return;
                }
                root.stableSamples++;
                if (root.stableSamples < 3) return;
                var markers = ["INITIAL_OK", "RELOAD_OK", "INVALID_VALUE_OK", "MISSING_KEY_OK", "RESTORE_OK"];
                console.warn("KROHNKITE_FILE_CONFIG_" + markers[root.phase] +
                    " native=" + JSON.stringify(root.nativeGaps()) +
                    " geometry=" + JSON.stringify(root.expectedGeometry()));
                root.phase++;
                root.attempts = 0;
                root.stableSamples = 0;
                if (root.phase === markers.length) {
                    root.completed = true;
                    console.warn("KROHNKITE_FILE_CONFIG_OK");
                }
            } catch (error) {
                root.fail(String(error));
            }
        }
    }
}

import QtQuick
import org.kde.kwin 3.0
import "../../packages/kwin/dist/krohnkite.js" as K

// Manual integration fixture: load in KWin under a temporary script namespace.
// It acts only on the two test windows and never exits the compositor.
Item {
    id: root
    property var runtime: null
    property var ignoredTitles: []
    property int phase: 0
    property int attempts: 0
    property bool failed: false

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function geometry(window) {
        var value = window.frameGeometry;
        return { x: value.x, y: value.y, width: value.width, height: value.height };
    }
    function testWindows() {
        return Workspace.stackingOrder.filter(function(window) {
            return /^Krohnkite rewrite check [12]$/.test(window.caption);
        });
    }
    function config(name, fallback) {
        if (name === "ignoreTitle") return ignoredTitles.join(",");
        if (name === "ignoreClass" || name === "floatingClass" || name === "floatingTitle") return "";
        if (name === "floatUtility" || name === "preventMinimize" || name === "monocleMinimizeRest") return false;
        if (name === "noTileBorder") return true;
        if (/^screenGap/.test(name)) return 8;
        return fallback;
    }
    Component.onCompleted: {
        console.warn("KROHNKITE_REWRITE_KWIN_ENTER");
        ignoredTitles = Workspace.stackingOrder.map(function(window) { return window.caption; }).filter(function(title) {
            return title.length > 0 && !/^Krohnkite rewrite check [12]$/.test(title);
        });
        runtime = K.Krohnkite.createRuntime({
            workspace: Workspace, kwin: { PlacementArea: 0 }, readConfig: config, shortcuts: [],
            log: function(message) { console.warn("KROHNKITE_REWRITE_KWIN_LOG " + message); }
        });
        if (!runtime.start()) {
            failed = true;
            console.error("KROHNKITE_REWRITE_KWIN_FAILED runtime.start");
        }
    }
    Timer {
        interval: 200; running: !root.failed; repeat: true
        onTriggered: {
            try {
                root.attempts++;
                root.check(root.attempts < 60, "Timed out waiting for KWin test windows");
                var windows = root.testWindows();
                if (windows.length !== 2) return;
                var first = root.geometry(windows[0]);
                var second = root.geometry(windows[1]);
                if (root.phase === 0) {
                    root.check(first.width > 0 && second.width > 0, "Empty tiled geometry");
                    var ordered = [first, second].sort(function(a,b) { return a.x-b.x; });
                    if (Math.abs(ordered[1].x - ordered[0].x - ordered[0].width - 8) > 2) {
                        console.warn("KROHNKITE_REWRITE_KWIN_WAIT " + JSON.stringify([first, second]));
                        return;
                    }
                    console.warn("KROHNKITE_REWRITE_KWIN_TILE " + JSON.stringify([first, second]));
                    var state = root.runtime.snapshot();
                    var windowState = state.windows.find(function(window) { return window.caption === windows[0].caption; });
                    root.check(windowState !== undefined, "Test window missing from Effect state");
                    root.runtime.send({ type: "action", action: "layout:monocle", surfaceId: windowState.surfaceId });
                    root.phase = 1;
                    return;
                }
                if (!(Math.abs(first.x-second.x) <= 2 && Math.abs(first.y-second.y) <= 2 && Math.abs(first.width-second.width) <= 2 && Math.abs(first.height-second.height) <= 2)) {
                    console.warn("KROHNKITE_REWRITE_KWIN_MONOCLE_WAIT " + JSON.stringify([first, second]));
                    return;
                }
                console.warn("KROHNKITE_REWRITE_KWIN_MONOCLE " + JSON.stringify([first, second]));
                // Leave the runtime active so unloading exercises the same
                // Component.onDestruction cleanup as the packaged script.
                running = false;
                console.warn("KROHNKITE_REWRITE_KWIN_OK");
            } catch(error) {
                running = false;
                if (root.runtime !== null) root.runtime.dispose();
                console.error("KROHNKITE_REWRITE_KWIN_FAILED " + String(error));
            }
        }
    }
    Component.onDestruction: {
        try {
            if (runtime !== null) {
                runtime.dispose();
                check(!runtime.isRunning(), "Runtime remained active after unloading");
                runtime.dispose();
            }
            console.warn("KROHNKITE_REWRITE_KWIN_DISPOSE_OK");
        } catch (error) {
            console.error("KROHNKITE_REWRITE_KWIN_FAILED disposal " + String(error));
        }
    }
}

import QtQuick
import "../../packages/kwin/dist/krohnkite.js" as K

Item {
    id: root
    property var runtime: null

    Component {
        id: stressShortcutFactory
        QtObject { signal activated() }
    }

    Component {
        id: stressWindowFactory
        QtObject {
            property string internalId: ""
            property string resourceClass: "krohnkite-qt-stress"
            property string resourceName: "krohnkite-qt-stress"
            property string caption: ""
            property var output: null
            property var desktops: []
            property var activities: []
            property rect frameGeometry: Qt.rect(100, 100, 400, 300)
            property size minSize: Qt.size(1, 1)
            property size maxSize: Qt.size(2147483647, 2147483647)
            property bool normalWindow: true
            property bool specialWindow: false
            property bool resizeable: true
            property bool hidden: false
            property bool minimized: false
            property bool fullScreen: false
            property bool noBorder: false
            property bool keepAbove: false
            property bool keepBelow: false
            property bool skipPager: false
            property int stackingOrder: 0
            property int maximizeMode: 0
            signal maximizedChanged()
            signal maximizedAboutToChange(int mode)
            signal bufferGeometryChanged()
            signal moveResizedChanged()
            signal interactiveMoveResizeFinished()
            function setMaximize(vertically, horizontally) {
                maximizeMode = (vertically ? 1 : 0) + (horizontally ? 2 : 0);
                maximizedChanged();
            }
        }
    }

    Component {
        id: stressWorkspaceFactory
        QtObject {
            property var screens: []
            property var desktops: []
            property var activeScreen: null
            property var currentDesktop: null
            property string currentActivity: "activity-stress"
            property var stackingOrder: []
            property var activeWindow: null
            signal windowAdded(var window)
            signal windowRemoved(var window)
            signal windowActivated(var window)
            signal virtualScreenGeometryChanged()
            signal activityRemoved(string activity)
            function currentDesktopForScreen(output) { return currentDesktop; }
            function clientArea(kind, output, desktop) { return Qt.rect(0, 32, 1536, 832); }
        }
    }

    function assertTrue(condition, message) {
        if (!condition) throw new Error(message);
    }

    function signal() {
        var handlers = [];
        return {
            connect: function(callback) { handlers.push(callback); },
            disconnect: function(callback) {
                var index = handlers.indexOf(callback);
                if (index >= 0) handlers.splice(index, 1);
            },
            emit: function(value) {
                handlers.slice().forEach(function(callback) { callback(value); });
            },
            count: function() { return handlers.length; }
        };
    }

    function windowObject(id, screen) {
        var changed = signal();
        var geometry = { x: 100, y: 100, width: 400, height: 300 };
        var result = {
            internalId: id,
            resourceClass: "krohnkite-qt-test",
            caption: id,
            output: screen,
            normalWindow: true,
            noBorder: false,
            keepAbove: false,
            keepBelow: false,
            minimized: false,
            maximizeMode: 0,
            maximizeCalls: [],
            frameGeometryChanged: changed,
            minimizedChanged: signal(),
            maximizedChanged: signal(),
            maximizedAboutToChange: signal(),
            setMaximize: function(vertically, horizontally) {
                result.maximizeCalls.push([vertically, horizontally]);
                result.maximizeMode = (vertically ? 1 : 0) + (horizontally ? 2 : 0);
                result.maximizedChanged.emit();
            }
        };
        Object.defineProperty(result, "frameGeometry", {
            get: function() { return geometry; },
            set: function(value) { geometry = value; changed.emit(); }
        });
        return result;
    }

    function testRuntime() {
        var output = { name: "QT-1" };
        var desktop = { id: "desktop-1", name: "Desktop 1" };
        var first = windowObject("first", output);
        var second = windowObject("second", output);
        var selectedLayout = signal();
        var errors = [];
        var diskGap = "8";
        var cachedGap = diskGap;
        var readFailure = false;
        var workspace = {
            screens: [output], activeScreen: output,
            currentDesktop: desktop, currentActivity: "activity-1",
            stackingOrder: [first, second], activeWindow: first,
            windowAdded: signal(), windowRemoved: signal(), windowActivated: signal(),
            screensChanged: signal(),
            clientArea: function() { return { x: 0, y: 0, width: 1200, height: 800 }; }
        };
        runtime = K.Krohnkite.createRuntime({
            workspace: workspace,
            kwin: { PlacementArea: 0 },
            readConfig: function(name, fallback) {
                if (readFailure && name === "screenGapTop") throw new Error("KConfig test read failure");
                if (name.indexOf("screenGap") === 0) return cachedGap;
                if (name === "noTileBorder" || name === "preventMinimize") return false;
                if (name.indexOf("ignore") === 0 || name.indexOf("floating") === 0) return "";
                return fallback;
            },
            shortcuts: [{ name: "SetMonocleLayoutSC", hdl: { activated: selectedLayout } }],
            log: function(message) {
                errors.push(message);
                if (message.indexOf("KConfig test read failure") < 0) console.log(message);
            }
        });
        assertTrue(runtime.start(), "Effect runtime failed to start in Qt");
        assertTrue(runtime.isRunning(), "Runtime must be running");
        assertTrue(first.frameGeometry.x === 8, "Screen gap must be applied");
        assertTrue(first.frameGeometry.width > 0 && second.frameGeometry.width > 0, "Both windows must be tiled");
        assertTrue(second.frameGeometry.x >= first.frameGeometry.x + first.frameGeometry.width + 8,
                   "Tile windows must be separated by the configured gap");
        selectedLayout.emit();
        assertTrue(first.frameGeometry.x === second.frameGeometry.x &&
                   first.frameGeometry.width === second.frameGeometry.width,
                   "A shortcut must select Monocle through Effect");
        var connections = first.frameGeometryChanged.count();
        diskGap = "12";
        assertTrue(!runtime.reloadIfChanged(), "readConfig must keep reading cached KConfig until the host reparses it");
        assertTrue(first.frameGeometry.x === 8, "File edits alone must not change cached configuration");
        cachedGap = diskGap;
        assertTrue(runtime.reloadIfChanged(), "Changed KConfig must reload");
        assertTrue(first.frameGeometry.x === 12, "Reload must apply the new gap");
        assertTrue(!runtime.reloadIfChanged(), "Unchanged KConfig must not reload");
        cachedGap = "24";
        readFailure = true;
        assertTrue(!runtime.reloadIfChanged(), "A partial KConfig read failure must not be applied");
        assertTrue(first.frameGeometry.x === 12, "A failed read must preserve the previous configuration");
        readFailure = false;
        assertTrue(runtime.reloadIfChanged(), "A later successful read must recover");
        assertTrue(first.frameGeometry.x === 24, "Recovery must apply the complete configuration");
        cachedGap = "not-a-number";
        assertTrue(runtime.reloadIfChanged(), "Invalid numeric values must decode to defaults");
        assertTrue(first.frameGeometry.x === 0, "Invalid gap must use its zero default");
        assertTrue(!runtime.reloadIfChanged(), "The same invalid input must not cause repeated arrangements");
        assertTrue(first.frameGeometryChanged.count() === connections, "Reload must retain exactly one set of window callbacks");
        assertTrue(errors.length === 4 && errors[0].indexOf("configuration reloaded") >= 0 &&
                   errors[1].indexOf("readConfig") >= 0 && errors[1].indexOf("KConfig test read failure") >= 0 &&
                   errors[2].indexOf("configuration reloaded") >= 0 && errors[3].indexOf("configuration reloaded") >= 0,
                   "Only the intentional read failure and successful reloads may be reported");
        runtime.dispose();
        assertTrue(!runtime.isRunning(), "Disposed runtime must stop");
        assertTrue(workspace.windowAdded.count() === 0 && first.frameGeometryChanged.count() === 0 &&
                   selectedLayout.count() === 0, "All Qt callbacks must be disconnected");
        assertTrue(!runtime.reloadIfChanged(), "Disposed runtime must not reload configuration");
        runtime.dispose();
    }

    function testPartialMaximizeRestoration() {
        for (var mode of [1, 2]) {
            var output = { name: "QT-PARTIAL-" + mode };
            var desktop = { id: "desktop-partial", name: "Partial" };
            var first = windowObject("partial-first", output);
            var second = windowObject("partial-second", output);
            var layout = signal();
            var errors = [];
            first.maximizeMode = mode;
            var workspace = {
                screens: [output], activeScreen: output, currentDesktop: desktop,
                currentActivity: "activity-partial", stackingOrder: [first, second],
                activeWindow: first, windowAdded: signal(), windowRemoved: signal(),
                windowActivated: signal(),
                clientArea: function() { return { x: 0, y: 0, width: 1200, height: 800 }; }
            };
            runtime = K.Krohnkite.createRuntime({
                workspace: workspace, kwin: { PlacementArea: 0 },
                shortcuts: [{ name: "SetMonocleLayoutSC", hdl: { activated: layout } }],
                readConfig: function(name, fallback) {
                    if (name === "preventMinimize") return false;
                    if (name.indexOf("ignore") === 0 || name.indexOf("floating") === 0) return "";
                    return fallback;
                },
                log: function(message) { errors.push(message); }
            });
            assertTrue(runtime.start(), "Partial maximization runtime did not start");
            layout.emit();
            assertTrue(first.maximizeMode === mode, "User maximization must remain untouched");
            first.maximizedAboutToChange.emit(0);
            assertTrue(first.maximizeMode === 3, "Monocle must own the new full maximization");
            runtime.dispose();
            assertTrue(first.maximizeMode === mode, "Disposal changed the original maximization axis");
            assertTrue(JSON.stringify(first.maximizeCalls) === JSON.stringify([
                [true, true], [mode === 1, mode === 2]
            ]), "setMaximize must receive vertical before horizontal");
            assertTrue(first.maximizedChanged.count() === 0 &&
                       first.maximizedAboutToChange.count() === 0 && layout.count() === 0,
                       "Partial maximization observers must disconnect");
            assertTrue(errors.length === 0, "Partial maximization reported errors: " + JSON.stringify(errors));
        }
        console.log("KROHNKITE_QT_PARTIAL_MAXIMIZE_OK");
    }

    function testInternalWindows() {
        var output = { name: "QT-INTERNAL" };
        var desktop = { id: "desktop-internal", name: "Internal" };
        var first = windowObject("internal-test-first", output);
        var second = windowObject("empty-class-client", output);
        second.resourceClass = "";
        var initialPopup = windowObject("initial-popup", output);
        var popup = windowObject("notification-popup", output);
        var unsafeReads = 0;
        for (var internal of [initialPopup, popup]) {
            internal.resourceClass = "";
            internal.toString = function() { return 'KWin::InternalWindow(0x1234, "notification")'; };
            Object.defineProperty(internal, "minSize", { get: function() {
                unsafeReads += 1;
                throw new Error("Deleted internal QWindow minimumSize");
            } });
            Object.defineProperty(internal, "maxSize", { get: function() {
                unsafeReads += 1;
                throw new Error("Deleted internal QWindow maximumSize");
            } });
        }
        var layout = signal();
        var errors = [];
        var workspace = {
            screens: [output], activeScreen: output, currentDesktop: desktop,
            currentActivity: "activity-internal", stackingOrder: [first, second, initialPopup],
            activeWindow: first, windowAdded: signal(), windowRemoved: signal(),
            windowActivated: signal(),
            clientArea: function() { return { x: 0, y: 0, width: 1200, height: 800 }; }
        };
        runtime = K.Krohnkite.createRuntime({
            workspace: workspace, kwin: { PlacementArea: 0 },
            shortcuts: [{ name: "SetMonocleLayoutSC", hdl: { activated: layout } }],
            readConfig: function(name, fallback) {
                if (name === "preventMinimize") return false;
                if (name.indexOf("ignore") === 0 || name.indexOf("floating") === 0) return "";
                return fallback;
            },
            notify: function(message) {
                if (workspace.stackingOrder.indexOf(popup) < 0) {
                    workspace.stackingOrder.push(popup);
                    workspace.windowAdded.emit(popup);
                }
            },
            log: function(message) { errors.push(message); }
        });
        assertTrue(runtime.start(), "Internal windows prevented startup");
        assertTrue(runtime.snapshot().windows.length === 2, "An internal window entered the initial snapshot");
        assertTrue(initialPopup.frameGeometryChanged.count() === 0, "Initial internal windows must not have observers");
        assertTrue(second.frameGeometryChanged.count() === 1, "An empty resourceClass must not exclude an ordinary client");
        layout.emit();
        assertTrue(popup.frameGeometryChanged.count() === 0, "A notification must not acquire window observers");
        runtime.send({ type: "action", action: "layout:tile" });
        assertTrue(runtime.snapshot().windows.length === 2, "A notification entered Tile state");
        assertTrue(first.frameGeometry.height === 800 && second.frameGeometry.height === 800,
                   "A notification consumed a Tile slot");
        assertTrue(first.frameGeometry.x + first.frameGeometry.width <= second.frameGeometry.x,
                   "Client windows did not return to separate Tile columns");
        workspace.stackingOrder.splice(workspace.stackingOrder.indexOf(popup), 1);
        workspace.windowRemoved.emit(popup);
        runtime.dispose();
        assertTrue(unsafeReads === 0, "Internal QWindow-backed properties were read");
        assertTrue(first.frameGeometryChanged.count() === 0 && second.frameGeometryChanged.count() === 0 &&
                   layout.count() === 0, "Internal-window regression leaked observers");
        assertTrue(errors.length === 0, "Internal-window regression reported errors: " + JSON.stringify(errors));
        console.log("KROHNKITE_QT_INTERNAL_WINDOWS_OK");
    }

    function testSynchronousBudget() {
        // The full upstream shortcut list plus twelve native windows registers
        // over two hundred scoped callbacks. This exceeds Effect's default
        // 2048-operation cooperative budget without a clock-based slowdown.
        var names = [
            "FocusNextSC", "FocusPrevSC", "FocusLeftSC", "FocusRightSC",
            "ToggleDockSC", "FocusDownSC", "FocusUpSC", "MoveDownSC", "MoveUpSC",
            "MoveLeftSC", "MoveRightSC", "GrowHeightSC", "ShrinkHeightSC",
            "ShrinkWidthSC", "GrowWidthSC", "IncreaseSC", "DecreaseSC",
            "ToggleFloatSC", "ToggleFloatAllSC", "NextLayoutSC", "PreviousLayoutSC",
            "RotateSC", "RotatePartSC", "SetMasterSC", "RaiseSurfaceCapacitySC",
            "LowerSurfaceCapacitySC", "AlterRegisterSC", "SetTileLayoutSC",
            "SetMonocleLayoutSC", "SetThreeColumnLayoutSC", "SetSpreadLayoutSC",
            "SetStairLayoutSC", "SetFloatingLayoutSC", "SetQuarterLayoutSC",
            "SetStackedLayoutSC", "SetColumnsLayoutSC", "SetSpiralLayoutSC",
            "SetBinaryTreeLayoutSC", "SetCascadeLayoutSC"
        ];
        assertTrue(names.length === 39, "Stress fixture must register all upstream shortcuts");
        var shortcuts = [];
        var handlers = {};
        var windows = [];
        var owned = [];
        var errors = [];
        var gap = 8;
        var output = { name: "QT-STRESS-1" };
        var desktop = { id: "desktop-stress", name: "Stress Desktop" };
        var workspace = null;
        function layoutId() {
            var layouts = runtime.snapshot().layouts;
            var key = JSON.stringify([output.name, "activity-stress", desktop.id]);
            return layouts[key].id;
        }
        function assertTile(count) {
            var state = runtime.snapshot();
            assertTrue(state.windows.length === count, "Stress start/event left a partial window snapshot");
            assertTrue(layoutId() === "tile", "Stress Tile signal selected a different layout");
            var rectangles = windows.slice(0, count).map(function(window) { return window.frameGeometry; });
            rectangles.forEach(function(rectangle, index) {
                assertTrue(rectangle.width > 0 && rectangle.height > 0,
                           "Stress layout produced an empty rectangle");
                for (var other = index + 1; other < rectangles.length; other++) {
                    var candidate = rectangles[other];
                    var overlapX = Math.min(rectangle.x + rectangle.width, candidate.x + candidate.width) - Math.max(rectangle.x, candidate.x);
                    var overlapY = Math.min(rectangle.y + rectangle.height, candidate.y + candidate.height) - Math.max(rectangle.y, candidate.y);
                    assertTrue(overlapX <= 0 || overlapY <= 0, "Stress Tile windows overlap");
                }
            });
            assertTrue(windows[0].frameGeometry.x === gap, "Stress gap did not apply synchronously");
        }
        try {
            names.forEach(function(name) {
                var handler = stressShortcutFactory.createObject(root);
                assertTrue(handler !== null, "Could not create native shortcut signal");
                owned.push(handler);
                handlers[name] = handler;
                shortcuts.push({ name: name, hdl: handler });
            });
            for (var index = 0; index < 12; index++) {
                var window = stressWindowFactory.createObject(root, {
                    internalId: "stress-" + index, caption: "Stress window " + index,
                    output: output, desktops: [desktop], activities: ["activity-stress"], stackingOrder: index
                });
                assertTrue(window !== null, "Could not create native window metadata");
                owned.push(window);
                windows.push(window);
            }
            workspace = stressWorkspaceFactory.createObject(root, {
                screens: [output], desktops: [desktop], activeScreen: output,
                currentDesktop: desktop, stackingOrder: windows.slice(0, 11), activeWindow: windows[0]
            });
            assertTrue(workspace !== null, "Could not create native workspace signals");
            owned.push(workspace);
            runtime = K.Krohnkite.createRuntime({
                workspace: workspace, kwin: { PlacementArea: 0 }, shortcuts: shortcuts,
                readConfig: function(name, fallback) {
                    if (name.indexOf("screenGap") === 0) return gap;
                    if (name === "screenDefaultLayout") return ":tile";
                    if (name === "monocleMaximize" || name === "preventMinimize") return false;
                    if (name === "noTileBorder") return true;
                    if (name.indexOf("ignore") === 0 || name.indexOf("floating") === 0) return "";
                    return fallback;
                },
                log: function(message) { errors.push(message); }
            });
            assertTrue(runtime.start(), "Native stress runtime did not complete synchronously: " + JSON.stringify(errors));
            assertTile(11);
            workspace.stackingOrder = windows;
            workspace.windowAdded(windows[11]);
            assertTile(12);
            gc();
            workspace.activeWindow = windows[11];
            workspace.windowActivated(windows[11]);
            assertTrue(runtime.snapshot().focusId === windows[11].internalId, "Native activation did not commit synchronously");
            handlers.SetMonocleLayoutSC.activated();
            assertTrue(layoutId() === "monocle", "Full native shortcut registration lost the Monocle callback");
            windows.forEach(function(window) {
                assertTrue(window.frameGeometry.x === windows[0].frameGeometry.x &&
                           window.frameGeometry.width === windows[0].frameGeometry.width,
                           "Stress Monocle left partial geometry commands");
            });
            handlers.SetTileLayoutSC.activated();
            assertTile(12);
            windows[0].frameGeometry = Qt.rect(100, 100, 400, 300);
            assertTile(12);
            workspace.virtualScreenGeometryChanged();
            assertTile(12);
            gap = 12;
            assertTrue(runtime.reloadIfChanged(), "Stress config reload did not complete synchronously");
            assertTile(12);
            assertTrue(windows.every(function(window) { return window.noBorder; }), "Stress decoration commands were incomplete");
            runtime.dispose();
            assertTrue(!runtime.isRunning(), "Stress disposal exceeded the synchronous Effect budget");
            assertTrue(windows.every(function(window) { return !window.noBorder; }), "Stress finalization left owned decorations");
            var stoppedGeometry = JSON.stringify(windows.map(function(window) { return window.frameGeometry; }));
            gc();
            handlers.SetMonocleLayoutSC.activated();
            workspace.windowAdded(windows[0]);
            workspace.virtualScreenGeometryChanged();
            assertTrue(JSON.stringify(windows.map(function(window) { return window.frameGeometry; })) === stoppedGeometry,
                       "Disposed native stress callbacks still mutated windows");
            assertTrue(errors.length === 1 && errors[0] === "KROHNKITE: configuration reloaded",
                       "Native stress runtime reported a defect: " + JSON.stringify(errors));
            runtime.dispose();
        } finally {
            if (runtime !== null) runtime.dispose();
            owned.forEach(function(object) { object.destroy(); });
        }
        console.log("KROHNKITE_QT_SYNC_BUDGET_OK");
    }

    Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            try {
                root.testRuntime();
            root.testPartialMaximizeRestoration();
            root.testInternalWindows();
                root.testSynchronousBudget();
                console.log("KROHNKITE_QT_SMOKE_OK");
                Qt.exit(0);
            } catch (error) {
                console.error("KROHNKITE_QT_SMOKE_FAILED", String(error));
                if (root.runtime !== null) root.runtime.dispose();
                Qt.exit(1);
            }
        }
    }
}

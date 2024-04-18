/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0

import org.kde.kwindowsystem 1.0
import QtGraphicalEffects 1.0
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.quicklaunch 1.0


import QtQuick.Dialogs 1.2
PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int iconSize: units.iconSizes.medium
    property int iconSizeSide: units.iconSizes.smallMedium
    property int cellWidth: units.gridUnit * 15
    property int cellWidthSide: units.gridUnit * 13
    property int cellHeight: iconSize +  ( Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                    highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property bool searching: (searchField.text != "")

    onVisibleChanged: {
        if (!visible) {
            reset();
        } else {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
        }
    }

    onHeightChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onWidthChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onSearchingChanged: {
        if (searching) {
            pageList.model = runnerModel;

        } else {
            reset();
        }
    }

    function reset() {
        if (!searching) {
            pageList.model = rootModel.modelForRow(0);
            pageList.currentIndex = 1;
        }
        searchField.text = "";
        pageListScrollArea.focus = true;
        pageList.currentItem.itemGrid.currentIndex = -1;
    }

    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;
        //QtBug - QTBUG-64115
        var screen = Qt.rect(screenAvail.x + screenGeom.x,
                             screenAvail.y + screenGeom.y,
                             screenAvail.width,
                             screenAvail.height);

        var offset = units.smallSpacing;

        // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
        var x = offset;
        var y = screen.height - height - offset;
        var horizMidPoint;
        var vertMidPoint;
        var appletTopLeft;
        if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = parent.height + panelSvg.margins.bottom + offset;
        } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = parent.width + panelSvg.margins.right + offset;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        }

        return Qt.point(x, y);
    }


    FocusScope {
        Layout.minimumWidth:  root.cellWidth + root.cellWidthSide + units.smallSpacing*3
        Layout.maximumWidth:  root.cellWidth + root.cellWidthSide + units.smallSpacing*3
        Layout.minimumHeight: (cellHeight *  plasmoid.configuration.numberRows) + searchField.height +  units.iconSizes.smallMedium
        Layout.maximumHeight: (cellHeight *  plasmoid.configuration.numberRows) + searchField.height +  units.iconSizes.smallMedium

        focus: true

        KCoreAddons.KUser {   id: kuser  }
        Logic {   id: logic }
        

        PlasmaCore.DataSource {
            id: pmEngine
            engine: "powermanagement"
            connectedSources: ["PowerDevil", "Sleep States"]
            function performOperation(what) {
                var service = serviceForSource("PowerDevil")
                var operation = service.operationDescription(what)
                service.startOperationCall(operation)
            }
        }

        PlasmaCore.DataSource {
            id: executable
            engine: "executable"
            connectedSources: []
            onNewData: {
                var exitCode = data["exit code"]
                var exitStatus = data["exit status"]
                var stdout = data["stdout"]
                var stderr = data["stderr"]
                exited(sourceName, exitCode, exitStatus, stdout, stderr)
                disconnectSource(sourceName)
            }
            function exec(cmd) {
                if (cmd) {
                    connectSource(cmd)
                }
            }
            signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
        }

        PlasmaComponents.Highlight {
            id: delegateHighlight
            visible: false
            z: -1 // otherwise it shows ontop of the icon/label and tints them slightly
        }

        PlasmaExtras.Heading {
            id: dummyHeading
            visible: false
            width: 0
            level: 5
        }

        TextMetrics {
            id: headingMetrics
            font: dummyHeading.font
        }

        ActionMenu {
            id: actionMenu
            onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
            onClosed: {
                if (pageList.currentItem) {
                    pageList.currentItem.itemGrid.currentIndex = -1;
                }
            }
        }


        PlasmaComponents.TextField {
            id: searchField
            anchors{
                top: parent.top
                topMargin: units.smallSpacing * 2
                left: parent.left
                right: sidePanel.left
                rightMargin: units.largeSpacing * 2
                leftMargin:  units.smallSpacing
            }

            width: root.cellWidth
            placeholderText: i18n("Search ...")
            text: ""
            onTextChanged: {
                runnerModel.query = text;
            }
            Keys.onPressed: {
                if (event.key == Qt.Key_Down) {
                    event.accepted = true;
                    console.log("$ ",pageList.currentItem.itemGrid.model.count, pageList.currentItem.itemGrid.currentIndex)
                    if(pageList.currentItem.itemGrid.model.count > 1 && pageList.currentItem.itemGrid.currentIndex !== -1)
                        pageList.currentItem.itemGrid.tryActivate(1, 0);
                    else // @todo query next group
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                } else if (event.key == Qt.Key_Right) {

                } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                    if (text != "" && pageList.currentItem.itemGrid.count > 0) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                        pageList.currentItem.itemGrid.model.trigger(0, "", null);
                        root.visible = false;
                    }
                } else if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                } else if (event.key == Qt.Key_Backtab) {
                    event.accepted = true;
                    if (!searching) {
                        filterList.forceActiveFocus();
                    }
                }
            }

            function backspace() {
                if (!root.visible) {
                    return;
                }

                focus = true;
                text = text.slice(0, -1);
            }

            function appendText(newText) {
                if (!root.visible) {
                    return;
                }

                focus = true;
                text = text + newText;
            }
        }

        PlasmaExtras.ScrollArea {
            id: pageListScrollArea

            anchors {
                top: searchField.bottom
                topMargin: units.smallSpacing
                left: parent.left
                leftMargin: units.smallSpacing
                bottomMargin: units.smallSpacing

            }
            width:  root.cellWidth
            height: (root.cellHeight * plasmoid.configuration.numberRows)
            focus: true;
            frameVisible: false;
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            verticalScrollBarPolicy: Qt.ScrollBarAsNeeded

            ListView {
                id: pageList
                anchors.fill: parent

                snapMode: ListView.SnapOneItem

                onCurrentIndexChanged: {
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }

                onCurrentItemChanged: {
                    if (!currentItem) {
                        return;
                    }

                    currentItem.itemGrid.focus = true;
                }

                onModelChanged: {
                    currentIndex = 0;
                }

                onFlickingChanged: {
                    if (!flicking) {
                        var pos = mapToItem(contentItem, root.width / 2, root.height / 2);
                        var itemIndex = indexAt(pos.x, pos.y);
                        currentIndex = itemIndex;
                    }
                }

                function cycle() {
                    enabled = false;
                    enabled = true;
                }

                function activateNextPrev(next) {
                    var newIndex
                    if (next) {
                        newIndex = pageList.currentIndex + 1;
                        if (newIndex === pageList.count) {
                            return
                        }
                        pageList.currentIndex = newIndex;
                    } else {
                        newIndex = pageList.currentIndex - 1;
                        if (newIndex < 0) {
                            return
                        }
                        pageList.currentIndex = newIndex;
                    }
                }

                delegate: Item {
                    width:  root.cellWidth
                    height: gridView.model.count >  plasmoid.configuration.numberRows ? plasmoid.configuration.numberRows * root.cellHeight : gridView.model.count * root.cellHeight
                    property Item itemGrid: gridView
                    ItemGridView {
                        id: gridView

                        anchors.fill: parent

                        cellWidth:  root.cellWidth
                        cellHeight: root.cellHeight

                        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                        verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                        dragEnabled: (index == 0)

                        model: searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(0).modelForRow(index)

                        onCurrentIndexChanged: {
                            if (currentIndex != -1 && !searching) {
                                pageListScrollArea.focus = true;
                                focus = true;
                            }
                        }

                        onCountChanged: {
                            if (searching && index == 0) {
                                currentIndex = 0;
                            }
                        }

                        onKeyNavUp: {
                            var newIndex = pageList.currentIndex - 1;
                            if (!searching && newIndex === 0) {
                                currentIndex = -1;
                                searchField.focus = true;
                                return
                            }
                            if(searching && newIndex < 0) {
                                currentIndex = -1;
                                searchField.focus = true;
                                return
                            }
                            pageList.currentIndex = newIndex;
                            pageList.currentItem.itemGrid.tryActivate(pageList.currentItem.itemGrid.model.count-1, 0);

                        }

                        onKeyNavDown: {
                            var newIndex = pageList.currentIndex + 1;
                            if (newIndex === pageList.count) {
                                return
                            }
                            pageList.currentIndex = newIndex;
                            pageList.currentItem.itemGrid.tryActivate(0, 0);
                        }
                    }

                    Kicker.WheelInterceptor {
                        anchors.fill: parent
                        z: 1
                        property int wheelDelta: 0
                        function scrollByWheel(wheelDelta, eventDelta) {
                            // magic number 120 for common "one click"
                            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                            wheelDelta += eventDelta;
                            var increment = 0;
                            while (wheelDelta >= 120) {
                                wheelDelta -= 120;
                                increment++;
                            }
                            while (wheelDelta <= -120) {
                                wheelDelta += 120;
                                increment--;
                            }
                            while (increment != 0) {
                                pageList.activateNextPrev(increment < 0);
                                increment += (increment < 0) ? 1 : -1;
                            }
                            return wheelDelta;
                        }
                        onWheelMoved: {
                            wheelDelta = scrollByWheel(wheelDelta, delta.y);
                        }
                    }


                }
            }
        }

        Item{
            id: sidePanel
            width: root.cellWidthSide
            height: parent.height
            anchors{
                left: pageListScrollArea.right
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                bottomMargin: units.largeSpacing
                leftMargin: units.largeSpacing
                rightMargin: units.smallSpacing
            }

            FileDialog {
                id: folderDialog
                visible: false
                folder: shortcuts.pictures

                function getPath(val){
                    if(val === 1)
                        return shortcuts.pictures
                    else if (val === 2)
                        return shortcuts.documents
                    else if (val === 3)
                        return shortcuts.music
                    else if (val === 4)
                        return shortcuts.home
                    else if (val === 5)
                        return shortcuts.movies
                }
            }

            Rectangle{
                id: iconUser
                height: units.iconSizes.huge
                width: height
                color: "transparent"
                anchors.left: parent.left
                anchors.leftMargin: units.smallSpacing
                anchors.top: parent.top
                anchors.topMargin: units.smallSpacing * 2

               // Image {
                PlasmaCore.IconItem {
                    id: imgAuthor
                    anchors.fill: parent
                    source: kuser.faceIconUrl.toString() || "user-identity"
                
                    visible: false
                     usesPlasmaTheme: false
                }

                OpacityMask {
                    anchors.fill: imgAuthor
                    source: imgAuthor
                    maskSource: Rectangle {
                        width: imgAuthor.width
                        height: imgAuthor.height
                        radius: iconUser.width*0.5
                        visible: false
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: {
                        KCMShell.open("user_manager")
                    }
                }
            }
            ColumnLayout{
                spacing: units.smallSpacing
                anchors.top: iconUser.bottom
                anchors.topMargin: units.largeSpacing
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                ListDelegate {
                    text: "Home"
                    highlight: delegateHighlight
                    icon: "user-home"
                    size: iconSizeSide
                    onClicked: executable.exec("dolphin --new-window "+folderDialog.getPath(4))
                }
                ListDelegate {
                    text: "Documents"
                    highlight: delegateHighlight
                    icon: "folder-documents"
                    size: iconSizeSide
                    onClicked: executable.exec("dolphin --new-window "+folderDialog.getPath(2))
                }
                ListDelegate {
                    text: "Music"
                    highlight: delegateHighlight
                    icon: "folder-music"
                    size: iconSizeSide
                    onClicked: executable.exec("dolphin --new-window "+folderDialog.getPath(3))
                }
                ListDelegate {
                    text: "Pictures"
                    highlight: delegateHighlight
                    icon: "folder-pictures"
                    size: iconSizeSide
                    onClicked: executable.exec("dolphin --new-window "+folderDialog.getPath(1))
                }
                ListDelegate {
                    text: "Videos"
                    highlight: delegateHighlight
                    icon: "folder-music"
                    size: iconSizeSide
                    onClicked: executable.exec("dolphin --new-window "+folderDialog.getPath(5))
                }

                ListDelegate {
                    text: "System Settings"
                    highlight: delegateHighlight
                    icon: "configure"
                    size: iconSizeSide
                    onClicked: logic.openUrl("file:///usr/share/applications/systemsettings.desktop")
                }

                Item{
                    Layout.fillHeight: true
                }
                Clock{}

                Item{
                    height: units.smallSpacing
                }

                RowLayout{
                    width: parent.width
                    Layout.fillWidth: true
                    ListDelegate {
                        text: i18nc("@action", "Lock Screen")
                        icon: "system-lock-screen"
                        highlight: delegateHighlight
                        enabled: pmEngine.data["Sleep States"]["LockScreen"]
                        size: iconSizeSide
                        showIcon: true
                        onClicked: pmEngine.performOperation("lockScreen")
                    }
                    ListDelegate {
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Leave ... ")
                        highlight: delegateHighlight
                        icon: "system-log-out"
                        size: iconSizeSide
                        showIcon: true
                        onClicked: pmEngine.performOperation("requestShutDown")
                    }
                }
            }
        }


        Keys.onPressed: {
            if (event.key == Qt.Key_Escape) {
                event.accepted = true;

                if (searching) {
                    reset();
                } else {
                    root.visible = false;
                }

                return;
            }

            if (searchField.focus) {
                return;
            }

            if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                searchField.backspace();
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Backtab) {
                if (pageListScrollArea.focus == true && pageList.currentItem.itemGrid.currentIndex == -1) {
                    event.accepted = true;
                    pageList.currentItem.itemGrid.tryActivate(0, 0);
                }
            } else if (event.text != "") {
                event.accepted = true;
                searchField.appendText(event.text);
            }
        }

    }

    Component.onCompleted: {
        kicker.reset.connect(reset);
        dragHelper.dropped.connect(pageList.cycle);
        reset();
    }
}

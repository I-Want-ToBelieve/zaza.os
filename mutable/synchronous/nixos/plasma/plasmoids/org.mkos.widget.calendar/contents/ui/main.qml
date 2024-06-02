/*
    SPDX-FileCopyrightText: zayronxio
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root
    property var fSize: plasmoid.configuration.fontSize
    property var textmonth: Qt.formatDateTime(new Date(), "MMMM")
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground


    function abbreviate(text, maxLength) {
        if (text.length > maxLength) {
            return text.substring(0, maxLength) + "..."
        } else {
            return text
        }
    }
    FontLoader {
    id: fontB
    source: "../fonts/Helvetica-Bold-Font.ttf"
    }
    Plasmoid.fullRepresentation: Item {
        Layout.minimumWidth: background.width
        Layout.minimumHeight: background.height
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumWidth
     Rectangle {
         id: background
         anchors.centerIn: parent
         width: datefull.height
         height: datefull.height
         radius: 25
         color: "#f8fcfc"
         focus: true
         opacity: 1
                 onActiveFocusChanged: {
            if (activeFocus) {
                background.color = "#f8fcfc"
                background.opacity = 1
                day.color = "#ff3a30"
                month.color = "#5c5c5c"
                dayNu.color = "#080808"
            } else {
                background.color = "#04000c"
                background.opacity = 0.4
                day.color = "#40ffffff"
                month.color = "#33ffffff"
                dayNu.color = "#40ffffff"
            }
        }
             ColumnLayout {
         id:  datefull
         anchors.top: parent.top
         anchors.horizontalCenter: parent.horizontalCenter
         anchors.topMargin: fSize*.4
         Layout.minimumWidth: 150
         Layout.minimumHeight: 150
         Layout.preferredWidth:  !dayandm.width > dayNu.width ? dayandm.width : dayNu.width
         Layout.preferredHeight: dayandm.height + month.height
         spacing: -fSize*.1
              Row {
                  id: dayandm
                  spacing:  20
             Kirigami.Heading {
                  id: day
                  visible: true
                   text: Qt.formatDateTime(new Date(), "ddd")
                   color: "#ff3a30"
                   font.bold: true
                   font.family: fontB.name
                   font.pixelSize: fSize
                   font.capitalization: Font.Capitalize
               }
             Kirigami.Heading {
                   id: month
                   visible: true
                   font.bold: true
                   text: (abbreviate(textmonth, 4)).replace(/\.{3}/g, "")
                   color: "#5c5c5c"
                   font.family: fontB.name
                   font.pixelSize: fSize
                   font.capitalization: Font.Capitalize
              }
              }
              Kirigami.Heading {
                  id: dayNu
                  visible: true
                   text: Qt.formatDateTime(new Date(), "d")
                   color: "#080808"
                   font.family: fontB.name
                   font.bold: true
                   font.pixelSize: fSize*4
                   font.capitalization: Font.Capitalize
            }
        }
    }
      Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                mask.text = Qt.formatDateTime(new Date(), "  ddd - MMM  ")
                dayshortNum.text = Qt.formatDateTime(new Date(), "d")

            }
        }
     Timer {
       id: timerforfocus
       running: true
       repeat: false
       interval: 1000
       onTriggered: background.forceActiveFocus()
            }

    onWidthChanged: {
         background.forceActiveFocus()
    }

    onHeightChanged: {
         background.forceActiveFocus()
    }


    MouseArea {
        anchors.fill: parent
        drag.target: parent
        hoverEnabled: true
        onClicked:  background.forceActiveFocus()
    }
        }

        }



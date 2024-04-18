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

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground

    FontLoader {
    id: fontB
    source: "../fonts/LeagueGothic-Condensed.ttf"
    }
          Plasmoid.fullRepresentation: Item {
              Layout.minimumWidth: datefull.width
              Layout.minimumHeight: datefull.height
              Layout.preferredWidth: Layout.minimumWidth
              Layout.preferredHeight: Layout.minimumHeight

              ColumnLayout {
              id:  datefull
              anchors.centerIn: parent
              Layout.minimumWidth: root.Layout.minimumWidth
              Layout.minimumHeight: root.Layout.minimumHeight
              Layout.preferredWidth: mask.width
              Layout.preferredHeight: mask.height + dayshortNum.height
              spacing: 0

                                     Kirigami.Heading {
                  id: dayshortNum
                   text: Qt.formatDateTime(new Date(), "d")
                   font.family: fontB.name
                   font.pixelSize: fSize*1.4
                   color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter

            }

             Kirigami.Heading {
                  id: mask
                  visible: false
                   text: (Qt.formatDateTime(new Date(), "  ddd - MMM  ")).replace(/\.{1}/g, "")
                   font.family: fontB.name
                   font.pixelSize: fSize
                   font.capitalization: Font.Capitalize
            }
            Rectangle{
                id: bac
                Layout.minimumWidth:5
                Layout.minimumHeight: 5
                Layout.preferredWidth: mask.width
                Layout.preferredHeight: mask.height
                radius: 100
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
                layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: mask
                            invert: true
                        }

            }
      Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                mask.text = (Qt.formatDateTime(new Date(), "  ddd - MMM  ")).replace(/\.{1}/g, "")
                dayshortNum.text = Qt.formatDateTime(new Date(), "d")

            }
        }
        }
        }
}



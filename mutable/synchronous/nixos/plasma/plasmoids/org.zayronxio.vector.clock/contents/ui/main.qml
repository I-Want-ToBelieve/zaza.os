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


    property var fSize: 60

    function cateto(n)
    {
       var hipotenusa = n/Math.sin((65*Math.PI/180))
       var cate = Math.sqrt(Math.pow(hipotenusa, 2)-Math.pow(n, 2))
       var cater = Math.round(cate)
       return cater
       }

       function hipotenusa(n)  {
       return n/Math.sin((65*Math.PI/180))
       }
           function abbreviate(text, maxLength) {
        if (text.length > maxLength) {
            return text.substring(0, maxLength) + "..."
        } else {
            return text
        }
    }

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground

    FontLoader {
    id: fontB
    source: "../fonts/Bungee-Regular.otf"
    }
    FontLoader {
    id: fontC
    source: "../fonts/Arcon-Regular.otf"
    }
    FontLoader {
    id: fontA
    source: "../fonts/DIMIS___.TTF"
    }


          Plasmoid.fullRepresentation: Item {
              id: fullbase
              Layout.minimumWidth: full.width
              Layout.minimumHeight: full.height
              Layout.preferredWidth: Layout.minimumWidth
              Layout.preferredHeight: Layout.minimumHeight

                  Rectangle {
                      id: maskday
                      width: textday.width
                      height: textday.height
                      color: "transparent"
                      visible: false
                  Canvas {

                 // canvas size
                 anchors.fill: parent

                 onPaint: {
                  // get context to draw with
                 var ctx = getContext("2d")

                 ctx.fillStyle = "red"
                 ctx.strokeStyle = "transparent"
                 ctx.beginPath()
                 // top-left start point
                 ctx.moveTo(textday.width-cateto(textday.height),textday.height)
                 // upper line
                 ctx.lineTo(textday.width,0)
                 // right line
                 ctx.lineTo(0,0)
                  // bottom line
               // left line through path closing
                ctx.lineTo(0,textday.height)
        ctx.closePath()
        // fill using fill style

        ctx.fill()
        ctx.stroke()
           }
         }
                  }
              RowLayout {
                  id: full
                  Layout.minimumWidth: textday.width + separator.width+ datefull
                  Layout.minimumHeight: separator.height
                  Layout.preferredWidth: Layout.minimumWidth
                  Layout.preferredHeight: Layout.minimumHeight

                  spacing: -25
                  Rectangle {
                  width: textday.width
                  height: textday.height
                  color: "transparent"
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: fSize*.3
                  Kirigami.Heading {
                  anchors.right: parent.right
                  anchors.rightMargin: -8
                  id: textday
                  text: (abbreviate(Qt.formatDateTime(new Date(), "dddd"),3)).replace(/\.{3}/g, "")
                  font.family: fontA.name
                  color: "white"
                  horizontalAlignment: Text.AlignRight
                  font.pixelSize: fSize*1.7
                  font.capitalization: Font.Capitalize
                  layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: maskday
                        }
            }
                  }
            Rectangle {
                id: separator
                width: cateto(base.height)*2.3
                height: fSize*3.105
                color: "transparent"
                                    Canvas {
                // canvas size
               anchors.fill: parent

             onPaint: {
        // get context to draw with
        var ctx = getContext("2d")

        ctx.fillStyle = "white"
        ctx.strokeStyle = "white"
        ctx.beginPath()
        // top-left start point
        ctx.moveTo(cateto(base.height)*2.3,0)
        // upper line
        ctx.lineTo(0,fSize*3.105)
        // right line
        ctx.closePath()
        // fill using fill style

        ctx.fill()
        ctx.stroke()
           }
         }
            }
ColumnLayout {
    spacing: 0
    id: datefull
    Layout.minimumWidth: day.width
    Layout.minimumHeight: base.height + fSize
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight
Rectangle{
    id: base
    width: day.width
    height: fSize*1.35
    color: "transparent"
    Rectangle {
        id: clockmask
        visible: false
        width: parent.width
        height: parent.height
        color: "transparent"
    Kirigami.Heading {
            id: numclock
            anchors.left: parent.left
            anchors.leftMargin: cateto(base.height)*.7
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(new Date(), "h:mm")
            color: "white"
            font.family: fontB.name
            font.pixelSize: fSize
            font.capitalization: Font.Capitalize
            }
    }
      Rectangle {
             id: clock
             anchors.right: parent.right
             visible: true
             color: "white"
             width: base.width - cateto(base.height)
             height: base.height
             layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: clockmask
                            invert: true
                        }
        }
    Canvas {
      id: backgroundClock
      // canvas size
      anchors.fill: parent

    onPaint: {
        // get context to draw with
        var ctx = getContext("2d")

        ctx.fillStyle = "white"
        ctx.strokeStyle = "transparent"
        ctx.beginPath()
        // top-left start point
        ctx.moveTo(cateto(base.height),fSize*1.43)
        // upper line
        ctx.lineTo(0,fSize*1.43)
        // right line
        ctx.lineTo(cateto(base.height),0)
        // bottom line
               // left line through path closing
        ctx.closePath()
        // fill using fill style

        ctx.fill()
        ctx.stroke()
           }
         }
                 MouseArea {
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.XAndYAxis

            onPositionChanged: {
                base.width = base.width + drag.delta.x;
                base.height = base.height + drag.delta.y;
                dynamicCanvas.requestPaint();
            }
        }
       }
       Rectangle {
            anchors.bottom: parent.bottom
                Layout.minimumWidth: day.width
          Layout.minimumHeight: fSize
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight
            color: "transparent"
            Kirigami.Heading {
            id: day
            font.capitalization: Font.Capitalize
            text: (Qt.formatDateTime(new Date(), "MMMM d yyyy")).toUpperCase()
            color: "white"
            font.family: fontC.name
            font.bold: false
            font.pixelSize: fSize*.6
            }
                          Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                day.text = (Qt.formatDateTime(new Date(), "MMMM d yyyy")).toUpperCase()
                numclock.text = Qt.formatDateTime(new Date(), "h:mm")
                textday.text = (abbreviate(Qt.formatDateTime(new Date(), "dddd"),3)).replace(/\.{3}/g, "")

            }
        }
    }
}
              }
        }


}


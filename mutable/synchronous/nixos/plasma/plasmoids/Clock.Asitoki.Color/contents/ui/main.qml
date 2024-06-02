/*
    SPDX-FileCopyrightText: zayronxio
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root

    property var textC: plasmoid.configuration.textinC
    property string hgColor: !plasmoid.configuration.useSystemHG ? plasmoid.configuration.coloraccentpersonalizado : PlasmaCore.ColorScope.highlightColor
    property string geColor: plasmoid.configuration.colorGeneral

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground

    FontLoader {
    id: berkshireswash
    source: "../fonts/berkshireswash-regular.ttf"
    }
    FontLoader {
    id: eas
    source: "../fonts/EASPORTS15.ttf"
    }
    FontLoader {
    id: acherus
    source: "../fonts/AcherusGrotesque-Light.ttf"
    }

          Plasmoid.fullRepresentation: RowLayout {
              id: base
              Layout.minimumWidth: 300
              Layout.minimumHeight: 300
              Layout.preferredWidth: Layout.minimumWidth
              Layout.preferredHeight: Layout.minimumHeight
              ColumnLayout {
                  Layout.minimumWidth: parent.width
                  Layout.minimumHeight: parent.height
                  Layout.preferredWidth: Layout.minimumWidth
                  Layout.preferredHeight: Layout.minimumHeight
                  spacing: 0
                  Item {
                      id: day
                      Layout.preferredHeight: base.height*.56
                      Layout.preferredWidth: base.width
                      Rectangle {
                          id: maskdaytext
                          width: parent.width
                          height: parent.height
                          color: "transparent"
                          visible: false
                          Rectangle {
                              id: bubblediamask
                              width: parent.height*.43
                              height: parent.height*.43
                              radius: parent.height*3
                              color: "black"
                              anchors.left: parent.left
                              anchors.leftMargin: base.width/2 + parent.height*.17
                               }
                          Rectangle {
                              id: med
                              width: parent.height*.85
                              height: parent.height*.85
                              color: "transparent"
                              radius: parent.height*3
                              anchors.horizontalCenter: parent.horizontalCenter
                              anchors.bottom: parent.bottom
                           Text {
                              id: daytext
                              anchors.centerIn: parent
                              text: (Qt.formatDateTime(new Date(), "dddd")).substring(0,2)
                              color: "black"
                              font.capitalization: Font.Capitalize
                              font.family: berkshireswash.name
                              font.pixelSize: Math.min(med.width, med.height) * 0.7
                                }
                                }
                         }

                        Rectangle {
                           width: parent.width
                           height : parent.height
                           color: "transparent"
                           Rectangle {
                              id: background_daytext
                              anchors.horizontalCenter: parent.horizontalCenter
                              anchors.bottom: parent.bottom
                              height: parent.height*.85
                              width: parent.height*.85
                              color: geColor
                              radius: parent.height*3
                              }
                          layer.enabled: true
                              layer.effect: OpacityMask {
                              maskSource: maskdaytext
                              invert: true
                                }
                         }
                       Rectangle {
                          id: maskdaynum
                          width: parent.height*.43
                          height: parent.height*.43
                          radius: parent.height*3
                          color: "transparent"
                          visible: false
                          Text {
                              id: daynum
                              anchors.centerIn: parent
                              text: Qt.formatDateTime(new Date(), "dd")
                              font.pixelSize: Math.min(maskdaynum.width, maskdaynum.height) * 0.65
                              font.family: eas.name
                            }
                       }
                      Rectangle {
                          id: background_daynum
                          width: parent.height*.431
                          height: parent.height*.431
                          radius: parent.height*3
                          color: hgColor
                          visible: true
                          anchors.left: parent.left
                          anchors.leftMargin: base.width/2 + parent.height*.169
                          layer.enabled: true
                               layer.effect: OpacityMask {
                               maskSource: maskdaynum
                               invert: true
                                }
                       }
                      Timer {
                         id: timer_day
                         interval: 8.64e+7-((new Date().getHours()*60*60*1000)+(new Date().getMinutes()*60*1000)+(new Date().getSeconds()*1000)+new Date().getMilliseconds())
                         running: true
                         repeat: true
                         onTriggered: {
                                 daynum.text = Qt.formatDateTime(new Date(), "dd")
                                 timer_day.interval = 8.64e+7
                             }
                         }
                     }
                     Item {
                         Layout.preferredHeight: parent.height*.22
                         anchors.horizontalCenter: parent.horizontalCenter
                         Text {
                             id: mes
                             height: parent.height*.22
                             text:  Qt.formatDateTime(new Date(), "MMMM")
                             font.capitalization: Font.Capitalize
                             font.pixelSize: Math.min(background_daynum.width, background_daynum.height) * 0.8
                             font.family: acherus.name
                             anchors.horizontalCenter: parent.horizontalCenter
                             anchors.top: parent.top
                             anchors.topMargin: - font.pixelSize*.3
                             color: geColor
                             Timer {
                                 id: timer_mes
                                 interval: 8.64e+7-((new Date().getHours()*60*60*1000)+(new Date().getMinutes()*60*1000)+(new Date().getSeconds()*1000)+new Date().getMilliseconds())
                                 running: true
                                 repeat: true
                                 onTriggered: {
                                     daynum.text = Qt.formatDateTime(new Date(), "MMMM")
                                     daytext.text = (Qt.formatDateTime(new Date(), "dddd")).substring(0,2)
                                     timer_mes.interval = 8.64e+7
                                       }
                                   }
                            }
                     }

                    Row {
                        id: clock
                        Layout.preferredWidth: mashors.width + separator.width + minutes.width
                        Layout.preferredHeight: parent.height*.22
                        anchors.horizontalCenter: parent.horizontalCenter
                        Rectangle {
                            id: hors
                            width: parent.height
                            height: parent.height
                            color: "transparent"
                            Rectangle {
                                id: mashors
                                width: parent.width
                                height: parent.height
                                visible: false
                                color: "transparent"
                                radius: parent.height*3
                                Text {
                                    id: horsnum
                                    anchors.centerIn: parent
                                    text: Qt.formatDateTime(new Date(), "h")
                                    font.pixelSize: Math.min(clock.width, clock.height) * 0.7
                                    font.bold: true
                                }
                            }
                          Rectangle {
                              id: background_hors
                              color: background_daynum.color
                              radius: parent.height*3
                              width: parent.width
                              height: parent.height
                              layer.enabled: true
                                   layer.effect: OpacityMask {
                                   maskSource: mashors
                                   invert: true
                                }
                        }
                        }
                        Text {
                            id: separator
                            text: ":"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Math.min(clock.width, clock.height) * 0.7
                            color: geColor
                            font.bold: true
                        }

                        Text {
                            id: minutes
                            text: Qt.formatDateTime(new Date(), "mm")
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Math.min(clock.width, clock.height) * 0.7
                            color: geColor
                            font.bold: true
                        }
                        Timer {
                            interval: 1000
                            repeat: true
                            running: true
                            onTriggered: {
                                minutes.text = Qt.formatDateTime(new Date(), "mm")
                                horsnum.text = Qt.formatDateTime(new Date(), "h")
                            }
                        }
                    }
                }
            }
        }




/*
    SPDX-FileCopyrightText: zayronxio
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore


Item {
    id: root
    width: 400
    height: 200

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground

    property string useCoordinatesIp: plasmoid.configuration.useCoordinatesIp
    property string temperatureUnit: plasmoid.configuration.temperatureUnit

    property string latitudeC: plasmoid.configuration.latitudeC
    property string longitudeC: plasmoid.configuration.longitudeC

    property string latitude: (useCoordinatesIp === "true") ? "null" : (latitudeC === "0") ? "null" : latitudeC
    property string longitud: (useCoordinatesIp === "true") ? "null" : (longitudeC === "0") ? "null" : longitudeC


    property string textbycommand: (" "+latitude+" "+longitud+" ")

    property string temperatura: "0"
    property string temperaturaRound: Math.round(temperatura)+"°"
    property string temperaturaFRound: Math.round(temperaturaF)+"°"
    property string temperaturaF: (temperatura*9 / 5)+ 32
    property int codeweather: 0
    property string loc: "null"
    property string minTemp: "0"
    property string maxTemp: "0"
    property string command: "bash $HOME/.local/share/plasma/plasmoids/weather.bicolor.widget/contents/ui/lib/datos.sh"

    PlasmaCore.DataSource {
      id: executable
      engine: "executable"
      connectedSources: []
      onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName) // cmd finished
                  }
     function exec(cmd) {
            connectSource(cmd)
           }
     signal exited(int exitCode, int exitStatus, string stdout, string stderr)
       }

   Connections {
     target: executable
     onExited: {
                    temperatura = stdout
                }
          }




PlasmaCore.DataSource {
        id: executable2
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName) // cmd finished
                   }
        function exec(cmd) {
            connectSource(cmd)
}
signal exited(int exitCode, int exitStatus, string stdout, string stderr)
}

Connections {
target: executable2
onExited: {
                    loc = stdout
}
}

PlasmaCore.DataSource {
        id: executable3
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName) // cmd finished
                   }
function exec(cmd) {
            connectSource(cmd)
}
signal exited(int exitCode, int exitStatus, string stdout, string stderr)
}

Connections {
target: executable3
onExited: {
                    codeweather = stdout
}
}

PlasmaCore.DataSource {
        id: executable4
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName) // cmd finished
                   }
function exec(cmd) {
            connectSource(cmd)
}
signal exited(int exitCode, int exitStatus, string stdout, string stderr)
}

Connections {
      target: executable4
      onExited: {
          minTemp = stdout
          }
      }
PlasmaCore.DataSource {
        id: executable5
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName) // cmd finished
                   }
function exec(cmd) {
            connectSource(cmd)
}
signal exited(int exitCode, int exitStatus, string stdout, string stderr)
}

Connections {
target: executable5
onExited: {
                    maxTemp = stdout
}
}

Component.onCompleted: {
            var cmd = command+textbycommand+"tem"
            var cmd1 = command+textbycommand+"ubi"+" "+(Qt.locale().name).replace("_", "-")
            var cmd2 = command+textbycommand+"codetem"
            var cmd3 = command+textbycommand+"min"
            var cmd4 = command+textbycommand+"max"
            executable.exec(cmd)
            executable2.exec(cmd1)
            executable3.exec(cmd2)
            executable4.exec(cmd3)
            executable5.exec(cmd4)
}
   function asingicon(){
            let wmocodes = {
              0 : "clear",
              1 : "few-clouds",
              2 : "few-clouds",
              3 : "clouds",
              51 : "showers-scattered",
              53 : "showers-scattered",
              55 : "showers-scattered",
              56 : "showers-scattered",
              57 : "showers-scattered",
              61 : "showers",
              63 : "showers",
              65 : "showers",
              66 : "showers-scattered",
              67 : "showers",
              71 : "snow-scattered",
              73 : "snow",
              75 : "snow",
              77 : "hail",
              80 : "showers",
              81 : "showers",
              82 : "showers",
              85 : "snow-scattered",
              86 : "snow",
              95 : "storm",
              96 : "storm",
              99 : "storm",
                     }
            var cicloOfDay = isday()

            var iconName = "weather-" + (wmocodes[codeweather] || "unknown") + "-" +cicloOfDay

    return iconName
    }

    function isday() {
    var timeActual = Qt.formatDateTime(new Date(), "h")
    if (timeActual < 6) {
      if (timeActual > 19) {
        return "night"
      } else {
        return "day"
      }
    } else {
      if (timeActual > 19) {
        return "night"
      } else {
        return "day"
      }
    }
  }
   function porcentOftext(a,b) {
          var porcenttext = b/a
          return  porcenttext
        }
   Column {
       id: base
       width: parent.width < parent.height*2 ? parent.width : parent.height*2
       height: width/2
       anchors.centerIn: parent

       Row {
           id: twoRectangle
           width: base.width
           height: base.height
           Rectangle {
             width: parent.width/2
             height: parent.height
             color: "#ff444f5b"
             Column {
               anchors.verticalCenter: parent.verticalCenter
               width: parent.width
               height: parent.height*.7
               Text {
                 text: (temperatureUnit === "0") ? temperaturaRound :  temperaturaFRound
                 color: "white"
                 font.bold: true
                 font.pixelSize: parent.height*.5
                 anchors.horizontalCenter: parent.horizontalCenter
              }

               Text {
                 id: textLocalidadPrev
                 visible: false
                 text: loc
                 font.bold: true
                 font.pixelSize: parent.height*.3
              }
              Text {
                id: textWithWrap
                visible: false
                text: loc
                font.bold: true
                wrapMode: porcentOftext(textLocalidadPrev.width,(parent.width*.9)) > .7 ? Text.WordWrap : Text.NoWrap
                font.pixelSize:  porcentOftext(textLocalidadPrev.width,(parent.width*.9)) > .7 ? textLocalidadPrev.font.pixelSize : textLocalidadPrev.font.pixelSize*porcentOftext(textLocalidadPrev.width,(parent.width*.9))
              }
              Text {
                id: textlocFinal
                color: "white"
                text: loc
                wrapMode: textWithWrap.wrapMode
                font.pixelSize:  porcentOftext(textWithWrap.width,(parent.width*.9)) > .101 ? textWithWrap.font.pixelSize : textWithWrap.font.pixelSize*porcentOftext(textWithWrap.width,(parent.width*.9))
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
          Rectangle {
            width: parent.width/2
            height: parent.height
            color: "#fff7f8f9"
            Column {
              width: parent.width
              height:parent.height

              Rectangle {
                width: parent.width
                height: parent.height*.75
                color: "transparent"

                Image {
                  width: parent.height*.75
                  height: width
                  source: "../icons/"+asingicon()
                  sourceSize: Qt.size(width, width)
                  fillMode: Image.PreserveAspectFit
                  anchors.centerIn: parent
                }
              }

              Rectangle {
                id: secondrectangle
                color: "#ff3fa4bb"
                width: parent.width
                height: parent.height*.25
                Row {
                  width: down.impliciWidth + textOfMinTemp.impliciWidth + separator.width + up.impliciWidth + textOfMaxTemp.impliciWidth
                  height: parent.height
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: 0
                      Image {
                        id: down
                        width: parent.height*.7
                        height: width
                        source: "../icons/down.svg"
                        sourceSize: Qt.size(width, width)
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        height: parent.height
                        id: textOfMinTemp
                        text: Math.round(minTemp)+"°"
                        color: "white"
                        font.pixelSize: parent.height*.5
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                      }
                      Rectangle {
                        id: separator
                        width: parent.width*.15
                        height: parent.height
                        color: "transparent"
                      }
                      Image {
                        id: up
                        width: parent.height*.7
                        height: width
                        source: "../icons/up.svg"
                        sourceSize: Qt.size(width, width)
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        height: parent.height
                        id: textOfMaxTemp
                        wrapMode: Text.NoWrap
                        text: Math.round(maxTemp)+"°"
                        color: "white"
                        font.pixelSize: parent.height*.5
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                      }
                }
              }
            }
          }

           }
        Timer {
            interval: 900000
            running: true
            repeat: true
            onTriggered: {
               var cmd = command+textbycommand+"tem"
            var cmd1 = command+textbycommand+"ubi"+" "+(Qt.locale().name).replace("_", "-")
            var cmd2 = command+textbycommand+"codetem"
            var cmd3 = command+textbycommand+"min"
            var cmd4 = command+textbycommand+"max"
            executable.exec(cmd)
            executable2.exec(cmd1)
            executable3.exec(cmd2)
            executable4.exec(cmd3)
            executable5.exec(cmd4)
                       }
        }
   }
}

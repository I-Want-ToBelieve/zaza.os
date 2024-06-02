import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.11
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: configRoot

    signal configurationChanged

    property alias cfg_coloraccentpersonalizado: colorperso.text
    property alias cfg_useSystemHG: useSystemAccentColor.checked
    property alias cfg_colorGeneral: color.text

    ColumnLayout {
        spacing: units.smallSpacing * 2



        RowLayout{
            Label {
                text: i18n("color")
            }
             CheckBox {
            id: useSystemAccentColor
            text: i18n('Use system color for text')
            Layout.columnSpan: 2
        }
        }
        RowLayout{
            visible: (useSystemAccentColor.checked === true) ? false : true

            Label {
                text: i18n("custom color")
            }
            TextField {
                id: colorperso
                width: 200
            }
        }
                RowLayout{
            Label {
                text: i18n("Color")
            }
            TextField {
                id: color
                width: 200
            }
        }
}

}

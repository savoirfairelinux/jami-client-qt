import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import Qt.labs.platform 1.1

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"



ColumnLayout{
    id:root

    property int itemWidth

    function monitorAndReceiveLogs(continuous){
        SettingsAdapter.monitorAndReceiveLogs(continuous)
    }

    LogsView{
        id: logsView
    }

    Label{
        Layout.fillWidth: true
        text: JamiStrings.troubleshootTitle
        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true
        color: JamiTheme.textColor

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    RowLayout{
        Text{
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.rightMargin: JamiTheme.preferredMarginSize

            text: JamiStrings.troubleshootText
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter

            color: JamiTheme.textColor

        }

        MaterialButton {
            id: enableTroubleshootingButton

            Layout.alignment: Qt.AlignRight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.preferredWidth: itemWidth/1.5

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            outlined: true

            text: JamiStrings.troubleshootButton

            onClicked: {
                logsView.open()
            }
        }


    }



}


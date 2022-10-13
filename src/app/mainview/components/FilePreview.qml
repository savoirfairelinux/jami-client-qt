import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import QtWebEngine

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Component {
    id: dataTransferMsgComp

    Rectangle {
        id: dataTransferRect

        clip: true
        width: (documents.width - spacingLength ) / numberElementsPerRow
        height: width
        color: "transparent"

        ColumnLayout{
            anchors.fill: parent
            anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins

            Text {
                id: myText

                text: TransferName
                color: JamiTheme.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.preferredHeight: parent.height - myText.height - JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.preferredWidth: parent.width
                Layout.rightMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.bottomMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                color: "transparent"

                Rectangle {
                    id: rectContent

                    anchors.fill: parent
                    anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins
                    color: "transparent"
                    border.color: CurrentConversation.color
                    border.width: 2
                    radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                    layer.enabled: true

                    ResponsiveImage {
                        id: paperClipImage

                        source: JamiResources.link_black_24dp_svg
                        width: parent.width / 2
                        height: parent.height / 2
                        anchors.centerIn: parent
                        color: JamiTheme.textColor

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onEntered: {
                                cursorShape = Qt.PointingHandCursor
                            }

                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    ctxMenu.x = mouse.x
                                    ctxMenu.y = mouse.y
                                    ctxMenu.openMenu()
                                } else {
                                    Qt.openUrlExternally("file://" + Body)
                                }
                            }
                        }
                        SBSContextMenu {
                            id: ctxMenu

                            msgId: Id
                            location: Body
                            transferId: Id
                            transferName: TransferName
                        }
                    }
                }
            }
        }
    }
}

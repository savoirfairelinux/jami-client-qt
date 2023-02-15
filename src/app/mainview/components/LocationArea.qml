import QtQuick
import QtQuick.Layouts
import QtQuick.Controls


import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../webengine/map"
import "../../commoncomponents"


Rectangle {
    id: root

    property string attachedAccountId: CurrentAccount.id

    color: JamiTheme.locationAreaColor
    height: mainFlow.height + 10
    width: parent.width
    //property bool reducedMode: width > 600 ? false : true

    onWidthChanged: {
        console.warn("width,", width)
    }

    Flow {
        id: mainFlow

        width: parent.width

        RowLayout {
            id: iconRow

            //anchors.top: parent.top
            Layout.verticalCenter: Qt.AlignVCenter

            spacing: 20
            //height: 40

            BlinkingLocationIcon {
                Layout.leftMargin: 20
                isSharing: true
                arrowTimerVisibility: locationIconTimer.showIconArrow
                color: JamiTheme.sharePositionIndicatorColor
            }

            Text {
                text: "You're sharing your location"
                font.pointSize: JamiTheme.textFontSize + 2
            }
        }

        Item {
            width: Math.max(root.width - iconRow.width - buttonsRow.width, 30)
            height: 5
        }

        RowLayout {
            id: buttonsRow
            //            anchors.right: reducedMode ? iconRow.right : parent.right
            //            anchors.top: reducedMode ? iconRow.bottom : parent.top
            spacing: 20
            //height: 40

            Item {
                Layout.preferredWidth: textmetricShowLocation.width
                Layout.preferredHeight: parent.height

                TextMetrics {
                    id: textmetricShowLocation
                    text: "show location"
                    font.pointSize: JamiTheme.textFontSize + 2
                    font.bold: true
                }

                Button {
                    anchors.centerIn: parent
                    contentItem: Text {
                        text: "show location"
                        font.pointSize: JamiTheme.textFontSize + 2
                        color: JamiTheme.detailsShareLocationButtonBackgroundColor
                        font.bold: parent.hovered ? true : false
                    }
                    background: Rectangle {
                        visible: false
                    }
                    onClicked: {
                        PositionManager.setMapActive(CurrentAccount.id)
                    }
                }
            }

            Rectangle {
                height: 30
                width: 2
                color: "black"
            }

            Item {
                Layout.preferredWidth: textmetricStopSharing.width
                Layout.preferredHeight: parent.height

                TextMetrics {
                    id: textmetricStopSharing
                    text: "stop sharing"
                    font.pointSize: JamiTheme.textFontSize + 2
                    font.bold: true
                }

                Button {
                    anchors.centerIn: parent
                    property bool stopAllSharing: !(PositionManager.positionShareConvIdsCount >= 2
                                                    && PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId))
                    property string attachedAccountId: CurrentAccount.id

                    contentItem: Text {
                        text: "stop sharing"
                        font.pointSize: JamiTheme.textFontSize + 2
                        font.bold: parent.hovered ? true : false
                        color: JamiTheme.detailsShareLocationButtonBackgroundColor
                    }

                    background: Rectangle {
                        visible: false
                    }

                    onClicked: {
                        if (stopAllSharing) {
                            PositionManager.stopSharingPosition();
                        } else {
                            var component = Qt.createComponent("../../webengine/map/StopSharingPositionPopup.qml");
                            var sprite = component.createObject(root);
                            sprite.open()
                        }
                    }
                }
            }

            PushButton {
                id: btnClose

                Layout.rightMargin: 20
                width: 30
                height: 30
                imageContainerWidth: 30
                imageContainerHeight : 30
                radius : 5
                imageColor: "black"
                normalColor: JamiTheme.transparentColor
                source: JamiResources.round_close_24dp_svg
                onClicked: { root.destroy() }
            }
        }
    }
}

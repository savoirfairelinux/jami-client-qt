import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtWebEngine 1.10
import QtWebChannel 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Item {

    property bool sentByMe
    property var timeStampRegularMessage
    property var regularMessageBody
    property var regMessageImageId


    Column{

        id: column
        bottomPadding: 10
        Layout.fillWidth: true
        anchors.right: sentByMe ? listView.contentItem.right : undefined


        Row {
            id: row
            spacing: 5
            Layout.fillWidth: true
            anchors.right: sentByMe ? parent.right : undefined

            Avatar{
                id: avatar
                width: 30
                height: 30
                imageId: sentByMe ? "" : Author
                showPresenceIndicator: false
                mode: Avatar.Mode.Contact
                visible: true
            }

            Rectangle {
                id: textBackground
                height: messageText.implicitHeight + 24
                radius: 20

                width:  Math.min(messageText.implicitWidth + 24,
                                 300)
                color: sentByMe ? "#cfd8dc" : "#cfebf5"


                Rectangle {
                    id: squareRect

                    visible: true
                    color: textBackground.color
                    height: textBackground.radius
                    width: textBackground.width / 2
                    anchors.bottom: textBackground.bottom
                    anchors.left: sentByMe ? undefined : textBackground.left
                    anchors.right: sentByMe ? textBackground.right : undefined

                }
                Label {
                    id: messageText
                    text: regularMessageBody

                    anchors.fill: parent
                    anchors.margins: 12
                    wrapMode: Label.WrapAnywhere
                    color: sentByMe ? "black" : "black"
                }

            }

            Rectangle{
                id: dummyMessageSpace
                visible: false
                color: "black"
                width: 10
                height: 10
            }

        }

//        Row{

//            anchors.right: row.right
//            Loader{
//                anchors.right: undefined
//                id: timestampLoader
//                Component.onCompleted: {
//                    sourceComponent = timestampComponent
//                    dummyTimeSpace.visible = true
//                }

//                Component{
//                    id: timestampComponent
//                    Label {
//                        id: timestampText
//                        text: timeStampRegularMessage
//                        color: "lightgrey"
//                    }
//                }
//            }
//            Rectangle{
//                id: dummyTimeSpace
//                visible: false
//                color: "black"
//                height: 10
//                width: 15
//            }

//        }
    }

}

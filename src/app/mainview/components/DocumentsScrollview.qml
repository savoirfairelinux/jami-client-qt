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

Flickable {
    id: documents

    contentHeight: flow.implicitHeight
    contentWidth: width

    property int spacingFlow: JamiTheme.swarmDetailsPageDocumentsMargins
    property int numberElementsPerRow: {
        var sizeW = flow.width
        var breakSize = JamiTheme.swarmDetailsPageDocumentsMediaSize
        return Math.floor(sizeW / breakSize)
    }
    property int spacingLength: spacingFlow * (numberElementsPerRow - 1)

    onVisibleChanged: {
        if (visible) {
            MessagesAdapter.getConvMedias()
        } else {
            MessagesAdapter.mediaMessageListModel = null
        }
    }
    Flow {
        id: flow

        width: parent.width
        spacing: spacingFlow
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: MessagesAdapter.mediaMessageListModel

            delegate: Loader {
                id: loaderRoot

                sourceComponent: {
                    if(Status === Interaction.Status.TRANSFER_FINISHED || Status === Interaction.Status.SUCCESS ){
                        if (Object.keys(MessagesAdapter.getMediaInfo(Body)).length !== 0 && WITH_WEBENGINE)
                            return localMediaMsgComp

                        return fileMsgComp
                    }
                }

                FilePreview {
                    id: fileMsgComp
                }
                MediaPreview {
                    id: localMediaMsgComp
                }
            }
        }
    }
}

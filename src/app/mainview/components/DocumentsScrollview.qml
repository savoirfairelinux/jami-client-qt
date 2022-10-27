/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
    id: root

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

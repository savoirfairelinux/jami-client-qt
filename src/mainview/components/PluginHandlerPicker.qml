/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Popup {
    id: root

    property bool isCall
    property string pluginId: ""
    property string handlerName: ""

    width: JamiTheme.preferredDialogWidth
    height: JamiTheme.pluginHandlersPopupViewHeight + JamiTheme.pluginHandlersPopupViewDelegateHeight

    modal: true

    contentItem: StackView {
        id: stack
        initialItem: pluginhandlerPreferenceStack
        anchors.fill: parent
    }

    Component {
        id: pluginhandlerPreferenceStack

        Rectangle {
            color: JamiTheme.backgroundColor
            radius: 10
            anchors.fill: parent

            Connections {
                target: root

                function onAboutToShow(visible) {
                    // Reset the model on each show.
                    if (isCall) {
                        pluginhandlerPickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(CurrentConversation.callId)
                    } else {
                        var peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversation.uris[0]
                        pluginhandlerPickerListView.model = PluginAdapter.getChatHandlerSelectableModel(LRCInstance.currentAccountId, peerId)
                    }
                }
            }

            function toggleHandlerSlot(handlerId, isLoaded) {
                if (isCall) {
                    PluginModel.toggleCallMediaHandler(handlerId, CurrentConversation.callId, !isLoaded)
                    pluginhandlerPickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(CurrentConversation.callId)
                } else {
                    var accountId = LRCInstance.currentAccountId
                    var peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversation.uris[0]
                    PluginModel.toggleChatHandler(handlerId, accountId, peerId, !isLoaded)
                    pluginhandlerPickerListView.model = PluginAdapter.getChatHandlerSelectableModel(accountId, peerId)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.bottomMargin: 5

                RowLayout {
                    height: JamiTheme.preferredFieldHeight

                    Text {
                        Layout.topMargin: 10
                        Layout.leftMargin: 5 + closeButton.width
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true

                        font.pointSize: JamiTheme.textFontSize
                        font.bold: true

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: JamiTheme.textColor

                        text: qsTr("Choose plugin")
                    }

                    PushButton {
                        id: closeButton
                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: 5
                        Layout.topMargin: 5

                        source: JamiResources.round_close_24dp_svg
                        imageColor: JamiTheme.textColor

                        onClicked: {
                            root.close()
                        }
                    }
                }

                ListViewJami {
                    id: pluginhandlerPickerListView

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: {
                        if (isCall) {
                            return PluginAdapter.getMediaHandlerSelectableModel(CurrentConversation.callId)
                        } else {
                            var peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversation.uris[0]
                            return PluginAdapter.getChatHandlerSelectableModel(LRCInstance.currentAccountId, peerId)
                        }
                    }

                    clip: true

                    delegate: PluginHandlerItemDelegate {
                        id: pluginHandlerItemDelegate
                        visible: PluginModel.getPluginsEnabled()
                        width: pluginhandlerPickerListView.width
                        height: JamiTheme.pluginHandlersPopupViewDelegateHeight

                        handlerName : HandlerName
                        handlerId: HandlerId
                        handlerIcon: HandlerIcon
                        isLoaded: IsLoaded
                        pluginId: PluginId

                        onBtnLoadHandlerToggled: {
                            toggleHandlerSlot(HandlerId, isLoaded)
                        }

                        onOpenPreferences: {
                            root.handlerName = handlerName
                            root.pluginId = pluginId
                            stack.push(pluginhandlerPreferenceStack2, StackView.Immediate)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: pluginhandlerPreferenceStack2

        Rectangle {
            color: JamiTheme.backgroundColor
            radius: 10
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.bottomMargin: 5

                RowLayout {
                    height: JamiTheme.preferredFieldHeight

                    BackButton {
                        id: backButton

                        Layout.leftMargin: 5
                        Layout.topMargin: 5

                        toolTipText: JamiStrings.goBackToPluginsList

                        onClicked: {
                            stack.pop(null, StackView.Immediate)
                        }
                    }

                    Text {
                        Layout.topMargin: 10
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true

                        font.pointSize: JamiTheme.textFontSize
                        font.bold: true

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                        text: qsTr("Preferences")
                    }

                    PushButton {
                        id: closeButton2
                        Layout.rightMargin: 5
                        Layout.topMargin: 5

                        source: JamiResources.round_close_24dp_svg
                        imageColor: JamiTheme.textColor

                        onClicked: {
                            root.close()
                        }
                    }
                }

                ListViewJami {
                    id: pluginhandlerPreferencePickerListView

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: PreferenceItemListModel {
                        id: handlerPickerPrefsModel
                        lrcInstance: LRCInstance
                        accountId_: LRCInstance.currentAccountId
                        mediaHandlerName_: handlerName
                        pluginId_: pluginId
                    }

                    clip: true

                    delegate: PreferenceItemDelegate {
                        id: pluginHandlerPreferenceDelegate
                        width: pluginhandlerPreferencePickerListView.width
                        height: JamiTheme.pluginHandlersPopupViewDelegateHeight

                        preferenceName: PreferenceName
                        preferenceSummary: PreferenceSummary
                        preferenceType: PreferenceType
                        preferenceCurrentValue: PreferenceCurrentValue
                        pluginId: PluginId
                        currentPath: CurrentPath
                        preferenceKey : PreferenceKey
                        fileFilters: FileFilters
                        isImage: IsImage
                        enabled: Enabled
                        pluginListPreferenceModel: PluginListPreferenceModel {
                            id: handlerPickerPreferenceModel

                            lrcInstance: LRCInstance
                            preferenceKey : PreferenceKey
                            accountId_: LRCInstance.currentAccountId
                            pluginId: PluginId
                        }

                        onClicked:  pluginhandlerPreferencePickerListView.currentIndex = index

                        onBtnPreferenceClicked: {
                            PluginModel.setPluginPreference(LRCInstance.currentAccountId, pluginId, preferenceKey, preferenceNewValue)
                            handlerPickerPrefsModel.reset()
                        }
                    }
                }
            }
        }
    }

    onAboutToHide: stack.pop(null, StackView.Immediate)

    background: Rectangle {
        color: "transparent"
    }
}

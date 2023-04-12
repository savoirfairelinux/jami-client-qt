/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Popup {
    id: root
    property string handlerName: ""
    property bool isCall
    property string pluginId: ""

    height: JamiTheme.pluginHandlersPopupViewHeight + JamiTheme.pluginHandlersPopupViewDelegateHeight
    modal: true
    width: JamiTheme.preferredDialogWidth

    onAboutToHide: stack.pop(null, StackView.Immediate)

    Component {
        id: pluginhandlerPreferenceStack
        Rectangle {
            anchors.fill: parent
            color: JamiTheme.backgroundColor
            radius: 10

            function toggleHandlerSlot(handlerId, isLoaded) {
                if (isCall) {
                    PluginModel.toggleCallMediaHandler(handlerId, CurrentCall.id, !isLoaded);
                    pluginhandlerPickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(CurrentCall.id);
                } else {
                    var accountId = LRCInstance.currentAccountId;
                    var peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversationMembers[0];
                    PluginModel.toggleChatHandler(handlerId, accountId, peerId, !isLoaded);
                    pluginhandlerPickerListView.model = PluginAdapter.getChatHandlerSelectableModel(accountId, peerId);
                }
            }

            Connections {
                target: root

                function onAboutToShow(visible) {
                    // Reset the model on each show.
                    if (isCall) {
                        pluginhandlerPickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(CurrentCall.id);
                    } else {
                        var peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversationMembers[0];
                        pluginhandlerPickerListView.model = PluginAdapter.getChatHandlerSelectableModel(LRCInstance.currentAccountId, peerId);
                    }
                }
            }
            ColumnLayout {
                anchors.bottomMargin: 5
                anchors.fill: parent

                RowLayout {
                    height: JamiTheme.preferredFieldHeight

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.leftMargin: 5 + closeButton.width
                        Layout.topMargin: 10
                        color: JamiTheme.textColor
                        font.bold: true
                        font.pointSize: JamiTheme.textFontSize
                        horizontalAlignment: Text.AlignHCenter
                        text: JamiStrings.choosePlugin
                        verticalAlignment: Text.AlignVCenter
                    }
                    PushButton {
                        id: closeButton
                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: 5
                        Layout.topMargin: 5
                        imageColor: JamiTheme.textColor
                        source: JamiResources.round_close_24dp_svg

                        onClicked: {
                            root.close();
                        }
                    }
                }
                JamiListView {
                    id: pluginhandlerPickerListView
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    model: {
                        if (isCall) {
                            return PluginAdapter.getMediaHandlerSelectableModel(CurrentCall.id);
                        } else {
                            var peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversationMembers[0];
                            return PluginAdapter.getChatHandlerSelectableModel(LRCInstance.currentAccountId, peerId);
                        }
                    }

                    delegate: PluginHandlerItemDelegate {
                        id: pluginHandlerItemDelegate
                        handlerIcon: HandlerIcon
                        handlerId: HandlerId
                        handlerName: HandlerName
                        height: JamiTheme.pluginHandlersPopupViewDelegateHeight
                        isLoaded: IsLoaded
                        pluginId: PluginId
                        visible: PluginModel.getPluginsEnabled()
                        width: pluginhandlerPickerListView.width

                        onBtnLoadHandlerToggled: {
                            toggleHandlerSlot(HandlerId, isLoaded);
                        }
                        onOpenPreferences: {
                            root.handlerName = handlerName;
                            root.pluginId = pluginId;
                            stack.push(pluginhandlerPreferenceStack2, StackView.Immediate);
                        }
                    }
                }
            }
        }
    }
    Component {
        id: pluginhandlerPreferenceStack2
        Rectangle {
            anchors.fill: parent
            color: JamiTheme.backgroundColor
            radius: 10

            ColumnLayout {
                anchors.bottomMargin: 5
                anchors.fill: parent

                RowLayout {
                    height: JamiTheme.preferredFieldHeight

                    BackButton {
                        id: backButton
                        Layout.leftMargin: 5
                        Layout.topMargin: 5
                        toolTipText: JamiStrings.goBackToPluginsList

                        onClicked: {
                            stack.pop(null, StackView.Immediate);
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        color: JamiTheme.textColor
                        font.bold: true
                        font.pointSize: JamiTheme.textFontSize
                        horizontalAlignment: Text.AlignHCenter
                        text: JamiStrings.pluginPreferences
                        verticalAlignment: Text.AlignVCenter
                    }
                    PushButton {
                        id: closeButton2
                        Layout.rightMargin: 5
                        Layout.topMargin: 5
                        imageColor: JamiTheme.textColor
                        source: JamiResources.round_close_24dp_svg

                        onClicked: {
                            root.close();
                        }
                    }
                }
                JamiListView {
                    id: pluginhandlerPreferencePickerListView
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    delegate: PreferenceItemDelegate {
                        id: pluginHandlerPreferenceDelegate
                        currentPath: CurrentPath
                        enabled: Enabled
                        fileFilters: FileFilters
                        height: JamiTheme.pluginHandlersPopupViewDelegateHeight
                        isImage: IsImage
                        pluginId: PluginId
                        preferenceCurrentValue: PreferenceCurrentValue
                        preferenceKey: PreferenceKey
                        preferenceName: PreferenceName
                        preferenceSummary: PreferenceSummary
                        preferenceType: PreferenceType
                        width: pluginhandlerPreferencePickerListView.width

                        onBtnPreferenceClicked: {
                            PluginModel.setPluginPreference(pluginId, LRCInstance.currentAccountId, preferenceKey, preferenceNewValue);
                            handlerPickerPrefsModel.reset();
                        }
                        onClicked: pluginhandlerPreferencePickerListView.currentIndex = index

                        pluginListPreferenceModel: PluginListPreferenceModel {
                            id: handlerPickerPreferenceModel
                            accountId_: LRCInstance.currentAccountId
                            lrcInstance: LRCInstance
                            pluginId: PluginId
                            preferenceKey: PreferenceKey
                        }
                    }
                    model: PreferenceItemListModel {
                        id: handlerPickerPrefsModel
                        accountId_: LRCInstance.currentAccountId
                        lrcInstance: LRCInstance
                        mediaHandlerName_: handlerName
                        pluginId_: pluginId
                    }
                }
            }
        }
    }

    background: Rectangle {
        color: "transparent"
    }
    contentItem: StackView {
        id: stack
        anchors.fill: parent
        initialItem: pluginhandlerPreferenceStack
    }
}

/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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


BaseModalDialog {
    id: root

    property bool isCall

    property string pluginId: ""
    property string handlerName: ""
    property Component currentStackComponent: picker

    titleText: currentStackComponent === picker ? JamiStrings.chooseExtension : JamiStrings.extensionPreferences

    autoClose: false
    closeButtonVisible: currentStackComponent === picker

    button1.text: JamiStrings.back
    button1.onClicked: { currentStackComponent = picker }
    button1.visible: currentStackComponent === preferences

    popupContent: Loader {
        id: loader
        width: 400
        height: 300
        sourceComponent: root.currentStackComponent
    }

    Component {
        id: picker
        JamiListView {
            id: pickerListView

            anchors.fill: parent

            Connections {
                target: root

                function onAboutToShow(visible) {
                    if (root.currentStackComponent !== picker) {
                        return;
                    }

                    if (isCall) {
                        pickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(CurrentCall.id);
                    } else {
                        const peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversation.members[0];
                        pickerListView.model = PluginAdapter.getChatHandlerSelectableModel(LRCInstance.currentAccountId, peerId);
                    }
                }
            }

            model: {
                if (isCall) {
                    return PluginAdapter.getMediaHandlerSelectableModel(CurrentCall.id);
                } else {
                    const peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversation.members[0];
                    return PluginAdapter.getChatHandlerSelectableModel(LRCInstance.currentAccountId, peerId);
                }
            }

            delegate: PluginHandlerItemDelegate {
                id: pluginHandlerItemDelegate

                width: pickerListView.width
                height: JamiTheme.pluginHandlersPopupViewDelegateHeight

                handlerName: HandlerName
                handlerId: HandlerId
                handlerIcon: HandlerIcon
                isLoaded: IsLoaded
                pluginId: PluginId

                onBtnLoadHandlerToggled: {
                    if (isCall) {
                        PluginModel.toggleCallMediaHandler(HandlerId, CurrentCall.id, !isLoaded);
                        pickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(CurrentCall.id);
                    } else {
                        const accountId = LRCInstance.currentAccountId;
                        const peerId = CurrentConversation.isSwarm ? CurrentConversation.id : CurrentConversation.members[0];
                        PluginModel.toggleChatHandler(HandlerId, accountId, peerId, !isLoaded);
                        pickerListView.model = PluginAdapter.getChatHandlerSelectableModel(accountId, peerId);
                    }
                }

                onOpenPreferences: {
                    root.handlerName = handlerName;
                    root.pluginId = pluginId;
                    root.currentStackComponent = preferences;
                }
            }
        }
    }

    Component {
        id: preferences
        JamiListView {
            id: preferencesListView

            anchors.fill: parent

            model: PreferenceItemListModel {
                id: handlerPickerPrefsModel
                lrcInstance: LRCInstance
                accountId: LRCInstance.currentAccountId
                mediaHandlerName: handlerName
                pluginId: root.pluginId
            }

            delegate: PreferenceItemDelegate {
                id: pluginHandlerPreferenceDelegate
                width: preferencesListView.width
                height: JamiTheme.pluginHandlersPopupViewDelegateHeight

                preferenceName: PreferenceName
                preferenceSummary: PreferenceSummary
                preferenceType: PreferenceType
                preferenceCurrentValue: PreferenceCurrentValue
                pluginId: PluginId
                currentPath: CurrentPath
                preferenceKey: PreferenceKey
                fileFilters: FileFilters
                isImage: IsImage
                enabled: Enabled
                pluginListPreferenceModel: PluginListPreferenceModel {
                    id: handlerPickerPreferenceModel

                    lrcInstance: LRCInstance
                    preferenceKey: PreferenceKey
                    accountId: LRCInstance.currentAccountId
                    pluginId: PluginId
                }

                onClicked: preferencesListView.currentIndex = index

                onBtnPreferenceClicked: {
                    PluginModel.setPluginPreference(pluginId, LRCInstance.currentAccountId, preferenceKey, preferenceNewValue);
                    handlerPickerPrefsModel.reset();
                }
            }
        }
    }
}
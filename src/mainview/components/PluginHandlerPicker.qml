/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Popup {
    id: root

    property bool isCall

    function toggleHandlerSlot(handlerId, isLoaded) {
        if (isCall) {
            var callId = UtilsAdapter.getCallId(callStackViewWindow.responsibleAccountId,
                                            callStackViewWindow.responsibleConvUid)
            PluginModel.toggleCallMediaHandler(handlerId, callId, !isLoaded)
            pluginhandlerPickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(callId)
        } else {
            var accountId = AccountAdapter.currentAccountId
            var peerId = UtilsAdapter.getPeerUri(accountId, UtilsAdapter.getCurrConvId())
            PluginModel.toggleChatHandler(handlerId, accountId, peerId, !isLoaded)
            pluginhandlerPickerListView.model = PluginAdapter.getChatHandlerSelectableModel(accountId, peerId)
        }
    }

    width: 350

    modal: true

    contentItem: StackLayout {
        id: stack
        currentIndex: 0
        height: childrenRect.height

        Rectangle {
            id: pluginhandlerPickerPopupRect
            width: root.width
            height: childrenRect.height + 50
            color: JamiTheme.backgroundColor
            radius: 10

            PushButton {
                id: closeButton

                anchors.top: pluginhandlerPickerPopupRect.top
                anchors.topMargin: 5
                anchors.right: pluginhandlerPickerPopupRect.right
                anchors.rightMargin: 5

                source: "qrc:/images/icons/round-close-24px.svg"
                imageColor: JamiTheme.textColor

                onClicked: {
                    root.close()
                }
            }

            ColumnLayout {
                id: pluginhandlerPickerPopupRectColumnLayout

                anchors.top: pluginhandlerPickerPopupRect.top
                anchors.topMargin: 15
                height: 230

                Text {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: pluginhandlerPickerPopupRect.width
                    Layout.preferredHeight: 30

                    font.pointSize: JamiTheme.textFontSize
                    font.bold: true

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor

                    text: qsTr("Choose plugin")
                }

                ListView {
                    id: pluginhandlerPickerListView

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: pluginhandlerPickerPopupRect.width
                    Layout.preferredHeight: 200

                    model: {
                        if (isCall) {
                            var callId = UtilsAdapter.getCallId(callStackViewWindow.responsibleAccountId,
                                                                callStackViewWindow.responsibleConvUid)
                            return PluginAdapter.getMediaHandlerSelectableModel(callId)
                        } else {
                            var accountId = AccountAdapter.currentAccountId
                            var peerId = UtilsAdapter.getPeerUri(accountId, UtilsAdapter.getCurrConvId())
                            return PluginAdapter.getChatHandlerSelectableModel(accountId, peerId)
                        }
                    }

                    clip: true

                    delegate: PluginHandlerItemDelegate {
                        id: pluginHandlerItemDelegate
                        visible: PluginModel.getPluginsEnabled()
                        width: pluginhandlerPickerListView.width
                        height: 50

                        handlerName : HandlerName
                        handlerId: HandlerId
                        handlerIcon: HandlerIcon
                        isLoaded: IsLoaded
                        pluginId: PluginId

                        onBtnLoadHandlerToggled: {
                            toggleHandlerSlot(HandlerId, isLoaded)
                        }

                        onOpenPreferences: {
                            pluginhandlerPreferencePickerListView.pluginId = pluginId
                            pluginhandlerPreferencePickerListView.handlerName = handlerName
                            pluginhandlerPreferencePickerListView.model = PluginAdapter.getPluginPreferencesModel(pluginId, handlerName)
                            stack.currentIndex = 1
                        }
                    }

                    ScrollIndicator.vertical: ScrollIndicator {}
                }
            }
        }

        Rectangle {
            id: pluginhandlerPreferencePopupRect2
            width: root.width
            height: childrenRect.height + 50
            color: JamiTheme.backgroundColor
            radius: 10

            PushButton {
                id: backButton
                anchors.top: pluginhandlerPreferencePopupRect2.top
                anchors.topMargin: 5
                anchors.left: pluginhandlerPreferencePopupRect2.left
                anchors.leftMargin: 5

                imageColor: JamiTheme.textColor
                source: "qrc:/images/icons/ic_arrow_back_24px.svg"
                toolTipText: qsTr("Go back to plugins list")
                hoverEnabled: true
                onClicked: {
                    stack.currentIndex = 0
                }
            }

            PushButton {
                id: closeButton2

                anchors.top: pluginhandlerPreferencePopupRect2.top
                anchors.topMargin: 5
                anchors.right: pluginhandlerPreferencePopupRect2.right
                anchors.rightMargin: 5

                source: "qrc:/images/icons/round-close-24px.svg"
                imageColor: JamiTheme.textColor

                onClicked: {
                    stack.currentIndex = 0
                    root.close()
                }
            }

            ColumnLayout {

                anchors.top: pluginhandlerPreferencePopupRect2.top
                anchors.topMargin: 15
                height: 230

                Text {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: pluginhandlerPreferencePopupRect2.width
                    Layout.preferredHeight: 30

                    font.pointSize: JamiTheme.textFontSize
                    font.bold: true

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    color: JamiTheme.textColor
                    text: qsTr("Preferences")
                }

                ListView {
                    id: pluginhandlerPreferencePickerListView
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: pluginhandlerPickerPopupRect.width
                    Layout.fillHeight: true

                    property string pluginId: ""
                    property string handlerName: ""

                    model: PluginAdapter.getPluginPreferencesModel(pluginId, handlerName)

                    clip: true

                    delegate: PreferenceItemDelegate {
                        id: pluginHandlerPreferenceDelegate
                        width: pluginhandlerPreferencePickerListView.width
                        height: 50

                        preferenceName: PreferenceName
                        preferenceSummary: PreferenceSummary
                        preferenceType: PreferenceType
                        preferenceCurrentValue: PreferenceCurrentValue
                        pluginId: PluginId
                        currentPath: CurrentPath
                        preferenceKey : PreferenceKey
                        fileFilters: FileFilters
                        isImage: IsImage
                        pluginListPreferenceModel: PluginListPreferenceModel {
                            id: pluginListPreferenceModel
                            preferenceKey : PreferenceKey
                            pluginId: PluginId
                        }

                        onClicked:  pluginhandlerPreferencePickerListView.currentIndex = index

                        onBtnPreferenceClicked: {
                            PluginModel.setPluginPreference(pluginId, preferenceKey, preferenceNewValue)
                            pluginhandlerPreferencePickerListView.model = PluginAdapter.getPluginPreferencesModel(pluginId, pluginhandlerPreferencePickerListView.handlerName)
                        }
                    }

                    ScrollIndicator.vertical: ScrollIndicator {}
                }
            }
        }
    }

    onAboutToHide: stack.currentIndex = 0

    onAboutToShow: {
        if (isCall) {
            // Reset the model on each show.
            var callId = UtilsAdapter.getCallId(callStackViewWindow.responsibleAccountId,
                                                callStackViewWindow.responsibleConvUid)
            pluginhandlerPickerListView.model = PluginAdapter.getMediaHandlerSelectableModel(callId)
        } else {
            // Reset the model on each show.
            var accountId = AccountAdapter.currentAccountId
            var peerId = UtilsAdapter.getPeerUri(accountId, UtilsAdapter.getCurrConvId())
            pluginhandlerPickerListView.model = PluginAdapter.getChatHandlerSelectableModel(accountId, peerId)
        }
    }

    background: Rectangle {
        color: "transparent"
    }
}

/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    property string accountId: ""
    required property string pluginId
    required property bool isLoaded
    width: parent.width

    property int count: pluginPreferenceView.count + pluginPreferenceViewCategory.count

    implicitHeight: childrenRect.height
    onVisibleChanged: {
        if (visible) {
            preferencesPerCategoryModel.reset();
            generalPreferencesModel.reset();
        }
    }

    color: "transparent"
    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            if (accountId) {
                preferencesPerCategoryModel.reset();
                generalPreferencesModel.reset();
            }
        }
    }

    property string category: categories.length > 0 ? categories[0] : category ? category : ""
    property var categories: PluginAdapter.getPluginPreferencesCategories(pluginId, accountId)
    property string generalCategory: categories.length <= 1 ? "all" : ""

    function setPreference(pluginId, preferenceKey, preferenceNewValue) {
        PluginModel.setPluginPreference(pluginId, accountId, preferenceKey, preferenceNewValue);
    }

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right

        Item {
            id: prefsByCategory

            visible: categories.length > 1

            Layout.topMargin: 24
            Layout.fillWidth: true
            implicitHeight: childrenRect.height

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right

                GridLayout {
                    id: categoriesGrid

                    Layout.fillWidth: true
                    implicitHeight: gridModel.count * JamiTheme.preferredFieldHeight
                    columns: 2
                    columnSpacing: 0
                    rowSpacing: 0

                    Repeater {
                        id: gridModel
                        model: categories.length % 2 === 1 ? PluginAdapter.getPluginPreferencesCategories(pluginId, accountId, true) : root.categories
                        Button {
                            id: repDelegate
                            Layout.fillWidth: true
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            highlighted: root.category === modelData
                            text: modelData
                            flat: true
                            onClicked: {
                                root.category = modelData;
                            }
                            background: Rectangle {
                                anchors.fill: parent
                                color: repDelegate.highlighted ? JamiTheme.selectedColor : JamiTheme.primaryBackgroundColor
                                border.color: JamiTheme.selectedColor
                                border.width: 1
                            }
                            contentItem: Text {
                                text: repDelegate.text
                                font: repDelegate.font
                                opacity: enabled ? 1.0 : 0.3
                                color: JamiTheme.primaryForegroundColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Button {
                    id: oddCategoryButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    flat: true
                    visible: categories.length % 2 === 1

                    text: categories[categories.length - 1]
                    highlighted: root.category === text

                    onClicked: {
                        root.category = oddCategoryButton.text;
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        color: oddCategoryButton.highlighted ? JamiTheme.selectedColor : JamiTheme.primaryBackgroundColor
                        border.color: JamiTheme.selectedColor
                        border.width: 1
                    }
                    contentItem: Text {
                        text: oddCategoryButton.text
                        font: oddCategoryButton.font
                        opacity: enabled ? 1.0 : 0.3
                        color: JamiTheme.primaryForegroundColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                ListView {
                    id: pluginPreferenceViewCategory
                    Layout.fillWidth: true
                    Layout.minimumHeight: 1
                    Layout.preferredHeight: childrenRect.height

                    model: PreferenceItemListModel {
                        id: preferencesPerCategoryModel
                        lrcInstance: LRCInstance
                        category: root.category
                        accountId: root.accountId
                        pluginId: root.pluginId

                        onCategoryChanged: {
                            this.reset();
                        }
                    }
                    interactive: false

                    delegate: PreferenceItemDelegate {
                        id: preferenceItemDelegateCategory

                        width: pluginPreferenceViewCategory.width
                        height: 50

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
                            id: pluginListPreferenceCategoryModel

                            lrcInstance: LRCInstance
                            preferenceKey: PreferenceKey
                            accountId: root.accountId
                            pluginId: PluginId
                        }

                        onBtnPreferenceClicked: {
                            setPreference(pluginId, preferenceKey, preferenceNewValue);
                            preferencesPerCategoryModel.reset();
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            color: JamiTheme.backgroundColor
                        }
                    }
                }
            }
        }

        ListView {
            id: pluginPreferenceView

            Layout.fillWidth: true
            Layout.minimumHeight: 1
            Layout.preferredHeight: childrenRect.height

            model: PreferenceItemListModel {
                id: generalPreferencesModel
                lrcInstance: LRCInstance
                category: generalCategory
                accountId: root.accountId
                pluginId: root.pluginId

                onCategoryChanged: {
                    this.reset();
                }
            }
            interactive: false

            delegate: PreferenceItemDelegate {
                id: preferenceItemDelegate

                width: pluginPreferenceView.width
                height: 50

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
                    id: pluginListPreferenceModel

                    lrcInstance: LRCInstance
                    preferenceKey: PreferenceKey
                    accountId: root.accountId
                    pluginId: PluginId
                }

                onBtnPreferenceClicked: {
                    setPreference(pluginId, preferenceKey, preferenceNewValue);
                    generalPreferencesModel.reset();
                }
            }
        }

        MaterialButton {
            id: resetButton
            visible: count > 0
            Layout.alignment: Qt.AlignCenter

            preferredWidth: JamiTheme.preferredFieldWidth
            buttontextHeightMargin: JamiTheme.buttontextHeightMargin

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true

            text: JamiStrings.reset

            onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                    "title": JamiStrings.resetPreferences,
                    "infoText": JamiStrings.pluginResetConfirmation.arg(pluginId),
                    "buttonTitles": [JamiStrings.optionOk, JamiStrings.optionCancel],
                    "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlack],
                    "buttonCallBacks": [function () {
                            if (isLoaded) {
                                PluginModel.unloadPlugin(pluginId);
                                PluginModel.resetPluginPreferencesValues(pluginId, accountId);
                                PluginModel.loadPlugin(pluginId);
                            } else {
                                PluginModel.resetPluginPreferencesValues(pluginId, accountId);
                            }
                            preferencesPerCategoryModel.reset();
                            generalPreferencesModel.reset();
                        }],
                        "buttonRoles": [DialogButtonBox.AcceptRole, DialogButtonBox.RejectRole]
                })
        }
    }
}

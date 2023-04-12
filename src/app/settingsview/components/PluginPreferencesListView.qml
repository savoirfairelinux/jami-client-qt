/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    property var categories: PluginAdapter.getPluginPreferencesCategories(pluginId, accountId)
    property string category: categories.length > 0 ? categories[0] : category ? category : ""
    property int count: pluginPreferenceView.count + pluginPreferenceViewCategory.count
    property string generalCategory: categories.length <= 1 ? "all" : ""

    color: "transparent"
    implicitHeight: childrenRect.height
    visible: false

    function setPreference(pluginId, preferenceKey, preferenceNewValue) {
        PluginModel.setPluginPreference(pluginId, accountId, preferenceKey, preferenceNewValue);
    }

    onVisibleChanged: {
        if (visible) {
            preferencesPerCategoryModel.reset();
            generalPreferencesModel.reset();
        }
    }

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            if (accountId) {
                preferencesPerCategoryModel.reset();
                generalPreferencesModel.reset();
            }
        }
    }
    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right

        Rectangle {
            id: prefsByCategory
            Layout.fillWidth: true
            Layout.topMargin: 24
            color: JamiTheme.backgroundColor
            implicitHeight: childrenRect.height
            visible: categories.length > 1

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right

                GridLayout {
                    id: categoriesGrid
                    Layout.fillWidth: true
                    columnSpacing: 0
                    columns: 2
                    implicitHeight: gridModel.count * JamiTheme.preferredFieldHeight
                    rowSpacing: 0

                    Repeater {
                        id: gridModel
                        model: categories.length % 2 === 1 ? PluginAdapter.getPluginPreferencesCategories(pluginId, accountId, true) : root.categories

                        Button {
                            id: repDelegate
                            Layout.fillWidth: true
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            flat: true
                            highlighted: root.category === modelData
                            text: modelData

                            onClicked: {
                                root.category = modelData;
                            }

                            background: Rectangle {
                                anchors.fill: parent
                                border.color: JamiTheme.selectedColor
                                border.width: 1
                                color: repDelegate.highlighted ? JamiTheme.selectedColor : JamiTheme.primaryBackgroundColor
                            }
                            contentItem: Text {
                                color: JamiTheme.primaryForegroundColor
                                elide: Text.ElideRight
                                font: repDelegate.font
                                horizontalAlignment: Text.AlignHCenter
                                opacity: enabled ? 1.0 : 0.3
                                text: repDelegate.text
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
                Button {
                    id: oddCategoryButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    flat: true
                    highlighted: category === text
                    text: categories[categories.length - 1]
                    visible: categories.length % 2 === 1

                    onClicked: {
                        root.category = oddCategoryButton.text;
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        border.color: JamiTheme.selectedColor
                        border.width: 1
                        color: oddCategoryButton.highlighted ? JamiTheme.selectedColor : JamiTheme.primaryBackgroundColor
                    }
                    contentItem: Text {
                        color: JamiTheme.primaryForegroundColor
                        elide: Text.ElideRight
                        font: oddCategoryButton.font
                        horizontalAlignment: Text.AlignHCenter
                        opacity: enabled ? 1.0 : 0.3
                        text: oddCategoryButton.text
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                ListView {
                    id: pluginPreferenceViewCategory
                    Layout.fillWidth: true
                    Layout.minimumHeight: 1
                    Layout.preferredHeight: childrenRect.height
                    interactive: false

                    delegate: PreferenceItemDelegate {
                        id: preferenceItemDelegateCategory
                        currentPath: CurrentPath
                        enabled: Enabled
                        fileFilters: FileFilters
                        height: 50
                        isImage: IsImage
                        pluginId: PluginId
                        preferenceCurrentValue: PreferenceCurrentValue
                        preferenceKey: PreferenceKey
                        preferenceName: PreferenceName
                        preferenceSummary: PreferenceSummary
                        preferenceType: PreferenceType
                        width: pluginPreferenceViewCategory.width

                        onBtnPreferenceClicked: {
                            setPreference(pluginId, preferenceKey, preferenceNewValue);
                            preferencesPerCategoryModel.reset();
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            color: JamiTheme.backgroundColor
                        }
                        pluginListPreferenceModel: PluginListPreferenceModel {
                            id: pluginListPreferenceCategoryModel
                            accountId_: accountId
                            lrcInstance: LRCInstance
                            pluginId: PluginId
                            preferenceKey: PreferenceKey
                        }
                    }
                    model: PreferenceItemListModel {
                        id: preferencesPerCategoryModel
                        accountId_: accountId
                        category_: category
                        lrcInstance: LRCInstance
                        pluginId_: pluginId

                        onCategory_Changed: {
                            this.reset();
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
            interactive: false

            delegate: PreferenceItemDelegate {
                id: preferenceItemDelegate
                currentPath: CurrentPath
                enabled: Enabled
                fileFilters: FileFilters
                height: 50
                isImage: IsImage
                pluginId: PluginId
                preferenceCurrentValue: PreferenceCurrentValue
                preferenceKey: PreferenceKey
                preferenceName: PreferenceName
                preferenceSummary: PreferenceSummary
                preferenceType: PreferenceType
                width: pluginPreferenceView.width

                onBtnPreferenceClicked: {
                    setPreference(pluginId, preferenceKey, preferenceNewValue);
                    generalPreferencesModel.reset();
                }

                pluginListPreferenceModel: PluginListPreferenceModel {
                    id: pluginListPreferenceModel
                    accountId_: accountId
                    lrcInstance: LRCInstance
                    pluginId: PluginId
                    preferenceKey: PreferenceKey
                }
            }
            model: PreferenceItemListModel {
                id: generalPreferencesModel
                accountId_: accountId
                category_: generalCategory
                lrcInstance: LRCInstance
                pluginId_: pluginId

                onCategory_Changed: {
                    this.reset();
                }
            }
        }
        MaterialButton {
            id: resetButton
            Layout.alignment: Qt.AlignCenter
            buttontextHeightMargin: JamiTheme.buttontextHeightMargin
            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            iconSource: JamiResources.settings_backup_restore_24dp_svg
            preferredWidth: JamiTheme.preferredFieldWidth
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            text: JamiStrings.reset

            onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                    "title": JamiStrings.resetPreferences,
                    "infoText": JamiStrings.pluginResetConfirmation.arg(pluginName),
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
                        }]
                })
        }
    }
}

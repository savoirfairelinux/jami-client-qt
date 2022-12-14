/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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
    property int count: pluginPreferenceView.count + pluginPreferenceViewCategory.count

    implicitHeight: childrenRect.height
    onVisibleChanged: {
        if (visible) {
            preferencesPerCategoryModel.reset()
            generalPreferencesModel.reset()
        }
    }

    color: "transparent"

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            if (accountId) {
                preferencesPerCategoryModel.reset()
                generalPreferencesModel.reset()
            }
        }
    }

    property string category: categories.length > 0 ? categories[0] : category ? category : ""
    property var categories: PluginAdapter.getPluginPreferencesCategories(pluginId, accountId)
    property string generalCategory: categories.length <= 1 ? "all" : ""

    visible: false

    function setPreference(pluginId, preferenceKey, preferenceNewValue)
    {
        PluginModel.setPluginPreference(pluginId, accountId, preferenceKey, preferenceNewValue)
    }

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right

        Rectangle {
            id: prefsByCategory

            visible: categories.length > 1

            Layout.topMargin: 24
            Layout.fillWidth: true
            implicitHeight: childrenRect.height
            color: JamiTheme.backgroundColor

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
                                root.category = modelData
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
                    highlighted: category === text

                    onClicked: {
                        root.category = oddCategoryButton.text
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
                        category_: category
                        accountId_: accountId
                        pluginId_: pluginId

                        onCategory_Changed: {
                            this.reset()
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
                            preferenceKey : PreferenceKey
                            accountId_: accountId
                            pluginId: PluginId
                        }

                        onBtnPreferenceClicked: {
                            setPreference(pluginId, preferenceKey, preferenceNewValue)
                            preferencesPerCategoryModel.reset()
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
                category_: generalCategory
                accountId_: accountId
                pluginId_: pluginId

                onCategory_Changed: {
                    this.reset()
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
                    preferenceKey : PreferenceKey
                    accountId_: accountId
                    pluginId: PluginId
                }

                onBtnPreferenceClicked: {
                    setPreference(pluginId, preferenceKey, preferenceNewValue)
                    generalPreferencesModel.reset()
                }
            }
        }

        MaterialButton {
            id: resetButton

            Layout.alignment: Qt.AlignCenter

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredFieldHeight

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true

            iconSource: JamiResources.settings_backup_restore_24dp_svg

            text: JamiStrings.reset

            onClicked: {
                msgDialog.buttonCallBacks = [function () {
                    if (isLoaded) {
                        PluginModel.unloadPlugin(pluginId)
                        PluginModel.resetPluginPreferencesValues(pluginId, accountId)
                        PluginModel.loadPlugin(pluginId)
                    } else {
                        PluginModel.resetPluginPreferencesValues(pluginId, accountId)
                    }
                    preferencesPerCategoryModel.reset()
                    generalPreferencesModel.reset()
                }]
                msgDialog.openWithParameters(JamiStrings.resetPreferences,
                                             JamiStrings.pluginResetConfirmation.arg(pluginName))
            }
        }
    }
}

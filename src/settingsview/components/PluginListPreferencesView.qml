/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int effectiveHeight: visible ? implicitHeight : 0
    implicitHeight: childrenRect.height
    onVisibleChanged: {
        if (visible) {
            preferencesPerCategoryModel.reset()
            generalPreferencesModel.reset()
        }
    }

    property string category: categories.length > 0 ? categories[0] : category ? category : ""
    property var categories: PluginAdapter.getPluginPreferencesCategories(pluginId)
    property string generalCategory: categories.length <= 1 ? "all" : ""

    visible: false

    function setPreference(pluginId, preferenceKey, preferenceNewValue)
    {
        if (isLoaded) {
            PluginModel.unloadPlugin(pluginId)
            PluginModel.setPluginPreference("", pluginId, preferenceKey, preferenceNewValue)
            PluginModel.loadPlugin(pluginId)
        } else
            PluginModel.setPluginPreference("", pluginId, preferenceKey, preferenceNewValue)
    }

    SimpleMessageDialog {
        id: msgDialog

        buttonTitles: [qsTr("Ok"), qsTr("Cancel")]
        buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue,
                       SimpleMessageDialog.ButtonStyle.TintedBlack]
    }

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottomMargin: 10

        Label{
            Layout.topMargin: 34
            Layout.alignment: Qt.AlignHCenter
            height: 64
            background: Rectangle {
                Image {
                    anchors.centerIn: parent
                    source: pluginIcon === "" ? "" : "file:" + pluginIcon
                    sourceSize: Qt.size(256, 256)
                    height: 64
                    width: 64
                    mipmap: true
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            height: JamiTheme.preferredFieldHeight

            text: qsTr(pluginName + "\nPreferences")
            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true
            color: JamiTheme.textColor

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

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
                        model: categories.length % 2 === 1 ? PluginAdapter.getPluginPreferencesCategories(pluginId, true) : root.categories
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
                    pluginId: PluginId
                }

                onBtnPreferenceClicked: {
                    setPreference(pluginId, preferenceKey, preferenceNewValue)
                    generalPreferencesModel.reset()
                }
            }
        }

        RowLayout {
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            Layout.preferredHeight: 30
            Layout.fillWidth: true

            MaterialButton {
                id: resetButton

                Layout.fillWidth: true
                preferredHeight: JamiTheme.preferredFieldHeight

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                outlined: true

                iconSource: JamiResources.settings_backup_restore_24dp_svg

                text: JamiStrings.reset

                onClicked: {
                    msgDialog.buttonCallBacks = [function () {
                        if (isLoaded) {
                            PluginModel.unloadPlugin(pluginId)
                            PluginModel.resetPluginPreferencesValues(pluginId, "")
                            PluginModel.loadPlugin(pluginId)
                        } else {
                            PluginModel.resetPluginPreferencesValues(pluginId, "")
                        }
                        preferencesPerCategoryModel.reset()
                        generalPreferencesModel.reset()
                    }]
                    msgDialog.openWithParameters(qsTr("Reset preferences"),
                                                qsTr("Are you sure you wish to reset "+ pluginName +
                                                    " preferences?"))
                }
            }

            MaterialButton {
                id: uninstallButton

                Layout.fillWidth: true
                preferredHeight: JamiTheme.preferredFieldHeight

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                outlined: true

                iconSource: JamiResources.delete_24dp_svg

                text: qsTr("Uninstall")

                onClicked: {
                    msgDialog.buttonCallBacks = [function () {
                        PluginModel.uninstallPlugin(pluginId)
                        installedPluginsModel.removePlugin(index)
                    }]
                    msgDialog.openWithParameters(qsTr("Uninstall plugin"),
                                                qsTr("Are you sure you wish to uninstall " + pluginName + " ?"))
                }
            }
        }

        Rectangle {
            Layout.bottomMargin: 10
            height: 2
            Layout.fillWidth: true
            color: "transparent"
            border.width: 1
            border.color: JamiTheme.separationLine
        }
    }
}

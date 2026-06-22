/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import QtQuick.Effects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.UI as JUI

Item {
    id: root

    property int type: ContactList.ADDCONVMEMBER

    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        id: innerRect

        anchors.fill: parent
        anchors.margins: (typeof viewCoordinator !== "undefined" && viewCoordinator.isInSinglePaneMode) ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        Rectangle {
            id: gradientRectTop

            readonly property color baseColor: JamiTheme.globalIslandColor
            readonly property bool shouldShow: !contactPickerListView.atYBeginning

            anchors.top: innerRect.top
            anchors.topMargin: contactPickerContactSearchBar.height + 30

            width: contactPickerPopupRectColumnLayout.width
            height: JamiTheme.smartListItemHeight

            z: contactPickerListView.z + 1

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(gradientRectTop.baseColor.r, gradientRectTop.baseColor.g,
                                   gradientRectTop.baseColor.b, 1.0)
                }
                GradientStop {
                    position: 0.25
                    color: Qt.rgba(gradientRectTop.baseColor.r, gradientRectTop.baseColor.g,
                                   gradientRectTop.baseColor.b, 0.75)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(gradientRectTop.baseColor.r, gradientRectTop.baseColor.g,
                                   gradientRectTop.baseColor.b, 0.0)
                }
            }

            visible: opacity > 0
            opacity: shouldShow ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ColumnLayout {
            id: contactPickerPopupRectColumnLayout

            anchors.fill: parent

            Searchbar {
                id: contactPickerContactSearchBar

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
                Layout.margins: 15
                Layout.alignment: Qt.AlignTop

                placeHolderText: JamiStrings.inviteMember

                onVisibleChanged: {
                    if (visible)
                        forceActiveFocus();
                }

                onSearchBarTextChanged: function (text) {
                    ContactAdapter.setSearchFilter(text);
                }
            }

            JUI.ListView {
                id: contactPickerListView

                Layout.fillHeight: true
                Layout.fillWidth: true

                // Reset the model if visible or the current conv member count changes (0 or greater)
                model: visible && CurrentConversation.members.count >= 0 ? ContactAdapter.getContactSelectableModel(type) : null

                delegate: ContactPickerItemDelegate {
                    id: contactPickerItemDelegate

                    showPresenceIndicator: true
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    anchors.fill: root
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: innerRect.width
                            height: innerRect.height
                            bottomLeftRadius: innerRect.radius
                            bottomRightRadius: innerRect.radius
                        }
                    }
                }
            }
        }

        Rectangle {
            id: gradientRectBottom

            readonly property color baseColor: JamiTheme.globalIslandColor
            readonly property bool shouldShow: !contactPickerListView.atYEnd

            anchors.bottom: contactPickerPopupRectColumnLayout.bottom
            anchors.bottomMargin: -1

            width: contactPickerPopupRectColumnLayout.width
            height: JamiTheme.smartListItemHeight

            bottomRightRadius: innerRect.radius
            bottomLeftRadius: innerRect.radius

            z: contactPickerListView.z + 1

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(gradientRectBottom.baseColor.r, gradientRectBottom.baseColor.g,
                                   gradientRectBottom.baseColor.b, 0.0)
                }
                GradientStop {
                    position: 0.75
                    color: Qt.rgba(gradientRectBottom.baseColor.r, gradientRectBottom.baseColor.g,
                                   gradientRectBottom.baseColor.b, 0.75)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(gradientRectBottom.baseColor.r, gradientRectBottom.baseColor.g,
                                   gradientRectBottom.baseColor.b, 1.0)
                }
            }

            visible: opacity > 0
            opacity: shouldShow ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: innerRect
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
}

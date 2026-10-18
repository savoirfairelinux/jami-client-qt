/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import net.jami.Constants 1.1
import "../../commoncomponents"

// The two orders of the contacts list: most recent first, or from A to Z.
TabBar {
    id: root
    objectName: "contactsSortBar"

    readonly property bool sortByTitle: currentIndex === 1

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    Repeater {
        model: [{"icon": JamiResources.history_24dp_svg, "name": JamiStrings.contactsByDate},
                {"icon": JamiResources.sort_by_alpha_24dp_svg, "name": JamiStrings.contactsByName}]

        delegate: TabButton {
            id: tab

            required property var modelData
            required property int index

            objectName: "contactsSort-" + index
            hoverEnabled: true
            Accessible.name: modelData.name

            contentItem: Item {
                implicitHeight: 32

                ResponsiveImage {
                    anchors.centerIn: parent
                    containerWidth: 22
                    containerHeight: 22
                    source: tab.modelData.icon
                    color: tab.checked ? JamiTheme.tintedBlue : JamiTheme.textColor
                }
            }

            background: Rectangle {
                color: tab.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor
                radius: JamiTheme.primaryRadius

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 2
                    visible: tab.checked
                    color: JamiTheme.tintedBlue
                }
            }

            MaterialToolTip {
                visible: tab.hovered
                delay: Qt.styleHints.mousePressAndHoldInterval
                text: tab.modelData.name
            }
        }
    }
}

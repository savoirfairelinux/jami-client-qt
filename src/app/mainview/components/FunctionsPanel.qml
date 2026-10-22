/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../../commoncomponents"

// The nine functions, below the conversation list. The handle folds and unfolds
// them; the cards are sized so that the panel never exceeds maximumHeight, and
// laid out in a single row, without their names, when three rows do not fit.
Item {
    id: root
    objectName: "functionsPanel"

    enum Function {
        Calls,
        Messages,
        Contacts,
        Documents,
        Groups,
        Board,
        Services,
        Location,
        Circles
    }

    property bool expanded: true
    property real maximumHeight: 300
    // Functions with something going on, which pulse.
    property var pulsingFunctions: []

    signal functionTriggered(int fn)

    readonly property var functions: [
        {"fn": FunctionsPanel.Calls, "name": JamiStrings.functionCalls, "icon": JamiResources.call_24dp_svg, "color": "#22C55E"},
        {"fn": FunctionsPanel.Messages, "name": JamiStrings.functionMessages, "icon": JamiResources.chat_24dp_svg, "color": "#0EA5E9"},
        {"fn": FunctionsPanel.Contacts, "name": JamiStrings.functionContacts, "icon": JamiResources.person_24dp_svg, "color": "#A855F7"},
        {"fn": FunctionsPanel.Documents, "name": JamiStrings.functionDocuments, "icon": JamiResources.article_24dp_svg, "color": "#F59E0B"},
        {"fn": FunctionsPanel.Groups, "name": JamiStrings.functionGroups, "icon": JamiResources.group_24dp_svg, "color": "#EC4899"},
        {"fn": FunctionsPanel.Board, "name": JamiStrings.functionBoard, "icon": JamiResources.campaign_24dp_svg, "color": "#F97316"},
        {"fn": FunctionsPanel.Services, "name": JamiStrings.functionServices, "icon": JamiResources.peer_services_24dp_svg, "color": "#14B8A6"},
        {"fn": FunctionsPanel.Location, "name": JamiStrings.functionLocation, "icon": JamiResources.my_location_24dp_svg, "color": "#EF4444"},
        {"fn": FunctionsPanel.Circles, "name": JamiStrings.functionCircles, "icon": JamiResources.circles_24dp_svg, "color": "#6366F1"}
    ]

    function functionInfo(fn) {
        return functions.find(f => f.fn === fn);
    }

    // "#RRGGBB" with an alpha, as "#AARRGGBB".
    function tinted(color, alpha) {
        return "#" + alpha + color.substring(1);
    }

    readonly property real handleHeight: 24
    readonly property real gridPadding: 8
    readonly property real spacing: 6
    readonly property real minimumCellHeight: 52
    readonly property real maximumCellHeight: 76
    readonly property real namedCellSize: 56
    readonly property real minimumTouchSize: 40

    function cellHeightFor(rows) {
        return (maximumHeight - handleHeight - 2 * gridPadding - (rows - 1) * spacing) / rows;
    }

    readonly property int rows: cellHeightFor(3) >= minimumCellHeight ? 3 : 1
    readonly property int columns: functions.length / rows
    readonly property real cellWidth: (width - 2 * gridPadding - (columns - 1) * spacing) / columns
    readonly property bool showNames: Math.min(maximumCellHeight, cellHeightFor(rows)) >= namedCellSize
                                      && cellWidth >= namedCellSize
    // Without their names, the cards stay about square rather than becoming thin pills.
    readonly property real cellHeight: {
        const height = Math.min(maximumCellHeight, cellHeightFor(rows));
        return showNames ? height : Math.min(height, Math.max(cellWidth, minimumTouchSize));
    }
    readonly property real gridHeight: rows * cellHeight + (rows - 1) * spacing + 2 * gridPadding

    // 1 when unfolded, 0 when folded; follows the handle while it is dragged.
    property real reveal: expanded ? 1 : 0
    Behavior on reveal {
        enabled: !handleDrag.active
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    implicitHeight: handleHeight + reveal * gridHeight
    clip: true

    Accessible.role: Accessible.Grouping
    Accessible.name: JamiStrings.functionsPanelToggle

    AbstractButton {
        id: handle
        objectName: "functionsPanelHandle"

        width: parent.width
        height: root.handleHeight

        focusPolicy: Qt.TabFocus
        hoverEnabled: true
        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.functionsPanelToggle

        background: Rectangle {
            anchors.centerIn: parent
            width: 36
            height: 4
            radius: 2
            color: JamiTheme.faddedLastInteractionFontColor
            opacity: handle.hovered || handle.visualFocus ? 0.9 : 0.5
        }

        onClicked: root.expanded = !root.expanded
        Keys.onReturnPressed: root.expanded = !root.expanded

        DragHandler {
            id: handleDrag

            target: null
            xAxis.enabled: false
            onActiveTranslationChanged: {
                if (active) {
                    const start = root.expanded ? 1 : 0;
                    root.reveal = Math.max(0, Math.min(1, start - activeTranslation.y / root.gridHeight));
                }
            }
            onActiveChanged: {
                if (!active) {
                    root.expanded = root.reveal >= 0.5;
                    root.reveal = Qt.binding(() => root.expanded ? 1 : 0);
                }
            }
        }

        MaterialToolTip {
            visible: handle.hovered && !handleDrag.active
            delay: Qt.styleHints.mousePressAndHoldInterval
            text: JamiStrings.functionsPanelToggle
        }
    }

    GridLayout {
        id: grid
        objectName: "functionsGrid"

        y: root.handleHeight + root.gridPadding
        x: root.gridPadding
        width: root.width - 2 * root.gridPadding

        visible: root.reveal > 0
        opacity: root.reveal
        columns: root.columns
        rowSpacing: root.spacing
        columnSpacing: root.spacing

        Repeater {
            model: root.functions

            delegate: AbstractButton {
                id: card

                required property var modelData

                objectName: "functionCard-" + modelData.fn
                Layout.fillWidth: true
                Layout.preferredWidth: root.cellWidth
                Layout.preferredHeight: root.cellHeight

                enabled: root.expanded
                focusPolicy: Qt.TabFocus
                hoverEnabled: true
                Accessible.role: Accessible.Button
                Accessible.name: modelData.name

                background: Rectangle {
                    radius: 14
                    color: card.down ? root.tinted(card.modelData.color, "33")
                                     : card.hovered ? root.tinted(card.modelData.color, "1F")
                                                    : JamiTheme.secondaryBackgroundColor
                    border.width: card.visualFocus ? 2 : 1
                    border.color: root.tinted(card.modelData.color, card.visualFocus ? "E6" : "4D")
                }

                contentItem: ColumnLayout {
                    spacing: 4

                    Rectangle {
                        readonly property real size: Math.min(34, Math.min(card.height, card.width) - 8)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: size
                        Layout.preferredHeight: size
                        radius: size * 0.3
                        color: root.tinted(card.modelData.color, "26")

                        PulseRing {
                            radius: parent.radius
                            border.color: card.modelData.color
                            running: root.pulsingFunctions.includes(card.modelData.fn)
                        }

                        ResponsiveImage {
                            anchors.centerIn: parent
                            containerWidth: parent.size * 0.6
                            containerHeight: parent.size * 0.6
                            source: card.modelData.icon
                            color: card.modelData.color
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.showNames
                        text: card.modelData.name
                        color: JamiTheme.textColor
                        font.bold: true
                        font.pointSize: JamiTheme.textFontSize
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                onClicked: root.functionTriggered(modelData.fn)
                Keys.onReturnPressed: root.functionTriggered(modelData.fn)

                MaterialToolTip {
                    visible: card.hovered && !root.showNames
                    delay: Qt.styleHints.mousePressAndHoldInterval
                    text: card.modelData.name
                }
            }
        }
    }
}

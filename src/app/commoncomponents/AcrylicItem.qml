/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

Item {
    id: root

    required property Item effectSourceItem

    property real blurRadius: 56
    property color effectColor: "#80808080"
    property int containerRadius: 16
    property bool showDropShadow: true

    required default property var contentItem
    onContentItemChanged: {
        if (contentItem !== null) {
            contentItem.parent = contentContainer
        }
    }

    width: contentContainer.width
    height: contentContainer.height

    DropShadow {
        enabled: showDropShadow
        anchors {
            fill: effectContainer
            leftMargin: 1
            topMargin: 1
        }
        source: Rectangle {
            visible: false
            width: effectContainer.width - 2
            height: effectContainer.height - 2
            radius: containerRadius
        }
        radius: 12.0
        samples: 16
        color: "#80000000"
    }

    Item {
        id: effectContainer

        width: contentContainer.width
        height: contentContainer.height

        ShaderEffectSource {
            id: effectSource

            live: true
            sourceItem: effectSourceItem
            anchors.fill: effectContainer
            sourceRect: sourceItem.mapToItem(sourceItem,
                                             root.x, root.y,
                                             width, height)
        }

        component CachedBlur : FastBlur {
            cached: true
            layer.enabled: true
        }

        // Nesting faster blurs reduces artifacts as the sample count is
        // has been fixed and with a larger radius the artifacts are more
        // visible.
        CachedBlur {
            id: topBlur
            anchors.fill: effectContainer
            source: effectSource
            radius: blurRadius
            layer.effect: CachedBlur {
                anchors.fill: topBlur
                source: topBlur
                radius: 32
                layer.effect: ColorOverlay { color: effectColor }
            }
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                color: "black"
                width: effectContainer.width
                height: effectContainer.height
                radius: containerRadius
            }
        }
    }

    Item {
        id: contentContainer

        width: root.contentItem.width
        height: root.contentItem.height
    }
}

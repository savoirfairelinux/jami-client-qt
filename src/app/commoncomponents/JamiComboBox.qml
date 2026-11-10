/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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
pragma ComponentBehavior: Bound
import QtQuick
import Jami as JamiStyle
import net.jami.Constants 1.1

JamiStyle.ComboBox {
    id: control

    padding: 0

    // Accessibility name and description for the combobox itself
    required property string accessibilityName
    required property string accessibilityDescription

    // Content specific requirements
    required property real comboBoxPointSize

    // Accessibility
    Accessible.role: Accessible.ComboBox
    Accessible.name: accessibilityName
    Accessible.description: accessibilityDescription.arg(displayText)
    Accessible.focusable: true

    font.pointSize: comboBoxPointSize
}

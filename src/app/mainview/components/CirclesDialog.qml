/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

// The Circles of the account: create one, or manage one and broadcast to it.
BaseModalDialog {
    id: root
    objectName: "circlesDialog"

    property var circleService: CircleAdapter

    signal createRequested
    signal manageRequested(string circleId)

    titleText: JamiStrings.functionCircles

    popupContent: ColumnLayout {
        width: 440
        spacing: 10

        CircleList {
            Layout.fillWidth: true
            sectionTitle: JamiStrings.myCircles
            circles: root.circleService.circles
            onCreateRequested: {
                root.createRequested();
                root.close();
            }
            onManageRequested: function (id) {
                root.manageRequested(id);
                root.close();
            }
        }
    }
}

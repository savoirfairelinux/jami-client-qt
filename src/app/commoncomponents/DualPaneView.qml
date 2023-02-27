import QtQuick
import QtQuick.Controls

import net.jami.Constants 1.1

BaseView {
    id: viewNode

    required property Item leftPaneItem
    required property Item rightPaneItem

    property alias sv1: sv1
    property alias sv2: sv2

    onPresented: {
        leftPaneItem.parent = sv1
        rightPaneItem.parent = sv2
        splitView.restoreState(viewCoordinator.splitViewState)
        // Avoid double triggering this handler during instantiation.
        onIsSinglePaneChanged.connect(isSinglePaneChangedHandler)
    }

    property Item splitViewQCI
    Component.onCompleted: {
        sv1.SplitView.preferredWidth = viewCoordinator.defaultLeftPanelWidth
        splitViewQCI = sv1.parent
        sv1.parent = Qt.binding(() => activeParent)
    }

    property real splitThreshold: 400
    property bool isSinglePane: viewNode.width > 0 &&
                                viewNode.width < splitThreshold

    property Item activeParent: isSinglePane ?
                                    singlePaneContainer :
                                    splitViewQCI

    // Override this if needed.
    property var isSinglePaneChangedHandler: function() {
        if (isSinglePane) {
            rightPaneItem.parent = sv1
        } else {
            rightPaneItem.parent = sv2
        }
    }

    Item {
        id: singlePaneContainer
        anchors.fill: parent
        visible: isSinglePane
    }

    SplitView {
        id: splitView
        anchors.fill: parent
        visible: !isSinglePane
        onResizingChanged: {
            if (!resizing) {
                viewCoordinator.splitViewState = splitView.saveState()
            }
        }

        handle: Rectangle {
            implicitWidth: JamiTheme.splitViewHandlePreferredWidth
            implicitHeight: splitView.height
            color: JamiTheme.primaryBackgroundColor
            Rectangle {
                implicitWidth: 1
                implicitHeight: splitView.height
                color: JamiTheme.tabbarBorderColor
            }
        }

        StackView {
            id: sv1
            SplitView.minimumWidth: 300
            SplitView.preferredWidth: 300
            clip: true
        }
        StackView { id: sv2 }
    }
}

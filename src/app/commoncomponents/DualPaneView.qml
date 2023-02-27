import QtQuick
import QtQuick.Controls

import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseView {
    id: viewNode

    required property Item leftPaneItem
    required property Item rightPaneItem

    property alias sv1: sv1
    property alias sv2: sv2

    property string splitViewStateKey: objectName

    function saveSplitViewState() {
        UtilsAdapter.setAppValue("sv_" + splitViewStateKey, splitView.saveState())
    }

    function restoreSplitViewState() {
        splitView.restoreState(UtilsAdapter.getAppValue("sv_" + splitViewStateKey))
    }

    onPresented: {
        leftPaneItem.parent = sv1
        rightPaneItem.parent = sv2

        restoreSplitViewState()

        // Avoid double triggering this handler during instantiation.
        onIsSinglePaneChanged.connect(isSinglePaneChangedHandler)
        resolvePanes()
    }
    onDismissed: saveSplitViewState()

    property Item splitViewQCI
    Component.onCompleted: {
        sv1.SplitView.preferredWidth = 300
        splitViewQCI = sv1.parent
        sv1.parent = Qt.binding(() => activeParent)
    }

    property bool isSinglePane

    property Item activeParent: isSinglePane ? singlePaneContainer : splitViewQCI

    property real minimumRightPaneWidth: JamiTheme.chatViewHeaderMinimumWidth
    property real previousWidth: viewNode.width
    property real mainViewSidePanelRectWidth: sv1.width
    property real previousSidePanelWidth: sv1.width
    onWidthChanged: resolvePanes()
    function resolvePanes() {
        const isExpanding = previousWidth < viewNode.width
        if (viewNode.width < minimumRightPaneWidth + sv1.width
                && sv2.visible && !isExpanding) {
            // Save the side panel width and go into single pane mode.
            previousSidePanelWidth = sv1.width
            isSinglePane = true
        } else if (viewNode.width >= previousSidePanelWidth + minimumRightPaneWidth
                   && !sv2.visible && isExpanding && !layoutManager.isFullScreen) {
            // Restore dual pane mode.
            isSinglePane = false
        }
        previousWidth = viewNode.width
    }

    // Override this if needed.
    property var isSinglePaneChangedHandler: function() {
        rightPaneItem.parent = isSinglePane ? sv1 : sv2
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
        onResizingChanged: if (!resizing) saveSplitViewState()

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
            SplitView.maximumWidth: isSinglePane ?
                                        undefined :
                                        viewNode.width - minimumRightPaneWidth
            SplitView.preferredWidth: 300
            clip: true
        }
        StackView {
            id: sv2
            clip: true
        }
    }
}

import QtQuick

DualPaneView {
    id: viewNode

    // True if the right pane should never show in single pane mode.
    property bool isGimp: false

    Component.onCompleted: {
        if (isGimp) return
        onIndexChanged.connect(function() {
            if (index >= 0) {
                if (selectionFallback && isSinglePane) {
                    rightPaneItem.parent = sv1
                } else return
            }
            if (index >= 0) return
            if (!isSinglePane) dismiss()
            else handlePanes()
        })
    }

    // True if we should dismiss to the left pane if in single pane mode.
    // Also causes selection of a default index (0) in dual pane mode.
    property bool selectionFallback: false

    property int index: -1
    function selectIndex(index) { viewNode.index = index }

//    function dismiss() {
//        if (isSinglePane) {
//            if (!selectionFallback) viewCoordinator.dismiss(objectName)
//            else if (isSinglePane && sv1.children.length > 1) {
//                rightPaneItem.parent = null
//                //leftPaneItem.deselect()
//            }
//        } else viewCoordinator.dismiss(objectName)
//    }

    onPresented: handlePanes()
    onDismissed: {
        leftPaneItem.indexSelected.disconnect(selectIndex)
        //leftPaneItem.deselect()
    }

    function handlePanes() {
        if (isGimp) return
        // When transitioning from split to single pane, we need to move
        // the right pane item to left stack view if it has a valid index.
        if (isSinglePane) {
            if (viewNode.index >= 0) {
                rightPaneItem.parent = sv1
            }
        } else {
            rightPaneItem.parent = sv2
            // May need a default selection of item 0 here.
            if (index < 0 && selectionFallback) leftPaneItem.select(0)
        }
    }

    onLeftPaneItemChanged: {
        if (leftPaneItem) leftPaneItem.indexSelected.connect(selectIndex)
    }
    isSinglePaneChangedHandler: handlePanes
}

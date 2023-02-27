import QtQuick

Rectangle {
    id: root

    anchors.fill: parent

    // Override these if needed.
    property var select: function() {}
    property var deselect: function() {}

    signal indexSelected(int index)
    signal deselected
}

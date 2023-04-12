import QtQuick

Rectangle {
    id: root
    property var deselect: function () {}

    // Override these if needed.
    property var select: function () {}

    anchors.fill: parent

    signal deselected
    signal indexSelected(int index)
}

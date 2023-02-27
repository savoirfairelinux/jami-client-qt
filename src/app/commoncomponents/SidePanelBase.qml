import QtQuick

Item {
    id: root

    anchors.fill: parent

    function select(index) { listView.currentIndex = index }
    function deselect() { listView.currentIndex = -1 }
    signal indexSelected(int index)
    signal deselected
}

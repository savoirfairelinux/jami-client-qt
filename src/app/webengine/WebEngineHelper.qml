import QtQuick
import QtWebEngine

// Simple helper that can safely use instanceof WebEngineView
QtObject {
    function countWebEngineViews(fullScreenItems) {
        return fullScreenItems.filter(o => o.item instanceof WebEngineView).length
    }
} 
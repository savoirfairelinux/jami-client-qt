import QtQuick 2.15
import QtWebEngine 1.10

WebEngineView {
    id: root

    property string dir

    width: 1
    height: 1

    backgroundColor: "transparent"

    settings.javascriptCanOpenWindows: false
    settings.localContentCanAccessRemoteUrls: true
    settings.localContentCanAccessFileUrls: true

    anchors.fill: parent

    onContentsSizeChanged: {
        width = contentsSize.width
        height = contentsSize.height
    }

    onNavigationRequested: function(request) {
        if (request.navigationType ===
                WebEngineNavigationRequest.LinkClickedNavigation) {
            Qt.openUrlExternally(request.url)
            request.action = WebEngineNavigationRequest.IgnoreRequest
        }
    }

    function loadContent(info) {
        var imageHtml = ""
        if (info.image !== undefined) {
            imageHtml = '<img class="preview_image" src="' + info.image + '">'
        }
        var descriptionHtml = ""
        if (info.description !== undefined) {
            descriptionHtml = '<p class="preview_card_subtitle">' + info.description + '</p>'
        }
        loadHtml('<head><link rel="stylesheet" href="qrc:/misc/previewInfo.css"></head><body>
                  <div class="msg_cell_with_preview"><div class="preview_wrapper_' + dir + '">
                  <div class="preview_card_container"><div class="card_container_ ' + dir + '">
                  <a class="preview_container_link" href="' + info.url + '" target="_self">
                  ' + imageHtml + '
                  <div class="preview_text_container">
                  <pre class="preview_card_title">' + info.title + '</pre>
                  ' + descriptionHtml + '
                  <p class="preview_card_link">' + info.domain + '</p>
                  </div></a></div></div></div></div></body>')
    }
}


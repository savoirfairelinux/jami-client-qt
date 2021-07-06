import QtQuick 2.15
import QtWebEngine 1.10

WebEngineView {
    property var information
    property string dir

    backgroundColor: "transparent"

    settings.javascriptCanOpenWindows: false
    settings.localContentCanAccessRemoteUrls: true
    settings.localContentCanAccessFileUrls: true

    function loadContent() {
        var imageHtml = ""
        if (information.image !== undefined) {
            imageHtml = '<img class="preview_image" src="' + information.image + '">'
        }
        var descriptionHtml = ""
        if (information.description !== undefined) {
            descriptionHtml = '<p class="preview_card_subtitle">' + information.description + '</p>'
        }
        loadHtml('<head><link rel="stylesheet" href="qrc:/misc/previewInfo.css"></head><body>
                  <div class="msg_cell_with_preview"><div class="preview_wrapper_in' + dir + '">
                  <div class="preview_card_container"><div class="card_container_ ' + dir + '">
                  <a class="preview_container_link" href="' + information.url + '" target="_self">
                  ' + imageHtml + '
                  <div class="preview_text_container">
                  <pre class="preview_card_title">' + information.title + '</pre>
                  ' + descriptionHtml + '
                  <p class="preview_card_link">' + information.domain + '</p>
                  </div></a></div></div></div></div></body>')
    }
}


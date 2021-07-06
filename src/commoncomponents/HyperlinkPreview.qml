import QtQuick 2.0
import QtWebEngine 1.8

WebEngineView {
    id: previewWev

    property var information

    //                property var locale: Qt.LocaleDate

    backgroundColor: "transparent"
    anchors.fill: parent

    settings.localContentCanAccessRemoteUrls: true
    settings.localContentCanAccessFileUrls: true

    Component.onCompleted: {
//        textBackground.width = previewLoader.width
//        squareRect.width = textBackground.width

        var imageHtml = ""
        if (information.image !== undefined){
            imageHtml = "<img class=\"preview_image\" src=\"" + information.image + "\">"
        }
        var descriptionHtml = ""
        if (information.description !== undefined) {
            descriptionHtml = "<p class=\"preview_card_subtitle\">" + information.description + "</p>"
        }

        loadHtml("<head> <link rel=\"stylesheet\" href=\"qrc:/misc/previewInfo.css\"></head>
                  <body>
                  <div class=\"msg_cell_with_preview\">
                  <div class=\"preview_wrapper_in\">
                  <div class=\"preview_card_container\">
                  <div class=\"card_container_in\">
                  <a class=\"preview_container_link\" href=\"" + information.url + "\" target=\"_blank\">
                    " + imageHtml + "
                  <div class=\"preview_text_container\">
                  <pre class=\"preview_card_title\">" + information.title + "</pre>
                  " + descriptionHtml + "
                  <p class=\"preview_card_link\">" + information.domain + "</p>
                  </div>
                  </a>
                  </div>
                  </div>
                  </div>
                  </div>
                  </body>", "")
    }
}


_ = new QWebChannel(qt.webChannelTransport, function (channel) {
    window.jsbridge = channel.objects.jsbridge
})

function log(msg) {
    window.jsbridge.log(msg)
}



function getPreviewInfo(messageId, url) {
    var title = null
    var description = null
    var image = null
    if (!url.includes("http://") && !url.includes("https://")) {
        url = "http://".concat(url)
    }
    fetch(url, {
              mode: 'cors',
              headers: {'Set-Cookie': 'SameSite=None; Secure'}
          })
    .then(function (response) {
        return response.text()
    }).then(function (html) {
        // create DOM from html string
        var parser = new DOMParser()
        var doc = parser.parseFromString(html, "text/html")
        if (!url.includes("twitter.com")){
            title = getTitle(doc)
            image = getImage(doc, url)
            description = getDescription(doc)
            var domain = (new URL(url))
            domain = (domain.hostname).replace("www.", "")
        } else {
            title = "Twitter. It's what's happening."
        }

        window.jsbridge.infoReady(messageId, {
                                      'title': title,
                                      'image': image,
                                      'description': description,
                                      'url': url,
                                      'domain': domain,
                                  })
    }).catch(function (err) {
        // Error occured while fetching document
        log("Error occured while fetching document")
        console.warn("Warning", err)
    })
}

function parseMessage(messageId, message)
{
    var linkifiedString = linkifyStr(message)
    window.jsbridge.messageLinkifyReady(messageId, linkifiedString)

    var linkArray = linkify.find(message)
    if (linkArray.length > 0){
        getPreviewInfo(messageId, linkArray[0].href)
    }
}

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
    var u = new URL(url)
    if (u.protocol === '') {
        url = "https://".concat(url)
    }
    var domain = (new URL(url))
    fetch(url, {
              mode: 'no-cors',
              headers: {'Set-Cookie': 'SameSite=None; Secure'}
          }).then(function (response) {
        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('text/html')) {
            return
        }
        return response.body
    }).then(body => {
        const reader = body.getReader();

        return new ReadableStream({
          start(controller) {
            return pump();

            function pump() {
                return reader.read().then(({ done, value }) => {
                    // When no more data needs to be consumed, close the stream
                    if (done) {
                        controller.close();
                        return;
                    }
                    if(value.byteLength > 2*1024*1024) {
                        controller.close();
                        return;
                    }

                    // Enqueue the next data chunk into our target stream
                    controller.enqueue(value);
                    return pump();
                });
            }
          }
        })
      }, e => Promise.reject(e))
      .then(stream => new Response(stream))
      .then(response => response.text())
      .then(function (html) {
        // create DOM from html string
        var parser = new DOMParser()
        var doc = parser.parseFromString(html, "text/html")
        if (!url.includes("twitter.com")){
            title = getTitle(doc)
        } else {
            title = "Twitter. It's what's happening."
        }
        image = getImage(doc, url)
        description = getDescription(doc)
        domain = (domain.hostname).replace("www.", "")
    }).catch(function (err) {
        log("Error occured while fetching document: " + err)
    }).finally(() => {
        window.jsbridge.emitInfoReady(messageId, {
            'title': title,
            'image': image,
            'description': description,
            'url': url,
            'domain': domain,
        })
    })
}

function parseMessage(messageId, message, showPreview, color='#0645AD') {
    var links = linkify.find(message)
    if (links.length === 0) {
        return
    }
    if (showPreview)
        getPreviewInfo(messageId, links[0].href)
    window.jsbridge.emitLinkified(messageId, linkifyStr(message, {
        attributes: {
          style: "color:" + color + ";"
        }
    }))
}

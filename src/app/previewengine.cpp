/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "previewengine.h"

#include <QRegularExpression>

static QString
getInnerHtml(const QString& tag)
{
    static const QRegularExpression re(">([^<]+)<");
    const auto match = re.match(tag);
    return match.hasMatch() ? match.captured(1) : QString {};
};

const QRegularExpression PreviewEngine::newlineRe("\\n");

PreviewEngine::PreviewEngine(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
    , htmlParser_(new HtmlParser(this))
{
    // Connect on a queued connection to avoid blocking caller thread.
    connect(this, &PreviewEngine::parseLink, this, &PreviewEngine::onParseLink, Qt::QueuedConnection);
}

QString
PreviewEngine::getTagContent(QList<QString>& tags, const QString& value)
{
    Q_FOREACH (auto tag, tags) {
        const QRegularExpression re("(property|name)=\"(og:|twitter:|)" + value
                                    + "\".*?content=\"([^\"]+)\"");

        const auto match = re.match(tag.remove(newlineRe));
        if (match.hasMatch()) {
            return match.captured(3);
        }
    }
    return QString {};
}

QString
PreviewEngine::getTitle(HtmlParser::TagInfoList& metaTags)
{
    // Try with opengraph/twitter props
    QString title = getTagContent(metaTags[TidyTag_META], "title");
    if (title.isEmpty()) { // Try with title tag
        title = getInnerHtml(htmlParser_->getFirstTagValue(TidyTag_TITLE));
    }
    if (title.isEmpty()) { // Try with h1 tag
        title = getInnerHtml(htmlParser_->getFirstTagValue(TidyTag_H1));
    }
    if (title.isEmpty()) { // Try with h2 tag
        title = getInnerHtml(htmlParser_->getFirstTagValue(TidyTag_H2));
    }
    return title;
}

QString
PreviewEngine::getDescription(HtmlParser::TagInfoList& metaTags)
{
    // Try with og/twitter props
    QString d = getTagContent(metaTags[TidyTag_META], "description");
    if (d.isEmpty()) { // Try with first paragraph
        d = getInnerHtml(htmlParser_->getFirstTagValue(TidyTag_P));
    }
    return d;
}

QString
PreviewEngine::getImage(HtmlParser::TagInfoList& metaTags)
{
    static const QRegularExpression newlineRe("\\n");
    // Try with og/twitter props
    QString image = getTagContent(metaTags[TidyTag_META], "image");
    if (image.isEmpty()) { // Try with href of link tag (rel="image_src")
        auto tags = htmlParser_->getTags({TidyTag_LINK});
        Q_FOREACH (auto tag, tags[TidyTag_LINK]) {
            static const QRegularExpression re("rel=\"image_src\".*?href=\"([^\"]+)\"");
            const auto match = re.match(tag.remove(newlineRe));
            if (match.hasMatch()) {
                return match.captured(1);
            }
        }
    }
    return image;
}

void
PreviewEngine::onParseLink(const QString& messageId, const QString& link)
{
    sendGetRequest(QUrl(link), [this, messageId, link](const QByteArray& html) {
        htmlParser_->parseHtmlString(html);
        auto metaTags = htmlParser_->getTags({TidyTag_META});
        Q_EMIT infoReady(messageId,
                         {{"title", getTitle(metaTags)},
                          {"description", getDescription(metaTags)},
                          {"image", getImage(metaTags)},
                          {"url", link},
                          {"domain", QUrl(link).host()}});
    });
}

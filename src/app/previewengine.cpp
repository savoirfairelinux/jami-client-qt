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

#include "htmlparser.h"

#include <QRegularExpression>

PreviewEngine::PreviewEngine(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
    , htmlParser_(new HtmlParser(this))
{
    // Connect on a queued connection to avoid blocking caller thread.
    connect(this, &PreviewEngine::parseLink, this, &PreviewEngine::onParseLink, Qt::QueuedConnection);
}

void
PreviewEngine::onParseLink(const QString& messageId, const QString& link)
{
    qDebug() << Q_FUNC_INFO << messageId << link;
    static const QRegularExpression newlineRe("\\n");
    get(QUrl(link), [this](const QString& html) {
        static auto getTagContent = [](QList<QString>& tags, const QString& value) {
            Q_FOREACH (auto tag, tags) {
                const QRegularExpression re("(property|name)=\"(og:|twitter:|)" + value
                                            + "\".*?content=\"([^\"]+)\"");

                const auto match = re.match(tag.remove(newlineRe));
                if (match.hasMatch()) {
                    return match.captured(3);
                }
            }
            return QString {};
        };
        static auto getInnerHtml = [](const QString& tag) {
            static const QRegularExpression re(">([^<]+)<");
            const auto match = re.match(tag);
            return match.hasMatch() ? match.captured(1) : QString {};
        };

        htmlParser_->parseHtmlString(html);
        auto metaTags = htmlParser_->getTags({TidyTag_META});

        static auto getTitle = [&]() {
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
        };

        static auto getDescription = [&]() {
            // Try with og/twitter props
            QString d = getTagContent(metaTags[TidyTag_META], "description");
            if (d.isEmpty()) { // Try with first paragraph
                d = getInnerHtml(htmlParser_->getFirstTagValue(TidyTag_P));
            }
            return d;
        };

        static auto getImage = [&]() {
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
        };

        qDebug() << "Title:" << getTitle();
        qDebug() << "Description:" << getDescription();
        qDebug() << "Image:" << getImage();

        return;
    });
}

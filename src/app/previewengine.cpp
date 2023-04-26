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

PreviewEngine::PreviewEngine(ConnectivityMonitor* cm, QObject* parent)
    : NetWorkManager(cm, parent)
    , htmlParser_(new HtmlParser(this))
{
    // Connect on a queued connection to avoid blocking caller thread.
    connect(this, &PreviewEngine::parseLink, this, &PreviewEngine::onParseLink, Qt::QueuedConnection);
}

void
PreviewEngine::onParseLink(const QString& messageId, const QString& link)
{
    qDebug() << Q_FUNC_INFO << messageId << link;
    get(link, [this](const QString& html) {
        //        qDebug() << "HTML:" << html;
        //        htmlParser_->parseHtmlString(html);
        //        auto tagsMap = htmlParser_->getTags({TidyTag_META, TidyTag_A});
        //        qWarning() << tagsMap[QString::number(TidyTag_A)];
        //        // Loop through all the meta tags and extract the ones we are interested in.
        //        // For the title, we are interested in the following tags:
        //        // 1. og:title
        //        // 2. twitter:title
        //        for (auto& tag : tagsMap) {
        //            if (tag.toString().contains("og:title") ||
        //            tag.toString().contains("twitter:title")) {
        //                qDebug() << "Title:" << tag;
        //            }
        //        }
    });
}

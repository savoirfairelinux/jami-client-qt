/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

#pragma once

#include <QObject>
#include <QVariantMap>

#include "tidy.h"
#include "tidybuffio.h"

// This class is used to parse HTML strings. It uses the libtidy library to parse
// the HTML and traverse the DOM tree. It can be used to extract a list of tags
// and their values from an HTML string.
// Currently, it is used to extract the <a> and <pre> tags from a message body,
// and in the future it can be used in conjunction with QtNetwork to generate link
// previews without having to use QtWebEngine.
class HtmlParser : public QObject
{
    Q_OBJECT
public:
    HtmlParser(QObject* parent = nullptr)
        : QObject(parent)
    {
        doc_ = tidyCreate();
        tidyOptSetBool(doc_, TidyQuiet, yes);
        tidyOptSetBool(doc_, TidyShowWarnings, no);
        tidyOptSetBool(doc_, TidyUseCustomTags, yes);
    }

    ~HtmlParser()
    {
        tidyRelease(doc_);
    }

    bool parseHtmlString(const QString& html)
    {
        return tidyParseString(doc_, html.toLocal8Bit().data()) >= 0;
    }

    using TagInfoList = QMap<TidyTagId, QList<QString>>;

    // A function that traverses the DOM tree and fills a QVariantMap with a list
    // of the tags and their values. The result is structured as follows:
    // {tagId1: ["tagValue1", "tagValue2", ...],
    //  tagId: ["tagValue1", "tagValue2", ...],
    //  ... }
    TagInfoList getTags(const QList<TidyTagId>& tags, int maxDepth = -1)
    {
        TagInfoList result;
        traverseNode(
            tidyGetRoot(doc_),
            tags,
            [&result](const QString& value, TidyTagId tag) { result[tag].append(value); },
            maxDepth);

        return result;
    }

    QString getFirstTagValue(TidyTagId tag, int maxDepth = -1)
    {
        QString result;
        traverseNode(
            tidyGetRoot(doc_),
            {tag},
            [&result](const QString& value, TidyTagId) { result = value; },
            maxDepth);
        return result;
    }

private:
    // NOLINTNEXTLINE(misc-no-recursion)
    void traverseNode(TidyNode node,
                      const QList<TidyTagId>& tags,
                      const std::function<void(const QString&, TidyTagId)>& cb,
                      int depth = -1)
    {
        TidyBuffer nodeValue = {};
        for (auto tag : tags) {
            if (tidyNodeGetId(node) == tag && tidyNodeGetText(doc_, node, &nodeValue) == yes && cb) {
                cb(QString::fromLocal8Bit(nodeValue.bp), tag);
                if (depth != -1 && --depth == 0) {
                    return;
                }
            }
        }

        // Traverse the children of the current node.
        for (TidyNode child = tidyGetChild(node); child; child = tidyGetNext(child)) {
            traverseNode(child, tags, cb, depth);
        }
    }

    TidyDoc doc_;
};

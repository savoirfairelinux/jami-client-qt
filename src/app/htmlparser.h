/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
        tidyOptSetInt(doc_, TidyUseCustomTags, TidyCustomEmpty);
    }

    ~HtmlParser()
    {
        tidyRelease(doc_);
    }

    bool parseHtmlString(const QString& html)
    {
        return tidyParseString(doc_, html.toLocal8Bit().data()) >= 0;
        //return tidyParseString(doc_, html.toUtf8().data()) >= 0;
    }

    using TagNodeList = QMap<TidyTagId, QList<TidyNode>>;

    // A function that traverses the DOM tree and fills a QVariantMap with a list
    // of the tags and their nodes. The result is structured as follows:
    // {tagId1: [tagNode1, tagNode2, ...],
    //  tagId2: [tagNode3, tagNode4, ...],
    //  ... }
    TagNodeList getTagsNodes(const QList<TidyTagId>& tags, int maxDepth = -1)
    {
        TagNodeList result;
        traverseNode(
            tidyGetRoot(doc_),
            tags,
            [&result](TidyNode node, TidyTagId tag) { result[tag].append(node); },
            maxDepth);

        return result;
    }

    // The same as the above function, only it returns the first node for a single tag.
    TidyNode getFirstTagNode(TidyTagId tag, int maxDepth = -1)
    {
        TidyNode result = nullptr;
        traverseNode(
            tidyGetRoot(doc_),
            {tag},
            [&result](TidyNode node, TidyTagId) { result = node; },
            maxDepth);
        return result;
    }

    // Extract the text value from a node.
    QString getNodeText(TidyNode node)
    {
        TidyBuffer nodeValue = {0};
        if (!node || tidyNodeGetText(doc_, node, &nodeValue) != yes) {
            return QString();
        }
        QString result;
        if (nodeValue.bp && nodeValue.size > 0) {
            result = QString::fromUtf8(reinterpret_cast<char*>(nodeValue.bp), nodeValue.size);
        }
        tidyBufFree(&nodeValue);
        return result;
    }

    // Extract the attribute value from a node.
    QString getNodeAttr(TidyNode node, TidyAttrId attrId)
    {
        TidyAttr attr = tidyAttrGetById(node, attrId);
        if (!attr) {
            return QString();
        }
        const auto* attrValue = tidyAttrValue(attr);
        if (!attrValue) {
            return QString();
        }
        return QString::fromLocal8Bit(attrValue);
    }

    // Extract the inner HTML of a node.
    QString getNodeInnerHtml(TidyNode node)
    {
        if (!node) {
            return QString();
        }
        const auto* child = tidyGetChild(node);
        return child ? getNodeText(child) : QString();
    }

    QString getTagInnerHtml(TidyTagId tag)
    {
        return getNodeInnerHtml(getFirstTagNode(tag));
    }

private:
    // NOLINTNEXTLINE(misc-no-recursion)
    void traverseNode(TidyNode node,
                      const QList<TidyTagId>& tags,
                      const std::function<void(TidyNode, TidyTagId)>& cb,
                      int depth = -1)
    {
        for (auto tag : tags) {
            if (tidyNodeGetId(node) == tag && cb) {
                cb(node, tag);
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

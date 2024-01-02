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

#include "messageparser.h"

#include "previewengine.h"
#include "htmlparser.h"

#include <QRegularExpression>
#include <QtConcurrent>

#include "md4c-html.h"

namespace {
// A callback function that will be called by the md4c library (`md_html`) to output the HTML.
void
htmlChunkCb(const MD_CHAR* data, MD_SIZE data_size, void* userData)
{
    QByteArray* array = static_cast<QByteArray*>(userData);
    if (data_size > 0) {
        array->append(data, int(data_size));
    }
};
} // namespace

MessageParser::MessageParser(PreviewEngine* previewEngine, QObject* parent)
    : QObject(parent)
    , previewEngine_(previewEngine)
    , htmlParser_(new HtmlParser(this))
    , threadPool_(new QThreadPool(this))
{
    threadPool_->setMaxThreadCount(1);
    connect(previewEngine_, &PreviewEngine::infoReady, this, &MessageParser::linkInfoReady);
}

void
MessageParser::parseMessage(const QString& messageId,
                            const QString& msg,
                            bool previewLinks,
                            const QColor& linkColor,
                            const QColor& backgroundColor)
{
    // Run everything here on a separate thread.
    threadPool_->start(
        [this, messageId, md = msg, previewLinks, linkColor, backgroundColor]() mutable -> void {
            preprocessMarkdown(md);
            auto html = markdownToHtml(md.toUtf8().constData());

            // Now that we have the HTML, we can parse it to get a list of tags and their values.
            // We are only interested in the <a> and <pre> tags.
            htmlParser_->parseHtmlString(html);
            auto tagsMap = htmlParser_->getTagsNodes({TidyTag_A, TidyTag_DEL, TidyTag_PRE});

            static const QString styleTag("<style>%1</style>");
            QString style;

            // Check for any <pre> tags. If there are any, we need to:
            // 1. add some CSS to color them.
            // 2. add some CSS to make them wrap.
            if (tagsMap.contains(TidyTag_PRE)) {
                auto textColor = (0.2126 * backgroundColor.red() + 0.7152 * backgroundColor.green()
                                  + 0.0722 * backgroundColor.blue())
                                         < 153
                                     ? QColor(255, 255, 255)
                                     : QColor(0, 0, 0);
                style += QString("pre,code{background-color:%1;"
                                 "color:%2;white-space:pre-wrap;}")
                             .arg(backgroundColor.name(), textColor.name());
            }

            // md4c makes DEL tags instead of S tags for ~~strikethrough-text~~,
            // so we need to style the DEL tag content.
            if (tagsMap.contains(TidyTag_DEL)) {
                style += QString("del{text-decoration:line-through;}");
            }

            // Check for any <a> tags. If there are any, we need to:
            // 1. add some CSS to color them.
            // 2. parse them to get a preview IF the user has enabled link previews.
            if (tagsMap.contains(TidyTag_A)) {
                style += QString("a{color:%1;}").arg(linkColor.name());

                // Update the UI before we start parsing the link.
                html.prepend(QString(styleTag).arg(style));
                Q_EMIT messageParsed(messageId, html);

                // If the user has enabled link previews, then we need to generate the link preview.
                if (previewLinks) {
                    // Get the first link in the message.
                    auto href = htmlParser_->getNodeAttr(tagsMap[TidyTag_A].first(), TidyAttr_HREF);
                    if (!href.isEmpty()) {
                        Q_EMIT previewEngine_->parseLink(messageId, href);
                    }
                }

                return;
            }

            // If the message didn't contain any links, then we can just update the UI.
            html.prepend(QString(styleTag).arg(style));
            Q_EMIT messageParsed(messageId, html);
        });
}

void
MessageParser::preprocessMarkdown(QString& markdown)
{
    // Match all instances of the linefeed character.
    static const QRegularExpression newlineRegex("\\r?\\n");
    static const QString newline = "  \n";

    // Replace all instances of the linefeed character with 2 spaces + a linefeed character
    // in order to force a line break in the HTML.
    // Note: we should only do this for non-code fenced blocks.
    static const QRegularExpression codeFenceRe("`{1,3}([\\s\\S]*?)`{1,3}");
    auto match = codeFenceRe.globalMatch(markdown);

    // If there are no code blocks, then we can just replace all linefeeds with 2 spaces
    // + a linefeed, and we're done.
    if (!match.hasNext()) {
        markdown.replace(newlineRegex, newline);
        return;
    }

    // Save each block of text and code. The text blocks will be
    // processed for line breaks and the code blocks will be left
    // as is.
    enum BlockType { Text, Code };
    QVector<QPair<BlockType, QString>> codeBlocks;

    qsizetype start = 0;
    while (match.hasNext()) {
        auto m = match.next();
        auto nonCodelength = m.capturedStart() - start;
        if (nonCodelength) {
            codeBlocks.push_back({Text, markdown.mid(start, nonCodelength)});
        }
        codeBlocks.push_back({Code, m.captured(0)});
        start = m.capturedStart() + m.capturedLength();
    }
    // There may be some text after the last code block.
    if (start < markdown.size()) {
        codeBlocks.push_back({Text, markdown.mid(start)});
    }

    // Now we can process the text blocks.
    markdown.clear();
    for (auto& block : codeBlocks) {
        if (block.first == Text) {
            // Replace all newlines with two spaces and a newline.
            block.second.replace(newlineRegex, newline);
        }
        markdown += block.second;
    }
}

QString
MessageParser::markdownToHtml(const char* markdown)
{
    static auto md_flags = MD_FLAG_PERMISSIVEAUTOLINKS | MD_FLAG_NOINDENTEDCODEBLOCKS
                           | MD_FLAG_TASKLISTS | MD_FLAG_STRIKETHROUGH | MD_FLAG_UNDERLINE;
    const size_t data_len = strlen(markdown);
    if (data_len <= 0) {
        return QString();
    }
    QByteArray array;
    const int result = md_html(markdown, MD_SIZE(data_len), &htmlChunkCb, &array, md_flags, 0);
    return result == 0 ? QString::fromUtf8(array) : QString();
}

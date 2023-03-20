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

#include "messageparser.h"

#include "previewengine.h"
#include "htmlparser.h"

#include <QRegularExpression>
#include <QtConcurrent>

#include "md4c-html.h"

MessageParser::MessageParser(PreviewEngine* previewEngine, QObject* parent)
    : QObject(parent)
    , previewEngine_(previewEngine)
    , htmlParser_(new HtmlParser(this))
{
    connect(previewEngine_, &PreviewEngine::infoReady, this, &MessageParser::linkInfoReady);
}

void
MessageParser::parseMessage(const QString& messageId,
                            const QString& msg,
                            bool previewLinks,
                            const QColor& linkColor)
{
    // Run everything here on a separate thread.
    std::ignore = QtConcurrent::run(
        [this, messageId, msg = msg, previewLinks, linkColor]() mutable -> void {
            preprocessMarkdown(msg);
            auto html = markdownToHtml(msg.toUtf8().constData());

            // qDebug() << "HTML:" << html;

            // Now that we have the HTML, we can parse it to get a list of tags and their values.
            // We are only interested in the <a> and <pre> tags.
            htmlParser_->parseHtmlString(html);
            auto tagsMap = htmlParser_->getTags({TidyTag_A, TidyTag_PRE});

            // Check for any <pre> tags. If there are any, we need to:
            // 1. add some CSS to color them.
            // 2. add some CSS to make them wrap.
            if (tagsMap.contains(QString::number(TidyTag_PRE))) {
                html.prepend(QString("<style>pre,code{background-color:%1;"
                                     "color:%2;white-space:pre-wrap;}</style>")
                                 .arg("#f0f0f0")
                                 .arg("#222222"));
            }

            // qDebug() << "HTML2:" << html;

            // Check for any <a> tags. If there are any, we need to:
            // 1. add some CSS to color them.
            // 2. parse them to get a preview IF the user has enabled link previews.
            if (tagsMap.contains(QString::number(TidyTag_A))) {
                html.prepend(QString("<style>a{color:%1;}</style>").arg(linkColor.name()));

                // Update the UI before we start parsing the link.
                Q_EMIT messageParsed(messageId, html);

                // If the user has enabled link previews, then we need to generate the link preview.
                if (previewLinks) {
                    // Get the first link in the message.
                    auto anchorTag = tagsMap[QString::number(TidyTag_A)].toList().first().toString();
                    static QRegularExpression hrefRegex("href=\"(.*?)\"");
                    auto match = hrefRegex.match(anchorTag);
                    if (match.hasMatch()) {
                        previewEngine_->parseMessage(messageId, match.captured(1));
                    }
                }

                return;
            }

            // If the message didn't contain any links, then we can just update the UI.
            Q_EMIT messageParsed(messageId, html);
        });
}

void
MessageParser::preprocessMarkdown(QString& markdown)
{
    qDebug() << "Markdown:" << markdown;

    // Match all instances of the linefeed character.
    static QRegularExpression newlineRegex("\n");

    // Replace all instances of the linefeed character with 2 spaces + a linefeed character
    // in order to force a line break in the HTML.
    // Note: we should only do this for non-code fenced blocks.
    static QRegularExpression codeFenceRe("`{3}([\\s\\S]*?)`{3}");
    auto match = codeFenceRe.globalMatch(markdown);

    // If there are no code blocks, then we can just replace all linefeeds with 2 spaces
    // + a linefeed, and we're done.
    if (!match.hasNext()) {
        markdown.replace(newlineRegex, "  \n");
        return;
    }

    // Otherwise, we need to invert the matches, and replace all linefeeds in the non-code blocks
    int start = 0;
    int end;
    int offset = 0;
    while (match.hasNext()) {
        auto m = match.next();
        auto nonCodelength = m.capturedStart() + offset - start;
        auto nonCodeBlock = markdown.mid(start, nonCodelength);
        qDebug() << "***** Non-code block:" << nonCodeBlock;
        auto lastNonCodeBlockSize = nonCodeBlock.size();
        nonCodeBlock.replace(newlineRegex, "  \n");
        markdown.replace(start, nonCodelength, nonCodeBlock);
        offset += nonCodeBlock.size() - lastNonCodeBlockSize;
        start = m.capturedEnd() + (nonCodeBlock.size() - lastNonCodeBlockSize);
        end = m.capturedEnd();
    }

    qDebug() << "Markdown2:" << markdown;
}

// A callback function that will be called by the md4c library (`md_html`) to output the HTML.
static void
htmlChunkCb(const MD_CHAR* data, MD_SIZE data_size, void* userData)
{
    QByteArray* array = static_cast<QByteArray*>(userData);
    if (data_size > 0) {
        array->append(data, int(data_size));
    }
};

QString
MessageParser::markdownToHtml(const char* markdown)
{
    static auto md_flags = MD_FLAG_COLLAPSEWHITESPACE | MD_FLAG_WIKILINKS | MD_FLAG_LATEXMATHSPANS
                           | MD_FLAG_PERMISSIVEAUTOLINKS | MD_FLAG_UNDERLINE
                           | MD_FLAG_STRIKETHROUGH;
    size_t data_len = strlen(markdown);
    if (data_len <= 0) {
        return QString();
    } else {
        QByteArray array;
        int result = md_html(markdown, MD_SIZE(data_len), &htmlChunkCb, &array, md_flags, 0);
        return result == 0 ? QString::fromUtf8(array) : QString();
    }
}
